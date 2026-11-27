{ lib, pkgs, ... }:

lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") {
  spacewalk-defaults = ./defaults.nix;
  spacewalk-settings = ./settings.nix;
  spacewalk-launchd = ./launchd.nix;
  spacewalk-launchd-null-package = ./launchd-null-package.nix;
  spacewalk-disabled = ./disabled.nix;
}
