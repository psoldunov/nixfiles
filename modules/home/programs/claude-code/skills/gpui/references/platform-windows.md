# Windows on Linux and macOS

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

## Linux

### 1. Layer shell is Wayland-only, and `WindowKind::PopUp` can't take the keyboard
*gpui-pre-linux 0.3.8 · Wayland, GNOME, X11 · Concierge, Clokkr*

- **Symptom:** opening a layer-shell window errors on GNOME and X11. A `PopUp` fallback never gets
  keyboard focus.
- **Cause:** `gpui::layer_shell` types exist only on Linux. On X11 `PopUp` is an override-redirect
  window the window manager never focuses, and GPUI never calls `XSetInputFocus`. On Wayland GPUI
  doesn't implement `PopUp`.
- **Fix:** try layer shell first, then fall back. A `PopUp` at an explicit origin suits a surface
  that needs no keyboard; a borderless normal window suits one that does. Keep layer-shell types out
  of shared code.
  ```rust
  if cx.compositor_name() == "Wayland" {
      match gpui::open_window(layer_shell_options(o), cx, build) {
          Ok(w) => return Ok(w),
          Err(e) if e.is::<LayerShellNotSupportedError>() => { /* fall through */ }
          Err(e) => return Err(e),
      }
  }
  // fallback: PopUp at an explicit origin, or a borderless normal window
  ```

### 2. A 0×0 layer surface kills the app's Wayland connection
*gpui-pre-linux 0.3.8 · wlr-layer-shell · Clokkr*

- **Cause:** layer shell reads 0×0 as "fill the output", but GPUI sizes its viewport from
  `window_bounds` before the compositor answers, and a 0-wide viewport is a protocol error.
- **Fix:** always pass a real size, such as the output's logical size.

### 3. A click outside a layer surface never reaches it
*gpui-pre-linux 0.3.8 · wlr-layer-shell · Clokkr*

- **Symptom:** a popover never closes on an outside click.
- **Cause:** layer shell has no pop-up grab, and a click on the desktop or a panel doesn't move the
  keyboard.
- **Fix:** while the popover shows, put a full-screen see-through catcher surface under it on
  `Layer::Top` (the popover sits on `Overlay`), with `exclusive_zone: Some(px(-1.))` and
  `KeyboardInteractivity::None`. Close the popover on any press on the catcher. Tie the catchers'
  lifetime to the popover, and have each one also check on a timer that it is still needed.

### 4. The compositor can close your layer surface
*gpui-pre-linux 0.3.8 · wlr-layer-shell · Clokkr*

- **Symptom:** an always-on overlay disappears, and reopening it naively loops.
- **Cause:** `zwlr_layer_surface_v1::Closed`, for example when its output goes away.
- **Fix:** reopen after a pause, count closes that come soon after opening (Clokkr uses 5 s) as
  refusals, and give up after a few in a row (Clokkr uses 3).

### 5. GPUI before 0.3.10 never forgets a removed Wayland output
*gpui-pre-linux 0.3.8, fixed in 0.3.10 · Wayland · Clokkr*

- **Symptom:** after the screen locks and the monitor sleeps, layer surfaces (popovers, overlays)
  never appear. `cx.displays()` lists one monitor several times (`DP-1` ×3). Restarting the app
  fixes it.
- **Cause:** `wl_registry::GlobalRemove` is a TODO in 0.3.8. Dead outputs stay in GPUI's maps, the
  returning monitor gets a new `DisplayId`, and a surface pinned to an old id goes to a dead output.
- **Fix:** update to gpui-pre 0.3.10, which handles removal. On 0.3.8, pin `display_id` only when no
  other display shares its name, and otherwise pass `None` so the compositor picks:
  ```rust
  let ds: Vec<_> = cx.displays().iter().map(|d| (d.id(), d.uuid().ok())).collect();
  let display = display.filter(|&id| named_once(id, &ds));
  ```

### 6. Display bounds are wrong under fractional scaling
*gpui-pre-linux 0.3.8 · Wayland with fractional scaling · Clokkr*

- **Symptom:** a 3840×2160 output at scale 1.5 reports 1920×1080 instead of 2560×1440, so anything
  placed by those bounds lands in the wrong spot.
- **Cause:** GPUI reads only `wl_output`, whose scale is a whole number (2).
- **Fix:** read xdg-output's logical geometry on a short-lived Wayland connection of your own, match
  each GPUI display to its output, and correct the bounds and scale.

### 7. No xdg-activation for an already open window
*gpui-pre-linux 0.3.8 · Wayland · Concierge*

- **Symptom:** a running app reached by a second launch only flashes and doesn't come forward. Apps
  you launch may not be raised either.
- **Cause:** GPUI uses an activation token only for the first window of a process that starts
  windowed. `activate_window` requests its own token, and there is no API to activate with a token
  someone else passed.
- **Fix:** none inside GPUI yet. Pass `XDG_ACTIVATION_TOKEN` through to processes you launch.

### 8. The Linux clipboard gives text or a picture, never files
*gpui-pre-linux 0.3.8 · gpui-component 0.7.1 · Wayland and X11 · Concierge*

- **Symptom:** `ClipboardEntry::ExternalPaths` is always empty; files arrive as their paths in plain
  text. `Textarea::on_paste` skips its hook when the clipboard holds only a file list.
- **Cause:** GPUI never reads `text/uri-list`. Wayland prefers text and X11 prefers a picture.
- **Fix:** read the file list on your own connection, off the UI thread, with a timeout: the
  data-control protocol on Wayland, the X server otherwise, never GPUI's connection. To decide about
  a paste yourself, `capture_action` the `Paste` action on an element around the field. To let the
  field paste after all, `dispatch_action(&Paste)` on its focus handle; its own paste does more than
  `insert` (one undo step, a line per cursor).

### 9. GPUI can't hide a window on Linux
*gpui-kit 0.7.1 · Linux · Numero*

- **Symptom:** a tray or hotkey toggle has no hide call to use. (On macOS, `cx.hide()` hides the
  app.)
- **Fix:** hide by saving state, setting a "hiding" flag and calling `window.remove_window()`; show
  by reopening. Use `.with_quit_mode(QuitMode::Explicit)` so closing the last window doesn't quit,
  and decide in your own close handler.

### 10. X11 window managers ignore the requested origin and an early always-on-top
*gpui-pre-linux 0.3.8 · X11 (KWin), Wayland, macOS · Numero*

- **Symptom:** a restored window opens wherever the window manager places it, and always-on-top set
  at open does nothing.
- **Cause:** X11 window managers place new windows themselves and ignore `_NET_WM_STATE` requests on
  unmapped windows. GPUI has no API to change the window level after opening. Wayland has no
  protocol for either.
- **Fix:** on X11, wait 250 ms on the background executor's timer after open, then move the window
  with `x11rb` `configure_window` on a separate connection, in device pixels. Send
  `_NET_WM_STATE_ABOVE` from `window.on_next_frame(..)`. On macOS, set the `NSWindow` level. On
  Wayland, log that a compositor window rule is needed.

### 11. `window_bounds()` means different things on X11 and Wayland
*gpui-pre-linux 0.3.8 · Linux with client decorations · Numero*

- **Symptom:** a saved window size grows by the shadow inset on each restart (X11), or a saved
  position is garbage (Wayland).
- **Cause:** on X11 the bounds include the client inset, and the size you asked for is
  `inner_window_bounds`. On Wayland the bounds are the size you asked for, the inner bounds are
  smaller still, and there is no position.
- **Fix:** save `inner_window_bounds().size` on X11 and `window_bounds().size` elsewhere. Save the
  origin only when the raw window handle isn't `Wayland`, and restore it only if part of the window
  is still on a connected display.

### 12. `WindowOptions.app_id` is load-bearing on Wayland
*gpui-pre-linux 0.3.8 · ashpd 0.13.13 · Wayland · Numero*

- **Symptom:** the GlobalShortcuts portal rejects the app, or the compositor can't find its icon or
  desktop entry.
- **Cause:** the compositor and portals look up `<app_id>.desktop`, and the shortcuts portal needs a
  reverse-DNS id.
- **Fix:** set `app_id: Some("dev.example.app")` on every window and install the desktop file under
  that exact name with `StartupWMClass=<app_id>`. Outside Flatpak, call ashpd's `register_host_app`
  first.

### 13. Two log lines that look alarming and are harmless
*gpui-pre-linux 0.3.8 · KWin · Clokkr*

- `Server-side decorations requested, but the Wayland server does not support them` (INFO, every
  layer surface): layer surfaces have no xdg-decoration.
- `activation token received with no pending activation` (ERROR): GPUI's activation bookkeeping is
  loose.

Look past both when a window doesn't show. `WAYLAND_DEBUG=1` traces every request.

## macOS

### 14. A window comes forward only in the active app
*gpui-pre-macos 0.3.8 · macOS · Concierge, Clokkr, Numero*

- **Symptom:** `activate_window()` from a tray click or global hotkey does nothing while another app
  is frontmost, or the window opens behind the app the user is in. A second launch of a bare binary
  starts a second copy.
- **Cause:** AppKit brings windows forward only for the active app, and `activate_window()` only
  orders the window front. GPUI re-activates on a second launch only for `.app` bundles.
- **Fix:** call `cx.activate(true)` before `window.activate_window()`; it also undoes `cx.hide()`.
  Skip it for HUD-style windows that shouldn't take focus. Call `follow_active_space` on the
  `NSWindow` so it comes to the current Space. For single-instance behaviour, use your own Unix
  socket (`$XDG_RUNTIME_DIR` on Linux, the app's data dir on macOS).

### 15. Panels, resizing and displays
*gpui-pre-macos 0.3.8 · macOS · Concierge*

- **Popups:** `WindowKind::PopUp` is a non-activating `NSPanel` that joins every Space and floats
  over full-screen apps. With `focus: true` it becomes key without activating the app.
- **Resize:** `window.resize` keeps the bottom edge, so a growing panel grows upwards. Set the frame
  from the top through objc2 (see #16).
- **Displays:** every display's `bounds()` starts at (0,0). Pick one by `display_id`, which is
  `NSScreenNumber`.
- **Dock icon:** `App::set_activation_policy` toggles it without objc2.

### 16. Setting an `NSWindow` frame during a GPUI update loses the size
*gpui-pre-macos 0.3.8 · macOS · Concierge*

- **Symptom:** "RefCell already borrowed" in the log, and the window keeps laying out at its old
  size; a transparent window shows the desktop below it.
- **Cause:** AppKit reports the new size synchronously, GPUI's resize callback can't borrow the app
  at that moment, and it drops the size.
- **Fix:** set the frame from a spawned task, never from `render` or an observer.

### 17. Menu-bar actions run while GPUI holds the active window
*gpui-pre-macos 0.3.8 · macOS · Concierge, Numero*

- **Symptom:** `window.update` fails with "window not found", so code meant to bring a window
  forward opens a second one.
- **Cause:** a picked item dispatches through `App::dispatch_action` in the active window, and GPUI
  holds that window during the dispatch.
- **Fix:** run every item's work through `cx.defer` ([input-and-lifetimes.md](input-and-lifetimes.md) #1).
  With global listeners, every item shows as enabled. Call `cx.set_menus` again after the keymap
  changes, or the shortcuts shown go stale.

### 18. Reach the `NSWindow` for settings GPUI has no API for
*gpui-pre-macos 0.3.8 · macOS · Clokkr, Concierge*

- **Examples:** blur, panel level, how a panel grows.
- **Fix:** `HasWindowHandle::window_handle(window)` (the inherent `Window::window_handle()` hides the
  raw handle), match `RawWindowHandle::AppKit`, then `ns_view.window()`.
