# Tooltip — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show tooltip`

> **This is the pattern RAWeb 12.11 exists for.** Read the criterion before
> building one: `scripts/raweb-lookup.sh criterion 12.11`.

---

## Universal rules

- **`title` is not a tooltip.** It never appears on keyboard focus, can't be
  styled, can't be dismissed, is invisible on touch, and is announced
  inconsistently across screen readers. It is not a lesser tooltip — it is a
  broken one. (RAWeb 7.3)
- **Must appear on focus, not just hover.** A hover-only tooltip does not exist
  for a keyboard user. (RAWeb 7.3, 12.11)
- **The trigger must be focusable.** A tooltip on a `<span>` or a disabled button
  can never be reached by keyboard. (RAWeb 12.11)
- **`aria-describedby` on the trigger, pointing at the tooltip.** That's what
  makes it announced. Use `aria-labelledby` *instead* only when the tooltip **is**
  the trigger's name (an icon button with no visible text) — never both.
- **Escape must dismiss it** while focus stays on the trigger. (WCAG 1.4.13)
- **It must stay hoverable.** At 200% zoom a user may need to move the pointer
  *onto* the tooltip to read it. Don't hide on the trigger's `mouseleave` if the
  pointer moved into the tooltip. (WCAG 1.4.13, RAWeb 10.4)
- **No interactive content inside.** A link or button in a tooltip can never be
  reached: focus moves away, the tooltip hides, the target is gone. If it needs
  a link, **it is not a tooltip** — see the table below. (RAWeb 12.11)
- **The tooltip stays in the DOM.** `aria-describedby` is an IDREF; if you unmount
  the tooltip when hidden, the reference dangles.

### Is it actually a tooltip?

| Content | Pattern |
|---|---|
| A short text description of the trigger | **tooltip** (this file) |
| Anything with a link or button | [`disclosure`](disclosure.md), or a non-modal dialog |
| Rich content, several paragraphs | [`disclosure`](disclosure.md) |
| Actions | [`menu-button`](menu-button.md) |
| Text critical to a form field | **not a tooltip** — put it in a visible hint tied via `aria-describedby` |

That last row matters: a format hint ("8+ characters") hidden behind a tooltip
is invisible on touch and easy to miss. Show it. (RAWeb 11.10)

---

## Vanilla

### Do

```html
<!-- The tooltip DESCRIBES a button that already has a visible name. -->
<button type="button" id="save-button" aria-describedby="save-tip">
  Save
</button>
<!-- role="tooltip" and always in the DOM so aria-describedby resolves. -->
<div role="tooltip" id="save-tip" hidden>
  Saves to your local draft. Nothing is published.
</div>
```

```html
<!-- Icon button with NO visible text: the tooltip IS the name. Use
     aria-labelledby, not aria-describedby — a button with no name and only a
     description is announced as just "button" (RAWeb 7.1). -->
<button type="button" id="delete-button" aria-labelledby="delete-tip">
  <svg aria-hidden="true" focusable="false" width="16" height="16"><use href="#icon-trash"/></svg>
</button>
<div role="tooltip" id="delete-tip" hidden>Delete</div>
```

```css
[role="tooltip"] {
  position: absolute;
  z-index: 10;
  max-inline-size: 20rem;
  padding: 0.5rem 0.75rem;
  background: #1a1a1a;
  color: #fff;          /* verify ≥4.5:1 against #1a1a1a (RAWeb 3.2) */
  border-radius: 4px;
}

/* The trigger keeps its own focus ring while the tooltip shows (RAWeb 10.7). */
button:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

/* No pointer-events: none — the tooltip must stay hoverable so a zoomed user
   can move onto it to read it (WCAG 1.4.13). */
```

```js
const trigger = document.getElementById('save-button');
const tooltip = document.getElementById('save-tip');
let hideTimer;

const show = () => {
  clearTimeout(hideTimer);
  tooltip.hidden = false;
};

// Delay the hide so the pointer can travel from the trigger onto the tooltip
// without it vanishing mid-journey (WCAG 1.4.13 "hoverable").
const scheduleHide = () => {
  hideTimer = setTimeout(() => { tooltip.hidden = true; }, 150);
};

// Focus and hover BOTH show it (RAWeb 7.3, 12.11).
trigger.addEventListener('focus', show);
trigger.addEventListener('blur', () => { tooltip.hidden = true; });
trigger.addEventListener('mouseenter', show);
trigger.addEventListener('mouseleave', scheduleHide);

// Keep it open while the pointer is on the tooltip itself.
tooltip.addEventListener('mouseenter', show);
tooltip.addEventListener('mouseleave', scheduleHide);

// Escape dismisses without moving focus (WCAG 1.4.13 "dismissible").
document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') tooltip.hidden = true;
});
```

### Don't

```html
<!-- DON'T: the title attribute.
     → Never shows on keyboard focus. Unstyleable. Undismissable. Invisible on
       touch. Announced inconsistently — some screen readers read it, some read
       it INSTEAD of the label, some ignore it. It is not a tooltip. -->
<button type="button" title="Saves to your local draft">Save</button>

<!-- DON'T: a tooltip on a non-focusable element.
     → A keyboard user can never reach it (RAWeb 12.11). If it needs a tooltip,
       it needs to be focusable — which usually means it should be a button. -->
<span class="info-icon" aria-describedby="tip">ⓘ</span>

<!-- DON'T: a tooltip on a disabled button.
     → Disabled elements are not focusable and do not fire pointer events, so
       the tooltip explaining WHY it is disabled is exactly the thing nobody can
       read. Use aria-disabled="true" on an enabled button, and handle the
       no-op yourself. -->
<button type="button" disabled aria-describedby="why-disabled">Submit</button>

<!-- DON'T: interactive content inside a tooltip.
     → Unreachable. Tab moves focus off the trigger, the tooltip hides, the link
       is gone. RAWeb 12.11 requires interactive content in hover/focus popups to
       be keyboard reachable — a tooltip structurally cannot be. Use a disclosure. -->
<div role="tooltip" id="tip">
  See the <a href="/docs">documentation</a> for details.
</div>

<!-- DON'T: both aria-labelledby and aria-describedby to the same tooltip.
     → Announced twice: "Delete, Delete". Pick one. -->
<button aria-labelledby="tip" aria-describedby="tip">
  <svg aria-hidden="true"></svg>
</button>

<!-- DON'T: aria-describedby on an icon button with no other name.
     → A description does not name anything. Announced as "button", then the
       description. The user never learns what it does. Use aria-labelledby. -->
<button type="button" aria-describedby="delete-tip">
  <svg aria-hidden="true"></svg>
</button>

<!-- DON'T: role="tooltip" with no aria-describedby/labelledby pointing at it.
     → The role alone associates nothing. The tooltip is visible and never
       announced. -->
<button type="button">Save</button>
<div role="tooltip">Saves to your local draft.</div>
```

```js
// DON'T: hover only.
//     → Invisible to every keyboard user (RAWeb 7.3, 12.11).
trigger.addEventListener('mouseenter', show);
trigger.addEventListener('mouseleave', hide);

// DON'T: hide instantly on mouseleave.
//     → The pointer cannot travel from trigger to tooltip without crossing the
//       gap, so a zoomed-in user can never reach the text to read it
//       (WCAG 1.4.13 "hoverable").
trigger.addEventListener('mouseleave', () => { tooltip.hidden = true; });

// DON'T: pointer-events: none on the tooltip — same failure, in CSS.

// DON'T: no Escape handler.
//     → A tooltip covering content the user is trying to read cannot be
//       dismissed (WCAG 1.4.13 "dismissible").
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef, useState } from 'react';

export function Tooltip({ content, children, describes = true }) {
  const [isVisible, setIsVisible] = useState(false);
  const id = useId();
  const timerRef = useRef(null);

  const show = () => { clearTimeout(timerRef.current); setIsVisible(true); };
  const scheduleHide = () => {
    timerRef.current = setTimeout(() => setIsVisible(false), 150);
  };

  useEffect(() => () => clearTimeout(timerRef.current), []);

  useEffect(() => {
    if (!isVisible) return;
    const onKeyDown = (e) => { if (e.key === 'Escape') setIsVisible(false); };
    document.addEventListener('keydown', onKeyDown);
    return () => document.removeEventListener('keydown', onKeyDown);
  }, [isVisible]);

  return (
    <span className="tooltip-wrapper">
      {/* describes=true  → tooltip DESCRIBES a named trigger (aria-describedby)
          describes=false → tooltip IS the name of an icon button (aria-labelledby) */}
      {cloneTrigger(children, {
        [describes ? 'aria-describedby' : 'aria-labelledby']: id,
        onFocus: show,
        onBlur: () => setIsVisible(false),
        onMouseEnter: show,
        onMouseLeave: scheduleHide,
      })}

      {/* Always rendered — aria-describedby is an IDREF and needs a target. */}
      <div
        role="tooltip"
        id={id}
        hidden={!isVisible}
        onMouseEnter={show}
        onMouseLeave={scheduleHide}
      >
        {content}
      </div>
    </span>
  );
}
```

### Don't

```jsx
// DON'T: render the tooltip only when visible.
//     → aria-describedby points at an id that is not in the DOM whenever the
//       tooltip is hidden — which is almost always. The reference dangles and
//       nothing is announced.
<button aria-describedby={id}>Save</button>
{isVisible && <div role="tooltip" id={id}>{content}</div>}

// DON'T: onMouseOver/onMouseOut only.
//     → No keyboard support at all (RAWeb 12.11).
<button onMouseOver={show} onMouseOut={hide}>Save</button>

// DON'T: title={content} as a "fallback".
//     → Now BOTH announce: the screen reader reads the tooltip and the title.
<button title={content} aria-describedby={id}>Save</button>
```

---

## Angular

### Do

```ts
import { Component, input, signal } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-tooltip',
  host: { '(document:keydown.escape)': 'hide()' },
  template: `
    <span class="tooltip-wrapper">
      <button
        type="button"
        [attr.aria-describedby]="tipId"
        (focus)="show()"
        (blur)="hide()"
        (mouseenter)="show()"
        (mouseleave)="scheduleHide()"
      >
        <ng-content />
      </button>

      <div
        role="tooltip"
        [id]="tipId"
        [hidden]="!isVisible()"
        (mouseenter)="show()"
        (mouseleave)="scheduleHide()"
      >
        {{ content() }}
      </div>
    </span>
  `,
})
export class TooltipComponent {
  readonly content = input.required<string>();
  protected readonly tipId = `tooltip-${uid++}`;
  protected readonly isVisible = signal(false);
  private timer?: ReturnType<typeof setTimeout>;

  protected show(): void {
    clearTimeout(this.timer);
    this.isVisible.set(true);
  }

  protected hide(): void {
    clearTimeout(this.timer);
    this.isVisible.set(false);
  }

  protected scheduleHide(): void {
    this.timer = setTimeout(() => this.isVisible.set(false), 150);
  }
}
```

**Or use the CDK** — but read this first: `@angular/cdk/overlay`'s `cdkTooltip`
(and Material's `matTooltip`) show on focus and hover and handle Escape. They are
a reasonable choice. What they cannot do is stop you putting a link inside, or
using one on a `<span>`.

### Don't

```html
<!-- DON'T: [attr.hidden] — renders hidden="false" and still hides. Use [hidden]. -->
<div role="tooltip" [attr.hidden]="!isVisible()">…</div>

<!-- DON'T: [title]="content()" — see React: it double-announces. -->
<button [title]="content()" [attr.aria-describedby]="tipId">Save</button>
```

---

## Web Component

### Do

```js
// Light DOM. aria-describedby (trigger → tooltip) is an IDREF: if the trigger is
// the author's light-DOM button and the tooltip lives in a shadow root, the
// reference cannot resolve and the tooltip is never announced.
class A11yTooltip extends HTMLElement {
  #trigger;
  #tooltip;
  #timer;

  connectedCallback() {
    this.#trigger = this.querySelector('[aria-describedby], [aria-labelledby]');
    this.#tooltip = this.querySelector('[role="tooltip"]');
    if (!this.#trigger || !this.#tooltip) return;

    const show = () => { clearTimeout(this.#timer); this.#tooltip.hidden = false; };
    const scheduleHide = () => {
      this.#timer = setTimeout(() => { this.#tooltip.hidden = true; }, 150);
    };

    this.#trigger.addEventListener('focus', show);
    this.#trigger.addEventListener('blur', () => { this.#tooltip.hidden = true; });
    this.#trigger.addEventListener('mouseenter', show);
    this.#trigger.addEventListener('mouseleave', scheduleHide);
    this.#tooltip.addEventListener('mouseenter', show);
    this.#tooltip.addEventListener('mouseleave', scheduleHide);

    this.#onKeyDown = (e) => { if (e.key === 'Escape') this.#tooltip.hidden = true; };
    document.addEventListener('keydown', this.#onKeyDown);
  }

  disconnectedCallback() {
    clearTimeout(this.#timer);
    document.removeEventListener('keydown', this.#onKeyDown);
  }

  #onKeyDown;
}

customElements.define('a11y-tooltip', A11yTooltip);
```

```html
<a11y-tooltip>
  <button type="button" aria-describedby="save-tip">Save</button>
  <div role="tooltip" id="save-tip" hidden>Saves to your local draft.</div>
</a11y-tooltip>
```

### Don't

```js
// DON'T: tooltip in a shadow root, trigger in the light DOM.
//     → aria-describedby cannot cross the boundary. The tooltip renders, looks
//       perfect, and is never announced to anyone. Silent failure.
root.innerHTML = `<div role="tooltip" id="tip"><slot name="content"></slot></div>`;
```

---

## Verify

- **Keyboard-only:** Tab to the trigger — the tooltip **must appear**. If it only
  appears on hover, it fails RAWeb 7.3 and 12.11. Escape must dismiss it with
  focus still on the trigger.
- **The RAWeb 12.11 check:** does the tooltip contain anything interactive? If
  yes, it fails — that content is unreachable by keyboard. It is a disclosure.
- **Hoverable check (WCAG 1.4.13):** zoom to 200%, hover the trigger, then move
  the pointer onto the tooltip. It must stay open. If it vanishes as the pointer
  crosses the gap, you're hiding on `mouseleave` with no delay.
- **Screen reader:** for a described trigger expect "Save, button, «tooltip
  text»". For an icon button expect the tooltip text *as the name*. If you hear
  the text twice, you have `aria-labelledby` and `aria-describedby` both set, or
  a leftover `title`.
- **Automated:** axe catches a missing accessible name on an icon button. It does
  **not** catch hover-only tooltips, `title`-as-tooltip, links inside tooltips,
  or a tooltip on a non-focusable span. Every real tooltip bug is manual.
