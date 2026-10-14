# Language runtimes on the Macs come from mise rather than nixpkgs, so they
# can track upstream releases. mise itself is from nixpkgs; `update_system`
# runs `mise upgrade` (through update_bleeding_edge). Projects pin their own
# versions in mise.toml; these are the global defaults.
{...}: {
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # The managed defaults go to conf.d/50-home-manager.toml, so
    # `mise use --global` can still write config.toml.
    mutableSettings = true;
    globalConfig.tools = {
      node = "lts";
      bun = "latest";
      deno = "latest";
      python = "latest";
    };
  };
}
