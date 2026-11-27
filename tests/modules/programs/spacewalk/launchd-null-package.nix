{
  programs.spacewalk = {
    enable = true;
    launchd.enable = true;
    package = null;
  };

  test.asserts.assertions.expected = [
    "programs.spacewalk.launchd.enable requires programs.spacewalk.package to be set."
  ];
}
