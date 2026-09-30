# Periphery — finds unused code in Swift packages. nixpkgs packages only the
# upstream macOS binary (platforms = aarch64-darwin), and upstream ships no
# Linux release, so on Linux we build it from source.
#
# Periphery 3.x needs Swift 6.x, and nixpkgs' Swift is 5.10. The swift.org
# Ubuntu toolchain expects an Ubuntu /usr layout, so the build runs inside a
# buildFHSEnv carrying swift.org's Ubuntu 24.04 dependency set (bubblewrap
# works inside the Nix sandbox). The toolchain tarball is build-time only:
# the Swift stdlib is linked statically, and the one toolchain library
# Periphery links at runtime, libIndexStore.so, is copied into $out/lib.
#
# SwiftPM cannot fetch in the sandbox, so every dependency is fetched here at
# the revision pinned in upstream's Package.resolved and Package.swift is
# rewritten to use them as local path dependencies.
#
# On Linux Periphery only scans SwiftPM projects, and it drives them with
# `swift build`, so it needs a `swift` on PATH at runtime
# (hosts/whopper/home/dev/swift.nix provides one). It reads the index store
# from .build/debug/index/store, which only SwiftPM's native build system
# writes; Swift 6.4 defaults to swiftbuild, so scan with
#   periphery scan -- --build-system native
# or put `build_arguments: [--build-system, native]` in .periphery.yml.
#
# To bump: set `version`, refresh `src.hash`, then take each dependency's
# revision from the new tag's Package.resolved and refresh its hash with
#   nix flake prefetch github:<owner>/<repo>/<rev>
# `swiftVersion` follows https://www.swift.org/api/v1/install/releases.json:
#   nix store prefetch-file https://download.swift.org/swift-<v>-release/ubuntu2404/swift-<v>-RELEASE/swift-<v>-RELEASE-ubuntu24.04.tar.gz
self: super: let
  inherit (super) lib;

  version = "3.8.0";
  swiftVersion = "6.4.0";

  swiftToolchain = super.fetchurl {
    url = "https://download.swift.org/swift-${swiftVersion}-release/ubuntu2404/swift-${swiftVersion}-RELEASE/swift-${swiftVersion}-RELEASE-ubuntu24.04.tar.gz";
    hash = "sha256-afeytNvOYJC2ySGUtxFJoFfhYmkJO1qd3tOK/EoFCU4=";
  };

  # Linux dependencies from Package.resolved; xcodeproj (and its PathKit and
  # Spectre) are macOS-only. None of these has dependencies of its own.
  dependencies = [
    {
      owner = "apple";
      repo = "swift-system";
      rev = "7c6ad0fc39d0763e0b699210e4124afd5041c5df";
      hash = "sha256-bfxm2WS+4qcgSzheWTvRloDAIIIHzPZ8SaAZq9bWmSc=";
    }
    {
      owner = "jpsim";
      repo = "Yams";
      rev = "deaf82e867fa2cbd3cd865978b079bfcf384ac28";
      hash = "sha256-xEuCijDjhDPcn3HvZtAs/QM53QNiZRYBjzKgHGxh3n8=";
    }
    {
      owner = "tadija";
      repo = "AEXML";
      rev = "db806756c989760b35108146381535aec231092b";
      hash = "sha256-6KvO8zT667Td+4qOeYzHbd51hDzFJFrxcVyYr2h5igc=";
    }
    {
      owner = "apple";
      repo = "swift-argument-parser";
      rev = "626b5b7b2f45e1b0b1c6f4a309296d1d21d7311b";
      hash = "sha256-90ECc3iEmxvOUk9iLKbQdQEz88dOisPqWsJLOFcKUV8=";
    }
    {
      owner = "ileitch";
      repo = "swift-index-store";
      rev = "ed1f232d33b8e03956af0f4206fbd30171a43138";
      hash = "sha256-t2efXH2Vo9zIQulLpE8rRpujl12NJNDa+scqqId+WwY=";
    }
    {
      owner = "apple";
      repo = "swift-syntax";
      rev = "2b59c0c741e9184ab057fd22950b491076d42e91";
      hash = "sha256-k1jIzLL32iFSUpI6B3bGoVyEpbmwBoFat7g/GB+drFU=";
    }
    {
      owner = "ileitch";
      repo = "swift-filename-matcher";
      rev = "eef5ac0b6b3cdc64b3039b037bed2def8a1edaeb";
      hash = "sha256-JWqzIy1EpYwuOR88DrG/s7O1Kc61vsGiOZKH0g6dm6c=";
    }
  ];

  copyDependencies =
    lib.concatMapStringsSep "\n" (dep: ''
      cp -r --no-preserve=mode ${super.fetchFromGitHub {inherit (dep) owner repo rev hash;}} deps/${dep.repo}
    '')
    dependencies;

  # The toolchain links Ubuntu's narrow-char ncurses with a separate libtinfo
  # and requires its NCURSES6_* symbol versions (see swift.nix).
  ncursesUbuntu = super.ncurses.override {
    unicodeSupport = false;
    withTermlib = true;
  };

  # Only what compiling and linking a SwiftPM package touches: swift-frontend,
  # swift-build/swift-package, clang and lld, and the C/C++ sysroot. lldb and
  # the REPL (python, libedit) are never run.
  buildEnv = super.buildFHSEnv {
    name = "periphery-swift-build";
    targetPkgs = p:
      with p; [
        bash
        coreutils
        findutils
        gnugrep
        gnused
        binutils
        stdenv.cc.cc
        stdenv.cc.cc.lib
        glibc
        glibc.dev
        curl
        libxml2_13
        ncursesUbuntu
        sqlite
        util-linux
        zlib
      ];
    extraOutputsToInstall = ["dev"];
    runScript = "bash";
  };
in {
  periphery = super.stdenv.mkDerivation {
    pname = "periphery";
    inherit version;

    src = super.fetchFromGitHub {
      owner = "peripheryapp";
      repo = "periphery";
      tag = version;
      hash = "sha256-MULY3pvebzdMqm5/xbv/Xu0c0JuAGSBmjY0I86EhjmM=";
    };

    nativeBuildInputs = [super.autoPatchelfHook];
    buildInputs = [
      super.stdenv.cc.cc.lib
      super.curl
      super.libxml2_13
      super.zlib
    ];

    postPatch = ''
      mkdir deps
      ${copyDependencies}

      sed -i -E \
        's#\.package\(url: "https://github\.com/[^/"]+/([^"]+)", [^)]*\)#.package(path: "deps/\1")#' \
        Package.swift
      rm Package.resolved
      if grep -q 'package(url:' Package.swift; then
        echo "Package.swift still has a remote dependency" >&2
        exit 1
      fi

      # Shell commands (swift build, swift package describe) run through bash.
      substituteInPlace Sources/Shared/Shell.swift \
        --replace-fail '"/bin/bash"' '"${lib.getExe super.bash}"'
    '';

    dontConfigure = true;

    # The script runs inside the FHS env, after its /etc/profile. Unset the
    # stdenv compiler variables: SwiftPM would take CC for its C targets.
    # SwiftPM's native build system, not the default swiftbuild: swiftbuild
    # drops the autolink entries of the static Foundation libraries, so a
    # --static-swift-stdlib link misses CoreFoundation, _CFXMLInterface, ICU.
    buildPhase = ''
      runHook preBuild

      mkdir swift home
      tar -xzf ${swiftToolchain} -C swift --strip-components=1

      cat > build.sh <<EOF
      set -euo pipefail
      unset CC CXX LD AR NM RANLIB
      export HOME="$PWD/home"
      export PATH="$PWD/swift/usr/bin:\$PATH"
      flags=(-c release --static-swift-stdlib --build-system native)
      swift build "\''${flags[@]}" --product periphery -j $NIX_BUILD_CORES
      cp "\$(swift build "\''${flags[@]}" --show-bin-path)/periphery" periphery-bin
      EOF
      ${buildEnv}/bin/periphery-swift-build build.sh

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 periphery-bin $out/bin/periphery
      # Drop the RPATH into the build-dir toolchain; autoPatchelf sets one.
      patchelf --remove-rpath $out/bin/periphery
      mkdir -p $out/lib
      cp -P swift/usr/lib/libIndexStore.so* $out/lib/
      runHook postInstall
    '';

    meta = {
      description = "Tool to identify unused code in Swift projects";
      homepage = "https://github.com/peripheryapp/periphery";
      changelog = "https://github.com/peripheryapp/periphery/releases/tag/${version}";
      license = lib.licenses.mit;
      sourceProvenance = [
        lib.sourceTypes.fromSource
        # libIndexStore.so comes prebuilt from the swift.org toolchain.
        lib.sourceTypes.binaryNativeCode
      ];
      mainProgram = "periphery";
      platforms = ["x86_64-linux"];
    };
  };
}
