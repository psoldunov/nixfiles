# CLS Optimization (Cumulative Layout Shift)

Target: < 0.1. CLS = unexpected layout movement after initial render.
The score = impact fraction × distance fraction, summed across all shifts.

Most common culprits in Next.js: images without dimensions, late-loading fonts, and
dynamic content (cookie banners, ads, async-fetched content) injected above existing content.

---

## 1. Images — Always Explicit Dimensions

Every image without width/height causes a layout shift while the browser waits to know
how much space to reserve.

```tsx
// ✅ Explicit dimensions — space reserved before image loads
<Image src="/product.jpg" alt="Product" width={400} height={300} />

// ✅ Fill mode — parent container defines size
<div style={{ position: 'relative', aspectRatio: '16/9' }}>
  <Image src="/banner.jpg" alt="Banner" fill sizes="100vw" style={{ objectFit: 'cover' }} />
</div>

// ❌ Missing dimensions = CLS
<Image src="/product.jpg" alt="Product" />
<img src="/product.jpg" alt="Product" />
```

**For dynamic image grids** where dimensions aren't known at build time:
```tsx
// Use aspect-ratio CSS to reserve space
<div style={{ aspectRatio: '4/3', position: 'relative' }}>
  <Image src={src} alt={alt} fill style={{ objectFit: 'cover' }} />
</div>
```

---

## 2. Fonts — next/font with adjustFontFallback

Fonts that load late and cause text reflow are a classic CLS source.

```ts
// app/fonts.ts
import { Inter, Playfair_Display } from 'next/font/google'

export const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  adjustFontFallback: true,  // KEY: auto-adjusts fallback metrics
                              // to match custom font dimensions
                              // = near-zero shift when font loads
  variable: '--font-inter',  // use CSS variables for flexibility
})

export const playfair = Playfair_Display({
  subsets: ['latin'],
  display: 'swap',
  adjustFontFallback: true,
  variable: '--font-playfair',
})
```

```tsx
// app/layout.tsx
import { inter, playfair } from './fonts'

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${inter.variable} ${playfair.variable}`}>
      <body className={inter.className}>{children}</body>
    </html>
  )
}
```

**Local fonts** (for custom typefaces):
```ts
import localFont from 'next/font/local'

export const myFont = localFont({
  src: [
    { path: '../public/fonts/MyFont-Regular.woff2', weight: '400' },
    { path: '../public/fonts/MyFont-Bold.woff2', weight: '700' },
  ],
  display: 'swap',
  adjustFontFallback: false,  // set to false for non-latin fonts, tune manually
  fallback: ['system-ui', 'Arial'],
})
```

---

## 3. Dynamic Content — Reserve Space

Content injected after initial render (cookie banners, ads, async data) causes CLS
if it pushes existing content down.

```tsx
// ❌ Cookie banner appears and pushes everything down
{showBanner && <CookieBanner />}

// ✅ Reserve space for it regardless
<div style={{ minHeight: '60px' }}>  {/* matches banner height */}
  {showBanner && <CookieBanner />}
</div>

// ✅ Or position fixed (doesn't affect layout)
<div style={{ position: 'fixed', bottom: 0, left: 0, right: 0 }}>
  {showBanner && <CookieBanner />}
</div>
```

**Skeleton screens** for async content:
```tsx
import { Suspense } from 'react'

// ✅ Skeleton reserves space, no shift when content loads
<Suspense fallback={<ProductCardSkeleton />}>
  <ProductCard id={id} />
</Suspense>

// ProductCardSkeleton must match ProductCard dimensions exactly
function ProductCardSkeleton() {
  return (
    <div style={{ width: 300, height: 400 }} className="animate-pulse bg-gray-200 rounded" />
  )
}
```

---

## 4. Animations — Only Transform/Opacity

Animating properties that trigger layout recalculations causes CLS.

```css
/* ❌ Triggers layout — causes CLS */
.element {
  transition: width 0.3s, height 0.3s, margin 0.3s;
}

/* ✅ Compositor-only — zero CLS */
.element {
  transition: transform 0.3s, opacity 0.3s;
}

/* ✅ Scale instead of width/height */
.element:hover {
  transform: scale(1.05);  /* not width: 110% */
}
```

---

## 5. Video and Embeds

iframes (YouTube, Vimeo, maps) are notorious CLS sources.

```tsx
// ✅ Reserve space with aspect-ratio container
<div style={{ position: 'relative', paddingTop: '56.25%' }}>  {/* 16:9 */}
  <iframe
    style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }}
    src="https://www.youtube.com/embed/..."
    loading="lazy"
  />
</div>

// ✅ Even better — use facade pattern (loads iframe on click)
import dynamic from 'next/dynamic'
const YouTubeFacade = dynamic(() => import('./YouTubeFacade'))
<YouTubeFacade videoId="..." />
```

---

## 6. `contain` CSS Property

For components that update frequently (live data, counters):

```css
/* Limits layout recalculation scope */
.live-counter {
  contain: layout;  /* changes inside don't affect outside */
}

.card-grid {
  contain: layout paint;  /* most aggressive isolation */
}
```

---

## CLS Diagnostic Checklist

```
[ ] All <Image> components have explicit width + height (or fill with sized parent)
[ ] No raw <img> tags without dimensions
[ ] Fonts use next/font with adjustFontFallback: true
[ ] Dynamic content (banners, toasts) uses fixed positioning or reserved space
[ ] Suspense fallbacks match rendered content dimensions
[ ] Animations use transform/opacity only (not width/height/margin)
[ ] iframes wrapped in aspect-ratio containers
[ ] No content injected above existing content after initial load
[ ] CLS = 0 in Lighthouse (not just < 0.1 — aim for zero)
```
