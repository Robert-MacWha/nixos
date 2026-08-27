{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hermes-profiles;
  hermesCfg = config.services.hermes-agent;

  profilesRoot = "${hermesCfg.stateDir}/.hermes/profiles";

  runtimeDirs = [
    "cron"
    "home"
    "logs"
    "memories"
    "plans"
    "sessions"
    "skins"
    "workspace"
  ];

  profileLib = import ./lib.nix { inherit lib pkgs; };

  # Overwrite only the files/dirs this module owns; leave everything else
  # under the profile dir (memories, workspace, jobs, ...) untouched.
  syncProfile =
    name: profile:
    let
      drv = profileLib.mkProfileDerivation {
        inherit name profile;
        baseSettings = hermesCfg.settings;
        hermesPackage = hermesCfg.package;
      };
      dest = "${profilesRoot}/${name}";
      homeFilesManifest = "${dest}/.nix-managed-homefiles";
      currentHomeFiles = concatStringsSep " " (attrNames profile.homeFiles);
    in
    ''
      dest=${escapeShellArg dest}
      mkdir -p "$dest"

      # Runtime dirs: created empty on first sync, never touched again.
      ${concatMapStringsSep "\n" (d: ''
        mkdir -p "$dest/${d}"
        chown ${hermesCfg.user}:${hermesCfg.group} "$dest/${d}"
      '') runtimeDirs}

      # Managed files: always overwritten.
      cp -f ${drv}/config.yaml "$dest/config.yaml"
      cp -f ${drv}/profile.yaml "$dest/profile.yaml"
      if [ -e ${drv}/SOUL.md ]; then
        cp -f ${drv}/SOUL.md "$dest/SOUL.md"
      else
        rm -f "$dest/SOUL.md"
      fi

      chown ${hermesCfg.user}:${hermesCfg.group} \
        "$dest/config.yaml" "$dest/profile.yaml"
      [ -e "$dest/SOUL.md" ] && chown ${hermesCfg.user}:${hermesCfg.group} "$dest/SOUL.md"

      # Managed skill files: synced individually via manifest (like home
      # files below), so skills the agent creates on its own -- not tracked
      # here -- are never touched. The skills/ dir itself is owned by
      # hermes-agent so it can add to it.
      mkdir -p "$dest/skills"
      chown ${hermesCfg.user}:${hermesCfg.group} "$dest/skills"
      skillsManifest="$dest/.nix-managed-skills"
      currentSkills=$(cd ${drv}/skills && find . -type f -printf '%P\n' | sort | tr '\n' ' ')
      prune_stale "$skillsManifest" "$currentSkills" "$dest/skills"
      for f in $currentSkills; do
        mkdir -p "$dest/skills/$(dirname "$f")"
        cp -f "${drv}/skills/$f" "$dest/skills/$f"
        chown ${hermesCfg.user}:${hermesCfg.group} "$dest/skills/$f"
      done
      printf '%s\n' $currentSkills > "$skillsManifest"
      chown ${hermesCfg.user}:${hermesCfg.group} "$skillsManifest"

      # Home files: individual files placed at declared paths inside $dest,
      # which also holds runtime state (memories, workspace, jobs, ...) that
      # must never be touched. Same manifest-tracked approach as skills/
      # above: track what we've placed and prune only entries we previously
      # placed that are no longer declared.
      homeFilesManifest=${escapeShellArg homeFilesManifest}
      currentHomeFiles=${escapeShellArg currentHomeFiles}
      prune_stale "$homeFilesManifest" "$currentHomeFiles" "$dest"
      for f in $currentHomeFiles; do
        mkdir -p "$dest/$(dirname "$f")"
        cp -f "${drv}/home/$f" "$dest/$f"
        chown ${hermesCfg.user}:${hermesCfg.group} "$dest/$f"
      done
      printf '%s\n' $currentHomeFiles > "$homeFilesManifest"
      chown ${hermesCfg.user}:${hermesCfg.group} "$homeFilesManifest"

      # Everything else under $dest (memories, workspace, jobs, ...)
      # is left untouched.
    '';
in
{
  config = mkIf hermesCfg.enable {
    system.activationScripts.hermes-profiles-setup = {
      # Run after hermes-agent-setup (which nukes the top-level config.yaml)
      # and after the hermes user/group exist.
      deps = [
        "hermes-agent-setup"
        "users"
        "groups"
      ];
      text =
        let
          profileNames = attrNames cfg;

          # Manifest of profile names *this module* has previously created,
          # so we can tell "declared elsewhere / removed" apart from
          # "predates us / hand-made" when pruning. Lives alongside the
          # profiles themselves.
          manifestFile = "${profilesRoot}/.nix-managed-profiles";
        in
        ''
          set -eu
          profilesRoot=${escapeShellArg profilesRoot}
          manifestFile=${escapeShellArg manifestFile}
          mkdir -p "$profilesRoot"

          # Remove entries recorded in manifest file $1 that are no longer
          # present in the space-separated list $2, resolving them under
          # base dir $3. Only ever acts on entries found in the manifest, so
          # anything not nix-managed (or already removed) is never touched.
          prune_stale() {
            manifest=$1 current=$2 base=$3
            [ -f "$manifest" ] || return 0
            while IFS= read -r prev; do
              [ -z "$prev" ] && continue
              case "$prev" in
                /*|.|..|*..*) continue ;; # never trust a weird manifest entry
              esac
              keep=0
              for cur in $current; do
                if [ "$prev" = "$cur" ]; then
                  keep=1
                  break
                fi
              done
              if [ "$keep" -eq 0 ]; then
                echo "hermes-profiles: removing stale $base/$prev" >&2
                rm -rf "''${base:?}/$prev"
              fi
            done < "$manifest"
          }

          currentProfiles=${escapeShellArg (concatStringsSep " " profileNames)}
          prune_stale "$manifestFile" "$currentProfiles" "$profilesRoot"

          ${concatStringsSep "\n" (mapAttrsToList syncProfile cfg)}

          printf '%s\n' $currentProfiles > "$manifestFile"
          chown ${hermesCfg.user}:${hermesCfg.group} "$manifestFile"
        '';
    };
  };
}
