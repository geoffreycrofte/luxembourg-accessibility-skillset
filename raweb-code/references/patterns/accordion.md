# Accordion — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show accordion`

> **An accordion is a stack of [disclosures](disclosure.md) plus heading
> structure.** Read [`disclosure.md`](disclosure.md) first — every rule there
> applies here (`aria-expanded` on the button, `hidden` on the panel, never
> toggle the name and the state). This file covers only what accordion *adds*:
> the headings, and the optional arrow keys.

---

## Universal rules

- **Each header is a real heading wrapping a real button.** `<h3><button>` —
  the heading provides the outline entry, the button provides the control.
  Screen reader users navigate a page by heading; an accordion built from
  `<div>`s is invisible to that entire navigation mode. (RAWeb 9.1)
- **The heading wraps the button, not the other way round.** `<button><h3>` is
  wrong: it puts a heading inside a control, and the heading stops being an
  outline entry.
- **Pick the level from the document outline, not the accordion.** If the
  accordion sits under an `<h2>`, its headers are `<h3>` — regardless of how the
  accordion is nested internally. (RAWeb 9.1)
- **`role="heading"` + `aria-level` is a last resort.** Use a real `<h2>`–`<h6>`
  and both attributes disappear.
- **Arrow keys are optional, and must not replace Tab.** If you add Up/Down to
  move between headers, Tab must still work normally. Hijacking Tab here is a
  keyboard trap. (RAWeb 12.9)
- **Exclusive accordion? `<details name="…">` combine with `<summary>` does it with zero JS.** The browser
  handles the "opening one closes the others" logic natively.

---

## Vanilla

### Do — the zero-JS version

```html
<!-- Shared `name` makes these mutually exclusive: opening one closes the rest,
     with no JS. Omit `name` and they open independently. -->
<h2>Frequently asked questions</h2>

<details name="faq">
  <summary>What is RAWeb?</summary>
  <p>Luxembourg's web accessibility framework, based on EN 301 549.</p>
</details>

<details name="faq">
  <summary>Which conformance level applies?</summary>
  <p>Level AA by default.</p>
</details>
```

Caveat: `<summary>` is a button, but it is **not** a heading, so these sections
don't appear in the heading outline. For a short FAQ that's an acceptable
trade for zero JS. For content users need to navigate by heading, use the ARIA
version below.

### Do — the ARIA version, with real headings

```html
<h2 id="faq-heading">Frequently asked questions</h2>

<div class="accordion">
  <!-- h3 because the accordion lives under an h2. The heading is the outline
       entry; the button is the control. Never nest them the other way. -->
  <h3 class="accordion__heading">
    <button type="button" id="faq-1-button"
            aria-expanded="false" aria-controls="faq-1-panel">
      What is RAWeb?
    </button>
  </h3>
  <div id="faq-1-panel" role="region" aria-labelledby="faq-1-button" hidden>
    <p>Luxembourg's web accessibility framework, based on EN 301 549.</p>
  </div>

  <h3 class="accordion__heading">
    <button type="button" id="faq-2-button"
            aria-expanded="false" aria-controls="faq-2-panel">
      Which conformance level applies?
    </button>
  </h3>
  <div id="faq-2-panel" role="region" aria-labelledby="faq-2-button" hidden>
    <p>Level AA by default.</p>
  </div>
</div>
```

```css
/* The <h3> carries no visual weight — it exists for the outline. Style the
   button, and reset the heading. Do NOT delete the heading to avoid styling it. */
.accordion__heading {
  margin: 0;
  font-size: inherit;
  font-weight: inherit;
}

.accordion__heading button {
  width: 100%;
  text-align: left;
}

.accordion__heading button:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}
```

```js
const accordion = document.querySelector('.accordion');
const buttons = [...accordion.querySelectorAll('.accordion__heading button')];

// Click: plain disclosure behaviour, one per header.
accordion.addEventListener('click', (event) => {
  const button = event.target.closest('.accordion__heading button');
  if (!button) return;

  const isExpanded = button.getAttribute('aria-expanded') === 'true';
  button.setAttribute('aria-expanded', String(!isExpanded));
  document.getElementById(button.getAttribute('aria-controls')).hidden = isExpanded;
});

// OPTIONAL accelerator: Up/Down between headers. Tab is untouched, so this adds
// a shortcut without ever trapping the user (RAWeb 12.9).
accordion.addEventListener('keydown', (event) => {
  const button = event.target.closest('.accordion__heading button');
  if (!button) return;

  const index = buttons.indexOf(button);
  let next = null;

  if (event.key === 'ArrowDown') next = buttons[(index + 1) % buttons.length];
  if (event.key === 'ArrowUp') next = buttons[(index - 1 + buttons.length) % buttons.length];
  if (event.key === 'Home') next = buttons[0];
  if (event.key === 'End') next = buttons.at(-1);

  if (next) {
    event.preventDefault(); // only for the keys we handle — never blanket-prevent
    next.focus();
  }
});
```

### Don't

```html
<!-- DON'T: div headers.
     → The accordion is absent from the heading outline. A screen reader user
       navigating by heading (the most common way to skim a page) never finds it. -->
<div class="accordion__heading">
  <button type="button" aria-expanded="false">What is RAWeb?</button>
</div>

<!-- DON'T: heading inside the button.
     → The control now contains a heading. It stops being an outline entry, and
       the button's accessible name gets muddled. Invert it: <h3><button>. -->
<button type="button" aria-expanded="false">
  <h3>What is RAWeb?</h3>
</button>

<!-- DON'T: level chosen by nesting depth.
     → h4 here skips from h2 to h4 with no h3 (RAWeb 9.1). Levels come from the
       DOCUMENT outline, not from how deep the component sits. -->
<h2>Frequently asked questions</h2>
<div class="accordion">
  <h4><button type="button">What is RAWeb?</button></h4>
</div>

<!-- DON'T: role="heading" when a real heading would do.
     → More attributes, more to get wrong, no benefit. -->
<div role="heading" aria-level="3">
  <button type="button" aria-expanded="false">What is RAWeb?</button>
</div>

<!-- DON'T: role="region" on all 40 panels of a long accordion.
     → Every panel becomes a landmark. The landmark list — a primary screen
       reader navigation aid — is now unusable. Use it only for a handful of
       panels, or drop it. -->
```

```js
// DON'T: hijack Tab to move between headers.
//     → Tab is how users leave the component. Capturing it is a keyboard trap
//       (RAWeb 12.9). Arrows are an accelerator; Tab is not yours to take.
accordion.addEventListener('keydown', (event) => {
  if (event.key === 'Tab') {
    event.preventDefault();
    focusNextHeader();
  }
});

// DON'T: blanket preventDefault on every keydown.
//     → Kills Tab, Escape, and every screen reader shortcut that passes through.
accordion.addEventListener('keydown', (event) => {
  event.preventDefault();
  handleKey(event);
});
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

export function AccordionItem({ label, headingLevel: Heading = 'h3', children }) {
  const [isExpanded, setIsExpanded] = useState(false);
  const id = useId();
  const buttonId = `${id}-button`;
  const panelId = `${id}-panel`;

  return (
    <>
      {/* Heading level is a PROP, not a constant: the same component may sit
          under an h1 on one page and an h2 on another. Hardcoding h3 guarantees
          a broken outline somewhere (RAWeb 9.1). */}
      <Heading className="accordion__heading">
        <button
          type="button"
          id={buttonId}
          aria-expanded={isExpanded}
          aria-controls={panelId}
          onClick={() => setIsExpanded((value) => !value)}
        >
          {label}
        </button>
      </Heading>

      <div id={panelId} role="region" aria-labelledby={buttonId} hidden={!isExpanded}>
        {children}
      </div>
    </>
  );
}
```

```jsx
<h2>Frequently asked questions</h2>
<AccordionItem headingLevel="h3" label="What is RAWeb?">
  <p>Luxembourg's web accessibility framework.</p>
</AccordionItem>
```

### Don't

```jsx
// DON'T: hardcode the heading level inside the component.
//     → The component cannot adapt to its context. Drop it under an h1 and you
//       skip h2; drop it under an h3 and you go backwards. Take it as a prop.
export function AccordionItem({ label, children }) {
  return <h3><button>{label}</button></h3>;
}

// DON'T: a div styled to look like a heading.
//     → font-size: 1.5rem is not a heading. Nothing reaches the outline.
<div className="accordion__heading">
  <button aria-expanded={isExpanded}>{label}</button>
</div>

// DON'T: <button><h3>{label}</h3></button> — inverted nesting, same as vanilla.
```

---

## Angular

### Do

```ts
import { Component, input, signal } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-accordion-item',
  template: `
    <!-- Angular has no dynamic tag syntax, so switch on the level. Verbose, but
         it keeps the heading level honest to the document outline. -->
    @switch (headingLevel()) {
      @case (2) { <h2 class="accordion__heading"><ng-container *ngTemplateOutlet="trigger" /></h2> }
      @case (4) { <h4 class="accordion__heading"><ng-container *ngTemplateOutlet="trigger" /></h4> }
      @default  { <h3 class="accordion__heading"><ng-container *ngTemplateOutlet="trigger" /></h3> }
    }

    <ng-template #trigger>
      <button
        type="button"
        [id]="buttonId"
        [attr.aria-expanded]="isExpanded()"
        [attr.aria-controls]="panelId"
        (click)="toggle()"
      >
        {{ label() }}
      </button>
    </ng-template>

    <!-- [hidden] property binding, NOT [attr.hidden]: attr.hidden="false" would
         render hidden="false", which still hides it. See disclosure.md. -->
    <div [id]="panelId" role="region" [attr.aria-labelledby]="buttonId" [hidden]="!isExpanded()">
      <ng-content />
    </div>
  `,
})
export class AccordionItemComponent {
  readonly label = input.required<string>();
  readonly headingLevel = input<2 | 3 | 4>(3);

  protected readonly isExpanded = signal(false);
  private readonly id = uid++;
  protected readonly buttonId = `accordion-button-${this.id}`;
  protected readonly panelId = `accordion-panel-${this.id}`;

  protected toggle(): void {
    this.isExpanded.update((value) => !value);
  }
}
```

### Don't

```html
<!-- DON'T: [attr.hidden]="!isExpanded()".
     → Renders hidden="false" when expanded, which STILL hides the panel,
       because `hidden` is a boolean attribute. Use the [hidden] property. -->
<div [attr.hidden]="!isExpanded()">…</div>

<!-- DON'T: a fixed <h3> in a component used at several outline depths. -->
<h3><button (click)="toggle()">{{ label() }}</button></h3>
```

---

## Web Component

### Do

The heading is the problem: a heading inside a shadow root **does not appear in
the document's heading outline**. So the accordion item must take its heading
from the light DOM.

```js
// No shadow DOM. This component enhances light-DOM markup that already has the
// right headings, rather than generating headings the outline cannot see.
class A11yAccordion extends HTMLElement {
  connectedCallback() {
    // Light DOM only — the author supplies <h3><button> and the panel.
    this.addEventListener('click', (event) => {
      const button = event.target.closest('button[aria-expanded]');
      if (!button || !this.contains(button)) return;

      const isExpanded = button.getAttribute('aria-expanded') === 'true';
      button.setAttribute('aria-expanded', String(!isExpanded));
      const panel = this.querySelector(`#${CSS.escape(button.getAttribute('aria-controls'))}`);
      if (panel) panel.hidden = isExpanded;
    });
  }
}

customElements.define('a11y-accordion', A11yAccordion);
```

```html
<h2>Frequently asked questions</h2>
<a11y-accordion>
  <h3><button type="button" aria-expanded="false" aria-controls="p1">What is RAWeb?</button></h3>
  <div id="p1" hidden><p>Luxembourg's web accessibility framework.</p></div>
</a11y-accordion>
```

### Don't

```js
// DON'T: generate the headings inside a shadow root.
//     → Headings in a shadow root are NOT part of the document's heading
//       outline. Screen reader heading navigation skips them entirely, which is
//       the one thing an accordion most needs (RAWeb 9.1). Keep headings in the
//       light DOM, or accept that this component has no outline presence.
root.innerHTML = `<h3><button aria-expanded="false"><slot name="label"></slot></button></h3>`;
```

---

## Verify

- **Keyboard-only:** Tab must reach each header in order and must always be able
  to leave the accordion. If you added arrows, they move between headers *and*
  Tab still works (RAWeb 12.9).
- **Heading outline:** this is the accordion-specific check. Open the browser's
  accessibility tree, or run a heading-outline extension: every header must
  appear, at the right level, with no skips (RAWeb 9.1). If the accordion is
  missing from the outline, the headers aren't real headings.
- **Screen reader:** navigate by heading (VoiceOver `Ctrl+Opt+Cmd+H`, NVDA `H`).
  You must land on each header and hear "«label», collapsed, button, heading
  level 3".
- **Automated:** axe catches skipped heading levels and empty headings. It does
  **not** catch a `<div>` header that merely looks like a heading — there is
  nothing there to flag. The outline check is manual.
