# Build, linking and async runtimes

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

### 1. Pin gpui-kit and gpui-component exactly, and alias gpui-kit as `gpui`
*gpui-kit 0.7.1 (gpui-pre =0.3.8), 0.8.1 (gpui-pre =0.3.10) · gpui-component 0.7.1 · any platform · Concierge, Clokkr, Numero*

- **Symptom:** `gpui` on crates.io is stuck at 0.2.2, and newer gpui-component no longer builds
  against Zed's git. A plain `cargo update` can't move GPUI, or pairs gpui-component with a snapshot
  it wasn't built against. A `[patch]` over the snapshot crates fails or leaves two GPUIs in the
  build. GPUI's derive macros fail to resolve when the crate isn't named `gpui`.
- **Cause:** GPUI Kit republishes each Zed commit as renamed `gpui-pre-*` crates. gpui-kit pins one
  `gpui-pre` exactly, each gpui-component release requires that same snapshot, and the macros expand
  to `gpui::…` paths.
- **Fix:**
  ```toml
  gpui = { package = "gpui-kit", version = "=0.7.1" }
  gpui-component = "=0.7.1"
  ```
  Bump the two together, to a pair built on the same snapshot, as a change of its own. Then launch
  the app: the 0.3.10 keystroke panic ([input-and-lifetimes.md](input-and-lifetimes.md) #9) passes
  the build, Clippy and every test. Going 0.7.1 → 0.8.1 also pulls in the `gpui-fast-*` crates and
  heavy lockfile churn. Tests that need GPUI's harness take
  `gpui = { workspace = true, features = ["test-support"] }` in dev-dependencies.

### 2. GPUI dlopens its window and GPU libraries, so linking alone doesn't find them
*gpui-pre-linux 0.3.8 and 0.3.10 · Linux with Nix · Concierge, Clokkr, Numero*

- **Symptom:** a panic at startup outside the dev shell: `failed to connect to Wayland compositor:
  The wayland library could not be loaded` (`gpui-pre-linux …/src/linux/platform.rs`). A Nix-built
  binary fails the same way.
- **Cause:** GPUI opens libwayland, vulkan-loader, libxkbcommon, libglvnd, libX11 and libxcb with
  `dlopen`. They are never `DT_NEEDED`, so Nix's rpath shrinking drops them.
- **Fix:**
  - **Dev shell:** `LD_LIBRARY_PATH = lib.makeLibraryPath [libglvnd libx11 libxcb libxkbcommon vulkan-loader wayland]`,
    and run built binaries inside it (`nix develop -c target/debug/app`).
  - **Nix package:** `patchelf --add-rpath ${lib.makeLibraryPath libs} $out/bin/<app>` in
    `postFixup`. Fixup shrinks the rpath first, so adding it any earlier is undone. Prefer the rpath
    to an `LD_LIBRARY_PATH` wrapper, which leaks into child processes such as `xdg-open`. fontconfig
    and freetype go in `buildInputs`.
  - **AppImage:** leave the GPU stack (Vulkan, GL, EGL, drm, gbm) to the host and bundle only
    libxkbcommon and libxkbcommon-x11.

### 3. A macOS Nix dev shell must link against Xcode's SDK
*gpui-pre-macos 0.3.8 · macOS with Nix · Numero*

- **Symptom:** GPUI's macOS build links the wrong SDK or toolchain when the Rust toolchain sits in
  the shell's `packages`.
- **Cause:** rust-overlay's toolchain in `packages` propagates Nix's clang wrapper, and Nix points
  `SDKROOT` and `DEVELOPER_DIR` at store paths.
- **Fix:** use `mkShellNoCC`, put the toolchain on `PATH` in `shellHook`, point `DEVELOPER_DIR` at
  `xcode-select -p` (fallback `/Applications/Xcode.app/Contents/Developer`) and
  `unset SDKROOT MACOSX_DEPLOYMENT_TARGET`. Numero's `nix/devshell.nix` does this.

### 4. GPUI's dependency tree changes the rest of the workspace
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** `serde_json::Value` grows in every crate of a build that includes the UI. cargo-deny
  reports duplicate majors and unmaintained crates: ttf-parser, rustybuzz, paste, instant,
  rustls-pemfile.
- **Cause:** GPUI turns on `serde_json/preserve_order` and pulls those crates in.
- **Fix:** ignore those advisories by id. Allow Unlicense, 0BSD, CC0-1.0 and bzip2-1.0.6 only for
  the crates that carry them. Turn off duplicate-major lints such as rust-doctor's.

### 5. GPUI's executors are not tokio, and its D-Bus stack runs on async-io
*gpui-kit 0.7.1 · ashpd 0.13.13 · zbus 5.19 · ksni 0.3.6 · Linux · Concierge, Clokkr, Numero*

- **Symptom:** tokio-based clients (sockets, ksni, zbus) panic or hang when spawned from GPUI.
  Enabling ashpd's `tokio` feature fails the build. Portal calls land on the wrong runtime, or
  portal sessions can't be ended cleanly.
- **Cause:** GPUI runs its own executors with no tokio reactor or timers. GPUI's own ashpd turns on
  `async-io`, and ashpd refuses both runtime features at once. zbus 5.19 compiles both runtimes in
  and picks tokio only when a tokio runtime is current. ashpd's shared, cached zbus connection is
  GPUI's connection, and a portal session lives as long as its connection.
- **Fix:**
  - Build ashpd with `default-features = false, features = ["async-io", …]`, and ksni with
    `features = ["async-io"]` where the crate offers it. Run their futures with
    `cx.background_spawn`, and wait with `cx.background_executor().timer(..)`.
  - For crates that need tokio, start a small tokio runtime beside GPUI and `handle.spawn(fut)` onto
    it. A tokio `JoinHandle`, `mpsc::Receiver` or `async_channel` receiver is a plain future GPUI's
    executor can await; one main-thread task can drain results from tray, hotkey or socket threads.
  - Open your own zbus connection for your own D-Bus work (hotkey portal, single-instance name), one
    per portal session: `zbus::Connection::session().await`, then
    `GlobalShortcuts::with_connection(conn)`. Dropping it ends the session and its shortcut. Bake the
    keys into the shortcut id so a changed shortcut is confirmed again.
