"""HackenProof MCP proxy with tool filtering + transparent decryption.

Proxies MCP requests to the HackenProof MCP server, applying these features:
 - Decryption of pgp-encrypted report fields in certain responses

The associated nix flake also exposes the configuration options as native
module options so they can be configured from the configuration.nix directly
instead of via hermes' configuration interface.
"""

import sys
import asyncio
import logging
import argparse
import re

from pgpy import PGPKey, PGPMessage
import mcp.types as types
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s hackenproof %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("hackenproof")

server = Server("hackenproof")

DECRYPT_TOOLS = {"get_report_details", "get_reports_details_batch"}
PGP_REGEX = re.compile(
    r'(-----BEGIN PGP MESSAGE-----.*?-----END PGP MESSAGE-----)', 
    re.DOTALL
)

KEYS: list[PGPKey] = []
UPSTREAM: ClientSession | None = None

def decrypt_armored(armored: str) -> str:
    """Decrypt one armored PGP block; return it unchanged on failure."""
    try:
        msg = PGPMessage.from_blob(armored)
    except Exception as e:
        log.warning("pgpy failed to parse blob: %s", e)
        return "...invalid pgp block..."
    
    last_err = None
    for key in KEYS:
        try:
            if key.is_protected:
                with key.unlock(""):
                    out = key.decrypt(msg)
            else:
                out = key.decrypt(msg)
            data = out.message
            return data.decode("utf-8") if isinstance(data, (bytes, bytearray)) else str(data)
        except Exception as e:  # wrong key for this message, try the next
            last_err = e
    
    log.warning("no loaded key could decrypt a PGP block: %s", last_err)
    return "...unable to decrypt pgp block with any loaded key..."

def replace_block(match):
    block_content = match.group(1)
    block_content = block_content.replace("\\n", "\n").replace("\\r", "\r")
    decrypted = decrypt_armored(block_content)
    return decrypted.replace('\n', '\\n').replace('\r', '')

def transform_block(block):
    if not isinstance(block, types.TextContent):
        return block
    
    text = block.text
    if not "BEGIN PGP MESSAGE" in text:
        return types.TextContent(type="text", text=text)
    
    text = PGP_REGEX.sub(replace_block, text)
    if "BEGIN PGP MESSAGE" in text:
        log.warning("pgp block(s) remain after decryption attempt; maybe the regex failed to match something?")
        return types.TextContent(type="text", text="...pgp block(s) remain after decryption attempt.  Call with fields `vulnerability_description` and `validation_steps` to get full text...")

    return types.TextContent(type="text", text=text)

# --- MCP handlers (delegate to upstream) -----------------------------------

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    result = await UPSTREAM.list_tools()
    return result.tools


@server.call_tool()
async def call_tool(name: str, arguments: dict | None):
    log.info("calling tool %s(%s)", name, arguments or {})

    try:
        result = await UPSTREAM.call_tool(name, arguments or {})
    except Exception as e:
        log.error("error calling tool %s: %s", name, e)
        raise RuntimeError(f"error calling tool {name!r}: {e}") from e
    
    content = result.content
    log.info("tool %s returned with result %s", name, result.content)
    if name in DECRYPT_TOOLS:
        content = [transform_block(b) for b in content]
    
    return types.CallToolResult(
        content=content,
        isError=result.isError,
        meta=result.meta,
        structuredContent=result.structuredContent
    )


async def main() -> None:
    global UPSTREAM

    p = argparse.ArgumentParser(prog="hackenproof-decrypt-proxy")
    p.add_argument("--api-key-file", required=True)
    p.add_argument("--key-file", action="append", default=[], dest="key_files")
    p.add_argument("--upstream-url", default="https://mcp.hackenproof.com/mcp")
    args = p.parse_args()

    for path in args.key_files:
        key, _ = PGPKey.from_file(path)
        KEYS.append(key)
    if not KEYS:
        raise ValueError("at least one --key-file must be provided")

    log.info("loaded %d private key(s)", len(KEYS))

    with open(args.api_key_file) as f:
        api_key = f.read().strip()
    if not api_key:
        raise ValueError(f"api key file {args.api_key_file!r} was empty")
    headers = {"X-Api-Key": api_key} if api_key else {}

    async with streamablehttp_client(args.upstream_url, headers=headers) as (read, write, _):
        async with ClientSession(read, write) as upstream:
            await upstream.initialize()
            UPSTREAM = upstream
            log.info("connected upstream; serving over stdio")
            async with stdio_server() as (sread, swrite):
                await server.run(
                    sread, swrite, server.create_initialization_options()
                )


if __name__ == "__main__":
    asyncio.run(main())