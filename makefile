TARGET ?=
HOST ?=

REBUILD_ARGS :=

ifdef TARGET
REBUILD_ARGS += --flake .\#$(TARGET)
endif

ifdef HOST
REBUILD_ARGS += --target-host root@$(HOST)
endif

.PHONY: update
update:
	git add .
	sudo nixos-rebuild switch $(REBUILD_ARGS)
	git commit -m "update: $$(date -Iseconds)" || true

.PHONY: upgrade
upgrade:
	git add .
	nix flake update
	nixos-rebuild switch --upgrade --sudo $(REBUILD_ARGS)
	git commit -m "upgrade: $$(date -Iseconds)" || true

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
	for f in secrets/*.yaml; do sops updatekeys -y "$f"; done
