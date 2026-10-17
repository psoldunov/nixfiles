# Strata (github.com/Niko1221/Strata): runs Qwen3.8-Flash-Next on one GPU
# plus system RAM and serves OpenAI- and Anthropic-compatible APIs on
# localhost. Its own installer (setup.sh -> setup.py) owns the install: it
# makes a uv venv, installs ROCm from AMD's TheRock wheels into it (~10 GB),
# compiles the HIP engine for the card, downloads the model (~70 GB) and writes
# run-<model>.sh. None of that is Nix-built; upstream ships no package, and its
# own flake.nix is a CUDA-only dev shell.
#
# What Nix supplies is the place it runs: `strata-fhs`, an FHS sandbox. TheRock's
# clang, hipcc and libraries are prebuilt for a normal Linux, so they need
# /lib64/ld-linux, glibc headers in /usr/include and a GCC installation under
# /usr/lib/gcc to compile the engine against. That is how the one NixOS report
# upstream ran it (issue #349). `strata` is the front end: it clones the
# checkout on first use and runs setup, update and the shell inside the
# sandbox; start/stop go through the strata.service user unit.
{
  lib,
  buildFHSEnv,
  runCommand,
  writeShellApplication,
  coreutils,
  curl,
  git,
  # Where the checkout lives; setup puts the model files in `dataDir`.
  repoDir,
  dataDir,
  # setup's start script for the model: run-<tag>.sh.
  modelTag,
  # Flags `strata install` passes to setup.sh.
  installArgs,
  port,
}: let
  # Only the parts of a GCC installation that TheRock's clang searches for:
  # /usr/lib/gcc/<triple>/<version> (crtbegin.o, libgcc) and
  # /usr/include/c++/<version> (libstdc++'s headers).
  gccInstallTree = cc:
    runCommand "gcc-install-tree-${cc.version}" {} ''
      mkdir -p $out/lib $out/include
      ln -s ${cc}/lib/gcc $out/lib/gcc
      ln -s ${cc}/include/c++ $out/include/c++
    '';

  fhs = buildFHSEnv {
    name = "strata-fhs";
    targetPkgs = pkgs:
      with pkgs; [
        # setup.sh makes the venv with uv's own Python (STRATA_UV below).
        uv
        python3
        git
        curl
        cacert

        # The engine build: a host C++ compiler plus CMake/Ninja from here, the
        # HIP compiler from the TheRock wheels. GCC 14 is the vintage upstream
        # builds with (Ubuntu 24.04). The wrapped gcc14 owns /usr/bin; its
        # unwrapped compiler would shadow it and not find glibc's crt1.o.
        gcc14
        (gccInstallTree pkgs.gcc14.cc)
        binutils
        gnumake
        cmake
        ninja
        pkg-config

        # Libraries TheRock's binaries and the venv's pip wheels load.
        stdenv.cc.cc.lib
        zlib
        zstd
        xz
        bzip2
        libdrm
        numactl
        elfutils
        libxml2
        ncurses
        libffi
        expat
        openssl

        # Tools setup.py calls.
        pciutils
        procps
        util-linux
        which
        file
        gnutar
        gzip
        unzip
      ];
    # glibc's and the libraries' headers in /usr/include.
    extraOutputsToInstall = ["dev"];
    profile = ''
      # uv's managed Python everywhere, not just when /etc/os-release says NixOS.
      export STRATA_UV=1
      export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt
    '';
    runScript = "bash";
  };

  run = "${fhs}/bin/strata-fhs";
in
  (writeShellApplication {
    name = "strata";
    runtimeInputs = [coreutils curl git];
    text = ''
      repo=${lib.escapeShellArg repoDir}
      data=${lib.escapeShellArg dataDir}
      start_script="$repo/run-${modelTag}.sh"

      usage() {
        cat <<'EOF'
      Usage: strata <command> [args]

        install [args]   first install of the default model (clone, ROCm, engine,
                         model download); extra args go to setup.sh
        setup [args]     setup.sh with your own args (--setup for its menu)
        update [args]    update.sh: pull Strata and rebuild the engine
        check            setup.sh --check: what setup sees on this PC
        shell            a shell in the checkout, inside the FHS sandbox
        start | stop | restart | status
                         the strata.service user unit (the model server)
        logs [args]      journalctl for strata.service (-f to follow)
        health           GET /health from the running server
      EOF
      }

      checkout() {
        if [ ! -d "$repo/.git" ]; then
          mkdir -p "$(dirname "$repo")"
          git clone https://github.com/Niko1221/Strata.git "$repo"
        fi
        cd "$repo"
      }

      # The server only runs from strata.service, which lifts the memlock
      # limit, so setup never starts it in the foreground.
      cmd="''${1:-}"
      [ "$#" -gt 0 ] && shift
      case "$cmd" in
        install)
          checkout
          exec ${run} ./setup.sh ${lib.escapeShellArgs installArgs} --data-dir "$data" "$@"
          ;;
        setup)
          checkout
          exec ${run} ./setup.sh --data-dir "$data" --no-start --no-browser "$@"
          ;;
        update)
          checkout
          exec ${run} ./update.sh "$@"
          ;;
        check)
          checkout
          exec ${run} ./setup.sh --check
          ;;
        shell)
          checkout
          exec ${run}
          ;;
        start | restart)
          if [ ! -x "$start_script" ]; then
            echo "strata: $start_script is missing; run 'strata install' first." >&2
            exit 1
          fi
          systemctl --user "$cmd" strata.service
          echo "strata: loading the model (1-3 minutes); 'strata logs -f' shows progress."
          ;;
        stop | status)
          exec systemctl --user "$cmd" strata.service
          ;;
        logs)
          exec journalctl --user -u strata.service "$@"
          ;;
        health)
          exec curl -fsS http://127.0.0.1:${toString port}/health
          ;;
        "" | -h | --help | help)
          usage
          ;;
        *)
          echo "strata: unknown command '$cmd'" >&2
          usage >&2
          exit 1
          ;;
      esac
    '';
  })
  .overrideAttrs (old: {
    passthru = (old.passthru or {}) // {inherit fhs;};
  })
