# Layout, rendering, images and fonts

Each entry's tag line names the versions and platform it was seen on, then the apps that hit it.

### 1. Rounded corners don't clip children
*gpui-pre 0.3.8 · any platform · Concierge, Clokkr*

- **Symptom:** children paint square corners over a rounded parent or window, even with
  `overflow_hidden`. An `img` inside a rounded box isn't clipped either.
- **Cause:** content masks are rectangles.
- **Fix:** give every background that reaches a corner the frame's radius (minus its hairline), or
  keep it transparent and inset the content. Set radii on the `img` itself.

### 2. Shadows reach 3 × blur, stop at the surface and fill under their element
*gpui-pre 0.3.8 · any platform · Concierge, Clokkr, Numero*

- **Symptom:** a shadow ends in a hard line at the window's edge, and translucent elements look
  darker or muddy.
- **Cause:** the shader treats the blur as a standard deviation, drawing out to three times the blur
  radius, and GPUI never paints past the surface. A drop shadow also fills the area under its own
  element.
- **Fix:** keep `3 × blur + offset + spread` inside the inset you reserve for the shadow. Keep drop
  shadows faint or absent under translucent backgrounds. An inset shadow with `blur_radius: 0` gives
  a crisp 1 px rim with antialiased corners.

### 3. Borders come only in whole logical pixels
*gpui-pre 0.3.8 · any platform · Concierge, Clokkr, Numero*

- **Symptom:** a 1 px border smears across two device pixels at fractional scales (1.25, 1.5).
- **Cause:** `.border_1()` and its siblings are whole logical pixels.
- **Fix:** write the style directly, per side:
  `style().border_widths.top = Some(px(1. / window.scale_factor()).into())`.

### 4. `hidden()` with a `hover` or `group_hover` to `flex` crashes the window
*gpui-pre 0.3.8 · any platform · Concierge*

- **Symptom:** "must call prepaint before paint" the first time the pointer rests on the element,
  only in a real window; snapshot tests never hover.
- **Cause:** prepaint skips the children of a `display: none` element. Paint then re-resolves the
  style with hover, finds `flex`, and paints children that were never laid out.
- **Fix:** use `invisible()` with `group_hover(…, |s| s.visible())`. An invisible element registers
  no mouse listeners, so clicks reach what lies under it.

### 5. An absolute element with no offsets sits in its flow position
*gpui-pre 0.3.8 · any platform · Concierge*

- **Symptom:** a measuring or hit-testing `canvas` sits after its siblings, not at the parent's top
  left.
- **Fix:** add `.absolute().top_0().left_0()`.

### 6. Flex children and text wrapping
*gpui-pre 0.3.8 · any platform · Concierge*

- **Text in an `h_flex` doesn't wrap:** a flex child is at least as wide as its content, so one long
  line runs off the window. Give the row's child `min_w_0`; for a single line cut short, use
  `truncate`.
- **`min_w_0` on text inside a `v_flex` wraps it to a sliver** (at a sibling's width, or at zero).
  Taffy's min-content pass hands the text 0 as its available width, and GPUI's text caches that
  measurement for every later unbounded measure. Put `min_w_0` on the column (the row's child), never
  on the text inside it.

### 7. Text metrics: line height, baselines and rems
*gpui-pre 0.3.8 · gpui-component 0.7.1 · any platform, descent sign on Linux · Concierge, Clokkr*

- **Symptom:** body text looks stretched. `items_baseline` doesn't line up two text sizes; the
  smaller sits low. Every `text_sm`, `size_4` and so on moves when the base font size changes.
- **Cause:** GPUI's default line height is the golden ratio (1.618). GPUI gives Taffy no baseline.
  The size utilities are rems, and gpui-component sets the rem to `Theme::font_size`. On Linux
  `TextSystem::descent` comes back negative, which makes `baseline_offset` wrong.
- **Fix:** set a tighter `style.text.line_height` on the root or in the theme. For mixed sizes, use
  one line height and offset by hand with the `.abs()` of the descent.

### 8. An element can't know its own size while it renders
*gpui-pre 0.3.8 · any platform · Concierge*

1. Add a `canvas` child with `absolute().top_0().left_0().size_full()`.
2. In its prepaint, store the bounds on the view and notify when they change. The next frame uses
   them, so measured layout is right from the second frame ([testing.md](testing.md) #2).
3. Add the parent's border back: an absolute child fills the box inside the border.
4. To fit a window to scrolling content, measure a `relative` column inside the scroll area, not the
   scroll area itself.

### 9. A scrolling `div` lays out and paints every child, every frame
*gpui-pre 0.3.8 · any platform · Concierge*

- **Symptom:** about 100 ms frames with 1,000 rows while anything animates; one animation redraws the
  whole window.
- **Fix:**
  - **Variable-height rows:** `list` with a `ListState`. Rows not yet drawn count as 0 px, so the
    scrollbar is right only once every row has been seen.
  - **Uniform rows:** `uniform_list`, which measures one row; its scrollbar is right from the start.
  - Compute row data when the model changes, not in `render`.

### 10. `list` with `ListAlignment::Bottom` reports scrolls one event late
*gpui-pre 0.3.8 · any platform · Concierge*

- **Symptom:** paging driven by the scroll event reacts one wheel event late.
- **Cause:** `ListScrollEvent` reports the rows in view before the scroll, not after.
- **Note:** splicing older rows in above the view keeps the visible rows in place, so history can
  page in while the user reads.

### 11. A `.cached(..)` view is never measured
*gpui-pre 0.3.8 · any platform · Concierge*

- **Symptom:** a view as tall as its content gets no height as a cached child in a column. The first
  keystroke after a click redraws every cached view.
- **Cause:** a cached view is laid out from its own style only. GPUI refreshes the whole window when
  input switches from pointer to keyboard.
- **Fix:** give cached views explicit sizes, or overlay them and report their height through a
  `canvas`. A cached view must `notify` itself when it changes.

### 12. Images: `img(path)` caches forever, stretches, and decodes few formats
*gpui-pre 0.3.8 · any platform · Concierge, Clokkr*

- **Symptom:** a changed file keeps showing its first picture. A tall picture stretches the `img`
  past its box, and `ObjectFit::Cover` paints over what lies beneath. `.icns` and `.xpm` icons show
  nothing.
- **Cause:** the asset cache is keyed by path and never evicted. Taffy keeps a leaf at least its
  width over its aspect ratio tall. GPUI decodes only PNG, SVG and JPEG.
- **Fix:** decode and scale pictures yourself and pass an `Arc<RenderImage>`; its frames are BGRA, so
  swap R and B on an `RgbaImage`. Give each `img` its box's `aspect_ratio`. Convert other formats to
  PNG once and cache them.

### 13. Fonts
*gpui-pre 0.3.8 · gpui-component 0.7.1 · Linux unless noted · Concierge, Clokkr, Numero*

- **First use costs a frame:** a 15 to 22 ms frame the first time a font, weight or style is shaped,
  because cosmic-text works out fallback order once per font by opening every installed face of
  another weight. Call `TextSystem::prewarm_fonts` on the background executor before first use; it
  holds the text system's lock while it runs.
- **Loading:** load fonts with `cx.text_system().add_fonts(...)` and name them by typographic family;
  static TTFs are known to work. `font_family("monospace")` goes through fontconfig, so name your
  bundled mono family instead.
- **System UI font:** `.SystemUIFont` resolves to SF Pro (`.AppleSystemUIFont`) on macOS. On Linux it
  maps to a fixed family most desktops don't ship, and gpui-component's monospace is its own bundled
  pick. Before the first frame, set `theme.font_family` and `theme.mono_font_family` from the
  desktop: Plasma's `kdeglobals`, else fontconfig's `sans-serif` and `monospace` resolved through
  `cx.text_system().resolve_font(..)`, later the portal's `org.gnome.desktop.interface` `font-name`.
  Skip any family missing from `text_system().all_font_names()`. To scale controls with the desktop
  font size, set the theme rem to the desktop size divided by 0.875, since gpui-component labels are
  `text_sm`.
- **OpenType features are ignored on Linux:** tabular digits don't apply, so a running timer
  jitters. Put each digit in a fixed-width cell (colons in a narrower one).
