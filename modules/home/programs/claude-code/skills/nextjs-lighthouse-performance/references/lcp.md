# LCP Optimization (Largest Contentful Paint)

Target: ≤ 2.5s. LCP is almost always the hero image or largest above-fold text block.

---

## 1. Hero Image — The #1 LCP killer

```tsx
// ✅ Correct hero image setup
import Image from 'next/image'

<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority              // preloads — only use on above-fold LCP element
  fetchPriority="high"  // explicit browser hint
  quality={85}          // 85 is sweet spot: quality vs size
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 1200px"
  placeholder="blur"    // prevents CLS, shows blurred preview while loading
  blurDataURL="data:image/jpeg;base64,..."  // tiny base64 placeholder
/>

// ❌ Never do this for LCP element:
<img src="/hero.jpg" />                        // no optimization
<Image src="/hero.jpg" loading="lazy" />       // lazy = death for LCP
// omitting `priority` on hero image            // browser de-prioritizes it
```

**Only use `priority` on the one LCP image.** Using it everywhere negates the benefit.

---

## 2. Image Formats

```ts
// next.config.ts — serve AVIF first (50-80% smaller than JPEG), WebP fallback
images: {
  formats: ['image/avif', 'image/webp'],
}
```

AVIF can increase build time. If builds are slow, drop to WebP only.

---

## 3. External Images — Download at Build Time

External images (S3, Cloudinary, CDN) add network roundtrips + DNS lookups.

```ts
// app/lib/download-images.ts — run during generateStaticParams
import fs from 'fs'
import path from 'path'

export async function downloadImage(url: string, filename: string) {
  const res = await fetch(url)
  const buffer = await res.arrayBuffer()
  const dir = path.join(process.cwd(), 'public', 'images')
  fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(path.join(dir, filename), Buffer.from(buffer))
}
```

Then use the local `/images/filename.jpg` path instead of the external URL.

---

## 4. TTFB (Time to First Byte)

Poor TTFB directly delays LCP. Fix order:

**a) Prefer static over dynamic:**
```tsx
// Fastest possible TTFB — served from CDN edge
export const dynamic = 'force-static'    // explicit
// OR just don't use cookies/headers in the page — Next.js auto-detects

// Use ISR if content changes:
export const revalidate = 3600  // rebuild every hour max
```

**b) Cache data fetches:**
```tsx
// ✅ Cached at the fetch level
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 3600, tags: ['products'] }
})

// ✅ Or use unstable_cache for DB queries
import { unstable_cache } from 'next/cache'
const getCachedProducts = unstable_cache(
  async () => db.select().from(products),
  ['products'],
  { revalidate: 3600 }
)
```

**c) Use Edge Runtime for dynamic routes:**
```tsx
export const runtime = 'edge'  // runs at CDN edge, ~50ms TTFB globally
// Note: no Node.js APIs in edge runtime
```

---

## 5. Preload Critical Resources

```tsx
// app/layout.tsx — preload hero image if path is known at build time
import type { Metadata } from 'next'

// Via next/head link tag in layout:
export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        <link
          rel="preload"
          href="/images/hero.avif"
          as="image"
          type="image/avif"
        />
      </head>
      <body>{children}</body>
    </html>
  )
}
```

---

## 6. Font LCP (when hero is text)

If LCP element is a heading, fonts blocking render kills LCP.

```ts
// app/fonts.ts
import { Inter } from 'next/font/google'

export const inter = Inter({
  subsets: ['latin'],
  display: 'swap',          // don't block render waiting for font
  preload: true,            // default, but be explicit
  fallback: ['system-ui'],  // fallback prevents FOIT
  adjustFontFallback: true, // auto-adjusts fallback metrics to minimize CLS
})
```

---

## 7. Render-Blocking Resources Checklist

- ✅ No `<link rel="stylesheet">` for external CSS in `<head>`
- ✅ No `<script>` tags without `defer` or `async` in `<head>`
- ✅ Use `next/script` for all third-party scripts (never raw `<script>`)
- ✅ Inline critical CSS (above-fold styles) — Next.js does this automatically for CSS Modules
- ✅ No synchronous data fetching blocking page render

---

## LCP Diagnostic Checklist

```
[ ] Hero image uses next/image with priority + fetchPriority="high"
[ ] Hero image has correct sizes prop (not 100vw for desktop)
[ ] Image format is AVIF/WebP (check Network tab)
[ ] No lazy loading on above-fold images
[ ] TTFB < 800ms (check in Lighthouse waterfall)
[ ] Page is static or ISR (not force-dynamic for content pages)
[ ] No render-blocking scripts in <head>
[ ] Fonts use next/font with display: swap
[ ] Critical images preloaded if path is static
```
