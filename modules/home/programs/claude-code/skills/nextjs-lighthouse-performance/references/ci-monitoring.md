# CI Monitoring & Performance Budgets

Getting to 100 is one thing. Staying there is another.
Performance regressions are silent — add automated gates so they can't ship.

---

## 1. Lighthouse CI

```bash
bun add -D @lhci/cli
```

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI

on: [push, pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v2
      - run: bun install
      - run: bun run build
      - run: bunx lhci autorun
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

```js
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      startServerCommand: 'bun run start',
      url: ['http://localhost:3000', 'http://localhost:3000/about'],
      numberOfRuns: 3,  // average across 3 runs for stability
    },
    assert: {
      assertions: {
        // Block merge if any of these fail:
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'categories:best-practices': ['error', { minScore: 1.0 }],
        'categories:seo': ['error', { minScore: 1.0 }],
        // Core Web Vitals as budget gates:
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 200 }],
        // Bundle gates:
        'unused-javascript': ['warn', { maxLength: 0 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',  // stores reports publicly
      // Or use lhci server for private storage:
      // target: 'lhci',
      // serverBaseUrl: 'https://your-lhci-server.com',
    },
  },
}
```

---

## 2. next build Output Budget

```bash
# After build, Next.js prints per-route sizes:
Route (app)                    Size     First Load JS
┌ ○ /                         5.2 kB        85.3 kB
├ ○ /about                    1.1 kB        81.2 kB
└ ○ /blog/[slug]              3.4 kB        88.5 kB

# Add a build check to fail if First Load JS > threshold:
```

```ts
// scripts/check-bundle-size.ts
import { execSync } from 'child_process'

const MAX_FIRST_LOAD_KB = 150

const output = execSync('bun run build 2>&1').toString()
const matches = output.matchAll(/(\d+\.?\d*) kB\s+First Load/g)

for (const match of matches) {
  const size = parseFloat(match[1])
  if (size > MAX_FIRST_LOAD_KB) {
    console.error(`Bundle too large: ${size}kB > ${MAX_FIRST_LOAD_KB}kB`)
    process.exit(1)
  }
}
```

---

## 3. Vercel Speed Insights (Real User Monitoring)

Lab scores (Lighthouse) differ from field scores (real users). Monitor both.

```tsx
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next'
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />
        <Analytics />
      </body>
    </html>
  )
}
```

SpeedInsights tracks LCP, INP, CLS, FCP, TTFB per page per device type.
Available in Vercel dashboard under Analytics → Web Vitals.

---

## 4. Next.js 16 API Changes to Note in CI/Cache

**`revalidateTag()` now requires a second argument in Next.js 16:**
```ts
// Next.js 15
revalidateTag('blog-posts')

// Next.js 16 — second arg required (cacheLife profile or inline object)
revalidateTag('blog-posts', 'max')        // built-in profile
revalidateTag('blog-posts', 'hours')
revalidateTag('blog-posts', { expire: 3600 })  // inline

// Next.js 16 — new updateTag() for read-your-writes in Server Actions
'use server'
import { updateTag } from 'next/cache'
export async function savePost(id: string) {
  await db.posts.update(id, data)
  updateTag(`post-${id}`)  // expires and immediately reads fresh — user sees change now
}
```

**`middleware.ts` deprecated in Next.js 16 — rename to `proxy.ts`:**
```ts
// proxy.ts (Next.js 16) — rename from middleware.ts, same logic
import { NextRequest, NextResponse } from 'next/server'
export default function proxy(request: NextRequest) {
  // same logic as before
  return NextResponse.next()
}
// middleware.ts still works but is deprecated
```

---

## 4. reportWebVitals Hook

For non-Vercel deployments or custom analytics:

```ts
// app/web-vitals.ts
export function reportWebVitals(metric: {
  name: string
  value: number
  id: string
}) {
  // Send to your analytics
  if (typeof window !== 'undefined') {
    window.gtag?.('event', metric.name, {
      value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
      event_label: metric.id,
      non_interaction: true,
    })
  }
}
```

---

## 5. Performance Regression Runbook

When a score drops:

1. **Identify commit** — check Lighthouse CI run that first failed
2. **Diff the bundle** — `git diff HEAD~1 HEAD` + re-run `ANALYZE=true bun run build`
3. **Common regressions:**
   - New `'use client'` added to a component that renders large subtree
   - New heavy dependency imported without dynamic()
   - Image without `priority` added above fold
   - New third-party script without `strategy` set
   - SSG page accidentally made dynamic (cookies/headers used)
4. **Fix forward** — don't revert unless critical, understand root cause

---

## Monitoring Checklist

```
[ ] Lighthouse CI configured in GitHub Actions
[ ] Assertions gate merges on perf ≥ 90, a11y ≥ 90, BP = 100, SEO = 100
[ ] CWV numeric thresholds in LHCI config
[ ] Vercel Speed Insights installed for RUM
[ ] Bundle size check in CI
[ ] Performance runbook documented for team
```
