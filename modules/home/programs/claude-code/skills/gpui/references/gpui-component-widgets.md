# gpui-component widgets

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.
Everything here was seen on gpui-component 0.7.1 over gpui-pre 0.3.8 unless the tag says otherwise.

### 1. Text selection spans the whole window
*gpui-component 0.7.1 · any platform, window moves on Linux client decorations · Concierge, Clokkr, Numero*

- **Symptom:** a click that moves a pixel on a sidebar row selects transcript text. After a window
  move or resize, the selection follows the pointer until the next click.
- **Cause:** any left press no control claims starts a selection, and dragging carries it to the
  nearest selectable text, however far. During a move or resize the compositor keeps the release, so
  the selection never ends.
- **Fix:** claim left presses on all chrome (headers, rows, resize bands, drag areas) with
  `GlobalState::suppress_text_selection` in a mouse-down handler, and clear it on mouse-up and
  `on_mouse_down_out`. The claim must sit inside the view: on a `RootPlugin::decorate` wrapper it
  does nothing, because the selection listener is on Root under the view.

### 2. Selection API limits
*gpui-component 0.7.1 · any platform · Concierge*

- **Context-menu copy:** every left press clears every selection in the capture phase; a right press
  doesn't, but a context menu's "Copy" item is a left press. Read `TextSelection::selected_text`
  while building the menu and copy that.
- **TextView state:** `TextView::markdown` hides its `TextViewState`. To select a message whole, own a
  `TextViewState` and draw it with `TextView::new(&state)`.
- **SelectableText:** it can't select all, and its runs take `document_order` 0, so mixing it between
  TextViews selects the wrong spans.
- **Selection scopes:** Root resets the scope every render (`WindowState::prepare`), so a custom scope
  undoes itself a frame later.
- **Shortcuts:** Root binds Ctrl+C everywhere; Ctrl+A is bound only in the `TextView` and `Input`
  contexts.

### 3. Markdown tables are unusable for real content
*gpui-component 0.7.1 and 0.7.2 · any platform · Concierge*

- **Symptom:** columns are sized by character count, so words break mid-word. The last columns are
  clipped with no way to reach them: the scroll layout keeps each column at least half its widest
  cell, clamped to 160–480 px by private constants, draws no scrollbar, and keeps its scroll handle
  private. 0.7.2 measures widths but still clips.
- **Fix:** render tables yourself through `MarkdownExtensions`, a block parser plus a block renderer
  (Concierge `crates/ensemblr-ui/src/markdown/table.rs`):
  - Build the extensions once and clone them; a new set has a new revision and forces a reparse.
  - A block renderer gets no layout. Record the width with a `canvas` in `window.use_keyed_state` and
    draw twice.
  - A cell parsed as a whole document turns a leading `-`, `#`, `1.`, `>` or `<br>` into a block;
    escape the leading marker.
  - Nested TextViews take their selection order when their paint ends, so cells count as coming
    before their message.

### 4. Theme config quirks
*gpui-component 0.7.1 · any platform · Concierge*

- **Symptom:** a new colour key has no effect and no warning. Themes don't reload. Syntax colours
  stay light in dark mode.
- **Cause:** some `ThemeConfig` JSON keys are renamed (`link`, `link.hover`, `drag.border`,
  `progress.bar.background`, `slider.background`, `description_list.label.*`) and unknown keys are
  ignored. `Theme::update` doesn't reload when the mode is unchanged. A config without `highlight`
  keeps the previous config's syntax theme.
- **Fix:** check new keys against the `rename` attributes in `theme/schema.rs`. Set `light_theme` and
  `dark_theme`, then call `Theme::change(mode)`. Copy `highlight` into every config.

### 5. Button layout and styling
*gpui-component 0.7.1 · any platform · Concierge, Clokkr*

- **Alignment:** a Button centres its content and `content_style` is crate-private, so `justify_start`
  does nothing. For a left-aligned label, give the button a `flex_1` child instead of `label`.
- **Truncation:** `label` already ellipsizes. Cap the button with `max_w_full()`; a truncating child
  loses the accessible name.
- **Stretching:** a Button in a plain `div` inside a `v_flex` stretches to full width. Wrap a lone
  button in an `h_flex`.
- **Custom variants:** `ButtonCustomVariant` draws no border and mixes its colour towards black, so
  the colour shows at a fraction of its strength. Keep the button clear and paint the fill on a
  child.
- **ButtonGroup:** the selected outline is nearly invisible in dark mode; set `.bg` and `.text_color`
  yourself.
- **Icons:** a button's icon follows its size, so `.large()` gives 1.5 rem icons beside 1 rem labels.

### 6. A row of Buttons doesn't shrink, and `overflow_x_scrollbar()` breaks wheel scrolling
*gpui-component 0.7.1 · any platform · Concierge*

- **Symptom:** buttons paint over their neighbours. With `overflow_x_scrollbar()`, a plain mouse
  wheel can't reach what is cut off.
- **Cause:** that wrapper calls `lock_scroll_axis()`, which stops GPUI turning a vertical wheel into a
  sideways scroll. Its 16 px track also covers the buttons and takes their clicks.
- **Fix:** put the buttons in a `flex_none` row inside a `min_w_0` box with GPUI's own
  `overflow_x_scroll()` and no scrollbar. Menus and popovers they open aren't clipped, because
  `deferred` draws with no content mask.

### 7. `overflow_y_scrollbar()` ignores `max_h` in an auto-height parent
*gpui-component 0.7.1 · any platform · Concierge*

- **Symptom:** a list in a popover grows to its full height, and the cap only clips it.
- **Cause:** the wrapper adds a `size_full` box, which an auto-height parent doesn't bound.
- **Fix:** give a plain `div` an id, `max_h`, `overflow_y_scroll()` and `track_scroll(&ScrollHandle)`,
  and lay `Scrollbar::vertical` over it in a `relative` parent.

### 8. PopupMenu quirks
*gpui-component 0.7.1 · any platform · Concierge, Clokkr*

- **Check mark:** `.checked(true)` centres the check on the whole item, between the lines of a
  two-line item, and sets no accessibility state.
- **Submenu rows:** take no second line, no `checked` and no click.
- **Submenu side:** decided by the menu's left edge plus its own `max_w`, never the submenu's width,
  and nothing pulls an overflowing submenu back on screen.
- **Long menus:** don't scroll unless `.scrollable(true)`, which caps them at half the window, 450 px
  at most.
- **Row heights:** once a scrolling menu overflows, plain items shrink to their text height while
  submenu and element items keep 26 px. Use element items throughout a menu that scrolls.
- **Left-click menus:** `DropdownMenu` works only on `Button`; `context_menu` is right-click only.
- **Disabled items:** barely read as disabled; dim them yourself.

### 9. Inputs and editors
*gpui-component 0.7.1 · any platform · Concierge*

- **Borderless padding:** `Input::appearance(false)` keeps the horizontal padding; add `.px_0()`.
- **Cursor tracking:** `InputEvent::Change` doesn't fire on cursor moves. `cx.observe` the state and
  read `cursor()`, a byte offset.
- **Silent updates:** `set_value` emits no `Change`.
- **Cursor reset:** `set_value` and `replace_all` move the cursor to the start, and `set_value` clears
  undo. Call `set_cursor_position` after them; its `Position` counts lines and characters.
- **Focus events:** `InputEvent::Blur` and `Focus` come from the field, so a form needs no focus
  handle of its own.
- **Syntax highlighting:** `EditorState` highlights only languages whose `tree-sitter-*` features are
  enabled.
- **Bracket pairing:** `auto_close` is on by default, which gets in the way of prose.

### 10. The editor's scroll handle is private
*gpui-component 0.7.1 (`input::EditorState`) · gpui-base 0.7.2 · any platform · Numero*

- **Symptom:** a column that should scroll with the editor (results, a gutter) lags a frame or
  drifts.
- **Cause:** the scroll handle is private to gpui-base, and the editor settles its scroll offset
  (cursor follow, clamping) in its own `prepaint`, so reading it in `render` gets last frame's value.
- **Fix:** write a custom `Element` placed after the editor in the tree. In its `prepaint`, read
  `editor.input_bounds().origin.y + editor.scroll_offset().y` and wrap the child in
  `with_element_offset` and `with_content_mask`. Before the editor's first paint `input_bounds` is
  zero, so fall back to `scroll_offset` alone. Numero `crates/numero-app/src/follow.rs` does this.

### 11. Small widget gotchas
*gpui-component 0.7.1 · any platform · Concierge*

- **Switch:** controlled; it doesn't move until you store and re-render the value.
- **RadioGroup:** every radio is a Tab stop and there are no arrow keys. Roll your own with
  `tab_stop(false)`.
- **TabBar:** `TabBar::on_click` overrides each Tab's own `on_click`.
- **Icons:** `IconName` names all of Lucide, but `Assets` embeds only gpui-component's subset, and the
  others draw nothing, silently. Serve the extra SVGs yourself or use `AllAssets` (about 2,000).
- **TextView:** takes its font size from a parent's `text_size`, and `.style()` is folded onto the
  theme's style.
- **Clipboard:** gpui-component's `Clipboard` shows a check mark for 2 s after a copy.

### 12. MessageScroller
*gpui-component 0.7.1 · any platform · Concierge*

- **State:** `MessageScrollerState` keeps only row heights. Diff your rows and `splice` only the
  changed range, which keeps the scroll anchor. Call `remeasure_items` for a row that grew in place.
- **Padding:** its row wrapper pads every row but the last, so a side guide line breaks at each pad.
  Give the row's own element `pb(gap)` and `mb(-gap)`.
