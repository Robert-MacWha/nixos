.PHONY: update
update:
	sudo nixos-rebuild switch
	git add .
	git commit -m "update: $$(date -Iseconds)" || true

.PHONY: upgrade
upgrade:
	nix flake update
	sudo nixos-rebuild switch --upgrade
	git add .
	git commit -m "upgrade: $$(date -Iseconds)" || true

.PHONY: clean
clean:
	angrr run
	nix-collect-garbage -d

.PHONY: optimise
optimise:
	nix-store --optimise
