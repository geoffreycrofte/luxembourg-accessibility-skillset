# Button — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show button`

---

## Universal rules

- **`<button type="button">`. Always.** There is essentially no valid reason to
  build a button from a `<div>`. The native element gives you focus, Enter,
  Space, the role, and the name for free. (RAWeb 7.1, 7.3)
- **Always write `type`.** Inside a `<form>`, a `<button>` with no `type`
  defaults to `type="submit"`. That is a colossal source of accidental
  submissions — the "Show password" button that posts the form.
- **Navigates → link. Acts → button.** This is the most common semantic mistake
  on the web. See the table below.
- **Icon-only buttons need a name.** `aria-label` or visually hidden text, with
  `aria-hidden="true" focusable="false"` on the SVG. (RAWeb 7.1)
- **One state mechanism per button.** `aria-pressed` (toggle) *or*
  `aria-expanded` (disclosure) *or* `role="switch"` — never two.
- **Prefer `aria-disabled` to `disabled`** when the user needs to know *why*.
  `disabled` removes the button from the tab order entirely: a keyboard user
  can't reach it, can't focus it, and can't read a tooltip on it.

### Button or link?

| | `<button>` | `<a href>` |
|---|---|---|
| Purpose | performs an action | goes somewhere |
| Enter | activates | activates |
| Space | activates | **does nothing** |
| Right-click → open in new tab | no | yes |
| Announced as | "button" | "link" |
| Example | Save, Delete, Open dialog | Home, Next page, Download |

A `<div onclick="location.href=…">` fails both. If it changes the URL, it's a
link — and a link needs an `href`, not a click handler. (RAWeb 6.1)

---

## Vanilla

### Do

```html
<!-- Plain action button. type="button" is not optional. -->
<button type="button" onclick="saveDraft()">Save draft</button>

<!-- Submit: say what it does, not "Submit" (RAWeb 11.9). -->
<button type="submit">Create account</button>

<!-- Icon-only: the name lives in visually hidden text, the icon is decorative.
     Hidden text beats aria-label — it survives translation tooling, and it is
     picked up by voice control users saying "click Delete". -->
<button type="button" class="icon-button">
  <svg aria-hidden="true" focusable="false" width="16" height="16"><use href="#icon-trash"/></svg>
  <span class="sr-only">Delete draft</span>
</button>

<!-- Toggle button: aria-pressed carries the state. The label stays stable. -->
<button type="button" aria-pressed="false" id="bold-button">
  <svg aria-hidden="true" focusable="false"><use href="#icon-bold"/></svg>
  <span class="sr-only">Bold</span>
</button>

<!-- Unavailable, but the user needs to know why: aria-disabled keeps it
     focusable and announced, so the description can actually be read. -->
<button type="button" aria-disabled="true" aria-describedby="why-disabled">
  Publish
</button>
<p id="why-disabled">Add a title before publishing.</p>

<!-- Navigation is a link, styled as a button. -->
<a href="/pricing" class="button">See pricing</a>
```

```css
/* RAWeb 10.7 — never remove this without replacing it. */
button:focus-visible,
.button:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

/* aria-disabled is only semantic — style it yourself, and stop the action in JS. */
button[aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
}

/* RAWeb 3.3 — target size and non-text contrast for icon buttons. */
.icon-button {
  min-inline-size: 44px;
  min-block-size: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
```

```js
// aria-disabled does NOT block activation — that is the trade for staying
// focusable. Guard the handler yourself.
publishButton.addEventListener('click', (event) => {
  if (publishButton.getAttribute('aria-disabled') === 'true') {
    event.preventDefault();
    return;
  }
  publish();
});

// Toggle button: flip the state, keep the name.
boldButton.addEventListener('click', () => {
  const isPressed = boldButton.getAttribute('aria-pressed') === 'true';
  boldButton.setAttribute('aria-pressed', String(!isPressed));
  document.execCommand('bold');
});
```

### Don't

```html
<!-- DON'T: a div button.
     → Not focusable, no role, no Enter, no Space. You then need tabindex="0",
       role="button", AND a keydown handler for Enter and Space — three
       attributes and a handler to badly re-create <button>. -->
<div class="button" onclick="save()">Save</div>

<!-- DON'T: <button> with no type inside a form.
     → Defaults to type="submit". Clicking "Show password" submits the form. -->
<form>
  <button onclick="togglePassword()">Show password</button>
</form>

<!-- DON'T: a link that acts.
     → href="#" navigates to the top of the page if JS fails, and it is
       announced as a link when it is really a button. -->
<a href="#" onclick="deleteItem(); return false;">Delete</a>

<!-- DON'T: a button that navigates.
     → No open-in-new-tab, no middle-click, no status bar preview, and it is
       announced as a button when it goes somewhere (RAWeb 6.1). -->
<button type="button" onclick="location.href='/pricing'">See pricing</button>

<!-- DON'T: an icon button with no name.
     → Announced as "button". The single most common a11y bug on the web. -->
<button type="button"><svg><use href="#icon-trash"/></svg></button>

<!-- DON'T: a focusable icon inside the button.
     → The <svg> without focusable="false" is a tab stop of its own in some
       browsers, and its <title> can override the button's name. -->
<button type="button" aria-label="Delete">
  <svg><title>Trash icon</title><use href="#icon-trash"/></svg>
</button>

<!-- DON'T: two state mechanisms.
     → "Bold, toggle button, pressed, expanded". Which is it? -->
<button type="button" aria-pressed="true" aria-expanded="true">Bold</button>

<!-- DON'T: a label that flips with the state.
     → Announced "Unmute, pressed" — the name and the state contradict.
       Name the FUNCTION; let aria-pressed carry the state. -->
<button type="button" aria-pressed="true">Unmute</button>

<!-- DON'T: disabled on the thing whose tooltip explains the disabling.
     → Not focusable, fires no pointer events. The explanation is unreachable
       precisely when it is needed. Use aria-disabled. -->
<button type="button" disabled title="Add a title before publishing">Publish</button>
```

```css
/* DON'T: kill focus outlines.
   → Keyboard users lose all sense of where they are (RAWeb 10.7). If the
     default ring is ugly, replace it — never just delete it. */
button:focus { outline: none; }
```

---

## React

### Do

```jsx
export function IconButton({ label, icon: Icon, onClick }) {
  return (
    <button type="button" className="icon-button" onClick={onClick}>
      <Icon aria-hidden="true" focusable="false" />
      <span className="sr-only">{label}</span>
    </button>
  );
}

export function ToggleButton({ label, isPressed, onToggle }) {
  return (
    <button type="button" aria-pressed={isPressed} onClick={onToggle}>
      {label}
    </button>
  );
}

// Unavailable but discoverable.
export function PublishButton({ canPublish, reason, onPublish }) {
  const reasonId = useId();
  return (
    <>
      <button
        type="button"
        aria-disabled={!canPublish}
        aria-describedby={canPublish ? undefined : reasonId}
        onClick={(e) => {
          if (!canPublish) { e.preventDefault(); return; }
          onPublish();
        }}
      >
        Publish
      </button>
      {!canPublish && <p id={reasonId}>{reason}</p>}
    </>
  );
}
```

### Don't

```jsx
// DON'T: omit type inside a form. React does not add it for you.
<button onClick={handleClick}>Show password</button>

// DON'T: div + onClick + onKeyDown, reimplementing <button> badly.
//     → Even done "right" you have re-created the native element with more
//       code, and you will still miss something (Space scrolls the page unless
//       you preventDefault it).
<div role="button" tabIndex={0} onClick={act} onKeyDown={(e) => e.key === 'Enter' && act()}>
  Save
</div>

// DON'T: onClick on a non-interactive element.
//     → Not focusable, not announced, keyboard-dead. eslint-plugin-jsx-a11y
//       flags this — do not disable the rule.
<span onClick={handleClick}>Delete</span>

// DON'T: aria-label AND visible text that differ.
//     → Voice control users say what they SEE ("click Save"), and nothing
//       matches. The accessible name must contain the visible label (RAWeb 7.1).
<button type="button" aria-label="Submit form">Save</button>
```

---

## Angular

### Do

```ts
import { Component, input, model, output } from '@angular/core';

@Component({
  selector: 'app-icon-button',
  template: `
    <button type="button" class="icon-button" (click)="clicked.emit()">
      <ng-content />
      <span class="sr-only">{{ label() }}</span>
    </button>
  `,
})
export class IconButtonComponent {
  readonly label = input.required<string>();
  readonly clicked = output<void>();
}

@Component({
  selector: 'app-toggle-button',
  template: `
    <button type="button" [attr.aria-pressed]="pressed()" (click)="toggle()">
      {{ label() }}
    </button>
  `,
})
export class ToggleButtonComponent {
  readonly label = input.required<string>();
  readonly pressed = model(false);

  protected toggle(): void {
    this.pressed.update((v) => !v);
  }
}
```

### Don't

```html
<!-- DON'T: omit type inside a form — defaults to submit. -->
<form>
  <button (click)="togglePassword()">Show password</button>
</form>

<!-- DON'T: [disabled] when the user must learn why.
     → Not focusable; the aria-describedby explanation is unreachable.
       Use [attr.aria-disabled] and guard the handler. -->
<button [disabled]="!canPublish()" [attr.aria-describedby]="reasonId">Publish</button>

<!-- DON'T: (click) on a div. Angular will happily bind it and it stays
     keyboard-dead. -->
<div (click)="save()">Save</div>
```

---

## Web Component

### Do

```js
// Extend the native button's behaviour rather than rebuilding it. The simplest
// correct custom button is a thin wrapper that keeps a real <button> inside.
const template = document.createElement('template');
template.innerHTML = `
  <button type="button" part="button">
    <slot name="icon"></slot>
    <span class="label"><slot></slot></span>
  </button>
`;

const styles = new CSSStyleSheet();
styles.replaceSync(`
  button:focus-visible { outline: 2px solid #0056b3; outline-offset: 2px; }
  button { min-inline-size: 44px; min-block-size: 44px; }
`);

class A11yButton extends HTMLElement {
  #button;

  constructor() {
    super();
    // delegatesFocus makes the host focusable and forwards focus to the inner
    // button — appropriate here (unlike a modal, see dialog-modal.md).
    const root = this.attachShadow({ mode: 'open', delegatesFocus: true });
    root.adoptedStyleSheets = [styles];
    root.append(template.content.cloneNode(true));
    this.#button = root.querySelector('button');
  }
}

customElements.define('a11y-button', A11yButton);
```

**Honestly: don't.** A custom element wrapping a `<button>` cannot participate in
form submission without `ElementInternals`, cannot be `disabled` natively, and
gains nothing over `<button class="my-button">`. Reach for a custom element here
only if you are building a full design system with `formAssociated`.

### Don't

```js
// DON'T: a shadow-root div with role="button".
//     → Not focusable (shadow roots do not make things focusable), no Enter, no
//       Space, no form participation. Every problem of a div button, plus a
//       shadow boundary hiding it from your own tests.
root.innerHTML = `<div role="button" tabindex="0"><slot></slot></div>`;

// DON'T: a form-participating custom button without ElementInternals.
//     → <a11y-button type="submit"> inside a form submits nothing. The shadow
//       boundary stops the inner button reaching the outer form. You need
//       static formAssociated = true and this.attachInternals().
```

---

## Verify

- **Keyboard-only:** Tab to it. **Enter and Space must both activate.** If Space
  scrolls the page instead, it is not a real button. Focus ring must be visible
  (RAWeb 10.7).
- **The link/button check:** does it change the URL? Then it must be an `<a href>`
  — right-click and confirm "Open in new tab" appears.
- **Icon buttons:** with a screen reader, expect "Delete draft, button" — not
  "button". Then try voice control: saying the *visible* label must work, which
  is why hidden text beats `aria-label`.
- **Automated:** axe reliably catches icon buttons with no name and `onclick` on
  non-interactive elements — this is one of the few patterns where scanners do
  well. They do **not** catch a missing `type`, a button that should be a link,
  or a label that contradicts `aria-pressed`.
