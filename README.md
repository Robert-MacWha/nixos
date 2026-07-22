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

