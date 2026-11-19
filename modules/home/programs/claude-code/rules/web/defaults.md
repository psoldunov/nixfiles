# Web Frontend Defaults

- **Tailwind CSS is the default styling for any web frontend**: new projects, pages and
  components. Use something else only when the user asks for it, or when the project already styles
  with another system. Start new projects on Tailwind v4 (CSS-first, no `tailwind.config.js`).
- **Tailwind always ships with `clsx`, `tailwind-merge` and a `cn()` helper.** Whenever you add
  Tailwind to a project, install both packages in the same step and wrap them in `cn()`. A project
  that already uses Tailwind but has no `cn()` gets one the same way before you compose classes.
- Match the major versions: `tailwind-merge` v3 supports Tailwind v4 only; a Tailwind v3 project
  needs `tailwind-merge` v2.6.

```ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

Put it in `lib/utils.ts` (`src/lib/utils.ts` in a `src/` layout), imported as `@/lib/utils` (the
shadcn/ui location), unless the project already has a home for shared utilities. In plain JavaScript, drop the type import.

**Never store Tailwind class names in constants**, such as `const card = 'rounded-lg border p-6'`
or a `styles.ts` of class strings, in any file type. Write the classes on the element. A group
reused frequently becomes a custom utility built with `@apply` in the main stylesheet (`@utility card
{ @apply …; }` in v4). A lookup keyed by a prop (`sizes[size]`) and shadcn's `cva()` are allowed.
Rule 6 of the Tailwind rules has the details.

The full Tailwind rules are in [web/tailwind.md](./tailwind.md). They load when you read a
stylesheet or component file.
