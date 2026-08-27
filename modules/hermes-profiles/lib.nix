# Pure helpers for turning a `hermes-profiles.<name>` submodule value into
# an on-disk profile tree. Kept free of `config` so it's easy to reason
# about and reuse; config.nix supplies the pieces that come from config
# (the base settings to inherit from, in particular).
{ lib, pkgs }:

with lib;

rec {
  yamlFormat = pkgs.formats.yaml { };

  # Recursively walk an arbitrarily-nested skills attrset and flatten it
  # into a list of { relPath, source } pairs, e.g.
  #
  #   { wikipedia.skill = ./a.md; wikipedia.search.skill = ./b.md; }
  #
  # (which Nix's dotted-attrpath merging turns into
  #   { wikipedia = { skill = ./a.md; search = { skill = ./b.md; }; }; })
  #
  # becomes
  #
  #   [ { relPath = "wikipedia/SKILL.md";        source = ./a.md; }
  #     { relPath = "wikipedia/search/SKILL.md"; source = ./b.md; } ]
  flattenSkills =
    prefix: skills:
    concatLists (
      mapAttrsToList (
        name: node:
        let
          here = if prefix == "" then name else "${prefix}/${name}";
          selfEntry = optional (node ? skill && node.skill != null) {
            relPath = "${here}/SKILL.md";
            source = node.skill;
          };
          # everything on this node besides `skill` is a nested skill name
          children = removeAttrs node [ "skill" ];
        in
        selfEntry ++ flattenSkills here children
      ) skills
    );

  # Build the full on-disk tree for one profile as a single derivation:
  #   config.yaml, profile.yaml, [SOUL.md], skills/**, home/**
  #
  # `baseSettings` is the settings attrset to deep-merge profile.settings
  # over (normally `config.services.hermes-agent.settings`).
  mkProfileDerivation =
    {
      name,
      profile,
      baseSettings,
      hermesPackage,
    }:
    let
      mergedSettings = recursiveUpdate baseSettings profile.settings;

      configYaml = yamlFormat.generate "hermes-profile-${name}-config.yaml" mergedSettings;

      profileYaml = yamlFormat.generate "hermes-profile-${name}-profile.yaml" (
        {
          description = profile.description;
        }
        // optionalAttrs (profile.required_skills != [ ]) {
          skills.required = profile.required_skills;
        }
      );

      skillFiles = flattenSkills "" profile.skills;

      copySkillCmds = concatMapStringsSep "\n" (entry: ''
        mkdir -p "$out/skills/$(dirname ${escapeShellArg entry.relPath})"
        cp ${entry.source} "$out/skills/${entry.relPath}"
      '') skillFiles;

      copyHomeFileCmds = concatStringsSep "\n" (
        mapAttrsToList (relPath: source: ''
          mkdir -p "$out/home/$(dirname ${escapeShellArg relPath})"
          cp ${source} "$out/home/${relPath}"
        '') profile.homeFiles
      );

      # Bundled skills live in the hermes-agent package as full directories
      # (SKILL.md plus any scripts/references) under skills/<path> or
      # optional-skills/<path>; copy whichever tree has a match.
      copyDefaultSkillCmds = concatMapStringsSep "\n" (relPath: ''
        src=""
        for base in ${hermesPackage}/share/hermes-agent/skills ${hermesPackage}/share/hermes-agent/optional-skills; do
          if [ -d "$base/${relPath}" ]; then
            src="$base/${relPath}"
            break
          fi
        done
        if [ -z "$src" ]; then
          echo "hermes-profiles: default skill '${relPath}' not found under ${hermesPackage}/share/hermes-agent/{skills,optional-skills}" >&2
          exit 1
        fi
        mkdir -p "$out/skills/$(dirname ${escapeShellArg relPath})"
        cp -r "$src" "$out/skills/${relPath}"
      '') profile.defaultSkills;
    in
    pkgs.runCommand "hermes-profile-${name}" { } ''
      mkdir -p "$out/skills" "$out/home"
      cp ${configYaml} "$out/config.yaml"
      cp ${profileYaml} "$out/profile.yaml"
      ${optionalString (profile.soul != null) ''
        cp ${profile.soul} "$out/SOUL.md"
      ''}
      ${copySkillCmds}
      ${copyDefaultSkillCmds}
      ${copyHomeFileCmds}
      chmod -R u+rwX,go+rX "$out"
    '';
}
