{ config, ... }:

{
  programs.spacewalk = {
    enable = false;
    launchd.enable = true;
    settings.transition.effect = "slide";
  };

  assertions = [
    {
      assertion = !(config.home.activation ? spacewalkSettings);
      message = "Disabled Spacewalk must not merge settings.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/spacewalk
    assertPathNotExists LaunchAgents/org.nix-community.home.spacewalk.plist
    assertFileNotRegex activate 'spacewalk-config.toml'
  '';
}
