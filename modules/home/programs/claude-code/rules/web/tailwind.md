---
paths:
  - "**/*.css"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.html"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.astro"
  - "**/*.mdx"
---
# Tailwind CSS

> Applies only to projects that use Tailwind CSS; ignore it elsewhere. Rules 3 and 4 assume
> Tailwind v4's CSS-first configuration. Where v3 differs, the rule says so.

**Use rem for custom lengths. Built-in Tailwind utilities are always allowed, regardless of their
underlying units. Prefer existing utilities over custom values, and shared theme tokens over
repeated arbitrary values. An arbitrary value that is a scale step written the long way is drift —
convert it (rule 3).** Applies to styles you add or modify; existing violations are not precedent
for new code.

## No CSS modules

- Use Tailwind for sections, layout and UI. Do not add CSS modules, styled-components or another
  styling system to a Tailwind project. Any exception needs explicit user approval.
- UI that renders outside the site's cascade — an embedded CMS admin, a third-party widget with its
  own design system — follows that system's idiom instead. Rules 1 to 4 do not govern it, and the
  site's theme tokens may not exist there. A drift tool pointing such code at a site token is wrong.

## 1. Use rem for custom lengths; keep built-in utilities

- Use `rem`, never `px`, when authoring a fixed CSS length: spacing, sizing, typography, radii,
  borders, outlines, shadows and breakpoints. This covers custom CSS, theme tokens, inline styles
  and arbitrary Tailwind values. A `px` length ignores the reader's browser font size; a `rem`
  length scales with it.
- Use built-in Tailwind utilities without unit-based restrictions, including `w-px`, `h-px`,
  borders, outlines and shadows. Do not replace them with custom rem-based tokens merely because
  Tailwind uses pixels internally.
- `px-4` is allowed: `px-` means horizontal padding, not the pixel unit. Unitless and proportional
  utilities — `w-full`, `h-dvh`, `flex-1`, `min-h-[60vh]` — remain valid. Do not turn a fluid
  layout into fixed rem sizes.

## 2. Existing utilities first

- Check Tailwind's built-ins and the project's theme before reaching for `-[value]`. Prefer `p-4`
  over `p-[1rem]`, `gap-6` over `gap-[1.5rem]`, and a theme token such as `max-w-page` over
  repeating its value as an arbitrary one.
- If a built-in or existing token is visually indistinguishable from the requested value, use it.
  Do not introduce false precision, or a new token, for an imperceptible difference. Check the
  relevant breakpoints and states, and preserve functional sizing constraints and accessibility.

## 3. Token drift: converting an arbitrary value to the scale

Most `-[Xrem]` values are not genuinely arbitrary — they are scale steps written the long way.
Drift linters flag them; `fallow`, for one, reports them as `css-token-drift`. Convert them rather
than leaving them.

**Not every bracketed value is drift.** Decide per finding. Keep these as they are:

- A viewport-relative length with no built-in, such as `min-h-[60vh]`. (`100vw` and `100vh` do have
  built-ins: `w-screen`, `min-w-screen`, `h-screen`.)
- A fractional scale, such as `scale-[1.02]`: a bare `scale-*` must be an integer (below).
- A colour chosen to stand outside the palette on purpose, such as a draft-mode or debug banner.
  A raw hex that *is* part of the design gets a theme token (rule 4).

### The formula

Tailwind v4 derives spacing from `--spacing`, default `0.25rem`. Check the project's theme first:
if it overrides `--spacing`, divide by that value instead. For `p-*`, `m-*`, `gap-*`,
`w`/`h`/`size`, `min-*`, `max-*` and the inset utilities (`top`/`right`/`bottom`/`left`):

```
step = rem / 0.25          →  3.375rem   = 13.5   →  pt-13.5
                              30.0625rem = 120.25 →  min-h-120.25
```

Negatives take the sign on the utility, not the value: `right-[-2.375rem]` becomes `-right-9.5`.

Tailwind v3 has no spacing multiplier. Only the steps its spacing scale defines exist, so convert
only to one of those.

### Two limits the compiler enforces

- **A bare spacing step must be a multiple of `0.25`.** `h-13.75` compiles; `h-13.85`, `h-13.9` and
  `h-13.9304` emit nothing at all. At the default `--spacing`, that means the rem value must be a
  whole number of pixels, a multiple of `0.0625rem`.
- **A bare `scale-*` value must be an integer.** `scale-57` compiles, `scale-56.9499` does not — so
  `scale-[0.569499]` either snaps to `scale-57` or stays arbitrary.

A class Tailwind refuses is not a build error. It silently produces no CSS and the element loses the
style. Never ship a converted class you have not seen in compiled output.

### Non-length equivalents worth knowing (v4)

| Arbitrary | Built-in |
| --- | --- |
| `min-w-[100vw]` | `min-w-screen` |
| `aspect-[16/9]` | `aspect-video` (`--aspect-video: 16 / 9`) |
| `z-[9999]` | `z-9999` |
| `duration-[280ms]` | `duration-280` |
| `scale-[0.9]` | `scale-90` |

### Snapping an off-grid value

When the step is not a clean multiple, round to the nearest one **if the result is visually
indistinguishable** — that is rule 2, not an exception to it. `17.1953rem` → step `68.78` → `w-69`
(17.25rem, +0.875px) is fine.

Do not snap when:

- **Two distinct values would collapse into one class.** A 1px offset somebody chose deliberately
  is not noise; losing it is a regression, not a cleanup.
- **The file carries its own finer grid**, such as a transcription of a design frame at some
  fraction of its original scale. Snapping distorts the composition. Express the scale once rather
  than snapping every value, and leave the arbitrary values until someone does.

### A named token carries more than one property

A `--text-*` token sets `line-height` (and sometimes `font-weight`) alongside `font-size`;
`text-[0.8125rem]` sets the size alone. Swapping the token in is usually right, but read the call
site first — an element with no weight utility of its own will shift. The same applies to any
`--radius-*` or other token with modifiers.

### Outside a utility, reference the raw variable — not the theme alias

Tailwind v4 emits a theme variable as a CSS declaration only when the build uses it; the rest are
dropped (`@theme static` forces all of them out). With `@theme inline`, utilities carry the value
itself, so an alias often never reaches the browser. Which ones survive depends on what the build
happened to generate, so reading the stylesheet does not tell you.

- Hand-written CSS — a CSS module, a `<style>` block, styled-components, an inline `style` — that
  references `var(--color-accent)` may resolve to nothing. The browser then drops the declaration
  silently and the element loses the style.
- So reference the raw variable the theme aliases (`var(--accent)`, declared in a plain `:root`
  block), not the alias. Tailwind does not strip plain `:root` declarations.
- If you must use an alias, confirm it in a real build (below). Do not infer it from the token
  being present in `@theme`.
- Switching to `@theme static` or dropping `inline` changes the architecture. Raise it; do not fold
  it into another task.

### Finding and verifying

Build, then concatenate the compiled CSS into one file and search that. The output location depends
on the framework: `.next/static` for Next.js, `dist/` for Vite, and so on.

```bash
find .next/static -name '*.css' -exec cat {} + > /tmp/compiled.css
grep -o 'aspect-video[^{]*{[^}]*}' /tmp/compiled.css

# Is a variable emitted?
grep -q -- '--color-accent:' /tmp/compiled.css && echo emitted || echo 'not emitted'
```

- Test for a variable with `grep -q`. Piping into `... | head -1 || echo` reports nothing and
  success on a miss, so an unemitted variable looks like a blank line.
- Search the concatenated file rather than passing `--include='*.css'` to a recursive grep: on
  macOS `grep` is often `ugrep`, which warns on that flag and can return a different result set.
- A fractional step is escaped in the compiled selector, so escape it in the pattern too. A plain
  `w-155\.5` matches nothing and looks like a class that failed to emit:

  ```bash
  grep -o 'w-155\\\.5[^{]*{[^}]*}' /tmp/compiled.css
  # w-155\.5{width:calc(var(--spacing) * 155.5)}
  ```

- Variant-prefixed classes land as `.lg\:w-155\.5` and pseudo-element ones as
  `.lg\:before\:top-25\.5:before`, so anchor the pattern on the utility, not on the leading `.`.

Arithmetic is not verification. Compile and compare the declarations.

## 4. Extend the theme for recurring values

- When a genuinely distinct value recurs, add a named token and replace its repeated arbitrary
  usages with the generated utility. Reuse existing tokens first; do not extend the theme for every
  one-off.
- In v4, extend `@theme` in the project's main stylesheet (the one with `@import "tailwindcss"`).
  Do not add a `tailwind.config.js` to a v4 project. Follow the stylesheet's existing pattern; for a
  token that aliases another variable, declare the raw value in `:root` and alias it in
  `@theme inline`, so both spellings exist and a rebrand stays an edit to one block. In v3, extend
  `theme.extend` in `tailwind.config.*`.
- Use the right namespace and a meaningful name. A card radius that must differ from the existing
  ones is `--radius-card: 0.875rem` in `@theme`, used as `rounded-card`.
- **If `cn()` uses `tailwind-merge`, every non-colour token you add needs a matching entry in its
  `extendTailwindMerge` config, in the same commit.** `tailwind-merge` only knows Tailwind's own
  scales. A token it does not recognise lands in no conflict group, so `cn('rounded-lg',
  'rounded-card')` returns *both* and CSS source order decides the winner. The merge key matches
  the CSS namespace: `--radius-*` → `radius`, `--text-*` → `text`, `--spacing-*` → `spacing`, and
  so on. Colours need no entry; any unknown `bg-*` / `text-*` value counts as a colour. That is why
  an unregistered `--text-*` size is the worst case: `cn('text-body-sm', 'text-accent')` reads both
  as colours and silently drops the size. If the project tests its merge config, add a case there.
- Arbitrary values are a last resort for a genuinely one-off requirement no existing utility can
  express. Fixed lengths in one must still use rem. Moving a literal into an inline style or a CSS
  variable merely to hide the brackets does not satisfy this rule.
- Arbitrary *variants* for selectors are not arbitrary values; use them when needed, preferring
  built-in variants where available.

## 5. Compose classes with cn()

- Use the project's `cn()` helper (usually `clsx` plus `tailwind-merge`, at `@/lib/utils` in
  shadcn/ui projects) when combining base classes, conditional classes, or a caller's `className`.
  Do not use template literals, string concatenation or array joins for class composition. If the
  project has no such helper, follow its existing pattern rather than adding dependencies unasked.
- Use complete, statically detectable class names. Select whole classes rather than building
  fragments such as `bg-${color}-500` — Tailwind scans source text and will not generate a class it
  cannot see.
- A plain static `className="p-4 gap-6"` needs no `cn()` wrapper.

```tsx
className={cn('flex gap-6 p-4', isActive && 'bg-accent', className)}
```
