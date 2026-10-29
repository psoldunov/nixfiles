# Entity lifetimes, keys, focus and mouse

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

## Lifetimes and borrow panics

### 1. Updating a view or window GPUI already holds panics or fails
*gpui-kit 0.7.1 · any platform · Concierge, Clokkr, Numero*

GPUI leases a view or window for the length of a dispatch. A nested read or update of the same one
panics ("cannot read … while it is already being updated") or returns `Err` ("window not found").
The cases met so far:

- **`cx.listener` closures** run while GPUI holds the view. Use only the `&mut Self` you are handed;
  `cx.entity().read(cx)`, or a helper that takes the `Entity`, panics on every click.
- **A typed `WindowHandle<Root>::update`** holds Root, so a dialog or notification opened inside it
  panics. Call `AnyWindowHandle::from(handle).update(cx, …)` instead.
- **A global `cx.on_action`** runs while GPUI holds the window the key went to, so
  `window_handle.update` fails inside it (focusing a field, closing windows on Quit).
- **Menu-bar, tray and other windows' actions** dispatch through the active window, which GPUI holds.
- **A window removing itself** inside its own event handler: `window.remove_window()` does nothing,
  and an invisible window stays up eating clicks.

**Fix:** handle such actions app-wide and do the window work in `cx.defer`:
```rust
cx.defer(move |cx| {
    let _ = handle.update(cx, |_, window, cx| view.update(cx, |v, cx| act(v, window, cx)));
});
```
Keep the main window's `AnyWindowHandle` and a `WeakEntity` of its view in a `Global` for this.

### 2. `global_mut` inside an `observe_global` callback loops forever
*gpui-kit 0.7.1 · any platform · Clokkr*

- **Symptom:** the app hangs at 100% CPU on the main thread.
- **Cause:** `global_mut` queues the same global's notification again, so the observer runs again,
  endlessly.
- **Fix:** read with `global()` in observers, and send requests through a channel or router rather
  than a mutated global.

### 3. A token renderer that holds its field's `Entity` leaks
*gpui-component 0.7.1 · any platform · Concierge*

- **Symptom:** closed views stay alive, still subscribed and still parsing.
- **Cause:** `Input::token` and `Textarea::token` install the renderer into the field's persistent
  state, not one frame's element. A renderer holding the field, or its owner, is a cycle that never
  drops.
- **Fix:** capture a `WeakEntity` in the renderer.

### 4. `on_window_should_close` covers platform closes only
*gpui-kit 0.7.1 · any platform · Numero*

> **Unverified.** Inferred from Numero's code comments, not from GPUI's source or a test. Check
> whether `remove_window()` runs the hook in your version before relying on either reading.

- **Symptom:** unsaved state is lost when the app closes its own window.
- **Claim:** the handler runs for closes the platform asks for (traffic light, compositor), and the
  app's own `remove_window()` skips it.
- **Fix that holds either way:** register `window.on_window_should_close(cx, …)` for platform closes,
  and also save explicitly before every `remove_window()`.

## Keys

### 5. Keys go to interceptors, then bindings, then `on_key_down`
*gpui-kit 0.7.1 · any platform · Concierge, Clokkr, Numero*

- **Symptom:** a shortcut recorder built on `on_key_down` never sees bound keys, so recording Ctrl+Q
  quits the app. A recorder in one window receives keys typed in others.
- **Fix:** record through `App::intercept_keystrokes`, which runs before GPUI matches bindings. Return
  early unless `window.window_handle()` is the recorder's window, since interceptors see every
  window's keys. Call `cx.stop_propagation()` on the keys you take. Keep the returned `Subscription`
  alive only while recording.
- **Also:** letters typed into a field have no binding, so a parent's `on_key_down` sees them too.
  Handle each key in one place, either an action or `on_key_down`: by the time the second runs, the
  action may have moved focus.

### 6. A binding with no context outranks the same key in a context
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** a global shortcut steals a key from a focused text field (the `Input` context).
- **Fix:** bind keys that text fields use only inside a context, or warn the user when they choose
  one.

### 7. The keymap can't remove a single binding
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** `cx.clear_key_bindings()` drops gpui-component's bindings too.
- **Fix:** to move an action at run time, bind `Unbind("ns::Action")` on the old keys, then bind the
  action on the new keys. `Unbind` touches only that action on those keys. A later binding outranks
  an `Unbind`, so moving back works. The keymap grows by two bindings per change.

### 8. With nothing focused, only Root gets keys
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** a view's `on_key_down` and its context bindings stay silent until something inside it
  has focus.
- **Cause:** a key travels up the path from the focused element. With nothing focused, or a focused
  element the last frame didn't draw, only the window's root gets it, and that is gpui-kit's Root,
  not your view. A key bound in a context works only while focus is inside an element with that
  `key_context`.
- **Fix:** give each screen its own focus handle and focus it when the screen opens and when a tab is
  chosen.

### 9. Keystroke strings are parsed at run time
*gpui-kit 0.7.1 (gpui-pre 0.3.8) and 0.8.1 (gpui-pre 0.3.10) · any platform · Concierge, Clokkr, Numero*

- **Symptom:** `KeyBinding::new` panics at startup on a keystroke it can't parse, for example after
  someone edits a binding string. On gpui-pre 0.3.10 every `secondary-…` binding panics this way
  (`InvalidKeystrokeError { keystroke: "secondary-n" }`), though the build, Clippy and all tests
  pass. `Modifiers::secondary()` fails to compile on 0.3.10 with E0061.
- **Cause:** from 0.3.10, `KeyBinding::new` parses without knowing the OS, so the `secondary-` alias
  is rejected, and `Modifiers::secondary` asks the platform at run time.
- **Fix:**
  - Build bindings with `KeyBinding::load`, which returns the error instead of panicking. Its last
    argument differs by release: on 0.3.8 Concierge passes a keyboard mapper,
    `KeyBinding::load(keys, Box::new(action), None, false, None, &DummyKeyboardMapper)`; on 0.3.10
    Clokkr passes `cx`, `KeyBinding::load(keys, Box::new(action), context, false, None, cx)?`, which
    resolves `secondary-` for the OS. Or spell `cmd-` and `ctrl-` per platform.
  - On 0.3.10, call `modifiers.secondary(cx)`.
  - Build bindings in one function and unit-test that it runs, then launch the app after any GPUI
    bump.
  - On 0.3.8, `secondary-` maps to ⌘ on macOS and Ctrl elsewhere. For zoom-in, bind `secondary-=`,
    `secondary-+` and `secondary-shift-=` together to cover keyboard layouts.

### 10. Text fields swallow Up, Down, Enter, Tab and Escape
*gpui-component 0.7.1 · any platform · Concierge*

- **Cause:** `TextareaState` handles them through the `Input` context's actions: `MoveUp`,
  `MoveDown`, `Enter`, `IndentInline`, `Escape`.
- **Fix:** `capture_action` the action on an ancestor and call `cx.stop_propagation()`. Capture runs
  root-down, so the ancestor gets the key before the field.
- **`submit_on_enter(false)`:** every Enter adds a line, then emits `PressEnter`. Decide in a
  `capture_action` for `Enter`.

### 11. Key dispatch order on macOS
*gpui-pre-macos 0.3.8 · macOS · Concierge*

> **Unverified.** Worked out by reading `handle_key_event`; never tried on a Mac. Test it before
> relying on it.

- **Claim:** a key with a printable `key_char` and no Ctrl, Fn or Cmd goes to the keymap before the
  text field, so an ⌥⇧P binding in a field's key context would win over the "∏" the field would
  type. The exceptions are text being composed and an IME input source (Japanese, Chinese, Korean)
  with a field that prefers it.

## Focus

### 12. Focus events fire only in the active window
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** `on_blur` never fires in tests.
- **Cause:** GPUI compares focus paths only while the window is active.
- **Fix:** call `window.activate_window()` in blur tests. Use `on_mouse_down_out` to notice a click
  elsewhere, and `cx.on_blur` to notice focus moving away.

### 13. Clicks move keyboard focus
*gpui-kit 0.7.1 · gpui-component 0.7.1 · any platform · Concierge*

- **`track_focus`:** GPUI focuses a `track_focus` element on any left press inside it that no handler
  default-prevents. A focus handle on a large container, such as a transcript, steals the composer's
  focus on every click inside it; keep focus handles on small elements.
- **gpui-component `Button`:**

  > **Conflicting.** Concierge's notes disagree. The newer note (commit f5e0dba4) says a `Button`
  > keeps a focus handle for its focus ring and takes focus when clicked, blurring the field beside
  > it. The older note (commit 2bbb4f04) says it doesn't. Check in your version.

  Where focus matters, as next to a field that closes on blur, use a plain `div` that stops the
  press; that holds under both readings.

## Mouse

### 14. Nested click handlers, presses and drags
*gpui-kit 0.7.1 · gpui-component 0.7.1 · any platform · Concierge*

- **A Button inside a clickable row fires both handlers:** gpui-component's `Button` and
  `dropdown_menu` triggers don't stop the click. Wrap the buttons in a box with
  `.on_click(|_, _, cx| cx.stop_propagation())`.
- **Stop a press and still get a click:** put `on_mouse_down(Left, stop_propagation)` and `on_click`
  on the same `div`. The click's own listener is registered after the element's mouse-down
  listeners.
- **Drag and click:** on one element, a drag wins once the pointer passes the threshold, and the
  click is dropped.
- **Nested drop targets:** the innermost target under the pointer takes the drop.

### 15. Clicking a tray icon to close its popover reopens it
*gpui-kit 0.7.1 · tray-anchored popovers · Clokkr*

- **Cause:** the click first takes the keyboard, so `observe_window_activation` closes the popover,
  and then the toggle arrives.
- **Fix:** record when the popover closed on losing focus, and ignore a toggle shortly after (Clokkr
  uses 350 ms).
