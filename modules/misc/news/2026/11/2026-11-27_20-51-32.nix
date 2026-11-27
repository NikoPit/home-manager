{ pkgs, ... }:
{
  time = "2026-11-27T12:51:32+00:00";
  condition = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
  message = ''
    A new module is available: 'programs.spacewalk'. It manages Spacewalk's
    transition and shortcut settings, with optional launchd startup on macOS.
  '';
}
