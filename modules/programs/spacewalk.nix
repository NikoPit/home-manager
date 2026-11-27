{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.spacewalk;
  tomlFormat = pkgs.formats.toml { };
  settingsPath = "${config.xdg.configHome}/spacewalk/config.toml";
in
{
  meta.maintainers = [ lib.maintainers.NikoPit ];

  options.programs.spacewalk = {
    enable = lib.mkEnableOption "Spacewalk, an animated macOS Spaces switcher";

    package = lib.mkPackageOption pkgs "spacewalk" {
      nullable = true;
      default = null;
      extraDescription = ''
        Spacewalk is not currently packaged in Nixpkgs. Set this to a package
        containing {file}`Applications/Spacewalk.app`, or leave it null when
        installing the application separately. A package is required when
        {option}`programs.spacewalk.launchd.enable` is enabled.
      '';
    };

    launchd.enable = lib.mkEnableOption "the Spacewalk launchd agent" // {
      description = ''
        Whether to start Spacewalk in the user's graphical login session.
        This requires {option}`programs.spacewalk.package`. The module disables
        Spacewalk's own login item through `advanced.launch-at-login` to avoid
        managing startup in two places.
      '';
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        transition = {
          effect = "slide";
          duration-ms = 240;
          easing = "easeInOut";
        };
        shortcuts.space-1 = "alt-1";
      };
      description = ''
        Settings merged into {file}`$XDG_CONFIG_HOME/spacewalk/config.toml`.
        See <https://github.com/InsaneArts/Spacewalk#settings> for supported keys.

        Spacewalk atomically rewrites this file when settings change. During
        activation, declared values take precedence over existing values while
        settings written by the application are preserved. Removing a Nix
        declaration does not remove its last value from the file. Comments and
        formatting are not preserved. Empty settings leave the file unmanaged.

        When {option}`programs.spacewalk.launchd.enable` is enabled,
        `advanced.launch-at-login` is forced to false. The agent exports
        `XDG_CONFIG_HOME` so Spacewalk uses Home Manager's configuration path.
        An externally launched application must receive the same environment
        variable when using a non-default {option}`xdg.configHome`.

        Screen Recording and Accessibility permissions must be granted manually
        on first launch. Spacewalk requires macOS 26.6 or newer on Apple Silicon.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "programs.spacewalk" pkgs [ "aarch64-darwin" ])
          {
            assertion = !cfg.launchd.enable || cfg.package != null;
            message = "programs.spacewalk.launchd.enable requires programs.spacewalk.package to be set.";
          }
        ];
      }

      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.packages = lib.optional (cfg.package != null) cfg.package;

        # A store symlink would be replaced by Spacewalk's atomic settings writes.
        home.activation.spacewalkSettings = lib.mkIf (cfg.settings != { }) (
          lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "linkGeneration" ] (
            lib.hm.generators.mkImpureConfigMerger {
              inherit pkgs;
              format = "toml";
              empty = "{}";
              jqOperation = "$dynamic * $static";
              path = settingsPath;
              staticSettings = tomlFormat.generate "spacewalk-config.toml" cfg.settings;
              mode = "600";
            }
          )
        );

        programs.spacewalk.settings = lib.mkIf cfg.launchd.enable {
          advanced.launch-at-login = lib.mkForce false;
        };

        launchd.agents.spacewalk = lib.mkIf (cfg.launchd.enable && cfg.package != null) {
          enable = true;
          config = {
            Program = "${cfg.package}/Applications/Spacewalk.app/Contents/MacOS/Spacewalk";
            EnvironmentVariables.XDG_CONFIG_HOME = config.xdg.configHome;
            KeepAlive = true;
            RunAtLoad = true;
            ProcessType = "Interactive";
            LimitLoadToSessionType = "Aqua";
          };
        };
      })
    ]
  );
}
