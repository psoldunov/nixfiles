---
name: nextjs-lighthouse-performance
description: >
  Audit and optimize a Next.js codebase to maximize Lighthouse performance scores across all
  four categories: Performance, Accessibility, Best Practices, and SEO. Use this skill whenever
  a user wants to improve their Lighthouse score, fix Core Web Vitals (LCP, INP, CLS), optimize
  a Next.js app for speed, reduce bundle size, fix image or font loading issues, or asks why
  their PageSpeed score is low. Trigger on phrases like "improve my lighthouse score", "optimize
  my next.js app", "why is my LCP slow", "fix my core web vitals", "bundle is too large",
  "fonts are causing layout shift", "bad pagespeed score", "how do i get 100 on lighthouse",
  or any request mentioning performance, web vitals, or page speed in a Next.js context. When
  in doubt, use this skill — a structured audit beats ad-hoc guessing every time.
---

# Next.js Lighthouse Performance Skill

Systematic audit and fix process for achieving top Lighthouse scores in Next.js 15/16 App Router
projects. Covers all four Lighthouse categories with Next.js-specific implementation details.

**Version notes used throughout this skill:**
- **Next.js 15** — current stable LTS
- **Next.js 16** — released Oct 2025; several config keys promoted out of `experimental`

**Target thresholds:**
- LCP ≤ 2.5s | INP ≤ 200ms | CLS < 0.1 | TTFB < 800ms
- Lighthouse Performance ≥ 95 | Accessibility ≥ 95 | Best Practices 100 | SEO 100

---

## Process Overview

0. **Version check** — confirm Next.js ≤ 16, warn and pause if 17+ (see Step 0)
1. **Audit** — run Lighthouse and identify which metrics are failing (see Step 1)
2. **Triage** — classify findings by impact × effort (see Step 2)
3. **Fix** — apply fixes in priority order using the reference files
4. **Verify** — re-run and confirm improvement
5. **Maintain** — add CI budget gates

Always audit before fixing. Don't guess what's slow.

---

## Step 0: Version Check

**Do this before anything else.**

Check the Next.js version in the project:

```bash
cat package.json | grep '"next"'
# or
bun pm ls | grep next
```

Then act on the result:

- **Next.js 15** — this skill is fully accurate. Proceed.
- **Next.js 16** — this skill is fully accurate. Proceed.
- **Next.js 17 or later** — stop and warn the user:

> ⚠️ This skill was last verified against Next.js 16. You're running Next.js **{version}**.
> Some config options, APIs, or rendering patterns in this skill may be outdated.
> Consider updating the skill before proceeding — check the [Next.js upgrade guide](https://nextjs.org/docs/app/guides/upgrading) and the [Next.js blog](https://nextjs.org/blog) for breaking changes since v16, then use the skill-creator skill to update this skill.
> Want me to continue with the current skill anyway, or check the latest docs first?

If the user says continue anyway, proceed with a caveat on any config snippets you provide.
If they want docs checked first, fetch https://nextjs.org/blog and the relevant upgrade guide before proceeding.

---

## Step 1: Audit

If the user hasn't run Lighthouse yet, guide them:

```bash
# Production build first — Lighthouse on dev is useless
bun run build && bun run start

# Then open Chrome DevTools → Lighthouse tab
# OR use CLI:
bunx lighthouse http://localhost:3000 --output=json --output-path=./lighthouse-report.json
```

Also check:
```bash
# Bundle analysis — run this, share the output
ANALYZE=true bun run build
```

Ask the user to share either:
- The Lighthouse report JSON/HTML
- The specific metric scores (LCP, INP, CLS, TBT, FCP, SI)
- The bundle analyzer output

**Do not start fixing until you know which metrics are failing.**

---

## Step 2: Triage

Map failing metrics to fix areas:

| Failing metric | Primary cause area | Reference file |
|---|---|---|
| LCP > 2.5s | Images, fonts, TTFB, render-blocking | `references/lcp.md` |
| INP > 200ms | Too much client JS, hydration cost | `references/inp.md` |
| CLS > 0.1 | Images missing dimensions, font swap, dynamic content | `references/cls.md` |
| TBT > 200ms | Large JS bundles, heavy client components | `references/bundles.md` |
| High FCP | Render-blocking resources, slow TTFB | `references/lcp.md` |
| Score 90-95 | Fine-tuning, metadata, accessibility | `references/accessibility-seo.md` |
| Score < 90 | Multiple issues — work through all reference files |

Read the relevant reference file(s) before proposing fixes.

---

## Step 3: Fix Priority Order

Work in this sequence — each layer enables the next:

1. **Rendering strategy** — SSG > ISR > SSR > CSR. Wrong strategy tanks everything.
2. **LCP element** — almost always the hero image. Fix first, biggest impact.
3. **Bundle size** — reduce JS shipped to client (INP + TBT).
4. **Fonts** — always `next/font`, never raw `@import`.
5. **Third-party scripts** — defer with `next/script` strategies.
6. **CLS** — explicit dimensions everywhere, stable font fallbacks.
7. **Caching headers** — long TTL for static assets.
8. **Metadata & SEO** — `generateMetadata`, canonical, OG, JSON-LD.
9. **Accessibility** — semantic HTML, ARIA, color contrast.

---

## Step 4: Audit Output Format

When reviewing a codebase or Lighthouse report, structure output as:

### 🔴 Critical (score killer, fix immediately)
Each issue: **What** | **Where** (file/line) | **Fix** (code snippet)

### 🟡 High Impact (5-15 point swing)
Same format.

### 🟢 Quick Wins (<1 hour, 1-5 points each)
Bullet list with one-liner fixes.

### ✅ Already Good
What's working — don't break this during fixes.

### 🗺️ Recommended Fix Order
Numbered sequence based on this project's specific issues.

---

## Next.js 15 Specifics to Always Check

**App Router patterns:**
```tsx
// ✅ Server Component by default — no 'use client' unless needed
// ✅ Async server components fetch on server, zero client JS
export default async function Page() {
  const data = await fetch('...', { next: { revalidate: 3600 } })
  return <div>{data}</div>
}

// ❌ Don't do this for data that can be static
'use client'
export default function Page() {
  const [data, setData] = useState(null)
  useEffect(() => { fetch('...').then(setData) }, [])
  ...
}
```

**Partial Prerendering (PPR):**

Next.js 15 — still experimental, opt-in per route:
```ts
// next.config.ts
const config: NextConfig = {
  experimental: { ppr: 'incremental' },
}
```
```tsx
// page.tsx or layout.tsx — opt this route into PPR
export const experimental_ppr = true

export default function Page() {
  return (
    <>
      <StaticHero />           {/* prerendered at build time */}
      <Suspense fallback={<Skeleton />}>
        <DynamicUserData />    {/* streamed in at request time */}
      </Suspense>
    </>
  )
}
```

Next.js 16 — `experimental.ppr` removed, replaced by Cache Components:
```ts
// next.config.ts
const config: NextConfig = {
  cacheComponents: true,  // replaces experimental.ppr entirely
}
```

**`next.config.ts` baseline:**

Next.js 15:
```ts
const config: NextConfig = {
  compress: true,
  poweredByHeader: false,
  experimental: {
    reactCompiler: true,            // experimental in 15
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons', 'date-fns'],
    turbopack: {},                  // optional: experimental in 15
  },
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
  },
}
```

Next.js 16 — `reactCompiler` and `turbopack` promoted to top-level:
```ts
const config: NextConfig = {
  compress: true,
  poweredByHeader: false,
  reactCompiler: true,              // top-level in 16, no longer experimental
  turbopack: {},                    // top-level in 16
  cacheComponents: true,            // replaces experimental.ppr
  experimental: {
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons', 'date-fns'],
  },
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920],
  },
}
```

---

## Reference Files

Read the relevant file(s) for deep dives:

- `references/lcp.md` — LCP fixes: images, fonts, TTFB, render-blocking resources
- `references/inp.md` — INP fixes: client JS reduction, hydration, interactions
- `references/cls.md` — CLS fixes: image dimensions, font fallbacks, dynamic content
- `references/bundles.md` — Bundle analysis and reduction: dynamic imports, tree shaking
- `references/accessibility-seo.md` — Accessibility and SEO for 100/100
- `references/ci-monitoring.md` — Lighthouse CI setup, performance budgets, monitoring

---

## Related Agents

This skill drives a Next.js performance/accessibility/SEO audit workflow. When
the audit surfaces concerns that warrant a dedicated reviewer, delegate via the
Agent tool — keep this skill focused on Lighthouse-driven measurement and fixes.

- **`code-reviewer`** — for diff-level review of the perf changes once written
  (TypeScript / Next.js / Bun specialist; will catch RSC/Client-boundary
  regressions, missing `revalidateTag`, hydration mismatches, accidental
  `force-dynamic`, etc.).
- **`security-reviewer`** — when the audit touches headers, CSP, redirects,
  Server Actions, or anything that affects the security posture.
- **`refactor-cleaner`** — when the audit identifies large unused-code surface
  contributing to bundle size; runs knip / depcheck / ts-prune to delete it
  safely.
- **`e2e-runner`** — when fixes risk regressing critical flows and the user
  wants Playwright/Vercel Agent Browser coverage before merging.

One agent per concern. Run them on the diff *after* the perf work is committed,
not in parallel with measurement — the Lighthouse score is the gate; the agents
sign off on the implementation.
