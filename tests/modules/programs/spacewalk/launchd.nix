{ config, ... }:

let
  package = config.lib.test.mkStubPackage {
    name = "spacewalk";
    buildScript = ''
      mkdir -p $out/Applications/Spacewalk.app/Contents/MacOS
      touch $out/Applications/Spacewalk.app/Contents/MacOS/Spacewalk
      chmod +x $out/Applications/Spacewalk.app/Contents/MacOS/Spacewalk
    '';
  };
in
{
  xdg.configHome = "${config.home.homeDirectory}/custom-config";

  imports = [
    { programs.spacewalk.settings.transition.effect = "slide"; }
    { programs.spacewalk.settings.shortcuts.space-1 = "alt-1"; }
  ];

  programs.spacewalk = {
    enable = true;
    inherit package;
    launchd.enable = true;
    settings = {
      transition = {
        duration-ms = 240;
        easing = "easeInOut";
      };
      advanced.launch-at-login = true;
      shortcuts.space-9 = "alt-9";
    };
  };

  nmt.script = ''
    assertFileExists home-path/Applications/Spacewalk.app/Contents/MacOS/Spacewalk
    assertPathNotExists home-files/custom-config/spacewalk
    assertFileContains activate 'display_path=/home/hm-user/custom-config/spacewalk/config.toml'
    settings="$(grep -m1 -o '/nix/store/[^ ]*-spacewalk-config.toml' "$TESTED/activate")"
    assertFileContent "$settings" ${./launchd-settings-expected.toml}
    serviceFile=$(normalizeStorePaths LaunchAgents/org.nix-community.home.spacewalk.plist)
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${./launchd-expected.plist}
  '';
}
