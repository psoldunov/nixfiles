# Swift toolchain via swiftly, the upstream toolchain manager.
#
# nixpkgs pins Swift 5.10, which has no Swift 6 language mode and no
# swift-testing. swiftly installs current toolchains, but those are built for
# Ubuntu: dynamically linked, and their clang expects crt files, headers and
# libraries under /usr. So they run inside `swift-fhs`, a bubblewrap FHS env
# carrying swift.org's Ubuntu 24.04 dependency set. Thin wrappers put swift,
# swiftc, sourcekit-lsp, ... on PATH and re-enter the env on every call.
#
# Toolchains live in ~/.local/share/swiftly, outside the nix store:
#   swiftly install latest     # first toolchain; `swiftly use` to switch
#   swift-fhs                  # interactive shell inside the env
#   swift-fhs lldb ./.build/debug/App   # any other toolchain binary
#
# `swiftly install` ends with an apt-get prerequisites error and exit 1: it
# probes dpkg, which the env lacks. The toolchain still installs; the env
# already provides those packages.
#
# iOS/macOS app targets (SwiftUI, UIKit, Xcode projects) cannot build on
# Linux; this covers SwiftPM packages, CLIs, servers and editing.
{
  config,
  lib,
  pkgs,
  ...
}: let
  swiftly = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "swiftly";
    version = "1.2.0";

    src = pkgs.fetchurl {
      url = "https://download.swift.org/swiftly/linux/swiftly-${finalAttrs.version}-x86_64.tar.gz";
      hash = "sha256-Cya1aIEUBDdMfX8HJ2tqrUFF210Yk6RfMH3mqUyo2cM=";
    };

    sourceRoot = ".";

    # Upstream ships a statically linked binary: nothing to patch.
    installPhase = ''
      runHook preInstall
      install -Dm755 swiftly $out/bin/swiftly
      runHook postInstall
    '';

    meta = {
      description = "Swift toolchain installer and manager";
      homepage = "https://github.com/swiftlang/swiftly";
      license = lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = "swiftly";
    };
  });

  swiftlyHome = "${config.xdg.dataHome}/swiftly";
  swiftlyBin = "${swiftlyHome}/bin";

  swiftlyEnv = ''
    export SWIFTLY_HOME_DIR="${swiftlyHome}"
    export SWIFTLY_BIN_DIR="${swiftlyBin}"
    export SWIFTLY_TOOLCHAINS_DIR="${swiftlyHome}/toolchains"
  '';

  # The toolchain links Ubuntu's library layout. The FHS loader resolves
  # through ld.so.cache, which ldconfig keys by SONAME, so symlinked aliases
  # are not found: these carry the Ubuntu SONAMEs themselves. (SwiftBuild
  # also scrubs LD_LIBRARY_PATH from the tools it spawns.)
  #
  # Ubuntu's ncurses is narrow-char with a separate libtinfo, and the
  # toolchain requires its NCURSES6_* symbol versions; nixpkgs' default
  # wide build exports NCURSESW6_* from a single library.
  ncursesUbuntu = pkgs.ncurses.override {
    unicodeSupport = false;
    withTermlib = true;
  };

  # Debian ships the same libedit ABI as nixpkgs under SONAME libedit.so.2.
  libeditUbuntu = pkgs.runCommand "libedit-ubuntu" {nativeBuildInputs = [pkgs.patchelf];} ''
    mkdir -p $out/lib
    cp -L ${pkgs.libedit}/lib/libedit.so.0 $out/lib/libedit.so.2
    chmod u+w $out/lib/libedit.so.2
    patchelf --set-soname libedit.so.2 $out/lib/libedit.so.2
  '';

  swiftFhs = pkgs.buildFHSEnv {
    name = "swift-fhs";

    # swift.org's Ubuntu 24.04 prerequisites, plus the lib/dev outputs so
    # clang finds headers and linkable libraries under /usr. libxml2_13 and
    # python312 match the SONAMEs the toolchain links (libxml2.so.2,
    # libpython3.12.so.1.0); current libxml2 is libxml2.so.16.
    targetPkgs = p:
      with p; [
        swiftly
        binutils
        stdenv.cc.cc
        stdenv.cc.cc.lib
        glibc
        glibc.dev
        curl
        libxml2_13
        libedit
        libeditUbuntu
        ncursesUbuntu
        sqlite
        util-linux
        python312
        z3
        zlib
        openssl
        pkg-config
        git
        gnupg
        tzdata
        unzip
      ];
    extraOutputsToInstall = ["dev"];

    profile = ''
      ${swiftlyEnv}
      export PATH="${swiftlyBin}:$PATH"
      export SWIFT_FHS=1
    '';

    # No arguments: interactive shell. Otherwise run the given command.
    runScript = pkgs.writeShellScript "swift-fhs-run" ''
      if [ "$#" -eq 0 ]; then
        exec "''${SHELL:-bash}"
      fi
      exec "$@"
    '';
  };

  # swiftly's proxies in ${swiftlyBin} dispatch to the active toolchain.
  # Inside the env they already lead PATH; the guard only stops a nested
  # bubblewrap if something calls a wrapper by absolute path.
  mkSwiftTool = name:
    pkgs.writeShellScriptBin name ''
      if [ -n "''${SWIFT_FHS:-}" ]; then
        exec "${swiftlyBin}/${name}" "$@"
      fi
      exec ${swiftFhs}/bin/swift-fhs "${swiftlyBin}/${name}" "$@"
    '';

  swiftTools = [
    "swift"
    "swiftc"
    "sourcekit-lsp"
    "swift-format"
    "swift-demangle"
    "docc"
  ];

  # The nix-pinned binary, not the copy `swiftly init` leaves in the bin dir,
  # so a flake bump is what upgrades swiftly.
  swiftlyWrapper = pkgs.writeShellScriptBin "swiftly" ''
    exec ${swiftFhs}/bin/swift-fhs ${swiftly}/bin/swiftly "$@"
  '';
in {
  home.packages =
    [
      swiftFhs
      swiftlyWrapper
      pkgs.swiftlint
      pkgs.swiftformat
      # Built from source by overlays/periphery.nix; runs `swift` from above.
      pkgs.periphery
    ]
    ++ map mkSwiftTool swiftTools;

  # Offline, idempotent: writes config.json and the bin dir, installs no
  # toolchain. --platform skips os-release detection, which rejects NixOS.
  # --no-modify-profile because fish config is home-manager owned. init moves
  # its own executable into the bin dir, which fails from the read-only
  # store, so it runs from a writable copy.
  home.activation.swiftlyInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${swiftlyHome}/config.json" ]; then (
      ${swiftlyEnv}
      tmp=$(mktemp -d)
      install -m755 ${swiftly}/bin/swiftly "$tmp/swiftly"
      run "$tmp/swiftly" init --assume-yes --no-modify-profile \
        --skip-install --quiet-shell-followup --platform ubuntu24.04
      rm -f "$tmp/swiftly"
      rmdir "$tmp"
    ) fi
  '';
}
