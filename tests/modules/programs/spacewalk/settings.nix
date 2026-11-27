{ config, lib, ... }:

{
  xdg.enable = false;
  programs.spacewalk = {
    enable = true;
    package = null;
    settings = {
      transition = {
        effect = "slide";
        duration-ms = 240;
        easing = "easeInOut";
      };
      shortcuts.space-1 = "alt-1";
    };
  };

  assertions = [
    {
      assertion =
        config.home.activation.spacewalkSettings.after == [ "linkGeneration" ]
        && config.home.activation.spacewalkSettings.before == [ "setupLaunchAgents" ];
      message = "Spacewalk settings must be merged after linking and before agent startup.";
    }
    {
      assertion = !(config.home.file ? ".config/spacewalk/config.toml");
      message = "Spacewalk's writable settings must not be replaced by a store symlink.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "spacewalk") config.home.packages);
      message = "Spacewalk settings must not require package installation.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/spacewalk
    assertPathNotExists LaunchAgents/org.nix-community.home.spacewalk.plist
    assertFileContains activate 'display_path=/home/hm-user/.config/spacewalk/config.toml'
    settings="$(grep -m1 -o '/nix/store/[^ ]*-spacewalk-config.toml' "$TESTED/activate")"
    assertFileContent "$settings" ${./settings-expected.toml}
  '';
}
