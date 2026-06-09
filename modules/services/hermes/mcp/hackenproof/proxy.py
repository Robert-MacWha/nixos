"""HackenProof MCP proxy with tool filtering + transparent decryption.

Proxies MCP requests to the HackenProof MCP server, applying these features:
 - Tool filtering to allowlist or blocklist specific tools
 - Decryption of pgp-encrypted report fields in certain responses

The associated nix flake also exposes the configuration options as native
module options so they can be configured from the configuration.nix directly
instead of via hermes' configuration interface.
"""

import sys
import json
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
ENCRYPTED_FIELDS = ["vulnerability_description", "validation_steps"]
PGP_REGEX = re.compile(
    r'(-----BEGIN PGP MESSAGE-----.*?-----END PGP MESSAGE-----)', 
    re.DOTALL
)

KEYS: list[PGPKey] = []
ALLOWED: set[str] = set()
BLOCKED: set[str] = set()
UPSTREAM: ClientSession | None = None


def tool_permitted(name: str) -> bool:
    """Returns True if the tool is permitted by the current allow/block lists"""
    if ALLOWED and name not in ALLOWED:
        return False
    return name not in BLOCKED

def decrypt_armored(armored: str) -> str:
    """Decrypt one armored PGP block; return it unchanged on failure."""
    try:
        msg = PGPMessage.from_blob(armored)
    except Exception as e:
        log.warning("pgpy failed to parse blob: %s", e)
        return armored
    
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
    return armored


def decrypt_report(report) -> None:
    """Decrypt the configured field(s) on a single report dict, in place."""
    if not isinstance(report, dict):
        return
    for field in ENCRYPTED_FIELDS:
        val = report.get(field)
        if isinstance(val, str) and "BEGIN PGP MESSAGE" in val:
            # Find all PGP blocks in the text and replace them with their decrypted versions
            def replace_block(match):
                block = match.group(1)
                decrypted = decrypt_armored(block)
                return decrypted
            
            report[field] = PGP_REGEX.sub(replace_block, val)


def decrypt_payload(text: str) -> str:
    """Parse the tool's JSON text and decrypt fields on the report(s)."""
    try:
        payload = json.loads(text)
    except (ValueError, TypeError):
        return text
    
    if isinstance(payload, list):
        # list of reports from batch tool
        for r in payload:
            decrypt_report(r)
    else:
        # single report
        decrypt_report(payload)
    return json.dumps(payload)


def transform_block(block):
    if isinstance(block, types.TextContent):
        return types.TextContent(type="text", text=decrypt_payload(block.text))
    return block


# --- MCP handlers (delegate to upstream) -----------------------------------

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    result = await UPSTREAM.list_tools()
    return [t for t in result.tools if tool_permitted(t.name)]


@server.call_tool()
async def call_tool(name: str, arguments: dict | None):
    if not tool_permitted(name):
        raise ValueError(f"tool {name!r} is not permitted by this proxy")
    
    log.info("calling tool %s(%s)", name, arguments or {})
    result = None
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
    global UPSTREAM, ALLOWED, BLOCKED

    p = argparse.ArgumentParser(prog="hackenproof-decrypt-proxy")
    p.add_argument("--api-key-file", required=True)
    p.add_argument("--key-file", action="append", default=[], dest="key_files")
    p.add_argument("--upstream-url", default="https://mcp.hackenproof.com/mcp")
    p.add_argument("--allowed-tools", default="")
    p.add_argument("--blocked-tools", default="")
    args = p.parse_args()

    ALLOWED = {t.strip() for t in args.allowed_tools.split(",") if t.strip()}
    BLOCKED = {t.strip() for t in args.blocked_tools.split(",") if t.strip()}
    log.info("allowed tools: %s", ", ".join(ALLOWED) or "(all)")
    log.info("blocked tools: %s", ", ".join(BLOCKED) or "(none)")

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