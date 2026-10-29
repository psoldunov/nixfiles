# Window chrome, blur and translucency

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

### 1. gpui-component's init restyles every window through a Root plugin
*gpui-kit 0.7.1 · gpui-component 0.7.1 · Linux with client decorations, any platform for rem and corners · Concierge, Clokkr, Numero*

- **Symptom:** a black 20 px band around a client-decorated window, square corners with a fixed
  border colour around a custom rounded frame, and a changed rem size.
- **Cause:** gpui-kit's `gpui::open_window` wraps the view in `gpui::base::Root`, and every
  registered Root plugin joins in. gpui-component's plugin sets the rem to `Theme::font_size`, paints
  an opaque background and wraps the surface in `window_border()`, which has radius 0 and 20 px of
  shadow padding. Plugins run in registration order, the registry is never reset, and
  gpui-component's plugin type is private, so it can't be unregistered.
- **Fix:** register plugins on both sides of gpui-component's own.
  ```rust
  frame::register_capture(cx); // Root::register_plugin(cx, Capture::new)
  gpui_component::init(cx);    // Numero reaches it through gpui::init
  frame::register_frame(cx);   // Root::register_plugin(cx, Frame::new)
  ```
  The capture plugin's `decorate` stashes the surface and returns an empty `div()`, which is all
  `window_border` then wraps; its `style` sets `surface.style().background` transparent. The frame
  plugin's `decorate` throws away `window_border`'s output and frames the captured surface itself.

### 2. A RootPlugin's hooks can't read the Root entity
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** a borrow panic.
- **Cause:** the hooks run inside `Root::render`, while Root is being updated.
- **Fix:** decide per window from state set beforehand, such as a global keyed on the window id and
  set while the view is built. The plugin's own `Render::render` runs later and may read Root and
  calls like `window.has_active_dialog`.

### 3. Client decorations always give the surface an alpha channel
*gpui-pre-linux 0.3.8 · Wayland · Concierge*

- **Symptom:** transparent pixels show the desktop whatever `window_background` says.
- **Fix:** paint every pixel you want opaque yourself.

### 4. Keep the client inset set while the window is tiled
*gpui-pre 0.3.8 · Linux, Wayland and X11 client decorations · Concierge, Numero*

- **Symptom:** the first resize after restoring from maximized or tiled counts the shadow inset
  twice, and the window jumps in size.
- **Cause:** `window.set_client_inset(px)` sets the xdg window geometry. Clearing it while tiled and
  setting it again makes GPUI miscount on the next configure. gpui-component's dialogs also read it
  back with `client_inset()`.
- **Fix:** call `window.set_client_inset(SHADOW_INSET)` on every frame, whatever the tiling. Pad
  only the sides that aren't tiled (`Decorations::Client { tiling }`).

### 5. KWin reports only the tiled edges that touch the screen
*gpui-pre-linux 0.3.8 · KWin 6.7 · Concierge*

- **Symptom:** a quarter-tiled window keeps one rounded corner.
- **Cause:** a window in the top-left quarter is tiled top and left only, even with windows against
  its other edges.
- **Fix:** square every corner once any edge is tiled, as GTK does.

### 6. A custom title bar on Linux needs several fixes
*gpui-pre 0.3.8 · gpui-component 0.7.1 · Linux client decorations · Concierge, Numero*

- **Moving:** call `start_window_move()` on the first mouse move after a press. Starting on the
  press kills double clicks; gpui-component's `TitleBar` does it the same way.
- **Text selection:** `start_window_move` and `start_window_resize` hand the button release to the
  compositor, so GPUI never sees the mouse-up and a text selection follows the pointer forever. On a
  left press over drag and resize areas, call `gpui_component::GlobalState::suppress_text_selection(cx)`,
  and clear it on mouse-up and `on_mouse_down_out` ([gpui-component-widgets.md](gpui-component-widgets.md) #1).
- **Maximize:** on `click_count() == 2`, call `zoom_window()`.
- **Window menu:** call `window.show_window_menu(pos)` on a right press, only under
  `Decorations::Client`.
- **Controls:** `prevent_default` and `stop_propagation` on their mouse-down so presses don't reach
  the bar. Show only what `window.window_controls()` offers, and none under server-side decorations.
- **gpui-component's `TitleBar`:** its controls can't be restyled, and it blends a gradient even when
  the theme's `title_bar` is transparent; override with `.bg()`.

### 7. A custom title bar on macOS
*gpui-pre-macos 0.3.8 · macOS · Concierge, Numero*

- **Traffic lights:** set `TitlebarOptions { appears_transparent: true, traffic_light_position: Some(point(..)) }`
  and pad the bar by `x * 2 + 52` px.
- **Double click:** with `app_owns_titlebar_drag`, call `window.titlebar_double_click()`, which
  follows the user's system setting, rather than `zoom_window()`.

### 8. `WindowBackgroundAppearance::Blurred` draws no blur on KWin 6.7 or current macOS
*gpui-pre 0.3.8 · wayland-backend 0.3.17 · wayland-protocols 0.32.13 · KWin 6.7.5, macOS 27 · Concierge, Clokkr, Numero*

- **Symptom:** the desktop shows sharp behind the window. On a KWin that still offers the old
  protocol, the whole square surface blurs instead.
- **Cause:** on Linux GPUI speaks only `org_kde_kwin_blur`, which KWin 6.7 dropped for
  `ext-background-effect-v1`. On macOS GPUI hides the `NSVisualEffectView`'s tint layers and the blur
  goes with them.
- **Fix:** keep the window `Transparent`, add blur yourself, and paint opaque wherever nothing blurs
  (GNOME, Sway, X11, the effect turned off).
  - **Linux:** open a second `wayland-client` connection as a guest on GPUI's own `wl_display`
    (`Backend::from_foreign_display` from the raw display handle; `wayland-backend` features
    `client_system` and `dlopen`). Bind `ExtBackgroundEffectManagerV1` once per app, wrap GPUI's
    `wl_surface` from the raw window handle with `ObjectId::from_ptr`, and set a rounded region.
    Rules:
    - **Raw handle:** `Window::window_handle()` hides the raw-window-handle method; call
      `HasWindowHandle::window_handle(window)`. It names the window, so get the `wl_surface` yourself.
    - **Join early and once:** join inside the `open_window` closure, so the first frame knows
      whether blur exists. Each join leaves a `wl_registry` and `wl_compositor` that can't be
      destroyed.
    - **Never drop the guest connection** (`ManuallyDrop`): GPUI may close its display before app
      globals drop, and cleanup would touch freed memory.
    - **Region timing:** set the region only while the window draws. A region on a destroyed surface
      is a protocol error, and it kills GPUI's connection too.
    - **Region origin:** KWin reads the region from the window geometry's corner, so subtract the
      client inset.
    - **Region precision:** regions are whole logical pixels; keep the rows inside the rounded curve.
    - **Capabilities:** follow `capabilities`; KWin drops `blur` while its Blur effect is off.
    - **Debugging:** `WAYLAND_DEBUG=1` traces every request.
  - **macOS:** get the `NSWindow` from the raw handle's `ns_view` and call
    `CGSSetWindowBackgroundBlurRadius(CGSMainConnectionID(), ns_window.windowNumber(), 40)`. Paint
    opaque while `NSWorkspace::accessibilityDisplayShouldReduceTransparency()` is true, and call
    `request_animation_frame()` when it changes.

### 9. Stacked translucent fills differ between Linux and macOS
*gpui-pre 0.3.8 · Linux and macOS · Concierge, Clokkr*

- **Symptom:** a 0.78 fill on 0.6 chrome lets 8.8% of the desktop through on Linux and comes out
  opaque on macOS.
- **Cause:** the Metal pipeline adds destination alpha (blend factor one); Linux's wgpu path uses one
  minus source alpha.
- **Fix:** compute a per-platform fill, thinner on macOS.

### 10. gpui-component's outlines vanish on a translucent window
*gpui-component 0.7.1 · any platform · Numero*

- **Symptom:** form controls lose their outlines on a blurred dark window (#262626 on #212226).
- **Cause:** the theme's colours assume its own opaque ground.
- **Fix:** give form-heavy windows (preferences, dialogs) an opaque ground and keep translucency for
  content windows.

### 11. Dialogs: the backdrop covers the frame, and popovers paint above dialogs
*gpui-component 0.7.1 · any platform · Concierge, Clokkr*

- **Backdrop:** the dialog backdrop covers the whole surface, shadow band and rounded corners
  included. Set the theme's `overlay` transparent and dim the window's own shape yourself.
- **Popover over dialog:** a `Popover` paints above the dialog layer, so a confirm dialog opened from
  inside a popover comes up behind it. Drive the popover with `open && !window.has_active_dialog(cx)`.
