# RAWeb 1.1 — Code examples by topic

Companion to the *Core rules* in `SKILL.md`: the rules and their criterion numbers
live there; this file only shows them applied. Headings match the SKILL.md topics.

## 1. Images (Topic 1)

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

## 2. Frames (Topic 2)

```html
<iframe src="map.html" title="Interactive map of our office locations"></iframe>
```

## 3. Colours (Topic 3)

```html
<!-- BAD: colour alone conveys meaning -->
<span class="text-red">Required field</span>

<!-- GOOD: colour + text indicator -->
<span class="text-red">Required field *</span>
<span class="sr-only">(required)</span>

<!-- Or better with native HTML -->
<input type="text" required aria-required="true">
```

## 4. Multimedia (Topic 4)

```html
<video controls>
  <source src="presentation.mp4" type="video/mp4">
  <track kind="captions" src="captions-en.vtt" srclang="en" label="English" default>
  <track kind="descriptions" src="descriptions-en.vtt" srclang="en" label="English audio descriptions">
</video>
```

## 5. Tables (Topic 5)

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

## 6. Links (Topic 6)

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

## 7. Scripts (Topic 7)

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

## 8. Mandatory Elements (Topic 8)

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

## 9. Information Structure (Topic 9)

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

## 10. Presentation of Information (Topic 10)

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

## 11. Forms (Topic 11)

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

## 12. Navigation (Topic 12)

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

## 13. Consultation (Topic 13)

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
