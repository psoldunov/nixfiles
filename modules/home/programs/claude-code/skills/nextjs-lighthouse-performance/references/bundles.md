# Bundle Size Optimization

Large JS bundles are the primary driver of high TBT (Total Blocking Time) and slow INP.
Every KB of JS must be downloaded, parsed, and executed before the page is fully interactive.

---

## 1. Bundle Analysis — Always Start Here

```bash
# Install if not present
bun add -D @next/bundle-analyzer

# next.config.ts
import bundleAnalyzer from '@next/bundle-analyzer'
const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
})
export default withBundleAnalyzer(config)

# Run
ANALYZE=true bun run build
```

**What to look for in the output:**
- Any single chunk > 100KB (uncompressed) — investigate
- Duplicate packages (two versions of the same library)
- Libraries where you only use 1-2 functions but import the whole thing
- `node_modules` appearing in client bundles that should be server-only

---

## 2. optimizePackageImports

Next.js 15 can tree-shake packages that don't support it natively:

```ts
// next.config.ts
experimental: {
  optimizePackageImports: [
    'lucide-react',         // icon libraries are big offenders
    '@radix-ui/react-icons',
    'react-icons',
    'date-fns',
    'lodash',
    'lodash-es',
    '@headlessui/react',
    '@heroicons/react',
    'framer-motion',        // if using selectively
  ],
}
```

---

## 3. Dynamic Imports

```tsx
import dynamic from 'next/dynamic'

// ✅ Heavy UI components
const RichTextEditor = dynamic(() => import('@/components/RichTextEditor'), {
  ssr: false,
  loading: () => <div className="h-64 bg-gray-100 animate-pulse rounded" />,
})

// ✅ Chart libraries (almost always huge)
const Chart = dynamic(() => import('react-chartjs-2').then(m => m.Line), {
  ssr: false,
})

// ✅ Modal/dialog content (not shown on initial render)
const ConfirmDialog = dynamic(() => import('@/components/ConfirmDialog'))

// ✅ Below-fold page sections
const TestimonialsSection = dynamic(() => import('./TestimonialsSection'))

// ❌ Don't dynamic import small components — overhead outweighs benefit
const Button = dynamic(() => import('./Button'))  // pointless
```

---

## 4. Barrel File Problem

Barrel files (`index.ts`) that re-export everything force the entire module into the bundle.

```ts
// ❌ This imports ALL components from the UI library
import { Button, Input, Modal, Table, ... } from '@/components/ui'

// ✅ Direct imports — only pulls in what you need
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
```

If you must keep barrel files, add `sideEffects: false` to package.json to enable tree-shaking.

---

## 5. Replace Heavy Dependencies

Common swap targets:

| Heavy library | Lighter alternative | Size saving |
|---|---|---|
| `moment` | `date-fns` (with tree-shaking) or `dayjs` | ~60-70KB |
| `lodash` | Native JS or `lodash-es` with tree-shaking | ~70KB |
| `axios` | Native `fetch` | ~15KB |
| `react-icons` (full import) | `lucide-react` with optimizePackageImports | ~200KB |
| `framer-motion` (full) | `motion/react` (new lighter package) | varies |
| Full `recharts` | Lazy import only used chart types | varies |

---

## 6. Server-Only Packages

Packages used only on the server should never reach the client bundle.

```ts
// Mark server-only modules explicitly
import 'server-only'  // throws at build time if imported from client

// Example: db client should never be in client bundle
// lib/db.ts
import 'server-only'
import { drizzle } from 'drizzle-orm/postgres-js'
export const db = drizzle(...)
```

Check for accidental client imports:
```bash
# If you see these in client chunks, something's wrong:
# - drizzle, prisma, mongoose (DB clients)
# - bcrypt, jsonwebtoken (server auth)
# - fs, path, os (Node.js built-ins)
# - dotenv
```

---

## 7. Compiler Optimizations

```ts
// next.config.ts — remove console.log in production (both 15 and 16)
compiler: {
  removeConsole: process.env.NODE_ENV === 'production'
    ? { exclude: ['error', 'warn'] }
    : false,
},

// Next.js 16: turbopack promoted out of experimental
// Next.js 15:
experimental: { turbopack: {} }
// Next.js 16:
turbopack: {}
```

---

## 8. CSS Bundle

```ts
// Tailwind v4 (2025) — zero config, automatic purging
// If still on Tailwind v3, ensure purge is configured:
// tailwind.config.ts
content: [
  './app/**/*.{ts,tsx}',
  './components/**/*.{ts,tsx}',
],

// Check CSS bundle size — should be < 20KB gzipped for most apps
// ANALYZE=true shows CSS bundle too
```

---

## Bundle Size Targets

| Metric | Green | Yellow | Red |
|---|---|---|---|
| First load JS (per route) | < 80KB | 80-150KB | > 150KB |
| Shared JS | < 100KB | 100-200KB | > 200KB |
| Single chunk | < 50KB | 50-100KB | > 100KB |
| Total page weight | < 300KB | 300-600KB | > 600KB |

Next.js shows first-load JS per route after `bun run build`.

---

## Bundle Checklist

```
[ ] @next/bundle-analyzer run, large chunks identified
[ ] optimizePackageImports configured for icon/utility libraries
[ ] Heavy components (charts, editors, maps) use dynamic()
[ ] No barrel file imports from large UI libraries
[ ] Heavy dependencies audited and swapped where possible
[ ] Server-only modules marked with 'server-only'
[ ] No Node.js-only packages in client bundle
[ ] First load JS < 100KB per route
[ ] removeConsole configured for production
```
