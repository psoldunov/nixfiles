# Strata: Qwen3.8-Flash-Next on the 7900 XTX plus system RAM, served on
# http://127.0.0.1:8080 (OpenAI /v1, Anthropic /v1/messages, a web chat at /).
# The package and why it runs in an FHS sandbox: ../../../../packages/strata.
#
# First install, once (the ROCm wheels, a 10-20 minute engine build and a
# ~70 GB download; rerunning continues where it stopped):
#
#   strata install
#
# Then `strata start` / `strata stop`. The unit has no WantedBy on purpose:
# the model locks ~35-55 GB of the 64 GB for the GPU while it runs, so it
# starts only when asked. A switch does not restart a running model either.
#
# The model is the full Qwen3.8-Flash-Next at IQ2_XS, upstream's pick for
# 64 GB of RAM. `strata setup --setup` adds another size or family; point
# `modelTag` at its run-<tag>.sh to serve that one instead.
#
# memlock: the engine mlock()s the expert arena and the PLE table, and without
# room to do so the kernel can page them out mid-answer. LimitMEMLOCK below is
# capped by the user manager's own hard limit, which
# ../../modules/services.nix lifts.
{
  config,
  lib,
  pkgs,
  ...
}: let
  root = "${config.xdg.dataHome}/strata";
  repoDir = "${root}/Strata";
  dataDir = "${root}/Strata-data";
  port = 8080;
  modelTag = "iq2_xs";
  # setup's default for a card with 20 GB of VRAM or more; written here so
  # pi's contextWindow below matches what the server allows.
  context = 131072;

  strata = pkgs.callPackage ../../../../packages/strata {
    inherit repoDir dataDir modelTag port;
    installArgs = [
      "--yes"
      "--backend"
      "hip"
      "--family"
      "qwen"
      "--model"
      "IQ2_XS"
      "--context"
      (toString context)
      "--port"
      (toString port)
      # The card also drives the 4K desktop. Upstream's 700 MiB default lets
      # the expert cache fill it until amdgpu evicts the compositor's buffers
      # (docs/AMD_HIP.md, #560).
      "--vram-reserve-mib"
      "3072"
      "--no-start"
      "--no-browser"
    ];
  };

  pi = config.programs.pi-coding-agent;
in {
  home.packages = [strata];

  systemd.user.services.strata = {
    Unit = {
      Description = "Strata model server (Qwen3.8-Flash-Next ${modelTag})";
      ConditionPathExists = "${repoDir}/run-${modelTag}.sh";
      # Reloading the model takes minutes and locks RAM again; a switch
      # leaves a running server alone.
      X-RestartIfChanged = false;
    };
    Service = {
      ExecStart = "${strata.fhs}/bin/strata-fhs ${repoDir}/run-${modelTag}.sh";
      WorkingDirectory = repoDir;
      LimitMEMLOCK = "infinity";
      # The first start reads ~40 GB into RAM before the port opens.
      TimeoutStartSec = "10min";
      TimeoutStopSec = "1min";
      # A crash is mostly memory pressure; a restart loop would only lock the
      # RAM again.
      Restart = "no";
    };
  };

  # pi: `strata/qwen3.8-flash-next` in /model once the server runs. Strata takes
  # any key and any model id. pi's thinking levels go out as reasoning_effort,
  # and Strata reads "none" as thinking off; it defaults to "high" when the
  # field is missing, so off is mapped explicitly.
  home.file."${pi.configDir}/models.json" = lib.mkIf pi.enable {
    text = builtins.toJSON {
      "$schema" = "https://pi.dev/schemas/models.schema.json";
      providers.strata = {
        name = "Strata (local)";
        baseUrl = "http://127.0.0.1:${toString port}/v1";
        api = "openai-completions";
        apiKey = "strata";
        models = [
          {
            id = "qwen3.8-flash-next";
            name = "Qwen3.8 Flash Next ${lib.toUpper modelTag} (Strata)";
            reasoning = true;
            thinkingLevelMap = {
              off = "none";
              minimal = null;
              low = "low";
              medium = "medium";
              high = "high";
              xhigh = "xhigh";
              max = null;
            };
            input = ["text"];
            contextWindow = context;
            maxTokens = 32000;
            cost = {
              input = 0;
              output = 0;
              cacheRead = 0;
              cacheWrite = 0;
            };
          }
        ];
      };
    };
  };
}
