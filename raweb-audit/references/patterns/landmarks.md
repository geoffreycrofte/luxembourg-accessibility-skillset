# Landmarks — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show landmarks`

> **No framework sections in this file.** Landmarks are static HTML — a React
> `<nav>` and an Angular `<nav>` are the same `<nav>`. There is no
> framework-specific concern to document, and inventing one would imply
> otherwise. The Vanilla section is the whole pattern.

---

## Universal rules

- **Use the native elements.** `<nav>` **is** `role="navigation"`. Writing
  `<nav role="navigation">` is redundant noise that every reviewer then has to
  ignore.
- **Exactly one `<main>` per page.** It is what the skip link targets.
  (RAWeb 12.7)
- **Name duplicate landmarks.** Two `<nav>`s announce as "navigation,
  navigation". `aria-label="Main"` and `aria-label="Breadcrumb"` fix it.
  (RAWeb 7.1)
- **Never put the role in the label.** `<nav aria-label="Main navigation">` is
  announced "**Main navigation navigation**". The role is already there — say
  `"Main"`.
- **`<section>` is only a landmark when it has a name.** An unnamed `<section>`
  is a `<div>` to assistive technologies. This surprises people.
- **Don't landmark everything.** The landmark list exists so users can *skip to*
  things. If every block is a landmark, it's just the page again.
- **`<header>`/`<footer>` stop being landmarks when nested.** Inside `<article>`,
  `<aside>`, `<main>`, `<nav>` or `<section>` they map to nothing special.

### Element → role

| Element | Role | Notes |
|---|---|---|
| `<header>` | `banner` | **only** at top level |
| `<nav>` | `navigation` | name it if there's more than one |
| `<main>` | `main` | exactly one |
| `<aside>` | `complementary` | |
| `<footer>` | `contentinfo` | **only** at top level |
| `<form>` | `form` | **only** when it has an accessible name |
| `<section>` | `region` | **only** when it has an accessible name |
| `<input type="search">` in a `<form>` | — | use `role="search"` on the form |

---

## Vanilla

### Do

```html
<body>
  <!-- Skip link: first focusable thing on the page (RAWeb 12.7). -->
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <!-- Top level → banner. -->
  <header>
    <a href="/"><img src="logo.svg" alt="Acme Corp"></a>

    <!-- Named, because there is more than one <nav> on this page.
         "Main", not "Main navigation" — the role is already announced. -->
    <nav aria-label="Main">
      <ul>
        <li><a href="/" aria-current="page">Home</a></li>
        <li><a href="/projects">Projects</a></li>
        <li><a href="/contact">Contact</a></li>
      </ul>
    </nav>

    <!-- role="search" goes on the form; there is no <search> mapping to rely on
         universally yet. -->
    <form role="search" action="/search">
      <label for="q">Search the site</label>
      <input type="search" id="q" name="q">
      <button type="submit">Search</button>
    </form>
  </header>

  <!-- The skip link's target. tabindex="-1" makes it programmatically
       focusable, so focus really lands here — without it, some browsers scroll
       but leave focus at the top, and the next Tab goes back to the nav. -->
  <main id="main-content" tabindex="-1">
    <h1>Projects</h1>

    <!-- Named <section> → region landmark. Unnamed, it would be a plain div. -->
    <section aria-labelledby="featured-heading">
      <h2 id="featured-heading">Featured</h2>
      …
    </section>

    <article>
      <!-- Nested <header>: NOT a banner. Just an article header. Correct. -->
      <header>
        <h2>Riverside housing</h2>
        <p>Published <time datetime="2026-03-01">1 March 2026</time></p>
      </header>
      <p>…</p>
    </article>
  </main>

  <aside aria-labelledby="related-heading">
    <h2 id="related-heading">Related projects</h2>
    …
  </aside>

  <!-- Top level → contentinfo. -->
  <footer>
    <nav aria-label="Legal">
      <ul>
        <li><a href="/privacy">Privacy</a></li>
        <li><a href="/terms">Terms</a></li>
      </ul>
    </nav>
    <p>© 2026 Acme Corp</p>
  </footer>
</body>
```

```css
/* The skip link must be reachable but not intrusive: hidden until focused,
   then visible (RAWeb 12.7). Never display:none it — that removes it from the
   tab order entirely and it can never be reached. */
.skip-link {
  position: absolute;
  inset-block-start: -100%;
  inset-inline-start: 0;
  z-index: 1000;
  padding: 0.75rem 1rem;
  background: #000;
  color: #fff;
}

.skip-link:focus {
  inset-block-start: 0;
}

/* main gets tabindex="-1" for the skip link, so suppress its focus ring —
   it is a scroll target, not an interactive control. */
main:focus {
  outline: none;
}
```

### Don't

```html
<!-- DON'T: redundant roles.
     → <nav> is already role="navigation". Pure noise. -->
<nav role="navigation">…</nav>
<main role="main">…</main>
<header role="banner">…</header>

<!-- DON'T: the role inside the label.
     → Announced "Main navigation navigation". Say aria-label="Main". -->
<nav aria-label="Main navigation">…</nav>

<!-- DON'T: two unnamed navs.
     → "navigation" and "navigation". The user cannot tell which is the site nav
       and which is the legal footer links. -->
<nav><ul>…</ul></nav>
<nav><ul>…</ul></nav>

<!-- DON'T: more than one <main>.
     → Invalid, and the skip link has an ambiguous target. -->
<main>…</main>
<main>…</main>

<!-- DON'T: an unnamed <section> expecting a landmark.
     → No name means no region. It is a <div> with extra letters. Either name it
       with aria-labelledby, or just use a <div>. -->
<section>
  <h2>Featured</h2>
</section>

<!-- DON'T: landmark everything.
     → Twelve regions in the landmark list is not navigation, it is the page
       again. Landmarks are for skipping TO things. -->
<section aria-label="Intro">…</section>
<section aria-label="Body">…</section>
<section aria-label="Sidebar">…</section>
<section aria-label="Related">…</section>

<!-- DON'T: div soup with roles bolted on.
     → Works, but the native elements are shorter, self-documenting, and cannot
       drift out of sync with the role. -->
<div role="banner">…</div>
<div role="main">…</div>

<!-- DON'T: a skip link that is display:none until focus.
     → display:none removes it from the tab order, so it can never BE focused.
       The link exists and is unreachable — a very common broken skip link
       (RAWeb 12.7). Move it off-screen instead. -->
<style>.skip-link { display: none; } .skip-link:focus { display: block; }</style>

<!-- DON'T: a skip link with no tabindex on the target.
     → Some browsers scroll to #main-content but leave focus at the top of the
       page, so the next Tab goes right back into the nav — exactly what the
       user was skipping. -->
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content">…</main>
```

---

## Verify

- **The landmark list is the check.** Open your screen reader's landmark rotor
  (VoiceOver: `Ctrl+Opt+U`; NVDA: `D` cycles landmarks). You should see a short,
  legible list: banner, Main navigation, main, complementary, contentinfo. If
  you see "navigation, navigation, region, region, region", they need names — or
  there are too many.
- **The skip link check (RAWeb 12.7):** load the page, press **Tab once**. The
  skip link must appear. Press **Enter**, then **Tab again** — focus must be
  inside `<main>`, not back in the nav. If it returns to the nav, the target is
  missing `tabindex="-1"`.
- **The one-`<main>` check:** `document.querySelectorAll('main').length` must be
  1.
- **Automated:** axe is genuinely good here — it catches multiple `<main>`s,
  duplicate unnamed landmarks, and content outside landmarks. This is one of the
  few patterns where scanners catch most of what matters. It will **not** tell
  you that `aria-label="Main navigation"` reads badly, or that you have twelve
  regions where two would do.
