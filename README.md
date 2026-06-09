 - [home-manager](https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module)
 - [sops-nix](https://github.com/Mic92/sops-nix)
 - [nixos-anywhere](https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md)
 - https://haseebmajid.dev/posts/2025-12-31-how-to-setup-a-new-pc-with-lanzaboote-tpm-decryption-sops-nix-impermanence-nixos-anywhere/

nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hosts/test-vm/hardware-configuration.nix --extra-files /tmp/extra --flake .#test-vm --target-host nixos@192.168.2.54