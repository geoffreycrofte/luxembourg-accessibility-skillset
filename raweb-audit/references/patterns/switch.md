# Switch — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show switch`

**Read this whole file** when building a toggle. Use `code switch <framework>`
only when you already know the universal rules and just want the snippet.

---

## Universal rules

- **Build it on a real control.** `<button role="switch">` for a setting that
  applies immediately; `<input type="checkbox" role="switch">` when the value
  must be *submitted with a form* — only a real input has a form value. Either
  way you get focus, Space, and pointer support free. (RAWeb 7.3)
- **`aria-checked` carries the state.** The sliding knob is decoration. Without
  `aria-checked`, a screen reader announces "button" and the user cannot tell
  on from off. (RAWeb 7.1)
- **A switch is binary — never `aria-checked="mixed"`.** That's what separates it
  from a [`checkbox`](checkbox.md). If you need a third state, you want a
  checkbox, not a switch.
- **Don't stack `aria-pressed` on top.** That's the toggle-button pattern.
  `role="switch"` already carries state via `aria-checked`; using both announces
  the state twice.
- **The label names the setting, not the state.** "Email notifications" — not
  "On"/"Off". Swapping the label between On and Off means the accessible name
  and `aria-checked` both claim to be the state, and they read contradictorily.
- **State must not be colour alone.** (RAWeb 3.1) The classic sliding switch
  passes *because the knob moves* — position encodes state, not just hue. A track
  that only shifts grey→green fails for anyone who can't separate those colours.
  This one is easy to miss because it looks obvious to the designer.

### Switch or checkbox?

| | Switch | Checkbox |
|---|---|---|
| Takes effect | immediately | on form submit |
| States | 2 | 3 (`mixed` allowed) |
| Announced | "switch, on" | "checkbox, checked" |
| Needs a form value | use `<input type="checkbox" role="switch">` | native |

If the change only lands when the user presses "Save", it's a checkbox — even if
the designer drew a slider.

---

## Vanilla

### Do — instant-effect setting

```html
<!-- The <span> is the label; the button is the control. The button's accessible
     name comes from aria-labelledby, so the visible text IS the name (RAWeb 7.1). -->
<div class="switch-row">
  <span id="notify-label">Email notifications</span>

  <button type="button" role="switch" aria-checked="false" aria-labelledby="notify-label">
    <!-- Decorative: the real state lives in aria-checked. -->
    <span class="switch__track" aria-hidden="true">
      <span class="switch__knob"></span>
    </span>
  </button>
</div>
```

```css
.switch__track {
  display: inline-block;
  inline-size: 2.75rem;
  block-size: 1.5rem;
  border-radius: 1rem;
  background: #767676; /* ≥3:1 against the page (RAWeb 3.3) */
  transition: background-color 150ms ease;
}

.switch__knob {
  display: block;
  inline-size: 1.25rem;
  block-size: 1.25rem;
  border-radius: 50%;
  background: #fff;
  transform: translateX(0.125rem);
  transition: transform 150ms ease;
}

/* State-driven from the ATTRIBUTE, so the visual can never drift from what is
   announced. Do not mirror state into a CSS class. */
[role="switch"][aria-checked="true"] .switch__track {
  background: #0056b3;
}

/* RAWeb 3.1: the knob MOVES. Position — not colour — is what makes this
   perceivable to a user who cannot distinguish grey from blue. */
[role="switch"][aria-checked="true"] .switch__knob {
  transform: translateX(1.375rem);
}

[role="switch"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  .switch__track,
  .switch__knob { transition: none; }
}

/* Windows High Contrast Mode strips background-color, so a colour-only switch
   becomes stateless there. A forced-colors-aware outline keeps it readable. */
@media (forced-colors: active) {
  [role="switch"][aria-checked="true"] .switch__knob { forced-color-adjust: none; background: Highlight; }
  .switch__track { border: 1px solid ButtonText; }
}
```

```js
const toggle = document.querySelector('[role="switch"]');

// No keydown handler: a native <button> already fires click on Space.
toggle.addEventListener('click', () => {
  const isChecked = toggle.getAttribute('aria-checked') === 'true';
  toggle.setAttribute('aria-checked', String(!isChecked));
  savePreference({ emailNotifications: !isChecked });
});
```

### Do — inside a form

```html
<!-- role="switch" on a real checkbox: it keeps the form value and the native
     label association, and the browser maps `checked` to aria-checked for you.
     No JS at all. -->
<div class="switch-row">
  <input type="checkbox" role="switch" id="notify" name="notify" class="switch__input">
  <label for="notify">Email notifications</label>
</div>
```

```css
/* Style the native input directly — do not hide it behind a fake div. */
.switch__input {
  appearance: none;
  inline-size: 2.75rem;
  block-size: 1.5rem;
  border-radius: 1rem;
  background: #767676;
  position: relative;
}

.switch__input::before {
  content: "";
  position: absolute;
  inset-block-start: 0.125rem;
  inset-inline-start: 0.125rem;
  inline-size: 1.25rem;
  block-size: 1.25rem;
  border-radius: 50%;
  background: #fff;
  transition: transform 150ms ease;
}

.switch__input:checked { background: #0056b3; }
.switch__input:checked::before { transform: translateX(1.25rem); } /* position = state */
.switch__input:focus-visible { outline: 2px solid #0056b3; outline-offset: 2px; }

@media (prefers-reduced-motion: reduce) {
  .switch__input::before { transition: none; }
}
```

### Don't

```html
<!-- DON'T: a div with a sliding knob.
     → Not focusable, no role, no state. A screen reader user has no idea this
       exists, let alone whether it is on. This is the most common switch. -->
<div class="switch" onclick="toggle()">
  <div class="switch__knob"></div>
</div>

<!-- DON'T: role="switch" with no aria-checked.
     → Announced "switch" with no state. The role promises a state that is not
       there. -->
<button type="button" role="switch">Email notifications</button>

<!-- DON'T: aria-pressed as well.
     → Announced "switch, on, pressed". Two state mechanisms on one control.
       role="switch" uses aria-checked. Pick one. -->
<button type="button" role="switch" aria-checked="true" aria-pressed="true">…</button>

<!-- DON'T: aria-checked="mixed" on a switch.
     → Invalid: a switch is binary. Assistive technologies fall back
       unpredictably. If you need three states, use a checkbox. -->
<button type="button" role="switch" aria-checked="mixed">…</button>

<!-- DON'T: label that flips with the state.
     → Announced "Off, switch, off" — then "On, switch, on". The name and the
       state say the same thing twice, and the user cannot tell which is which.
       Name the SETTING. -->
<button type="button" role="switch" aria-checked="false">Off</button>

<!-- DON'T: visually hidden native checkbox + a div doing the work, with the
     input left unlabelled.
     → The focusable thing and the labelled thing are different elements. -->
<input type="checkbox" class="sr-only" id="notify">
<div class="switch" onclick="document.getElementById('notify').click()"></div>
```

```css
/* DON'T: colour as the only difference.
   → The knob never moves; only the track hue changes. For a user who cannot
     distinguish these, the switch has no perceivable state at all — and in
     Windows High Contrast Mode background-color is dropped, so it has none for
     anyone (RAWeb 3.1). */
.switch__track { background: #ccc; }
[aria-checked="true"] .switch__track { background: #4caf50; }
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

export function Switch({ label, defaultChecked = false, onChange }) {
  const [isChecked, setIsChecked] = useState(defaultChecked);
  const labelId = useId();

  const toggle = () => {
    const next = !isChecked;
    setIsChecked(next);
    onChange?.(next);
  };

  return (
    <div className="switch-row">
      <span id={labelId}>{label}</span>
      <button
        type="button"
        role="switch"
        aria-checked={isChecked}
        aria-labelledby={labelId}
        onClick={toggle}
      >
        <span className="switch__track" aria-hidden="true">
          <span className="switch__knob" />
        </span>
      </button>
    </div>
  );
}
```

For a form, prefer the native input — no state, no JS, and it posts a value:

```jsx
<input type="checkbox" role="switch" id={id} name="notify" className="switch__input" />
<label htmlFor={id}>Email notifications</label>
```

### Don't

```jsx
// DON'T: div + onClick.
//     → Not focusable, no role, no state, no keyboard.
<div className="switch" onClick={toggle} data-checked={isChecked} />

// DON'T: aria-checked={isChecked ? 'true' : 'false'} — harmless but pointless;
//        React renders booleans correctly for aria-*. The real bug is below.

// DON'T: state only in a className.
//     → The CSS knows; assistive technologies do not. Two sources of truth,
//       and only one of them is announced.
<button role="switch" className={isChecked ? 'is-on' : 'is-off'} onClick={toggle} />

// DON'T: onChange on a <button>.
//     → Buttons don't fire change. The handler never runs. Use onClick.
<button role="switch" aria-checked={isChecked} onChange={toggle} />
```

---

## Angular

### Do

```ts
import { Component, input, model } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-switch',
  template: `
    <div class="switch-row">
      <span [id]="labelId">{{ label() }}</span>
      <button
        type="button"
        role="switch"
        [attr.aria-checked]="checked()"
        [attr.aria-labelledby]="labelId"
        (click)="toggle()"
      >
        <span class="switch__track" aria-hidden="true">
          <span class="switch__knob"></span>
        </span>
      </button>
    </div>
  `,
})
export class SwitchComponent {
  readonly label = input.required<string>();
  // model() gives two-way binding: [(checked)]="emailNotifications"
  readonly checked = model(false);
  protected readonly labelId = `switch-label-${uid++}`;

  protected toggle(): void {
    this.checked.update((value) => !value);
  }
}
```

### Don't

```html
<!-- DON'T: [attr.aria-checked] omitted, state kept in a class.
     → Announced "switch" with no state. -->
<button type="button" role="switch" [class.is-on]="checked()" (click)="toggle()"></button>

<!-- DON'T: (change) on a button — never fires. Use (click). -->
<button type="button" role="switch" (change)="toggle()"></button>
```

---

## Web Component

### Do

```js
const template = document.createElement('template');
template.innerHTML = `
  <button type="button" part="button" role="switch" aria-checked="false">
    <span class="track" aria-hidden="true"><span class="knob"></span></span>
  </button>
`;

const styles = new CSSStyleSheet();
styles.replaceSync(`
  .track { display:inline-block; inline-size:2.75rem; block-size:1.5rem; border-radius:1rem; background:#767676; }
  .knob { display:block; inline-size:1.25rem; block-size:1.25rem; border-radius:50%; background:#fff;
          transform: translateX(0.125rem); transition: transform 150ms ease; }
  :host([checked]) .track { background:#0056b3; }
  :host([checked]) .knob { transform: translateX(1.375rem); }  /* position = state */
  button:focus-visible { outline: 2px solid #0056b3; outline-offset: 2px; }
  @media (prefers-reduced-motion: reduce) { .knob { transition: none; } }
`);

class A11ySwitch extends HTMLElement {
  static observedAttributes = ['checked', 'label'];
  #button;

  constructor() {
    super();
    const root = this.attachShadow({ mode: 'open' });
    root.adoptedStyleSheets = [styles];
    root.append(template.content.cloneNode(true));
    this.#button = root.querySelector('button');
    this.#button.addEventListener('click', () => this.toggle());
  }

  attributeChangedCallback(name, _old, value) {
    if (name === 'checked') {
      this.#button.setAttribute('aria-checked', String(value !== null));
    }
    if (name === 'label') {
      // The name is TEXT, so it can cross the boundary — copy it in with
      // aria-label. An aria-labelledby IDREF pointing at light DOM could not.
      this.#button.setAttribute('aria-label', value ?? '');
    }
  }

  get checked() { return this.hasAttribute('checked'); }
  set checked(value) { this.toggleAttribute('checked', Boolean(value)); }

  toggle() {
    this.checked = !this.checked;
    this.dispatchEvent(new CustomEvent('change', {
      detail: { checked: this.checked }, bubbles: true, composed: true,
    }));
  }
}

customElements.define('a11y-switch', A11ySwitch);
```

```html
<a11y-switch label="Email notifications"></a11y-switch>
```

### Don't

```js
// DON'T: point the inner button at a light-DOM label.
//     → aria-labelledby is an IDREF and cannot cross the shadow boundary. The
//       switch ends up with NO accessible name, silently. Copy the TEXT in
//       (aria-label, as above) or slot it into the shadow root.
this.#button.setAttribute('aria-labelledby', 'notify-label');

// DON'T: reflect state only to the host.
//     → :host([checked]) styles it correctly and assistive technologies learn
//       nothing. The state must reach the inner button's aria-checked.
set checked(value) { this.toggleAttribute('checked', value); }  // and nothing else
```

---

## Verify

- **Keyboard-only:** Tab to the switch → **Space** toggles it. (Enter is optional
  for `role="switch"`; Space is the one that must work.) Focus ring must be
  visible in both states (RAWeb 10.7).
- **Screen reader:** expect "«setting name», switch, on/off" — the *setting*
  name, not "On". If you hear the state twice, you have `aria-pressed` as well,
  or a label that flips.
- **The RAWeb 3.1 check:** screenshot the switch in both states and desaturate
  it. If on and off are now indistinguishable, the state rests on colour alone.
  Also flip on Windows High Contrast Mode — `background-color` is dropped there,
  so a colour-only switch loses its state entirely.
- **Automated:** axe catches `role="switch"` with no accessible name and invalid
  `aria-checked` values. It does **not** catch a colour-only state, a label that
  flips with the state, or a `<div>` switch — nothing there to flag. Test by hand.
