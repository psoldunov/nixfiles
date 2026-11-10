---
name: gpui
description: "GPUI and gpui-component quirks with their fixes and the crate versions each was seen on: dependency pinning and Linux linking, async runtimes, window chrome and blur, layout and text, Wayland, X11 and macOS windows, borrow panics, keys and focus, widgets, snapshot tests. Use when writing, debugging or reviewing Rust code that uses gpui, gpui-kit or gpui-component."
---

# GPUI quirks

A shared log of the GPUI quirks met while building three apps: Concierge, Clokkr and Numero. Each
entry gives the symptom, the cause, the fix, the versions and platforms it was seen on, and the apps
that hit it.

## 1. Match the versions

GPUI changes between snapshots, so every entry is a fact about the release it names. Concierge now
runs the stack below; Clokkr and Numero may still be on older pins:

| Crate | Version |
|---|---|
| `gpui-kit`, imported as `gpui` | `=0.9.1`, with its `gpui-fast` feature on |
| `gpui-component` | `=0.9.1` |
| `gpui-pre` and its `gpui-pre-*` crates | 0.3.12 |
| `gpui-fast` and its `gpui-fast-*` crates | 0.1.14, held by `Cargo.lock` |

Read the project's own pins first: `grep -A1 -E 'name = "(gpui-pre|gpui-kit|gpui-component)"' Cargo.lock`.
Where the project runs a newer release than an entry names, treat the entry as a lead and check the
crate source under `~/.cargo/registry/src/*/gpui-pre-*/` before you build on it.

Concierge runs gpui-kit and gpui-component =0.9.1 on gpui-pre 0.3.12 with the gpui-fast 0.1.14
core. Known changes there:

- Keystrokes are `&'static str` and `KeyBinding::load` takes `cx` ([input-and-lifetimes.md](references/input-and-lifetimes.md) #16).
- `ScrollWheelEvent` is `ScrollEvent` ([testing.md](references/testing.md) #7).
- `ThemeConfig` is non-exhaustive, a submenu's side follows its drawn width, and a plugin block in
  Markdown is atomic in selections ([gpui-component-widgets.md](references/gpui-component-widgets.md) #13).
- gpui-fast retains views, so untracked state must notify ([layout-and-rendering.md](references/layout-and-rendering.md) #14).
- The `gpui-fast` feature compiles both cores, and `Cargo.lock` holds the fork's version ([build-and-runtime.md](references/build-and-runtime.md) #6).

Known changes in gpui-pre 0.3.10, which gpui-kit 0.8.1 pins (Clokkr tried that update and reverted):

- Removed Wayland outputs are forgotten at last ([platform-windows.md](references/platform-windows.md) #5).
- `KeyBinding::new` rejects `secondary-` keystrokes at run time, and `Modifiers::secondary` takes
  `cx` ([input-and-lifetimes.md](references/input-and-lifetimes.md) #9).

## 2. Weigh the markers

Entries marked **Unverified** or **Conflicting** are leads. Confirm them in your version before you
rely on one, and say so when you cite it:

- **Conflicting:** whether a gpui-component `Button` takes keyboard focus when clicked
  ([input-and-lifetimes.md](references/input-and-lifetimes.md) #13).
- **Unverified:** macOS key dispatch order, worked out from the source only
  ([input-and-lifetimes.md](references/input-and-lifetimes.md) #11).
- **Unverified:** `remove_window` skipping `on_window_should_close`, inferred from a code comment
  ([input-and-lifetimes.md](references/input-and-lifetimes.md) #4).

## 3. Read the reference for the area you touch

| File | Covers |
|---|---|
| [build-and-runtime.md](references/build-and-runtime.md) | Cargo pins, Nix linking and dev shells, dependency-tree side effects, tokio, async-io, ashpd and zbus |
| [window-chrome.md](references/window-chrome.md) | gpui-component's Root plugin, client decorations, client inset, tiling, title bars, blur, translucency, dialogs |
| [layout-and-rendering.md](references/layout-and-rendering.md) | Clipping, shadows, borders, flex and text wrapping, text metrics, measuring, lists, cached views, images, fonts |
| [platform-windows.md](references/platform-windows.md) | Linux layer shell, outputs, activation, clipboard, hiding, X11 placement, window bounds, app_id; macOS activation, panels, frames, menus, AppKit access |
| [input-and-lifetimes.md](references/input-and-lifetimes.md) | Borrow panics and `cx.defer`, observers, leaks, window close; key dispatch, bindings, focus, clicks and drags |
| [gpui-component-widgets.md](references/gpui-component-widgets.md) | Text selection, markdown tables, themes, buttons, scrollbars, menus, inputs and editors, small widgets |
| [testing.md](references/testing.md) | Headless and snapshot tests, the test scheduler, macOS test limits |

## 4. Borrow a working implementation

The three apps are `psoldunov/concierge`, `psoldunov/clokkr` and `psoldunov/numero` on GitHub, with
local clones under `~/Ensemblr/repos/<app>` on Whopper. Paths below are relative to each repo:

- **Window frame with Root plugins:** Numero `crates/numero-app/src/frame.rs`, Concierge
  `crates/ensemblr-ui/src/window_frame.rs`.
- **KWin blur through `ext-background-effect-v1`:** Numero `crates/numero-app/src/blur/linux.rs`,
  Clokkr `crates/clokkr-ui/src/blur/linux.rs`, Concierge `crates/ensemblr-ui/src/background_blur.rs`.
- **macOS blur:** Numero `crates/numero-app/src/blur.rs`.
- **Layer-shell popover, outside-click catcher, output fixes:** Clokkr
  `crates/clokkr-app/src/overlay.rs`, `crates/clokkr-app/src/overlay/catcher.rs`,
  `crates/clokkr-ui/src/outputs.rs`.
- **Window placement, levels and saved bounds:** Numero `crates/numero-app/src/system/windows.rs`,
  `crates/numero-app/src/system/window_level.rs`.
- **Desktop UI font on Linux:** Numero `crates/numero-app/src/ui_font.rs`.
- **Custom markdown tables:** Concierge `crates/ensemblr-ui/src/markdown/table.rs`.

Concierge's `docs/gpui.md` is its running log of GPUI notes and has more detail on the entries
tagged Concierge.

## 5. Record new quirks

A quirk that would bite any GPUI app belongs here. Tell the user what you found and propose an entry
for the matching reference file, in the same shape: symptom, cause, fix, the versions and platform
from the project's `Cargo.lock`, and the app. The source lives in nixfiles at
`modules/home/programs/claude-code/skills/gpui/`. A quirk of one app's own design goes in that app's
docs.
