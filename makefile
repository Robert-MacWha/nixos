HOSTS := robert-desktop ansuz fehu kaunan
ARGS_robert-desktop := --flake .\#robert-desktop --sudo
ARGS_ansuz		    := --flake .\#ansuz --target-host root@192.168.2.127
ARGS_fehu           := --flake .\#fehu --target-host root@192.168.2.52
ARGS_kaunan         := --flake .\#kaunan --target-host root@192.168.2.53

# `make update fehu` deploys fehu; a bare `make update` rebuilds locally
REBUILD_ARGS = $(or $(ARGS_$(firstword $(filter $(HOSTS),$(MAKECMDGOALS)))),--sudo)

.PHONY: $(HOSTS)
$(HOSTS):
	@:

.PHONY: update
update:
	git add .
	nixos-rebuild switch $(REBUILD_ARGS)
	git commit -m "update: $$(date -Iseconds)" || true

.PHONY: upgrade
upgrade:
	git add .
	nix flake update
	nixos-rebuild switch --upgrade $(REBUILD_ARGS)
	git commit -m "upgrade: $$(date -Iseconds)" || true

.PHONY: push
push:
	git fetch
	git reset --soft @{u}
	git commit -m "squash: $$(date -Iseconds)" || true
	git push

.PHONY: clean
clean:
	angrr run
	sudo nix-collect-garbage -d
	nix-collect-garbage -d

.PHONY: optimise
optimise:
	nix-store --optimise

.PHONY: update-keys
update-keys:
	for f in secrets/*.yaml; do sops updatekeys -y "$$f"; done
