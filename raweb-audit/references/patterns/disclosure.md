# Disclosure (Show/Hide) — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show disclosure`

**Read this whole file** when building a show/hide. Use
`code disclosure <framework>` only when you already know the universal rules and
just want the snippet.

> This is the foundation pattern. [`accordion`](accordion.md) is a group of
> disclosures with heading structure; a [`menu-button`](menu-button.md) looks
> identical but is **not** this pattern — see "Not this pattern" below.

---

## Universal rules

- **`<details>`/`<summary>` does all of this with zero JS.** Button semantics,
  `aria-expanded`, Enter/Space, and show/hide come free. Reach for the ARIA
  version only when you need to animate the open/close or control it from
  elsewhere. (RAWeb 7.1, 7.3)
- **`aria-expanded` goes on the button, never on the panel.** It describes what
  the *control* does. On the panel it is meaningless and the button is announced
  with no state at all. This is the most common disclosure bug. (RAWeb 7.1)
- **Use a real `<button>`.** Enter and Space then work with no keydown handler.
  (RAWeb 7.3)
- **Hide the panel with `hidden` or `display: none`.** `opacity: 0`,
  `visibility: hidden` + `height: 0`, or off-screen positioning all leave the
  content **in the accessibility tree and in the tab order** — a keyboard user
  tabs into links they cannot see. (RAWeb 10.8)
- **Don't toggle the name *and* the state.** A button labelled "Show" that also
  carries `aria-expanded="false"` is announced "Show, collapsed"; after clicking,
  "Hide, expanded" — which reads as though it is hiding something already hidden.
  Keep the name stable ("Shipping options") and let `aria-expanded` carry state.
- **A visual chevron conveys nothing to assistive tech.** Rotating an icon is
  presentation; `aria-expanded` is the state. You need both. (RAWeb 7.1, 3.1)

### Not this pattern

| If the panel contains… | Use |
|---|---|
| Arbitrary content — text, a form, a paragraph | **disclosure** (this file) |
| A list of *actions* (Edit, Duplicate, Delete) | [`menu-button`](menu-button.md) — different roles, arrow-key navigation |
| A list of *choices* that sets a value | [`combobox`](combobox.md) / [`listbox`](listbox.md) |
| Several sections, one heading each | [`accordion`](accordion.md) |

Picking `menu-button` semantics for a plain show/hide forces arrow-key
navigation on content that isn't a menu, and screen readers announce a menu that
isn't there.

---

## Vanilla

### Do — the zero-JS version

```html
<!-- Prefer this. The browser provides button semantics, aria-expanded,
     Enter/Space, and the toggling. Nothing to get wrong. -->
<details>
  <summary>What is RAWeb?</summary>
  <p>RAWeb is Luxembourg's web accessibility framework, based on EN 301 549.</p>
</details>
```

```css
/* <summary> is focusable by default — just make the ring visible (RAWeb 10.7). */
summary:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

### Do — the ARIA version, when you need control

```html
<button type="button" id="faq-1-button" aria-expanded="false" aria-controls="faq-1-panel">
  <svg class="disclosure__chevron" aria-hidden="true" focusable="false" width="12" height="12">
    <use href="#icon-chevron"/>
  </svg>
  What is RAWeb?
</button>

<!-- Always in the DOM, toggled with `hidden`. It must exist for aria-controls
     to resolve, and `hidden` removes it from BOTH the a11y tree and the tab
     order (RAWeb 10.8). -->
<div id="faq-1-panel" hidden>
  <p>RAWeb is Luxembourg's web accessibility framework, based on EN 301 549.</p>
</div>
```

```css
/* State-driven styling: the attribute IS the source of truth, so the visual and
   the announced state cannot drift apart. Don't mirror state into a CSS class. */
.disclosure__chevron {
  transition: transform 150ms ease;
}
[aria-expanded="true"] .disclosure__chevron {
  transform: rotate(90deg);
}

@media (prefers-reduced-motion: reduce) {
  .disclosure__chevron { transition: none; }
}

button:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

```js
const button = document.getElementById('faq-1-button');
const panel = document.getElementById('faq-1-panel');

// No keydown handler: a native <button> already fires click on Enter and Space.
button.addEventListener('click', () => {
  const isExpanded = button.getAttribute('aria-expanded') === 'true';
  button.setAttribute('aria-expanded', String(!isExpanded));
  panel.hidden = isExpanded;
});
```

### Don't

```html
<!-- DON'T: aria-expanded on the panel.
     → The button is announced with no state; the user never learns it toggles
       anything. aria-expanded describes the CONTROL. -->
<button type="button">What is RAWeb?</button>
<div id="panel" aria-expanded="false">…</div>

<!-- DON'T: a div with a click handler.
     → Not focusable, not announced as a button, Enter/Space do nothing. -->
<div class="faq-toggle" onclick="toggle()">What is RAWeb?</div>

<!-- DON'T: chevron only, no aria-expanded.
     → Sighted users see the state; screen reader users get "button" and no
       indication it expands. -->
<button type="button"><svg class="chevron"></svg> What is RAWeb?</button>

<!-- DON'T: aria-hidden on a panel that is still in the tab order.
     → Keyboard focus lands inside content the screen reader insists is absent.
       This is axe's `aria-hidden-focus`. Use `hidden`. -->
<div id="panel" aria-hidden="true">
  <a href="/raweb">Read more</a>
</div>

<!-- DON'T: toggle the name AND the state.
     → Announced "Hide, expanded" / "Show, collapsed" — the name and the state
       say the same thing twice, in opposite directions. -->
<button type="button" aria-expanded="true">Hide details</button>
```

```css
/* DON'T: hide the panel visually only.
   → It stays in the accessibility tree and the tab order. A keyboard user tabs
     into links floating in invisible space (RAWeb 10.8). */
.panel[data-collapsed] {
  opacity: 0;
  height: 0;
  overflow: hidden;
}

/* DON'T: this either — same failure, popular because it animates. If you must
   animate height, keep `hidden` (or `content-visibility`) and drive the
   animation from it; never rely on size alone to hide content. */
.panel[data-collapsed] {
  visibility: hidden;
  max-height: 0;
}
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

export function Disclosure({ label, children }) {
  const [isExpanded, setIsExpanded] = useState(false);
  const panelId = useId();

  return (
    <>
      <button
        type="button"
        aria-expanded={isExpanded}
        aria-controls={panelId}
        onClick={() => setIsExpanded((value) => !value)}
      >
        {label}
      </button>

      {/* Always rendered, toggled with `hidden`. Conditional rendering would
          leave aria-controls pointing at an id that does not exist while
          collapsed — a dangling reference. */}
      <div id={panelId} hidden={!isExpanded}>
        {children}
      </div>
    </>
  );
}
```

React renders `aria-expanded={isExpanded}` as the string `"true"`/`"false"`,
which is what ARIA wants — booleans are handled correctly for `aria-*`. That is
**not** true of arbitrary attributes, so don't generalise the habit.

### Don't

```jsx
// DON'T: conditional render while using aria-controls.
//     → While collapsed, aria-controls references an id with no element behind
//       it. Either always render with `hidden`, or drop aria-controls entirely.
<button aria-expanded={isOpen} aria-controls={panelId}>{label}</button>
{isOpen && <div id={panelId}>{children}</div>}

// DON'T: hardcoded id in a reusable component.
//     → Two disclosures on one page = duplicate ids (RAWeb 8.2). Use useId().
<div id="panel">{children}</div>

// DON'T: state in a class instead of on the attribute.
//     → The CSS and the announced state are now two sources of truth, and they
//       drift. Style from [aria-expanded="true"] instead.
<button className={isOpen ? 'is-open' : ''} onClick={toggle}>{label}</button>
```

---

## Angular

### Do

```ts
import { Component, input, signal } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-disclosure',
  template: `
    <button
      type="button"
      [attr.aria-expanded]="isExpanded()"
      [attr.aria-controls]="panelId"
      (click)="toggle()"
    >
      {{ label() }}
    </button>

    <!-- [hidden] keeps the element in the DOM so aria-controls resolves, while
         removing it from the a11y tree and the tab order. @if would destroy it. -->
    <div [id]="panelId" [hidden]="!isExpanded()">
      <ng-content />
    </div>
  `,
})
export class DisclosureComponent {
  readonly label = input.required<string>();
  protected readonly isExpanded = signal(false);
  protected readonly panelId = `disclosure-panel-${uid++}`;

  protected toggle(): void {
    this.isExpanded.update((value) => !value);
  }
}
```

### Don't

```html
<!-- DON'T: [attr.aria-expanded] on the panel instead of the button. -->
<button type="button" (click)="toggle()">{{ label() }}</button>
<div [attr.aria-expanded]="isExpanded()">…</div>

<!-- DON'T: @if with aria-controls — same dangling reference as React.
     → While collapsed the id does not exist in the DOM. -->
<button [attr.aria-controls]="panelId" [attr.aria-expanded]="isExpanded()">…</button>
@if (isExpanded()) {
  <div [id]="panelId">…</div>
}

<!-- DON'T: [attr.hidden]="!isExpanded()" — this is an Angular-specific trap.
     → [attr.hidden]="false" renders hidden="false", and `hidden` is a BOOLEAN
       attribute: any value, including the string "false", hides the element.
       The panel then never opens. Use the [hidden] PROPERTY binding, not
       [attr.hidden]. -->
<div [attr.hidden]="!isExpanded()">…</div>
```

---

## Web Component

### Do

```js
// Parsed once, cloned per instance. Static literal — nothing interpolated.
const template = document.createElement('template');
template.innerHTML = `
  <button type="button" part="trigger" aria-expanded="false" aria-controls="panel">
    <slot name="label"></slot>
  </button>
  <!-- aria-controls="panel" and id="panel" are both in THIS shadow root, so the
       IDREF resolves. It would silently fail if either end were in the light DOM. -->
  <div id="panel" part="panel" hidden>
    <slot></slot>
  </div>
`;

const styles = new CSSStyleSheet();
styles.replaceSync(`
  button:focus-visible { outline: 2px solid #0056b3; outline-offset: 2px; }
`);

class A11yDisclosure extends HTMLElement {
  #button;
  #panel;

  constructor() {
    super();
    const root = this.attachShadow({ mode: 'open' });
    root.adoptedStyleSheets = [styles];
    root.append(template.content.cloneNode(true));
    this.#button = root.querySelector('button');
    this.#panel = root.querySelector('#panel');

    // Constructor runs once; connectedCallback fires again on every DOM move.
    this.#button.addEventListener('click', () => this.toggle());
  }

  get expanded() {
    return this.#button.getAttribute('aria-expanded') === 'true';
  }

  set expanded(value) {
    this.#button.setAttribute('aria-expanded', String(Boolean(value)));
    this.#panel.hidden = !value;
  }

  toggle() {
    this.expanded = !this.expanded;
  }
}

customElements.define('a11y-disclosure', A11yDisclosure);
```

```html
<a11y-disclosure>
  <span slot="label">What is RAWeb?</span>
  <p>RAWeb is Luxembourg's web accessibility framework.</p>
</a11y-disclosure>
```

### Don't

```js
// DON'T: put the button in the shadow root and the panel in the light DOM.
//     → aria-controls cannot cross the boundary: the reference silently fails.
//       Keep both ends in the same root, or drop aria-controls.

// DON'T: reflect state only to the host element.
//     → <a11y-disclosure expanded> styles fine but tells assistive technologies
//       nothing. The state must reach the inner button's aria-expanded.
toggle() {
  this.toggleAttribute('expanded');
}
```

---

## Verify

- **Keyboard-only:** Tab to the trigger → Space → panel opens. Tab again → focus
  must move *into* the panel. Collapse it → Tab must **skip the panel entirely**.
  If you can still tab into hidden content, you hid it with CSS (RAWeb 10.8).
- **Screen reader:** expect "«name», button, collapsed" → after activation,
  "expanded". If you hear no state, `aria-expanded` is on the wrong element. If
  you hear the state twice, you're toggling the name as well.
- **Automated:** axe catches `aria-hidden-focus` and a missing accessible name.
  It does **not** catch `aria-expanded` on the panel instead of the button, nor
  a panel hidden with `opacity: 0` — both look fine to a scanner and are the two
  that actually ship. Test by hand.
