{pkgs, ...}: {
  home.file = {
    ".local/share/duckstation/settings.ini" = {
      source =
        (pkgs.formats.ini {}).generate "settings.ini"
        {
          Main = {
            SettingsVersion = 3;
            EmulationSpeed = 1;
            FastForwardSpeed = 0;
            TurboSpeed = 0;
            SyncToHostRefreshRate = false;
            IncreaseTimerResolution = true;
            InhibitScreensaver = true;
            StartPaused = false;
            StartFullscreen = false;
            PauseOnFocusLoss = false;
            SaveStateOnExit = true;
            CreateSaveStateBackups = true;
            CompressSaveStates = true;
            ConfirmPowerOff = true;
            ApplyCompatibilitySettings = true;
            ApplyGameSettings = true;
            EnableDiscordPresence = false;
            LoadDevicesFromSaveStates = false;
            DisableAllEnhancements = false;
            RewindEnable = false;
            RewindFrequency = 10;
            RewindSaveSlots = 10;
            RunaheadFrameCount = 0;
            SetupWizardIncomplete = false;
          };

          Console = {
            Region = "Auto";
            Enable8MBRAM = false;
            EnableCheats = false;
          };

          CPU = {
            ExecutionMode = "Recompiler";
            OverclockEnable = false;
            OverclockNumerator = 1;
            OverclockDenominator = 1;
            RecompilerMemoryExceptions = false;
            RecompilerBlockLinking = true;
            RecompilerICache = false;
            FastmemMode = "MMap";
          };

          TextureReplacements = {
            EnableVRAMWriteReplacements = false;
            PreloadTextures = false;
            DumpVRAMWrites = false;
            DumpVRAMWriteForceAlphaChannel = true;
            DumpVRAMWriteWidthThreshold = 128;
            DumpVRAMWriteHeightThreshold = 128;
          };

          Folders = {
            Cache = "cache";
            Cheats = "cheats";
            Covers = "covers";
            Dumps = "dump";
            GameSettings = "gamesettings";
            InputProfiles = "inputprofiles";
            SaveStates = "/SATA/Emulation/Saves/PS1/savestates";
            Screenshots = "screenshots";
            Shaders = "shaders";
            Textures = "textures";
            UserResources = "resources";
          };

          InputSources = {
            SDL = true;
            SDLControllerEnhancedMode = false;
            XInput = false;
            RawInput = false;
          };

          Pad1 = {
            Type = "AnalogController";
            Up = "SDL-0/DPadUp";
            Right = "SDL-0/DPadRight";
            Down = "SDL-0/DPadDown";
            Left = "SDL-0/DPadLeft";
            Triangle = "SDL-0/Y";
            Circle = "SDL-0/B";
            Cross = "SDL-0/A";
            Square = "SDL-0/X";
            Select = "SDL-0/Back";
            Start = "SDL-0/Start";
            L1 = "SDL-0/LeftShoulder";
            R1 = "SDL-0/RightShoulder";
            L2 = "SDL-0/+LeftTrigger";
            R2 = "SDL-0/+RightTrigger";
            L3 = "SDL-0/LeftStick";
            R3 = "SDL-0/RightStick";
            LLeft = "SDL-0/-LeftX";
            LRight = "SDL-0/+LeftX";
            LDown = "SDL-0/+LeftY";
            LUp = "SDL-0/-LeftY";
            RLeft = "SDL-0/-RightX";
            RRight = "SDL-0/+RightX";
            RDown = "SDL-0/+RightY";
            RUp = "SDL-0/-RightY";
            Analog = "SDL-0/Guide";
            SmallMotor = "SDL-0/SmallMotor";
            LargeMotor = "SDL-0/LargeMotor";
          };

          Pad2.Type = "None";
          Pad3.Type = "None";
          Pad4.Type = "None";
          Pad5.Type = "None";
          Pad6.Type = "None";
          Pad7.Type = "None";
          Pad8.Type = "None";

          ControllerPorts = {
            MultitapMode = "Disabled";
            PointerXScale = 8;
            PointerYScale = 8;
            PointerXInvert = false;
            PointerYInvert = false;
          };

          Cheevos = {
            Enabled = false;
            ChallengeMode = false;
            Notifications = true;
            LeaderboardNotifications = true;
            SoundEffects = true;
            Overlays = true;
            EncoreMode = false;
            SpectatorMode = false;
            UnofficialTestMode = false;
            UseFirstDiscFromPlaylist = true;
            UseRAIntegration = false;
            NotificationsDuration = 5;
            LeaderboardsDuration = 10;
          };

          Logging = {
            LogLevel = "Info";
            LogFilter = "";
            LogTimestamps = true;
            LogToConsole = true;
            LogToDebug = false;
            LogToWindow = false;
            LogToFile = false;
          };

          GPU = {
            Renderer = "Vulkan";
            Adapter = "AMD Radeon RX 7900 XTX (RADV NAVI31)";
            ResolutionScale = 9;
            Multisamples = 1;
            UseDebugDevice = false;
            DisableShaderCache = false;
            DisableDualSourceBlend = false;
            DisableFramebufferFetch = false;
            DisableTextureBuffers = false;
            DisableTextureCopyToSelf = false;
            PerSampleShading = false;
            UseThread = true;
            ThreadedPresentation = true;
            UseSoftwareRendererForReadbacks = false;
            TrueColor = true;
            Debanding = false;
            ScaledDithering = true;
            TextureFilter = "Nearest";
            LineDetectMode = "Disabled";
            DownsampleMode = "Box";
            DownsampleScale = 1;
            WireframeMode = "Disabled";
            DisableInterlacing = true;
            ForceNTSCTimings = true;
            WidescreenHack = false;
            ChromaSmoothing24Bit = false;
            PGXPEnable = true;
            PGXPCulling = true;
            PGXPTextureCorrection = true;
            PGXPColorCorrection = true;
            PGXPVertexCache = true;
            PGXPCPU = false;
            PGXPPreserveProjFP = true;
            PGXPTolerance = -1;
            PGXPDepthBuffer = false;
            PGXPDepthClearThreshold = 300;
          };

          Debug = {
            ShowVRAM = false;
            DumpCPUToVRAMCopies = false;
            DumpVRAMToCPUCopies = false;
            ShowGPUState = false;
            ShowCDROMState = false;
            ShowSPUState = false;
            ShowTimersState = false;
            ShowMDECState = false;
            ShowDMAState = false;
          };

          Hotkeys = {
            FastForward = "Keyboard/Tab";
            TogglePause = "Keyboard/Space";
            Screenshot = "Keyboard/F10";
            ToggleFullscreen = "Keyboard/F11";
            OpenPauseMenu = "Keyboard/Escape";
            LoadSelectedSaveState = "Keyboard/F1";
            SaveSelectedSaveState = "Keyboard/F2";
            SelectPreviousSaveStateSlot = "Keyboard/F3";
            SelectNextSaveStateSlot = "Keyboard/F4";
          };

          UI = {
            Theme = "";
            MainWindowGeometry = "AdnQywADAAAAAAAGAAAAOgAADvkAAAhpAAAABgAAADoAAA75AAAIaQAAAAAAAAAADwAAAAAGAAAAOgAADvkAAAhp";
            MainWindowState = "AAAA/wAAAAD9AAAAAAAADvQAAAf/AAAABAAAAAQAAAAIAAAACPwAAAABAAAAAgAAAAEAAAAOAHQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAA==";
            DisplayWindowGeometry = "AdnQywADAAAAAAAGAAAAOgAAB3kAAAhpAAAABgAAADoAAAd5AAAIaQAAAAAAAAAADwAAAAAGAAAAOgAAB3kAAAhp";
          };

          GameList = {
            RecursivePaths = "/SATA/Emulation/ROMS/PS1";
          };

          Display = {
            DeinterlacingMode = "Adaptive";
            CropMode = "Overscan";
            ActiveStartOffset = 0;
            ActiveEndOffset = 0;
            LineStartOffset = 0;
            LineEndOffset = 0;
            Force4_3For24Bit = false;
            AspectRatio = "Auto (Game Native)";
            Alignment = "Center";
            Scaling = "BilinearSmooth";
            OptimalFramePacing = false;
            PreFrameSleep = false;
            PreFrameSleepBuffer = 2;
            VSync = false;
            ExclusiveFullscreenControl = "Automatic";
            ScreenshotMode = "ScreenResolution";
            ScreenshotFormat = "PNG";
            ScreenshotQuality = 85;
            CustomAspectRatioNumerator = 0;
            ShowOSDMessages = true;
            ShowFPS = false;
            ShowSpeed = false;
            ShowResolution = false;
            ShowLatencyStatistics = false;
            ShowGPUStatistics = false;
            ShowCPU = false;
            ShowGPU = false;
            ShowFrameTimes = false;
            ShowStatusIndicators = true;
            ShowInputs = false;
            ShowEnhancements = false;
            OSDScale = 100;
            StretchVertically = false;
            MaxFPS = 0;
          };

          CDROM = {
            ReadaheadSectors = 8;
            MechaconVersion = "VC1A";
            RegionCheck = false;
            LoadImageToRAM = false;
            LoadImagePatches = false;
            MuteCDAudio = false;
            ReadSpeedup = 1;
            SeekSpeedup = 1;
          };
        };
    };
  };
}
