# INP Optimization (Interaction to Next Paint)

Target: ≤ 200ms. INP replaced FID in March 2024. It measures ALL interactions throughout
the page lifecycle — not just the first. The worst interaction at the 75th percentile is reported.

INP = Input Delay + Processing Delay + Presentation Delay

---

## 1. Reduce Client JavaScript — The Root Cause

Every KB of JS parsed/executed on the client is potential INP debt.

**Check current client JS:**
```bash
ANALYZE=true bun run build
# Look for large chunks in the client bundle
# Anything > 50KB in a single chunk is worth investigating
```

**The golden rule:** Default to Server Components. Only add `'use client'` when you actually
need browser APIs, event handlers, or state.

```tsx
// ✅ Server Component — zero JS shipped
export default async function ProductList() {
  const products = await getProducts()
  return <ul>{products.map(p => <li key={p.id}>{p.name}</li>)}</ul>
}

// ❌ Unnecessary client component
'use client'
export default function ProductList() {
  const [products, setProducts] = useState([])
  useEffect(() => { getProducts().then(setProducts) }, [])
  return <ul>{products.map(p => <li key={p.id}>{p.name}</li>)}</ul>
}
```

**Push 'use client' down to the leaf:**
```tsx
// ❌ Entire subtree becomes client JS
'use client'
export default function Page() {
  return (
    <div>
      <StaticHeader />       // now client JS — wasteful
      <StaticContent />      // now client JS — wasteful
      <InteractiveButton />  // the only thing that needed 'use client'
    </div>
  )
}

// ✅ Only the interactive leaf is client JS
export default function Page() {
  return (
    <div>
      <StaticHeader />       // stays Server Component
      <StaticContent />      // stays Server Component
      <InteractiveButton />  // 'use client' here only
    </div>
  )
}
```

---

## 2. Dynamic Imports for Heavy Client Components

```tsx
import dynamic from 'next/dynamic'

// ✅ Lazy load heavy components not needed on initial render
const HeavyChart = dynamic(() => import('./HeavyChart'), {
  loading: () => <ChartSkeleton />,  // prevents CLS
  ssr: false,                        // skip SSR for browser-only components
})

const RichTextEditor = dynamic(() => import('./RichTextEditor'), {
  ssr: false,
})

// Use in component — loads only when rendered
export default function Dashboard() {
  const [showChart, setShowChart] = useState(false)
  return (
    <div>
      <button onClick={() => setShowChart(true)}>Show Chart</button>
      {showChart && <HeavyChart />}
    </div>
  )
}
```

---

## 3. Optimize Heavy Event Handlers

Long tasks (>50ms) block the main thread and inflate INP.

```tsx
// ❌ Synchronous expensive computation blocks UI
function handleSearch(query: string) {
  const results = searchThroughThousandsOfItems(query)  // blocks main thread
  setResults(results)
}

// ✅ Use startTransition to mark as non-urgent
import { startTransition } from 'react'

function handleSearch(query: string) {
  startTransition(() => {
    const results = searchThroughThousandsOfItems(query)
    setResults(results)
  })
}

// ✅ Or offload to Web Worker for CPU-intensive work
const worker = new Worker(new URL('./search.worker.ts', import.meta.url))
function handleSearch(query: string) {
  worker.postMessage(query)
  worker.onmessage = (e) => setResults(e.data)
}
```

---

## 4. React Compiler

The React Compiler automatically memoizes components, reducing unnecessary re-renders.

```ts
// next.config.ts — Next.js 15 (experimental)
const config: NextConfig = {
  experimental: {
    reactCompiler: true,
  },
}

// next.config.ts — Next.js 16 (stable, promoted to top-level)
const config: NextConfig = {
  reactCompiler: true,
}
```

Install the Babel plugin (required for both):
```bash
bun add -D babel-plugin-react-compiler@latest
```

> Note: expect slightly longer build times — the React Compiler uses Babel under the hood.

---

## 5. optimizePackageImports

Prevents importing entire libraries when you only need one function:

```ts
// next.config.ts
experimental: {
  optimizePackageImports: [
    'lucide-react',
    '@radix-ui/react-icons',
    'date-fns',
    'lodash',
    '@headlessui/react',
  ],
}
```

---

## 6. Third-Party Scripts

Analytics, chat widgets, and tracking scripts are major INP killers.

```tsx
import Script from 'next/script'

// ✅ afterInteractive — loads after page is interactive
<Script
  src="https://www.googletagmanager.com/gtm.js?id=GTM-XXXX"
  strategy="afterInteractive"
/>

// ✅ lazyOnload — loads during browser idle time (best for non-critical)
<Script src="https://cdn.chat-widget.com/widget.js" strategy="lazyOnload" />

// ✅ worker — runs in Web Worker, off main thread (Partytown)
<Script src="https://analytics.example.com/script.js" strategy="worker" />

// ❌ Never use raw <script> tags in Next.js
<script src="https://..." async />
```

Use `@next/third-parties` for hardened wrappers around common scripts:
```tsx
import { GoogleTagManager } from '@next/third-parties/google'
<GoogleTagManager gtmId="GTM-XXXX" />
```

---

## INP Diagnostic Checklist

```
[ ] Server Components used by default, 'use client' pushed to leaves
[ ] No heavy client-side data fetching (useEffect + fetch)
[ ] Large components lazy-loaded with dynamic()
[ ] Heavy event handlers use startTransition or Web Workers
[ ] Third-party scripts use afterInteractive or lazyOnload strategy
[ ] optimizePackageImports configured for icon/utility libraries
[ ] No synchronous operations >10ms in event handlers
[ ] React Compiler enabled (experimental.reactCompiler in 15, reactCompiler top-level in 16)
[ ] Bundle analyzer shows no single chunk > 100KB
```
