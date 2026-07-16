# Breadcrumb — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show breadcrumb`

> **No framework sections.** A breadcrumb is static markup — see
> [`link.md`](link.md) and [`landmarks.md`](landmarks.md) for the rules it
> inherits.

---

## Universal rules

- **`<nav aria-label="Breadcrumb">` around an `<ol>`.** The order is meaningful,
  so it's an *ordered* list. The `<nav>` needs a name because the page already
  has another one. (RAWeb 9.3, 7.1)
- **`aria-current="page"` on the last crumb.** Once per page, nowhere else.
- **The last crumb usually isn't a link.** It points at the page you're already
  on. Plain text is honest.
- **Separators must not be announced.** A literal `/` between links is read as
  "slash" on every single crumb. Generate them in CSS, or `aria-hidden` them.
- **Don't put "Breadcrumb" in the label twice** — `aria-label="Breadcrumb"` on a
  `<nav>` announces "Breadcrumb, navigation". That's correct. `aria-label="Breadcrumb
  navigation"` announces "Breadcrumb navigation navigation".

---

## Vanilla

### Do

```html
<nav aria-label="Breadcrumb">
  <!-- <ol>, not <ul>: the sequence carries meaning, and a screen reader
       announces "list, 4 items" with positions (RAWeb 9.3). -->
  <ol class="breadcrumb">
    <li><a href="/">Home</a></li>
    <li><a href="/projects">Projects</a></li>
    <li><a href="/projects/housing">Housing</a></li>
    <!-- Last crumb: current page, not a link. aria-current marks it. -->
    <li><span aria-current="page">Riverside housing</span></li>
  </ol>
</nav>
```

```css
.breadcrumb {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  list-style: none;
  margin: 0;
  padding: 0;
}

/* The separator is generated content: it is decorative, and CSS ::before is not
   in the accessibility tree, so it is never announced. This is why it belongs
   in CSS rather than the markup. */
.breadcrumb li + li::before {
  content: "/";
  margin-inline-end: 0.5rem;
  color: #767676;
}

/* Not colour alone (RAWeb 3.1). */
.breadcrumb [aria-current="page"] {
  font-weight: 700;
}

.breadcrumb a:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

If your design needs the last crumb to *look* like the others but stay
non-navigable, keep it a link and let `aria-current` do the work:

```html
<li><a href="/projects/housing/riverside" aria-current="page">Riverside housing</a></li>
```

Both are valid. Plain text is slightly kinder — it doesn't offer the user a link
to where they already are.

### Don't

```html
<!-- DON'T: literal separators in the markup.
     → Announced: "Home, link. Slash. Projects, link. Slash. Housing, link.
       Slash." On a 5-level breadcrumb that is five spurious words. Put them in
       CSS. -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    /
    <li><a href="/projects">Projects</a></li>
    /
  </ol>
</nav>

<!-- DON'T: an <img> separator with no alt.
     → Announced as the filename. -->
<li><a href="/">Home</a><img src="chevron.svg"></li>

<!-- DON'T: <ul> for a breadcrumb.
     → The order IS the meaning. Use <ol>. -->
<nav aria-label="Breadcrumb"><ul>…</ul></nav>

<!-- DON'T: an unnamed <nav>.
     → Announced "navigation" — indistinguishable from the main nav in the
       landmark list. -->
<nav>
  <ol>…</ol>
</nav>

<!-- DON'T: "navigation" in the label.
     → "Breadcrumb navigation navigation". -->
<nav aria-label="Breadcrumb navigation">…</nav>

<!-- DON'T: no aria-current.
     → Nothing marks where the user actually is. -->
<li><a href="/projects/housing/riverside">Riverside housing</a></li>

<!-- DON'T: aria-current="page" on every crumb.
     → It means "the current page". Only one element per page may have it. -->
<li><a href="/" aria-current="page">Home</a></li>
<li><a href="/projects" aria-current="page">Projects</a></li>

<!-- DON'T: aria-current="true" on a breadcrumb.
     → Valid ARIA, but "page" is the precise token and is announced better.
       Use "true" only when no specific token fits. -->
<li><span aria-current="true">Riverside housing</span></li>

<!-- DON'T: divs and spans.
     → No list semantics: no "4 items", no position. Just four links in a row
       (RAWeb 9.3). -->
<div class="breadcrumb">
  <a href="/">Home</a> <span>/</span> <a href="/projects">Projects</a>
</div>
```

---

## Verify

- **Screen reader:** expect "Breadcrumb, navigation, list, 4 items" then "Home,
  link, 1 of 4". If you hear "slash" between crumbs, your separators are in the
  markup. If you hear no item count, it isn't a list.
- **Landmark list:** the breadcrumb must appear as its own named entry,
  distinguishable from the main nav.
- **`aria-current` check:**
  `document.querySelectorAll('[aria-current]').length` should be 1 for the whole
  page.
- **Automated:** axe catches an unnamed `<nav>` and invalid `aria-current`
  values. It does **not** catch literal separators, `<ul>`-instead-of-`<ol>`, or
  a missing `aria-current` — all manual.
