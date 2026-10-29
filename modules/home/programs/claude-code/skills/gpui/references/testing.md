# Headless and snapshot tests

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

### 1. Headless windows don't behave like real ones
*gpui-kit 0.7.1 · gpui-component 0.7.1 · Linux · Concierge, Clokkr*

- **Decorations:** they report server-side decorations, so snapshots show no frame, no window
  controls and no blur.
- **Redraw:** they redraw only when a view notifies. `Theme::change` and `refresh_windows()` alone
  leave the old frame, so notify the root view after switching modes.
- **Resize:** `window.resize` keeps the old layout size while the screenshot takes the new one, and
  the rest comes out black. Open at the final size.
- **Async work:** work on the background executor, and canvas-measured layout (#2), need extra
  frames before you save.
- **Hover:** snapshots never hover, so they miss hover-only crashes
  ([layout-and-rendering.md](layout-and-rendering.md) #4). Launch the app to cover those.

### 2. Measured layout needs two frames
*gpui-kit 0.7.1 · any platform · Concierge*

- **Symptom:** the first frame has the wrong layout in any view that measures itself with a `canvas`
  ([layout-and-rendering.md](layout-and-rendering.md) #8).
- **Fix:** draw twice, then capture.

### 3. Offscreen snapshot tests need a GPU
*gpui-kit 0.7.1 · Linux · Clokkr*

- **Fix:** mark them `#[ignore]`, run them with nextest's `--run-ignored ignored-only`, and write PNGs
  to `target/ui-snapshots`. Keep view state in plain models that tests exercise without GPUI.

### 4. GPUI tests can't run on macOS
*gpui-pre-macos 0.3.8 · macOS with nextest or the default harness · Concierge, Clokkr*

- **Symptom:** "Mac platform not created on main thread".
- **Cause:** the Mac platform must start on the main thread, and the test harness runs each test on
  its own thread.
- **Fix:** render GPUI snapshots on Linux and test only logic on the Mac. AppKit-only snapshots still
  work on macOS.

### 5. The test scheduler panics when another thread wakes a task
*gpui-kit 0.7.1 `test-support` · any platform · Numero*

- **Symptom:** a `#[gpui::test]` panics as soon as a file watcher (notify, inotify) or a similar
  thread wakes a GPUI task.
- **Cause:** the deterministic test dispatcher refuses wakes from foreign threads.
- **Fix:** skip starting cross-thread sources under `cfg!(test)` and call their handler directly from
  the test.

### 6. Focus tests need an active window
`on_blur` and other focus events fire only in the active window; call `window.activate_window()`
first ([input-and-lifetimes.md](input-and-lifetimes.md) #12).
