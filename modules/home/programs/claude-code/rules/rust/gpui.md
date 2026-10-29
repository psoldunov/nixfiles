---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
---
# GPUI

> This rule applies when the crate depends on `gpui`, `gpui-kit` or `gpui-component`. Skip it for
> any other Rust code.

**Load the `gpui` skill before you write, debug or review GPUI code.** It is the shared log of GPUI
quirks met in the Concierge, Clokkr and Numero apps, each with its fix and the crate versions it was
seen on. Read the reference file for the area you touch; most GPUI bugs there are a known quirk.

The quirks that bite first, seen on gpui-kit 0.7.1 and gpui-component 0.7.1 on gpui-pre 0.3.8:

- **Pin the pair.** `gpui = { package = "gpui-kit", version = "=…" }` plus `gpui-component = "=…"`,
  bumped together as their own change, then the app launched: tests miss runtime panics.
- **Defer work on a held window.** Inside `cx.listener`, a global `cx.on_action`, a menu or tray
  action, or a window's own event handler, GPUI already holds that view or window. Updating it
  again panics or fails; move the work into `cx.defer`.
- **Keystrokes parse at run time.** `KeyBinding::new` panics on a keystroke it can't parse, and
  from GPUI 0.3.10 that includes every `secondary-` binding, though it still compiles. Build
  bindings with `KeyBinding::load`.
- **No tokio.** GPUI's executors have no tokio reactor. Run tokio-only crates on a side runtime and
  build ashpd and ksni with `async-io`.
- **Rectangular clips.** Rounded corners never clip children; round every child that touches the
  corner.
- **Linux needs rpath.** GPUI `dlopen`s Wayland, X11, xkbcommon, GL and Vulkan; a Nix build needs
  `patchelf --add-rpath` in `postFixup`.
