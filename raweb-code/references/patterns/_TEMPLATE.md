# <Component Name> — code examples

<!--
AUTHORING CONTRACT — read before adding a new pattern file.

1. SINGLE SOURCE OF TRUTH
   ARIA attributes, their values/states, keyboard interactions and RAWeb
   criteria live in references/components/<slug>.json — NEVER retype them as
   tables here. They are rendered on demand by:
       scripts/raweb-component-lookup.sh show <slug>
   Criterion levels and official titles are resolved at render time from
   niveaux.json and criteres.json, so they cannot drift.
   This file holds ONLY prose + code.

2. FILE NAME
   references/patterns/<slug>.md — the slug MUST match the JSON file name,
   otherwise `code <slug>` cannot find it.

3. SECTION HEADINGS ARE AN API
   `raweb-component-lookup.sh code <slug> <framework>` extracts a single
   "## " section by fuzzy-matching its heading. Use exactly these, in order:
       ## Universal rules
       ## Vanilla
       ## React
       ## Angular
       ## Web Component
       ## Verify
   Add a framework only if you can write it correctly — a wrong example is
   worse than a missing one. Inside a section use "### Do" / "### Don't".

3b. STATIC PATTERNS GET VANILLA ONLY
   If the pattern needs no JavaScript (landmarks, link, breadcrumb, table,
   meter), write ONLY "## Universal rules", "## Vanilla" and "## Verify".
   A React <nav> is the same <nav>. A framework section would imply a
   framework-specific concern that does not exist, and send readers hunting for
   a difference that is not there. Say so in a blockquote at the top of the
   file; `code <slug> react` will report the sections that do exist.
   The brief is "vanilla HTML/CSS **or JS (when required)**" — where JS is not
   required, the framework sections are not either.

4. EVERY CLAIM MUST BE VERIFIABLE
   Cite the RAWeb criterion number for each rule (e.g. "RAWeb 7.3"). Verify it:
       scripts/raweb-lookup.sh criterion 7.3
   Do not invent criterion numbers. Do not cite WCAG SC numbers as if they were
   RAWeb numbers — they are different numbering schemes.

5. DON'TS MUST BE REAL
   Every "Don't" should be a mistake actually seen in production code, with a
   one-line explanation of the failure it causes for a real user. No strawmen.

Delete this comment block when authoring a real pattern file.
-->

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show <slug>`

**Read this whole file** when building the component. Use
`code <slug> <framework>` only when you already know the universal rules and
just want the snippet.

---

## Universal rules

Rules that hold no matter the framework. Each one cites its RAWeb criterion.

- **<Rule>.** <Why it matters for a real user.> (RAWeb <x.y>)

**Native element:** `<element>` — state what the browser gives you for free, so
the reader knows what NOT to reimplement.

---

## Vanilla

### Do

```html
<!-- Reference implementation. This is the one to get perfect: the framework
     sections are translations of it. -->
```

```css
/* Only the accessibility-relevant CSS. No visual design filler. */
```

```js
// Only the accessibility-relevant JS.
```

### Don't

```html
<!-- DON'T: <the mistake in one line>
     → <the concrete failure: who is blocked and how> -->
```

---

## React

### Do

```jsx
// Idiomatic React. Show the framework-specific traps:
// useId for label association, refs for imperative a11y APIs, cleanup on unmount.
```

### Don't

```jsx
// DON'T: <the React-specific mistake>
//     → <the concrete failure>
```

---

## Angular

### Do

```ts
// Modern Angular (signals, standalone). Mention the CDK equivalent if one exists.
```

### Don't

```ts
// DON'T: <the Angular-specific mistake>
//     → <the concrete failure>
```

---

## Web Component

### Do

```js
// Custom element. ALWAYS address the shadow DOM caveat: ARIA IDREF attributes
// (aria-labelledby, aria-describedby, aria-controls, aria-activedescendant)
// DO NOT cross the shadow boundary.
```

### Don't

```js
// DON'T: <the shadow DOM mistake>
//     → <the concrete failure>
```

---

## Verify

- Keyboard-only pass: <the exact key sequence to try>
- Screen reader: <what must be announced>
- Automated: <what axe/Lighthouse will and will NOT catch for this pattern>
