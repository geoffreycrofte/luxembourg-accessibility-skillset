# Alert / Live Regions — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show alert`

> **This is the pattern RAWeb 7.5 exists for** — "are status messages correctly
> rendered by assistive technologies?" It is the only Level AA criterion in
> Topic 7. Verify it: `scripts/raweb-lookup.sh criterion 7.5`.

---

## Universal rules

- **The region must exist, empty, *before* the message arrives.** This is the
  rule that decides whether any of this works. A screen reader watches live
  regions it already knows about; inject `<div role="alert">Saved</div>` in one
  go and it frequently announces **nothing**. Render the empty container on page
  load, then write text into it. (RAWeb 7.5)
- **Default to `role="status"`, not `role="alert"`.** `status` is polite: it
  waits for a pause. `alert` is assertive: it **interrupts whatever the user is
  currently hearing**, mid-word. Reserve it for genuine urgency — a failed
  payment, a session expiring. A "Copied to clipboard" toast that interrupts is
  hostile.
- **Announcements happen without moving focus.** That's the whole point — the
  user stays where they are. If you also move focus to the message, it gets
  announced twice.
- **Text only. Nothing interactive.** An "Undo" button inside a live region is
  announced but effectively unreachable: focus is elsewhere, and the toast
  disappears before the user can Tab to it.
- **Never `role="alert"` on something present at page load.** It fires on every
  load, announcing stale content for no reason.
- **Auto-dismiss is a time limit.** (RAWeb 13.1) A toast that vanishes after 4
  seconds gives a screen reader user — who may still be hearing the previous
  sentence — no chance. Don't auto-dismiss, or make it adjustable, and never put
  the only copy of important information in one.
- **Colour alone is not an error.** (RAWeb 3.1) Red text is not a message.

### Which role?

| Situation | Role | Politeness |
|---|---|---|
| Search returned 3 results | `status` | polite |
| Form saved | `status` | polite |
| Copied to clipboard | `status` | polite |
| Session expires in 2 minutes | `alert` | assertive |
| Payment failed | `alert` | assertive |
| Chat message arrived | `log` | polite, order matters |
| Progress / loading | `status` | polite |

**If unsure, use `status`.** Assertive is almost never the right answer.

---

## Vanilla

### Do

```html
<!-- Rendered EMPTY at page load. The screen reader registers the region now, so
     that later text changes are announced. This is non-negotiable (RAWeb 7.5). -->
<div id="form-status" role="status" class="sr-only"></div>

<!-- A visible, non-live message area. No role here: the live region above does
     the announcing, this one does the showing. -->
<div id="form-message" class="message" hidden></div>
```

```js
const liveRegion = document.getElementById('form-status');
const visibleMessage = document.getElementById('form-message');

function announce(message) {
  // Clear first. If the new text is identical to the old, some screen readers
  // detect no mutation and stay silent. The empty tick guarantees a change.
  liveRegion.textContent = '';
  requestAnimationFrame(() => {
    liveRegion.textContent = message;
  });
}

function showMessage(message, tone = 'info') {
  visibleMessage.textContent = message;
  visibleMessage.dataset.tone = tone;
  visibleMessage.hidden = false;
  announce(message);
}

showMessage('Your profile was saved.', 'success');
```

### Do — urgent, interrupting

```html
<!-- role="alert" is implicitly aria-live="assertive" + aria-atomic="true".
     Do not add those attributes as well — the role already carries them. -->
<div id="session-alert" role="alert" hidden></div>
```

```js
const sessionAlert = document.getElementById('session-alert');

// Genuinely urgent: worth interrupting for (RAWeb 7.5).
function warnSessionExpiring(minutes) {
  sessionAlert.hidden = false;
  sessionAlert.textContent = `Your session expires in ${minutes} minutes.`;
}
```

### Do — a visible error that is not colour-only

```html
<div class="message" data-tone="error">
  <!-- Icon + text, not just red (RAWeb 3.1). -->
  <svg aria-hidden="true" focusable="false" width="16" height="16"><use href="#icon-error"/></svg>
  <strong>Error:</strong> Your payment could not be processed.
</div>
```

```css
.message[data-tone="error"] {
  border-inline-start: 4px solid #b3261e; /* shape, not just hue */
  background: #fdeded;
  color: #5f1412;   /* verify ≥4.5:1 against #fdeded (RAWeb 3.2) */
}

/* Forced colors strips background/border colours — keep a non-colour signal. */
@media (forced-colors: active) {
  .message { border: 1px solid CanvasText; }
}
```

### Don't

```js
// DON'T: create the region and its text together. THE live-region bug.
//     → The screen reader was not watching this node — it did not exist. Very
//       often announces NOTHING. Works in your manual test maybe 50% of the
//       time, which is why it ships.
const toast = document.createElement('div');
toast.setAttribute('role', 'alert');
toast.textContent = 'Saved!';
document.body.append(toast);

// DON'T: write the same text twice and expect two announcements.
//     → No mutation is detected the second time. "No results" then "No results"
//       announces once. Clear the region first.
liveRegion.textContent = 'No results.';
liveRegion.textContent = 'No results.'; // silent

// DON'T: assertive for routine feedback.
//     → Interrupts the user mid-sentence to say "Copied". Rude, and it destroys
//       their place in the content. Use role="status".
copyStatus.setAttribute('aria-live', 'assertive');
copyStatus.textContent = 'Copied to clipboard';

// DON'T: announce AND move focus.
//     → Announced twice: once by the live region, once when focus lands.
//       Pick one. For form errors, moving focus is usually better.
errorRegion.textContent = 'Email is invalid.';
errorInput.focus();
```

```html
<!-- DON'T: role="alert" on a container populated at page load.
     → Announced on every single page load. Users learn to ignore it. -->
<div role="alert" class="banner">Welcome back!</div>

<!-- DON'T: interactive content in a live region.
     → "Undo" is announced but unreachable: focus is elsewhere, and the toast
       is gone in 4 seconds. If the user needs to act, use a dialog. -->
<div role="alert">
  Message deleted. <button type="button">Undo</button>
</div>

<!-- DON'T: aria-live AND a role that already implies it.
     → Redundant, and conflicting values are resolved unpredictably.
       role="alert" is already assertive. -->
<div role="alert" aria-live="polite">…</div>

<!-- DON'T: a live region on a whole page area.
     → Every DOM change inside announces. A live region on a results container
       reads the entire list on every keystroke. Keep them small and dedicated. -->
<main aria-live="polite">…</main>

<!-- DON'T: error by colour alone (RAWeb 3.1).
     → Nothing distinguishes this from any other text for a user who cannot
       perceive the red. And nothing at all is announced. -->
<span style="color: red">Invalid email</span>
```

---

## React

### Do

```jsx
import { useEffect, useRef, useState } from 'react';

// The region is ALWAYS mounted; only its text changes. Conditionally rendering
// the region itself is the number-one React live-region bug.
export function LiveRegion({ message, urgent = false }) {
  return (
    <div
      role={urgent ? 'alert' : 'status'}
      className="sr-only"
    >
      {message}
    </div>
  );
}
```

```jsx
export function SaveForm() {
  const [status, setStatus] = useState('');

  const onSubmit = async (event) => {
    event.preventDefault();
    setStatus('');            // clear, so an identical message re-announces
    await save();
    setStatus('Your profile was saved.');
  };

  return (
    <form onSubmit={onSubmit}>
      {/* … fields … */}
      <button type="submit">Save</button>
      {/* Always rendered, empty when idle. */}
      <LiveRegion message={status} />
    </form>
  );
}
```

A re-announce helper, when the same message can repeat:

```jsx
export function useAnnouncer() {
  const [message, setMessage] = useState('');

  const announce = (text) => {
    setMessage('');
    // Next frame, so React commits the empty string first and the DOM really
    // mutates. Setting the same string twice in one tick announces nothing.
    requestAnimationFrame(() => setMessage(text));
  };

  return { message, announce };
}
```

### Don't

```jsx
// DON'T: conditionally render the live region.
//     → The region and its text appear in the same commit. The screen reader
//       never registered the region, so it announces nothing. Keep it mounted
//       and change only the text.
{status && <div role="status">{status}</div>}

// DON'T: a toast library that mounts each toast as a new role="alert" node.
//     → Same failure, one layer down. Check that your toast library renders a
//       persistent live region container. Many do not.

// DON'T: role="alert" for every toast.
//     → Every "Saved" interrupts the user. Route urgency: status by default.
<Toast role="alert">{message}</Toast>

// DON'T: key the region to force a remount.
//     → Remounting recreates the node — the exact thing that breaks the
//       announcement.
<div key={message} role="status">{message}</div>
```

---

## Angular

### Do

```ts
import { Component, computed, input, signal } from '@angular/core';

@Component({
  selector: 'app-live-region',
  template: `
    <!-- Always present. Only the interpolated text changes. -->
    <div [attr.role]="urgent() ? 'alert' : 'status'" class="sr-only">
      {{ message() }}
    </div>
  `,
})
export class LiveRegionComponent {
  readonly message = input<string>('');
  readonly urgent = input<boolean>(false);
}
```

**Or use the CDK.** `@angular/cdk/a11y` ships `LiveAnnouncer`, which maintains a
single persistent live region for the whole app and handles the clear-then-write
dance. It is the right default:

```ts
import { LiveAnnouncer } from '@angular/cdk/a11y';

private readonly announcer = inject(LiveAnnouncer);

save(): void {
  this.announcer.announce('Your profile was saved.', 'polite');
}
```

### Don't

```html
<!-- DON'T: @if around the live region.
     → The region is created together with its text; nothing is announced. -->
@if (status()) {
  <div role="status">{{ status() }}</div>
}

<!-- DON'T: role="alert" on a banner rendered at bootstrap.
     → Announced on every navigation. -->
<div role="alert">{{ welcomeMessage }}</div>
```

---

## Web Component

### Do

```js
// The live region lives in the LIGHT DOM. Screen readers' live-region support
// inside shadow roots has been historically inconsistent, and this pattern's
// entire value is the announcement — it is not worth the risk. This component
// owns one persistent region for the whole page.
class A11yAnnouncer extends HTMLElement {
  #polite;
  #assertive;

  connectedCallback() {
    if (this.#polite) return;

    // Both regions created EMPTY, now, at page load — before any message.
    this.#polite = document.createElement('div');
    this.#polite.setAttribute('role', 'status');
    this.#assertive = document.createElement('div');
    this.#assertive.setAttribute('role', 'alert');

    for (const region of [this.#polite, this.#assertive]) {
      region.className = 'sr-only';
      this.append(region);
    }
  }

  announce(message, { urgent = false } = {}) {
    const region = urgent ? this.#assertive : this.#polite;
    region.textContent = '';
    requestAnimationFrame(() => { region.textContent = message; });
  }
}

customElements.define('a11y-announcer', A11yAnnouncer);
```

```html
<!-- Once, near the top of <body>. -->
<a11y-announcer id="announcer"></a11y-announcer>

<script>
  document.getElementById('announcer').announce('Your profile was saved.');
</script>
```

### Don't

```js
// DON'T: put the live region in a shadow root.
//     → Live-region support across the shadow boundary has been unreliable in
//       several screen readers. The one thing this component exists to do is
//       announce; do not gamble it on shadow DOM. Keep it in the light DOM.
this.attachShadow({ mode: 'open' }).innerHTML = `<div role="status"></div>`;

// DON'T: one announcer element per message.
//     → Every message creates a new region that was never registered. Nothing
//       announces. One persistent announcer, many messages.
```

---

## Verify

- **This pattern can only be verified with a screen reader.** There is no visual
  signal and no automated check. If you have not heard it announce, you do not
  know that it works.
- **The registration check:** trigger the message. If nothing is announced, your
  region was created at the same moment as its text. Confirm the empty container
  is in the DOM on page load, before anything happens.
- **The repeat check:** trigger the *same* message twice. If it announces only
  once, you are not clearing the region first.
- **The politeness check:** trigger a routine message while the screen reader is
  reading a paragraph. It must **wait**. If it interrupts, you used `alert` where
  `status` belongs.
- **Automated:** axe catches conflicting `aria-live` values and a live region on
  a hidden element. It catches **none** of the real bugs — not the registration
  problem, not the repeat problem, not misused assertiveness. Live regions are
  the least automatable pattern in this whole set.
