---
name: raweb-code
description: >
  Write accessible HTML, CSS, and JavaScript that conforms to RAWeb 1.1
  (Luxembourg Web Accessibility Framework, based on EN 301 549 / WCAG 2.1).
  Use when developing web interfaces, components, forms, navigation, or any
  front-end code that must meet Luxembourg accessibility law. Covers all 17
  RAWeb themes with code-level guidance, accessible patterns, and anti-patterns.
  Default conformance target: Level AA.
metadata:
  author: luxembourg-accessibility-skillset
  version: 1.4.0
  raweb-version: "1.1"
  wcag-version: "2.1"
  license: CC-BY-3.0-LU
  source: https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb
allowed-tools: Bash Read Grep
---

# RAWeb 1.1 — Accessible Code Development Guide

You are an accessibility-aware developer. Every piece of HTML, CSS, and JavaScript
you write MUST conform to **RAWeb 1.1** (Level AA by default). RAWeb is Luxembourg's
official web accessibility framework implementing EN 301 549 and WCAG 2.1.

## How to use the reference data

The full RAWeb 1.1 criteria, test methodologies, and glossary are available as
JSON files. Use the lookup script to query specific criteria on demand:

```bash
# List all topics
!`${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topics`

# Look up a specific criterion
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh criterion 1.1

# Look up test methodology
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh methodology 1.1.1

# Search criteria by keyword
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh search "form"

# Check glossary definition
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh glossary "text alternative"
```

The raw JSON reference files are located at:
- `${CLAUDE_SKILL_DIR}/references/criteres.json` — All 136+ criteria with tests and WCAG/EN 301 549 mappings
- `${CLAUDE_SKILL_DIR}/references/methodologies.json` — Step-by-step test procedures
- `${CLAUDE_SKILL_DIR}/references/glossaire.json` — Glossary of accessibility terms
- `${CLAUDE_SKILL_DIR}/references/themes.json` — Topic names
- `${CLAUDE_SKILL_DIR}/references/niveaux.json` — WCAG conformance levels per criterion

When writing code for a specific component, ALWAYS look up the relevant RAWeb
criteria first to ensure full compliance. For example, before writing a form,
run `search "form"` and `topic 11`.

---

## Core rules (apply to ALL code you write)

### 1. Images (Topic 1)

**ALWAYS:**
- Every `<img>` conveying information MUST have a meaningful `alt` attribute (1.1)
- Every decorative `<img>` MUST have `alt=""` and no `title`, `aria-label`, or `aria-labelledby` (1.2)
- Every `<svg>` conveying information MUST have `role="img"` — this one is mandatory, 1.1.5 invalidates the
  test without it — plus a text alternative via `aria-label`, `aria-labelledby`, or a `<title>` child (1.1)
- Decorative `<svg>` MUST have `aria-hidden="true"` (1.2)
- Every text alternative MUST be **relevant** — it must convey what the image conveys (1.3), **and short and
  concise** (test 1.3.9). RAWeb's glossary defines *short and concise* as "a maximum length of 80 characters
  is strongly recommended" — the 80 is a strong recommendation, but brevity itself is tested by 1.3
- Complex images (charts, infographics) need a detailed description (1.6) — but **the accepted routes differ
  by element type**:
  - `<img>`, `<object>`, `<embed>`: only two routes — a text alternative *referencing* an adjacent detailed
    description, or an **adjacent link/button** to it. **`aria-describedby` is not a route here** (1.6.1–1.6.3)
  - `<input type="image">`, `<svg>`, `role="img"`: `aria-describedby` **is** accepted, alongside
    `aria-label`/`aria-labelledby` and the adjacent link/button (1.6.4, 1.6.5, 1.6.10)
  - `<canvas>`: also accepts a detailed description placed between `<canvas>` and `</canvas>` (1.6.7)
  - Whichever you use, it must actually resolve for AT — tests 1.6.6, 1.6.8 and 1.6.9 validate the wiring
    rather than grant a route
- Avoid images of text unless a **replacement mechanism** exists, or the visual effect cannot be reproduced
  in CSS — 1.8 accepts either escape (1.8 — Level AA)
- Where an image has a visible caption, that caption MUST be correctly linked to the image — `<figure>`/`<figcaption>` (1.9)

**NEVER:**
- Leave `alt` undefined on an informative image
- Use `alt="image"`, `alt="photo"`, `alt="icon"` — describe what the image conveys
- Use `title` as the sole text alternative (poor assistive technology support)

```html
<!-- GOOD: informative image -->
<img src="chart.png" alt="Sales increased 40% in Q3 2024">

<!-- GOOD: decorative image -->
<img src="decoration.svg" alt="">

<!-- GOOD: complex image with detailed description -->
<figure>
  <img src="orgchart.png" alt="Company organisation chart. Full description below.">
  <figcaption>
    <details>
      <summary>Full description of the organisation chart</summary>
      <p>The CEO reports to the board. Three departments report to the CEO...</p>
    </details>
  </figcaption>
</figure>

<!-- GOOD: SVG informative -->
<svg role="img" aria-label="Warning: connection unstable">
  <use href="#icon-warning"/>
</svg>

<!-- GOOD: SVG decorative -->
<svg aria-hidden="true" focusable="false"><use href="#flourish"/></svg>
```

### 2. Frames (Topic 2)

- Every `<iframe>` MUST have a descriptive `title` attribute (2.1)
- The `title` must be relevant to the frame content (2.2)

```html
<iframe src="map.html" title="Interactive map of our office locations"></iframe>
```

### 3. Colours (Topic 3)

- Information must NEVER be conveyed by colour alone (3.1) — and RAWeb requires **both** complements, not
  either: additional information **in the code** (`aria-label`, visually hidden text, `aria-current`…)
  **and** an additional **visual** cue (icon, shape, position, typographic effect). An icon alone does not
  discharge 3.1. Applies to text, **colour named in text** ("click the green button"), images, CSS
  properties, and media
- Text contrast ratio: at least **4.5:1**, or **3:1** for large text — which RAWeb defines in **px**:
  **≥24px** non-bold, **≥18.5px** bold (3.2 — Level AA)
- Non-text elements (icons, borders, UI components): at least **3:1** contrast against adjacent colours (3.3)
- Both 3.2 and 3.3 also accept a **mechanism** that lets the user display a compliant ratio; if you ship one,
  it must itself be compliant (3.2.5, 3.3.4)

```html
<!-- BAD: colour alone conveys meaning -->
<span class="text-red">Required field</span>

<!-- GOOD: colour + text indicator -->
<span class="text-red">Required field *</span>
<span class="sr-only">(required)</span>

<!-- Or better with native HTML -->
<input type="text" required aria-required="true">
```

### 4. Multimedia (Topic 4)

- Pre-recorded video with audio MUST have captions (**4.3** — captions are 4.3, *not* 4.1; 4.1 is the
  transcript/audio-description criterion). Captions delivered via `<track>` MUST use `kind="captions"`
  (4.3.2). Live synchronised media needs captions too (4.3.3)
- Pre-recorded audio MUST have a text transcript (4.1)
- Pre-recorded video MUST have audio description if visual information is not in the audio track (4.5, 4.6 — Level AA)
- Every automatically triggered sound MUST be controllable by the user — stop it, or control its volume
  independently of the system volume (4.10). Exempt if the sequence lasts **3 seconds or less**
- Media viewing controls MUST **exist** (4.11.1): at least play/pause or stop; sound on/off if there is
  sound; a captions toggle if there are captions; an **audio-description toggle if there is AD**. Each MUST
  then be operable by keyboard AND any pointing device (4.11.2/4.11.3)
- Time-based **and non-time-based** media MUST be compatible with assistive technologies (4.13)
- Interactive `<canvas>`/`<svg>` content is **non-time-based media**: it MUST have an alternative reachable
  via a clearly identifiable adjacent link or button (4.8), that alternative MUST give the same content and
  similar features (4.9), and its controls MUST be keyboard- and pointer-operable (4.12)

These have **no WCAG equivalent** — they are EN 301 549 §7 requirements that no WCAG-based scanner reports:

- Caption and audio-description toggles MUST be presented at the **same level** as play/pause — not buried
  one extra click deep in a menu (4.14 — Level AA)
- Any transmit/convert/record feature MUST preserve captions (4.15) and audio description (4.16) — Level AA
- Caption presentation MUST be user-controllable: honour the OS caption settings, or provide an on-page
  control (4.17 — Level AA)
- Subtitles MUST be vocalisable — a spoken-subtitle track, a TTS feature, or an alternative version
  (4.18 — Level AA)

```html
<video controls>
  <source src="presentation.mp4" type="video/mp4">
  <track kind="captions" src="captions-en.vtt" srclang="en" label="English" default>
  <track kind="descriptions" src="descriptions-en.vtt" srclang="en" label="English audio descriptions">
</video>
```

### 5. Tables (Topic 5)

- Every **complex** data table MUST have a summary (5.1) — in the `<caption>` or a passage of text linked by
  `aria-describedby`, *not* the obsolete `summary` attribute — and that summary must be relevant (5.2).
  A table is "complex" when its headers are not confined to the first row and/or first column, or a header's
  scope is not valid for the whole row/column
- For each **layout** table, the linearised content must remain comprehensible **and** the `<table>` MUST
  carry `role="presentation"` — 5.3 requires both
- Where a data table has a title, it MUST be correctly associated — `<caption>`, `aria-label`, or `aria-labelledby` (5.4) — and the title must be relevant (5.5)
- Data tables MUST declare headers that span a whole column/row with `<th>` **or** `role="columnheader"`/
  `role="rowheader"` (5.6.1/5.6.2). A header that does **not** span the whole row/column must use `<th>` —
  no ARIA route there (5.6.3)
- Each cell MUST be associated with its headers: `scope` for simple tables, `headers`/`id` for complex ones (5.7).
  Use `scope="rowgroup"`/`scope="colgroup"` for header **groups** (5.7.6). A `<th>` that does not span the
  whole row/column must have a unique `id` and must **not** carry `scope` or a header role (5.7.3)
- Layout tables MUST NOT use `<th>`, `<caption>`, `<thead>`, `<tfoot>`, `role="rowheader"`/`"columnheader"`,
  a `summary` attribute, or `scope`/`headers`/`axis` on cells (5.8)

Note: 5.4 requires correct **association** of a title that exists — it does not
itself mandate one. In practice always give a data table a `<caption>`; just
don't cite 5.4 as the reason.

```html
<!-- GOOD: simple data table -->
<table>
  <caption>Q3 2024 Revenue by Region</caption>
  <thead>
    <tr>
      <th scope="col">Region</th>
      <th scope="col">Revenue</th>
      <th scope="col">Growth</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Europe</th>
      <td>€2.4M</td>
      <td>+12%</td>
    </tr>
  </tbody>
</table>
```

### 6. Links (Topic 6)

- Every link MUST have an accessible name (**6.2**), and that name must be explicit (6.1)
- Links with identical accessible names MUST lead to the same destination, or be distinguished by their
  context (6.1.6)
- The link's accessible name must be relevant and describe the destination or function (6.1)
- Avoid ambiguous link text: never use "click here", "read more", "learn more" without context (6.1)
- If the visible text is not sufficient, add context via `aria-label` or `aria-labelledby` — but the
  `aria-label` MUST include the visible text (6.1, test 6.1.5 — *Label in Name*)

```html
<!-- BAD -->
<a href="/report.pdf">Click here</a>

<!-- GOOD -->
<a href="/report.pdf">Download the Q3 2024 financial report (PDF, 2.4 MB)</a>

<!-- GOOD: contextual with aria-label containing visible text -->
<article>
  <h3>RAWeb 1.1 released</h3>
  <p>The new version adds 17 additional criteria...</p>
  <a href="/news/raweb" aria-label="Read more about RAWeb 1.1 released">Read more</a>
</article>
```

### 7. Scripts (Topic 7)

- Every script-driven UI MUST be compatible with assistive technologies — correct role, name, and value (7.1)
- Where a script has an alternative, that alternative MUST be relevant (7.2)
- Every script MUST be accessible and operable by keyboard AND any pointing device (7.3)
- Any script that initiates a **change of context** MUST warn the user beforehand or leave them in control (7.4)
- Status messages MUST be communicated without moving focus (7.5 — Level AA). RAWeb maps **message type to
  technique** — the wrong role for the type fails the test:

  | Message type | Use (7.5.1–7.5.3) |
  |---|---|
  | Success, result of an action, app state | `role="status"` **or** `aria-live="polite"` + `aria-atomic="true"` |
  | A suggestion, or warning of an error | `role="alert"` **or** `aria-live="assertive"` + `aria-atomic="true"` |
  | Progress of a process | `role="log"`, `role="progressbar"` or `role="status"` (or the matching `aria-live="polite"`) |

  Every `aria-live` branch requires **`aria-atomic="true"`** alongside it — bare `aria-live="polite"` fails
  7.5.1. `aria-relevant` is **not** a technique 7.5 recognises; it satisfies nothing here
- A script MUST NOT remove focus from an element that receives it (7.3.2)

Related criteria that live in other topics — do not cite them as Topic 7:
- Moving or blinking content must be controllable (pause, stop, hide) → **13.8**
- Sudden changes in brightness / flashing → **13.7**
- Keyboard traps → **12.9**

```html
<!-- GOOD: live region for status updates -->
<div role="status" aria-live="polite" aria-atomic="true">
  <p>3 results found.</p>
</div>

<!-- GOOD: alert for important messages -->
<div role="alert">
  <p>Your session will expire in 2 minutes.</p>
</div>
```

```javascript
// GOOD: keyboard + pointer support
button.addEventListener('click', handler);  // covers mouse + Enter/Space
button.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault();
    handler(e);
  }
});
```

### 8. Mandatory Elements (Topic 8)

- Every page MUST have a valid `<!DOCTYPE html>` (8.1)
- Every page MUST have a `lang` attribute on `<html>` (8.3); its code must be valid and relevant to the
  page's main language (8.4)
- Language changes in content MUST be marked with `lang` on the relevant element (8.7 — Level AA)
- Every page MUST have a unique and relevant `<title>` (8.5, 8.6)
- In an SPA, update the page `<title>` when the view changes — a title left at "Home" across views stops
  being relevant, which is what 8.6 tests (8.6 tests relevance; the update rule is the practical consequence)
- No duplicate `id` attributes in the page (8.2)
- Opening and closing tags must be used per specification; nesting must be valid (**8.2** — source-code
  validity. 8.1 is only the presence of a document type)
- Text whose reading direction differs from the page default must sit in a tag with a `dir` attribute
  (8.10), and that value must be a valid, relevant `rtl`/`ltr` (8.10.2)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Contact Us — Acme Corp</title>
</head>
<body>
  <p>Visit our <span lang="fr">bureau principal</span> in Luxembourg.</p>
</body>
</html>
```

### 9. Information Structure (Topic 9)

- Use headings (`<h1>`–`<h6>`, or `role="heading"` + `aria-level`) with a logical hierarchy (9.1.1). Each
  heading's text must be relevant (9.1.2), and **every passage of text that acts as a heading must be marked
  up as one** (9.1.3) — a styled `<div class="title">` fails 9.1.3 even when the hierarchy is clean
- Use the landmarks 9.2.1 actually requires: `<header>`→`banner`, `<nav>`→`navigation`,
  **`<search>`→`search`**, `<main>`→`main`, `<footer>`→`contentinfo`. (`<aside>`/`complementary` is fine to
  use but is **not** required by 9.2)
- Exactly **one visible** `main`, `banner` and `contentinfo` per page, and reserve `navigation` for primary
  and secondary navigation only (9.2.2)
- A `<header>`/`<footer>` without an explicit role must **not** be nested inside `article`, `complementary`,
  `main`, `navigation` or `section` (9.2.3/9.2.4) — a `<header>` inside `<main>` fails
- Use lists (`<ul>`, `<ol>`, `<dl>`) for list content (9.3)
- Use `<q>` for short inline quotations (9.4.1) and `<blockquote>` for quotation blocks (9.4.2). `cite` is
  good practice — 9.4 does not test it

```html
<body>
  <header role="banner">
    <nav aria-label="Main navigation">...</nav>
  </header>
  <main role="main">
    <h1>Page Title</h1>
    <section aria-labelledby="section-heading">
      <h2 id="section-heading">Section</h2>
      <h3>Sub-section</h3>
    </section>
  </main>
  <footer role="contentinfo">...</footer>
</body>
```

### 10. Presentation of Information (Topic 10)

- Content must remain readable and functional at 200% zoom (10.4 — Level AA)
- Content must reflow at 320px CSS width without horizontal scrolling — and, for vertically-read content, at
  256px height without vertical scrolling (10.11 — Level AA)
- Use CSS for all visual presentation. 10.1 forbids an enumerated set — `<font>`, `<center>`, `<big>`,
  `<blink>`, `<marquee>`, `<s>`, `<strike>`, `<tt>` and attributes like `align`, `bgcolor`, `border`,
  `cellpadding`, `hspace`, `valign`, `vspace`. **`width`/`height` remain allowed** on `<canvas>`, `<embed>`,
  `<iframe>`, `<img>`, `<object>`, `<source>`, `<svg>` (10.1.2) — keep them on images to prevent layout shift
- Never use spaces to separate letters in a word, or to simulate tables or columns (10.1.3)
- Visible content that conveys information must be reachable by AT — a CSS background image carrying meaning
  needs a text alternative on the page (10.2). Separately, the **reading order** must stay understandable
  with CSS disabled (10.3)
- Visible focus indicator on all interactive elements, with a **contrast ratio ≥ 3:1** (10.7)
- Do not hide content in a way that becomes unreachable (10.8)
- Text spacing: users must be able to override line-height (1.5×), paragraph spacing (2×), letter-spacing (0.12em), word-spacing (0.16em) without loss of content (10.12 — Level AA)

```css
/* GOOD: visible focus indicator */
:focus-visible {
  outline: 3px solid #0056b3;
  outline-offset: 2px;
}

/* GOOD: ensure reflow support */
.container {
  max-width: 100%;
  overflow-wrap: break-word;
}

/* NEVER: hide focus outline globally */
/* *:focus { outline: none; } ← FORBIDDEN */
```

### 11. Forms (Topic 11)

**This is a critical topic. Always look up criteria with `bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topic 11` when implementing forms.**

- Every form field MUST have a programmatically associated label (11.1). Always give it a **visible** one
  too — that is 11.4 (label next to its field) plus good practice; 11.1 itself also accepts `aria-label`
  or `title` with nothing visible
- Label association: `<label for="id">`, `aria-labelledby`, `aria-label`, or `title` (11.1)
- The `<label>` element with `for` attribute is the preferred method (11.1)
- The accessible name MUST include the visible label text (11.2)
- Labels must be relevant — clearly describe the expected input (11.2)
- Labels for fields with the same function MUST stay consistent across the set of pages (11.3 — Level AA)
- The label MUST sit next to its field (11.4): immediately **above or left** for normal fields (LTR), and
  immediately **below or right** for `checkbox`, `radio`, and `role="switch"`
- Related fields MUST be grouped — `<fieldset>`, `role="group"`, or `role="radiogroup"` for radios (11.5)
- Every group MUST have a legend (11.6): `<legend>` in a `<fieldset>`, or `aria-label`/`aria-labelledby`
  on a `role="group"`/`role="radiogroup"`. The legend must be relevant (11.7)
- Group `<select>` options of the same type with `<optgroup>`, each with a relevant `label` (11.8)
- Button labels MUST be relevant, and the accessible name MUST contain at least the visible label (11.9)
- Required fields must be indicated before the form or at the field level (11.10)
- Use `required` and/or `aria-required="true"` for mandatory fields (11.10) — **and keep a visible
  indication**: the attribute alone passes 11.10.1 but fails 11.10.2, which applies specifically to fields
  carrying `required`/`aria-required` and demands a visible indication in the label, an associated passage
  of text, or the legend
- Error messages MUST identify the field by name and be linked to it via `aria-invalid="true"`
  (11.10 — **Level A**)
- Error messages MUST also suggest the expected data type/format and examples of valid values
  (11.11 — Level AA)
- Forms that modify or delete data, submit exam answers, or carry financial/legal consequences MUST be
  reversible, checkable before submit, or explicitly confirmed (11.12 — Level AA)
- Input purpose for personal data must use `autocomplete` with appropriate values (11.13 — Level AA)

Note: **error *identification* is 11.10 (Level A); 11.11 is *only* error *suggestion* (AA).** Linking a
message to its field is 11.10, not 11.11 — filing it under 11.11 downgrades a Level A requirement.
`<legend>` is **11.6**, not 11.5 — 11.5 is the grouping alone.

```html
<form novalidate>
  <fieldset>
    <legend>Personal information</legend>

    <div>
      <label for="fname">First name <span aria-hidden="true">*</span></label>
      <input type="text" id="fname" name="fname"
             autocomplete="given-name"
             required aria-required="true"
             aria-describedby="fname-error">
      <p id="fname-error" role="alert" class="error" hidden>
        Please enter your first name.
      </p>
    </div>

    <div>
      <label for="email">Email address <span aria-hidden="true">*</span></label>
      <input type="email" id="email" name="email"
             autocomplete="email"
             required aria-required="true"
             aria-describedby="email-hint email-error">
      <p id="email-hint" class="hint">Format: name@example.com</p>
      <p id="email-error" role="alert" class="error" hidden>
        Please enter a valid email address (e.g., name@example.com).
      </p>
    </div>
  </fieldset>

  <button type="submit">Submit</button>
</form>
```

### 12. Navigation (Topic 12)

- At least two navigation mechanisms among: main nav, sitemap, search engine (12.1 — Level AA)
- Repeated content blocks must be reachable or avoidable (**12.6**) — a landmark role, a heading, a hide
  button, or a skip link all satisfy it
- A skip link to the **main content region** must be present and functional (12.7)
- Skip links must be visible on focus (12.7)
- Tab order must be logical and consistent (12.8), and must **stay** consistent after a script inserts or
  updates content — reposition focus correctly (12.8.2)
- Avoid positive `tabindex` values — they almost always break the coherent order 12.8.1 requires. (12.8
  tests the *order*, not the attribute; RAWeb notes the sequence need not follow natural reading order as
  long as it stays coherent.)
- Navigation MUST NOT contain keyboard traps (12.9) — a modal's Tab loop is legal *only* because Escape and a close button let the user out
- Single-key shortcuts must be remappable or disableable (12.10)
- Content appearing on hover or focus (tooltips, popovers) must be keyboard accessible (12.11 — Level AA)
- Menus and navigation bars must stay in the **same place in the presentation** and the **same relative
  order in the source** across the set of pages (12.2 — Level AA)
- Indicating the active page (e.g. `aria-current="page"`) is **good practice, not a RAWeb criterion** — 12.2
  only tests consistent placement. Do it, but don't cite 12.2 for it

```html
<body>
  <!-- Skip link: first focusable element -->
  <a href="#main-content" class="skip-link">Skip to main content</a>

  <nav aria-label="Main navigation">
    <ul>
      <li><a href="/" aria-current="page">Home</a></li>
      <li><a href="/about">About</a></li>
      <li><a href="/contact">Contact</a></li>
    </ul>
  </nav>

  <main id="main-content" tabindex="-1">
    <!-- Page content -->
  </main>
</body>
```

```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 1000;
  padding: 0.5rem 1rem;
  background: #000;
  color: #fff;
}
.skip-link:focus {
  top: 0;
}
```

### 13. Consultation (Topic 13)

- The user must have control over every time limit that modifies content — adjustable, extendable, or removable (13.1)
- A `<meta http-equiv="refresh">` redirect admits no user control: it must be **immediate** (`content="0"`)
  or at least **twenty hours** (`content` ≥ 72000) (13.1.2)
- A new window MUST NOT open without a user action (13.2)
- Every downloadable office document must have an accessible version (13.3), and that version must offer the same information (13.4)
- Sudden changes in brightness or flashing must be used correctly — no more than 3 flashes per second, **or**
  a cumulative effect area ≤ 21824 px² (13.7). Applies to media, scripted effects, and CSS animation alike
- Moving or blinking content must be controllable by the user: stop/restart, show/hide, or offer the same
  information without the movement (13.8). Exempt if it lasts **≤ 5 seconds**. Pausing **on focus only does
  not count**; content that cannot be stopped (a progress bar) is NA
- Content must be viewable in any screen orientation (13.9 — Level AA)
- Any feature using a complex gesture must also be usable with a simple gesture (13.10) — this covers
  **multi-touch** (13.10.1) *and* **path-based** gestures (13.10.2). A drag with no single-point
  alternative — a slider that only drags, a splitter with no reset — fails 13.10.2. Widely missed, because
  13.10 reads as though it were only about pinch
- Single-point actions must be cancellable (13.11): trigger on **release**, or on press-then-cancel-on-
  release, or provide an abort/undo mechanism
- Motion-actuated features must work via UI components instead (13.12), and the user must be able to
  **disable motion detection** entirely (13.12.3)
- Biometric identification or control (fingerprint, face, voice) MUST have an alternative — non-biometric,
  or a sufficiently *different* biological characteristic (13.14). EN 301 549 §5.3, **Level A**, no WCAG
  equivalent
- Document conversion features must preserve accessibility information (13.13 — Level AA, EN 301 549 §5.4)

Note: indicating a link's file format and size is **good practice, not a RAWeb
criterion** — do it, but do not cite 13.3 for it. Warning the user before a
context change is **7.4**, not 13.1.

```html
<!-- GOOD: file download with format and size -->
<a href="/report.pdf">
  Annual report 2024 <span class="file-info">(PDF, 3.2 MB)</span>
</a>

<!-- GOOD: new window warning -->
<a href="https://external.example.com" target="_blank"
   rel="noopener noreferrer">
  External resource
  <span class="sr-only">(opens in a new window)</span>
</a>
```

---

## Component patterns (WAI-ARIA APG)

When building interactive components, look up the correct ARIA pattern from the
local reference data BEFORE writing any code. The component library contains 30
patterns extracted from the [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/patterns/)
with keyboard interactions, required/optional ARIA attributes, and implementation notes.

### How to use

```bash
# Find the right pattern by keyword (e.g., "modal", "dropdown", "toggle")
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh find "<keyword>"

# Show the pattern contract as markdown tables:
# RAWeb criteria + keyboard interaction + ARIA roles/attributes/states
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh show <slug>

# Show working code examples (do + don't) for one framework
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh code <slug> [vanilla|react|angular|web-component]

# List all 30 available patterns
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh list

# Find patterns that use a specific ARIA role
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh roles "<role>"
```

### Workflow

1. **Identify** the component the developer is building (dialog, tabs, slider, etc.)
2. **Search** using `find` with the most natural keyword the developer used
3. **Load the contract** with `show <slug>` — the RAWeb criteria that apply, the
   keyboard interaction, and every ARIA attribute with its allowed values/states
4. **Load the code** with `code <slug>` — read the whole pattern file the first
   time; use `code <slug> <framework>` when you already know the universal rules
5. **Apply** the pattern, preferring native HTML elements over ARIA roles
6. **Cross-reference** anything the pattern doesn't cover against the criteria —
   especially Topics 7 (Scripts), 11 (Forms), and 12 (Navigation)

If a pattern has no code examples yet, `code` tells you so and lists what does.
Fall back to `show <slug>` — the contract is complete for all 30 patterns.

### Where the data lives

| Path | Holds | Status |
|---|---|---|
| `references/components/<slug>.json` | **Source of truth**: ARIA roles/attributes/values, keyboard interaction, RAWeb criteria mapping | All 30 patterns |
| `references/patterns/<slug>.md` | Code examples: vanilla, React, Angular, Web Component, each with dos **and** don'ts | Growing — see `code` output |
| `references/patterns/_TEMPLATE.md` | Authoring contract for adding a new pattern file | — |

Criterion **levels and official titles are resolved at render time** from
`niveaux.json` and `criteres.json`, so a pattern can never quote a stale level.
Never retype an ARIA table into a `.md` — add it to the JSON and let `show`
render it.

### Quick mapping: common requests → pattern slugs

| When the developer says... | Look up slug |
|---------------------------|-------------|
| modal, dialog, popup, overlay, lightbox | `dialog-modal` |
| tabs, tab panel, tabbed interface | `tabs` |
| accordion, collapsible, FAQ | `accordion` |
| dropdown menu, context menu, submenu | `menubar` or `menu-button` |
| toast, notification, flash message | `alert` |
| confirm dialog, delete confirmation | `alertdialog` |
| carousel, slideshow, image gallery | `carousel` |
| autocomplete, typeahead, combobox | `combobox` |
| select, dropdown list, listbox | `listbox` |
| breadcrumb, navigation trail | `breadcrumb` |
| tooltip, hint, hover text | `tooltip` |
| toggle, switch, on/off | `switch` |
| slider, range, volume control | `slider` or `slider-multithumb` |
| tree, file browser, nested list | `treeview` |
| data grid, spreadsheet, editable table | `grid` |
| static table, data table | `table` |
| toolbar, action bar, button group | `toolbar` |
| radio buttons, option group | `radio` |
| checkbox, check all | `checkbox` |
| show/hide, details, read more | `disclosure` |
| spinner, number input, stepper | `spinbutton` |
| meter, gauge, battery level | `meter` |
| feed, infinite scroll, timeline | `feed` |
| page structure, landmarks | `landmarks` |
| split view, resizable panes | `windowsplitter` |

---

## Screen-reader-only utility class

Always include and use this utility in your CSS:

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

---

## Pre-commit checklist (apply before finalizing any code)

Before considering any code complete, verify:

- [ ] All images have appropriate `alt` (informative) or `alt=""` (decorative)
- [ ] All form fields have associated labels
- [ ] Colour is never the sole means of conveying information
- [ ] All interactive elements are keyboard accessible
- [ ] Focus order is logical and follows visual order
- [ ] Focus indicator is visible on all interactive elements
- [ ] Page has valid `lang` attribute and language changes are marked
- [ ] Page has a unique, descriptive `<title>`
- [ ] Headings follow a logical hierarchy (no skipped levels)
- [ ] Semantic HTML elements are used (`<nav>`, `<main>`, `<header>`, `<footer>`)
- [ ] ARIA attributes are used correctly (prefer native HTML semantics first)
- [ ] Dynamic content changes are announced to assistive technologies
- [ ] No auto-playing media or animation without user control
- [ ] Links opening new windows are indicated

---

## When in doubt

1. **Look up the RAWeb criterion**: `bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh criterion <topic.criterion>`
2. **Check the test methodology**: `bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh methodology <topic.criterion.test>`
3. **Look up the ARIA pattern** for a component: `bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh find "<keyword>"`, then `show <slug>` for the contract and `code <slug>` for worked examples
4. **Consult the glossary** for precise definitions: `bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh glossary "<term>"`
5. Default to the most accessible approach — when two implementations are possible, choose the one with better assistive technology support
6. Prefer native HTML semantics over ARIA: a `<button>` is better than `<div role="button">`
7. When building an interactive widget, ALWAYS load the APG pattern first — do not guess ARIA attributes from memory
8. **Never cite a criterion number from memory.** RAWeb numbering is not WCAG
   numbering: RAWeb 7.3 is keyboard operability, WCAG 2.1.1 is. Verify with
   `criterion <x.y>` before writing a number into code, a comment, or a report
