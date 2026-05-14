# Accessibility & SEO — Getting to 100/100

Performance is usually the hard part. These two categories are very achievable at 100
with a checklist approach.

---

## Accessibility — 100/100

### 1. Images Must Have Alt Text

```tsx
// ✅ Descriptive alt
<Image src="/product.jpg" alt="Red leather wallet, front view" width={400} height={300} />

// ✅ Decorative image — empty alt, not missing
<Image src="/divider.svg" alt="" width={800} height={2} role="presentation" />

// ❌ Missing alt entirely
<Image src="/product.jpg" width={400} height={300} />

// ❌ Meaningless alt
<Image src="/product.jpg" alt="image" width={400} height={300} />
```

### 2. Semantic HTML Structure

```tsx
// ✅ Correct heading hierarchy
<h1>Page Title</h1>
  <h2>Section</h2>
    <h3>Subsection</h3>

// ❌ Skipping heading levels
<h1>Title</h1>
<h3>Jumped to h3</h3>

// ✅ Semantic landmarks
<header>...</header>
<nav aria-label="Main navigation">...</nav>
<main>...</main>
<aside aria-label="Related articles">...</aside>
<footer>...</footer>

// ❌ div soup
<div class="header">
  <div class="nav">
    <div class="main">
```

### 3. Interactive Elements — Keyboard Accessible

```tsx
// ✅ Buttons for actions, links for navigation
<button onClick={handleSubmit}>Submit</button>
<a href="/about">About</a>

// ❌ div as button — not keyboard accessible, no ARIA role
<div onClick={handleSubmit}>Submit</div>

// ✅ If you MUST use div as interactive element:
<div
  role="button"
  tabIndex={0}
  onClick={handleSubmit}
  onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
>
  Submit
</div>
```

### 4. Form Labels

```tsx
// ✅ Explicit label
<label htmlFor="email">Email address</label>
<input id="email" type="email" name="email" />

// ✅ aria-label for icon-only inputs
<input type="search" aria-label="Search products" />
<button aria-label="Close dialog">✕</button>

// ✅ aria-describedby for helper text
<input
  id="password"
  type="password"
  aria-describedby="password-hint"
/>
<p id="password-hint">Must be at least 8 characters</p>

// ❌ No label
<input type="email" placeholder="Email" />  // placeholder is NOT a label
```

### 5. Color Contrast

WCAG AA: 4.5:1 for normal text, 3:1 for large text (18px+ or 14px bold+).

```css
/* ❌ Common failures */
color: #999;  /* gray on white = ~2.9:1 */
color: #aaa;  /* light gray on white = ~2.3:1 */

/* ✅ Pass AA */
color: #767676;  /* exactly 4.5:1 on white */
color: #595959;  /* 7:1 on white — AAA */
```

Use: https://webaim.org/resources/contrastchecker/

### 6. Focus Indicators

```css
/* ✅ Never remove focus outline without providing alternative */
:focus-visible {
  outline: 2px solid #0070f3;
  outline-offset: 2px;
  border-radius: 2px;
}

/* ❌ Do not do this */
* { outline: none; }
button:focus { outline: none; }
```

### 7. ARIA for Dynamic Content

```tsx
// Loading states
<div aria-live="polite" aria-busy={isLoading}>
  {isLoading ? <Spinner /> : <Content />}
</div>

// Modals/dialogs
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title"
  aria-describedby="dialog-description"
>
  <h2 id="dialog-title">Confirm deletion</h2>
  <p id="dialog-description">This action cannot be undone.</p>
</div>

// Expandable sections
<button aria-expanded={isOpen} aria-controls="section-content">
  Section Title
</button>
<div id="section-content" hidden={!isOpen}>...</div>
```

---

## SEO — 100/100

### 1. Metadata API (App Router)

```tsx
// app/layout.tsx — site-wide defaults
import type { Metadata } from 'next'

export const metadata: Metadata = {
  metadataBase: new URL('https://yourdomain.com'),
  title: {
    default: 'Site Name',
    template: '%s | Site Name',  // page titles become "Page | Site Name"
  },
  description: 'Default description (150-160 chars)',
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://yourdomain.com',
    siteName: 'Site Name',
    images: [{ url: '/og-image.jpg', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    creator: '@yourhandle',
  },
  robots: {
    index: true,
    follow: true,
  },
}

// app/blog/[slug]/page.tsx — dynamic page metadata
export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.slug)
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.coverImage }],
    },
  }
}
```

### 2. Canonical URLs

```tsx
// Prevent duplicate content penalties
export const metadata: Metadata = {
  alternates: {
    canonical: 'https://yourdomain.com/page',
  },
}
```

### 3. Sitemap

```ts
// app/sitemap.ts
import type { MetadataRoute } from 'next'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getPosts()
  return [
    {
      url: 'https://yourdomain.com',
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1,
    },
    ...posts.map(post => ({
      url: `https://yourdomain.com/blog/${post.slug}`,
      lastModified: post.updatedAt,
      changeFrequency: 'monthly' as const,
      priority: 0.8,
    })),
  ]
}
```

### 4. Robots.txt

```ts
// app/robots.ts
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/', disallow: '/api/' },
    sitemap: 'https://yourdomain.com/sitemap.xml',
  }
}
```

### 5. JSON-LD Structured Data

```tsx
// app/blog/[slug]/page.tsx
export default async function BlogPost({ params }) {
  const post = await getPost(params.slug)
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post.title,
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    author: { '@type': 'Person', name: post.author },
  }

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article>...</article>
    </>
  )
}
```

### 6. lang Attribute

```tsx
// app/layout.tsx — Lighthouse flags missing lang
<html lang="en">
```

---

## Accessibility Checklist

```
[ ] All images have descriptive alt text (or alt="" for decorative)
[ ] Heading hierarchy is sequential (h1 → h2 → h3, no skips)
[ ] All interactive elements keyboard accessible (tab, enter, space)
[ ] Form inputs have associated labels
[ ] Color contrast ≥ 4.5:1 for normal text
[ ] Focus indicators visible and not removed
[ ] aria-live for dynamic content updates
[ ] Modals use role="dialog" with aria-modal
[ ] html lang attribute set
[ ] No positive tabIndex values (tabIndex={1}, tabIndex={2}, etc.)
```

## SEO Checklist

```
[ ] generateMetadata on every page (or static metadata export)
[ ] metadataBase set in root layout
[ ] OG image configured (1200×630px)
[ ] Canonical URL set
[ ] app/sitemap.ts generated
[ ] app/robots.ts configured
[ ] JSON-LD structured data on content pages
[ ] No noindex on pages that should be indexed
[ ] Title < 60 chars, description 150-160 chars
```
