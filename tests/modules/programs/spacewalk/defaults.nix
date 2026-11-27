{ config, lib, ... }:

{
  programs.spacewalk.enable = true;

  assertions = [
    {
      assertion = config.programs.spacewalk.package == null;
      message = "Spacewalk must support an externally installed application by default.";
    }
    {
      assertion = !(config.home.activation ? spacewalkSettings);
      message = "Empty Spacewalk settings must not create an activation entry.";
    }
    {
      assertion = !(lib.any (package: lib.getName package == "spacewalk") config.home.packages);
      message = "A null Spacewalk package must not be installed.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/.config/spacewalk
    assertPathNotExists LaunchAgents/org.nix-community.home.spacewalk.plist
  '';
}
