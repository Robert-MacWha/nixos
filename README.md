 - [home-manager](https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module)
 - [sops-nix](https://github.com/Mic92/sops-nix)
 - [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md)
 - https://haseebmajid.dev/posts/2025-12-31-how-to-setup-a-new-pc-with-lanzaboote-tpm-decryption-sops-nix-impermanence-nixos-anywhere/


## Setting up new machine:
1. Create new entry in flake.nix & new machine directory
2. Boot image into a linux environment (e.g. using a live USB or existing distro install) and enable root password ssh access.
3. Run nix-anywhere to install nixos: `nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hosts/test-vm/hardware-configuration.nix --extra-files /tmp/extra --flake .#test-vm --target-host nixos@192.168.2.54`
4. Record the new machine's age key with `nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"`
5. Add the new key to the .sops.yaml file and update secrets with `make update-keys`
6. Rebuild the new machine with `make update TARGET=test-vm HOST=192.168.2.159`

## Verifying a new service on an impermanent machine

Machines using the `preservation` module (`perth`, `test-vm`, `fehu`) wipe `/`
on every boot. `preservation.nix` on these hosts preserves all of `/var/lib`
(covers `/var/lib/private/<name>` for `DynamicUser` services too), so
anything a service writes there is safe. Anything written **outside**
`/var/lib` — e.g. a config dir under `/root`, `/opt`, or somewhere
non-standard — is lost on reboot. Before trusting a newly added service,
check it rather than waiting to find out via data loss:

1. Check whether the service is sandboxed to fail loudly instead of losing
   data silently: `systemctl cat <service>` and look for `ProtectSystem=strict`
   (or `full` combined with `DynamicUser=true`). If present, writes outside
   the allowed paths error out immediately instead of silently disappearing.
   Don't expect this by default, though — mainstream self-hosted/media
   services (jellyfin, immich, sonarr/radarr/prowlarr) generally run
   unsandboxed on this axis, since they need access to arbitrary
   user-configured library paths that can't be statically enumerated. Only
   more contained services (e.g. victoriametrics) tend to get it.
2. If it's not sandboxed, run the service for a while doing normal
   operations, then **before rebooting**, audit the ephemeral root for
   anything that isn't accounted for by a known mount:
   ```
   find / -xdev -mount 2>/dev/null | grep -vE '^/(nix|persistent|proc|sys|dev|run|tmp)'
   ```
   Anything listed there will vanish on the next reboot.
