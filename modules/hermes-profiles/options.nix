{ lib, ... }:

with lib;

let
  skillType = types.submodule {
    freeformType = types.attrsOf skillType;
    options.skill = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to this node's SKILL.md, if it is itself a skill.";
    };
  };

  profileType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Human readable description, written to profile.yaml.";
      };

      required_skills = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Skill names this profile always requires (-> profile.yaml `skills.required`).";
      };

      soul = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to this profile's SOUL.md.";
      };

      skills = mkOption {
        type = types.attrsOf skillType;
        default = { };
        example = literalExpression ''
          {
            wikipedia.skill = ./skills/wikipedia.md;
            wikipedia.search.skill = ./skills/wikipedia_search.md;
            wikipedia.read.skill = ./skills/wikipedia_read.md;
          }
        '';
        description = ''
          Recursive skill tree materialized under `skills/` in the profile
          directory. Each node's `skill` path becomes a `SKILL.md` at the
          corresponding nested path; any other attribute name nests
          further skills underneath it.
        '';
      };

      homeFiles = mkOption {
        type = types.attrsOf types.path;
        default = { };
        example = literalExpression ''
          {
            "hindsight/config.json" = ./hindsight/config.json;
          }
        '';
        description = ''
          Files to place at the given paths (relative to the profile's
          directory), mirroring `services.hermes-agent.hermesHomeFiles`.
        '';
      };

      defaultSkills = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "research/arxiv"
          "research/grounded-citations"
        ];
        description = ''
          Bundled hermes-agent skills to include, given as paths relative to
          the package's `skills/` or `optional-skills/` tree (whichever has
          a match). Copied in whole (SKILL.md plus any scripts/references)
          under `skills/<path>` in the profile directory.
        '';
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Hermes config.yaml settings for this profile. Deep-merged over
          `services.hermes-agent.settings` (profile values win). Note this
          only inherits the `settings` option itself -- fields the base
          hermes-agent module synthesizes from other options (e.g.
          `mcpServers.*` -> `mcp_servers`) are not automatically inherited;
          set them explicitly here if a profile needs them.
        '';
      };
    };
  };
in
{
  options.hermes-profiles = mkOption {
    type = types.attrsOf profileType;
    default = { };
    description = "Hermes agent profiles, materialized under <stateDir>/.hermes/profiles/<name>/.";
  };
}
