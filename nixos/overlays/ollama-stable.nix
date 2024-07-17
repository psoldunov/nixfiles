self: super: {
  ollama-stable = let
    pname = "ollama";
    version = "0.1.38";

    src = super.fetchFromGitHub {
      owner = "jmorganca";
      repo = "ollama";
      rev = "v${version}";
      hash = "sha256-9HHR48gqETYVJgIaDH8s/yHTrDPEmHm80shpDNS+6hY=";
      fetchSubmodules = true;
    };

    vendorHash = "sha256-zOQGhNcGNlQppTqZdPfx+y4fUrxH0NOUl38FN8J6ffE=";

    preparePatch = patch: hash:
      super.fetchpatch {
        url = "file://${src}/llm/patches/${patch}";
        inherit hash;
        stripLen = 1;
        extraPrefix = "llm/llama.cpp/";
      };

    llamacppPatches = [
      (preparePatch "02-clip-log.diff" "sha256-rMWbl3QgrPlhisTeHwD7EnGRJyOhLB4UeS7rqa0tdXM=")
      (preparePatch "03-load_exception.diff" "sha256-1DfNahFYYxqlx4E4pwMKQpL+XR0bibYnDFGt6dCL4TM=")
      (preparePatch "04-metal.diff" "sha256-Ne8J9R8NndUosSK0qoMvFfKNwqV5xhhce1nSoYrZo7Y=")
      (preparePatch "05-clip-fix.diff" "sha256-rCc3xNuJR11OkyiXuau8y46hb+KYk40ZqH1Llq+lqWc=")
    ];

    defaultConfig = {
      acceleration = null;
      rocmSupport = false;
      cudaSupport = false;
    };

    config = super.lib.mkMerge [defaultConfig (super.config or {})];

    accelIsValid = builtins.elem (config.acceleration or null) [null false "rocm" "cuda"];

    validateFallback =
      super.lib.warnIf (config.rocmSupport && config.cudaSupport)
      (super.lib.concatStrings [
        "both `nixpkgs.config.rocmSupport` and `nixpkgs.config.cudaSupport` are enabled, "
        "but they are mutually exclusive; falling back to cpu"
      ])
      (!(config.rocmSupport && config.cudaSupport));

    validateLinux = api: (super.lib.warnIfNot super.stdenv.isLinux
      "building ollama with `${api}` is only supported on linux; falling back to cpu"
      super.stdenv.isLinux);

    shouldEnable = assert accelIsValid;
      mode: fallback:
        ((config.acceleration or null == mode)
          || (fallback && config.acceleration or null == null && validateFallback))
        && (validateLinux mode);

    enableRocm = shouldEnable "rocm" config.rocmSupport;
    # enableCuda = shouldEnable "cuda" config.cudaSupport;

    rocmLibs = [
      super.rocmPackages.clr
      super.rocmPackages.hipblas
      super.rocmPackages.rocblas
      super.rocmPackages.rocsolver
      super.rocmPackages.rocsparse
      super.rocmPackages.rocm-device-libs
      super.rocmPackages.rocm-smi
    ];

    rocmClang = super.linkFarm "rocm-clang" {
      llvm = super.rocmPackages.llvm.clang;
    };

    rocmPath = super.buildEnv {
      name = "rocm-path";
      paths = rocmLibs ++ [rocmClang];
    };

    cudaToolkit = super.buildEnv {
      name = "cuda-toolkit";
      ignoreCollisions = true;
      paths = [
        super.cudaPackages.cudatoolkit
        super.cudaPackages.cuda_cudart
        super.cudaPackages.cuda_cudart.static
      ];
    };

    runtimeLibs = super.lib.optionals enableRocm [
      rocmPath
    ];
    # ++ super.lib.optionals enableCuda [
    #   super.linuxPackages.nvidia_x11
    # ];

    appleFrameworks = super.darwin.apple_sdk_11_0.frameworks;
    metalFrameworks = [
      appleFrameworks.Accelerate
      appleFrameworks.Metal
      appleFrameworks.MetalKit
      appleFrameworks.MetalPerformanceShaders
    ];

    goBuild =
      # if enableCuda
      # then super.buildGo122Module.override {stdenv = super.overrideCC super.stdenv super.gcc12;}
      # else
      super.buildGo122Module;
  in
    goBuild ((super.lib.optionalAttrs enableRocm {
        ROCM_PATH = rocmPath;
        CLBlast_DIR = "${super.clblast}/lib/cmake/CLBlast";
      })
      # // (super.lib.optionalAttrs enableCuda {
      #   CUDA_LIB_DIR = "${cudaToolkit}/lib";
      #   CUDACXX = "${cudaToolkit}/bin/nvcc";
      #   CUDAToolkit_ROOT = cudaToolkit;
      # })
      // {
        inherit pname version src vendorHash;

        nativeBuildInputs =
          [
            super.cmake
          ]
          ++ super.lib.optionals enableRocm [
            super.rocmPackages.llvm.bintools
          ]
          ++ super.lib.optionals (
            enableRocm
            #  || enableCuda
          ) [
            super.makeWrapper
          ]
          ++ super.lib.optionals super.stdenv.isDarwin
          metalFrameworks;

        buildInputs =
          super.lib.optionals enableRocm
          (rocmLibs ++ [super.libdrm])
          # ++ super.lib.optionals enableCuda [
          #   super.cudaPackages.cuda_cudart
          # ]
          ++ super.lib.optionals super.stdenv.isDarwin
          metalFrameworks;

        patches =
          [
            ./disable-git.patch
            ./disable-lib-check.patch
          ]
          ++ llamacppPatches;

        postPatch = ''
          substituteInPlace version/version.go --replace-fail 0.0.0 '${version}'
        '';

        preBuild = ''
          export OLLAMA_SKIP_PATCHING=true
          go generate ./...
        '';

        postFixup =
          ''
            mv "$out/bin/app" "$out/bin/.ollama-app"
          ''
          + super.lib.optionalString (
            enableRocm
            #  || enableCuda
          ) ''
            mv "$out/bin/ollama" "$out/bin/.ollama-unwrapped"
            makeWrapper "$out/bin/.ollama-unwrapped" "$out/bin/ollama" ${
              super.lib.optionalString enableRocm
              ''--set-default HIP_PATH '${rocmPath}' ''
            } \
              --suffix LD_LIBRARY_PATH : '/run/opengl-driver/lib:${super.lib.makeLibraryPath runtimeLibs}'
          '';

        ldflags = [
          "-s"
          "-w"
          "-X=github.com/jmorganca/ollama/version.Version=${version}"
          "-X=github.com/jmorganca/ollama/server.mode=release"
        ];

        passthru.tests = {
          service = super.nixosTests.ollama;
          rocm = self.ollama.override {config.acceleration = "rocm";};
          cuda = self.ollama.override {config.acceleration = "cuda";};
          version = super.testers.testVersion {
            inherit version;
            package = self.ollama;
          };
        };

        meta = {
          description = "Get up and running with large language models locally";
          homepage = "https://github.com/ollama/ollama";
          changelog = "https://github.com/ollama/ollama/releases/tag/v${version}";
          license = super.lib.licenses.mit;
          platforms = super.lib.platforms.unix;
          mainProgram = "ollama";
          maintainers = with super.maintainers; [abysssol dit7ya elohmeier];
        };
      });
}
