# Link — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show link`

> **No framework sections.** A link is `<a href>` in every framework. See
> [`button.md`](button.md) for the link-vs-button decision, which is where the
> real mistakes are.

---

## Universal rules

- **`<a>` without `href` is not a link.** No focus, no role, no Enter, announced
  as plain text. If it has no destination, it's a [`button`](button.md).
- **Every link needs an accessible name.** (RAWeb 6.2) An icon-only link with no
  name announces as "link".
- **Every link must be explicit.** (RAWeb 6.1) Screen reader users routinely pull
  up **a list of every link on the page**, stripped of context. Ten entries
  reading "Read more" is the failure this criterion exists for.
- **The accessible name must contain the visible text.** Voice control users say
  what they *see* — "click Download report". If `aria-label` replaces rather than
  extends the visible text, the command fails. (RAWeb 6.1)
- **Links in body text must not be colour-only.** (RAWeb 3.1) Underline them, or
  guarantee 3:1 against surrounding text **plus** a non-colour cue.
- **Announce new windows.** `target="_blank"` always needs `rel="noopener"`, and
  the user should be told before they activate it.
- **File format and size is good practice, not a criterion.** Do it — but don't
  cite 13.3 for it; that criterion is about accessible versions of office
  documents.

---

## Vanilla

### Do

```html
<!-- Explicit on its own. Read out of context in a links list, it still makes
     sense (RAWeb 6.1). -->
<a href="/reports/2024.pdf">
  Download the 2024 annual report
  <span class="file-meta">(PDF, 3.2 MB)</span>
</a>

<!-- "Read more" made explicit WITHOUT hiding the visible text: the aria-label
     CONTAINS the visible words, so voice control still works (RAWeb 6.1). -->
<article>
  <h3 id="post-42-title">RAWeb 1.1 released</h3>
  <p>The new version adds 17 criteria…</p>
  <a href="/news/raweb-1-1" aria-label="Read more about RAWeb 1.1 released">
    Read more
  </a>
</article>

<!-- Or better: no aria-label at all. Extend the visible text and hide the part
     that would be visual clutter. Nothing to keep in sync. -->
<a href="/news/raweb-1-1">
  Read more<span class="sr-only"> about RAWeb 1.1 released</span>
</a>

<!-- Icon-only link. -->
<a href="https://github.com/acme">
  <svg aria-hidden="true" focusable="false" width="24" height="24"><use href="#icon-github"/></svg>
  <span class="sr-only">Acme on GitHub</span>
</a>

<!-- New window, announced. rel="noopener" is not optional. -->
<a href="https://example.com" target="_blank" rel="noopener">
  Partner site
  <svg aria-hidden="true" focusable="false" width="12" height="12"><use href="#icon-external"/></svg>
  <span class="sr-only">(opens in a new window)</span>
</a>

<!-- Current page in a nav. -->
<nav aria-label="Main">
  <ul>
    <li><a href="/" aria-current="page">Home</a></li>
    <li><a href="/projects">Projects</a></li>
  </ul>
</nav>

<!-- An email/phone link's text should be the address itself: it is the most
     explicit possible name, and it is what a voice user will say. -->
<a href="mailto:info@example.lu">info@example.lu</a>
```

```css
/* RAWeb 3.1 — a link in a paragraph must not be identified by colour alone.
   The underline is the non-colour cue. This is the default browser behaviour;
   removing it is an active decision that usually fails 3.1. */
p a {
  color: #0056b3;
  text-decoration: underline;
}

/* If the design forbids underlines in body copy, you owe BOTH:
   - ≥3:1 contrast between link colour and surrounding text colour, AND
   - a non-colour cue on hover AND focus.
   This is hard to get right. Underlining is easier and better. */
.no-underline-links a {
  text-decoration: none;
  border-block-end: 1px solid currentColor; /* still a non-colour cue */
}

a:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

/* Current page — not by colour alone. */
[aria-current="page"] {
  font-weight: 700;
  border-block-end: 3px solid currentColor;
}
```

### Don't

```html
<!-- DON'T: <a> with no href.
     → Not focusable, no role, no Enter. Announced as text. This is the
       "clickable" that keyboard users simply cannot reach. -->
<a onclick="showPanel()">Show details</a>

<!-- DON'T: href="#" as a placeholder.
     → Navigates to the top of the page if the JS fails or is still loading,
       and it is announced as a link when it acts like a button. -->
<a href="#" onclick="deleteItem(); return false;">Delete</a>

<!-- DON'T: ambiguous link text (RAWeb 6.1).
     → In a screen reader's links list — a primary navigation tool — these are
       five identical, useless entries. -->
<a href="/a">Click here</a>
<a href="/b">Read more</a>
<a href="/c">Learn more</a>
<a href="/d">More</a>
<a href="/e">Here</a>

<!-- DON'T: aria-label that REPLACES the visible text.
     → Voice control user says "click Read more" — no match, because the
       accessible name is now something else entirely. The name must CONTAIN
       the visible text (RAWeb 6.1). -->
<a href="/news/raweb" aria-label="RAWeb 1.1 release notes">Read more</a>

<!-- DON'T: an image link with no alt.
     → Announced as the URL, character by character. -->
<a href="/"><img src="logo.svg"></a>

<!-- DON'T: alt describing the image instead of the destination.
     → For a LINKED image, the alt is the link's name: it must say where the
       link GOES, not what the picture shows. -->
<a href="/"><img src="logo.svg" alt="Blue circular logo with a swoosh"></a>

<!-- DON'T: target="_blank" with no rel and no warning.
     → noopener is a security requirement, and an unannounced new window
       disorients users whose Back button suddenly does nothing. -->
<a href="https://example.com" target="_blank">Partner site</a>

<!-- DON'T: nested interactive elements.
     → Invalid HTML. The browser's parser will break this apart in ways you did
       not intend, and it is unusable by keyboard. -->
<a href="/product/1">
  Product name
  <button type="button">Add to cart</button>
</a>

<!-- DON'T: the whole card wrapped in one link.
     → The link's accessible name becomes every word inside — heading, body,
       date, tag. Announced as one enormous run-on name. Link the HEADING and
       let CSS make the card clickable. -->
<a href="/projects/1" class="card">
  <h3>Riverside housing</h3>
  <p>A 200-unit development…</p>
  <span class="tag">Housing</span>
  <time datetime="2026-03-01">1 March 2026</time>
</a>

<!-- DO instead: link the heading, stretch it over the card with CSS. -->
<article class="card">
  <h3><a href="/projects/1" class="card__link">Riverside housing</a></h3>
  <p>A 200-unit development…</p>
</article>
```

```css
/* The card-link technique: one small, explicit link; whole card clickable. */
.card { position: relative; }
.card__link::after {
  content: "";
  position: absolute;
  inset: 0;
}
```

```html
<!-- DON'T: a link that is really a button (RAWeb 6.1).
     → See button.md. Space does not activate a link, and "open in new tab" on
       something that deletes a record is nonsense. -->
<a href="#" class="button" onclick="submitForm()">Save changes</a>
```

---

## Verify

- **The links-list check — this is the RAWeb 6.1 test.** Open your screen
  reader's links list (VoiceOver: `Ctrl+Opt+U` → Links; NVDA: `Insert+F7`). Read
  it with the page ignored. Every entry must make sense **alone**. Duplicates
  reading "Read more" are the failure.
- **The voice-control check:** for each link, could a user say "click «the
  visible text»" and hit it? If `aria-label` replaced the visible text, no.
- **Keyboard:** Tab to it, **Enter** activates. Space must **not** (that's a
  button). Focus ring visible (RAWeb 10.7).
- **The colour check (RAWeb 3.1):** screenshot a paragraph containing a link and
  desaturate it. Can you still tell there's a link? If not, it's colour-only.
- **Automated:** axe catches links with no accessible name and links with only an
  unlabelled image. It **cannot** catch "Read more" — that's valid, named, and
  useless. RAWeb 6.1 is fundamentally a human judgement.
