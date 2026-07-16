# Spinbutton — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show spinbutton`

---

## Is `<input type="number">` even right?

This is the first question, and it's usually answered wrong.

`type="number"` is for **quantities you'd do arithmetic on** — a basket count, a
price, an age. It is **not** for digit *strings*:

| Field | Element |
|---|---|
| Quantity, age, price, rating | `<input type="number">` |
| Phone number | `<input type="tel">` |
| Credit card, postcode, PIN, OTP, IBAN, invoice number | `<input type="text" inputmode="numeric">` |

**Why it matters for digit strings:**

- **Leading zeros are lost.** A Luxembourg postcode `L-1234`, or any `0`-prefixed
  reference, is silently mangled.
- **The scroll wheel changes the value.** Focus the field, scroll the page, and
  the quantity silently changes. This is a real data-integrity bug, not a
  nitpick.
- **Non-numeric input is discarded silently** in some browsers — `e`, `+` and `-`
  are accepted (they're valid in numbers), while other characters vanish with no
  feedback.
- **Spinner arrows are far below any sane target size**, and meaningless for a
  card number anyway.

`inputmode="numeric"` gets you the numeric keypad on mobile — the actual thing
people want from `type="number"` — without any of the above.

---

## Universal rules

- **Use `<input type="number">` for genuine quantities.** Up/Down arrows, the
  value announcement, and the form value are free. (RAWeb 7.3)
- **Kill the wheel.** A focused number field that changes when the page scrolls
  is a silent data corruption path.
- **It needs a real `<label for>`.** (RAWeb 11.1)
- **Custom +/- buttons need names** ("Increase quantity"), and should be
  `tabindex="-1"` — the input already handles keyboard, and 3 fields shouldn't
  cost 9 Tab stops.
- **Announce clamping.** (RAWeb 11.10) If the user types 999 and the max is 10,
  silently rewriting to 10 is baffling. Say so.
- **`role="spinbutton"` on a div means you owe `aria-valuenow`/`min`/`max`,
  arrows, and typing.** `<input type="number">` has all of it already.

---

## Vanilla

### Do — a quantity

```html
<div class="quantity">
  <label for="qty">Quantity</label>

  <!-- tabindex="-1": the input handles Up/Down already. These are pointer
       affordances, not extra Tab stops. -->
  <button type="button" id="qty-down" tabindex="-1" aria-hidden="true">−</button>

  <input type="number" id="qty" name="qty"
         min="1" max="10" step="1" value="1"
         inputmode="numeric"
         aria-describedby="qty-help">

  <button type="button" id="qty-up" tabindex="-1" aria-hidden="true">+</button>

  <p id="qty-help">Maximum 10 per order.</p>
</div>

<!-- Clamping is announced here (RAWeb 11.10), not silently applied. -->
<div id="qty-status" role="status" aria-live="polite" class="sr-only"></div>
```

`aria-hidden="true"` + `tabindex="-1"` on the +/- buttons is deliberate: they
duplicate what Up/Down already do on the input, so exposing them to a screen
reader adds two announcements for zero new capability. Keyboard and screen
reader users use the input; pointer users get the buttons.

```css
/* The spinners are tiny and inconsistent across browsers — hide them and use
   your own buttons at a real target size (RAWeb 3.3). */
input[type="number"] {
  appearance: textfield;
  inline-size: 4rem;
  text-align: center;
}
input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  appearance: none;
  margin: 0;
}

.quantity button {
  min-inline-size: 44px;
  min-block-size: 44px;
}

input[type="number"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

```js
const qty = document.getElementById('qty');
const status = document.getElementById('qty-status');
const MIN = 1, MAX = 10;

// THE fix people forget. Without this, focusing the field and scrolling the
// page silently changes the quantity — the user orders 7 mattresses.
qty.addEventListener('wheel', (event) => {
  if (document.activeElement === qty) event.preventDefault();
}, { passive: false });

function clampAndAnnounce() {
  const raw = Number(qty.value);
  if (Number.isNaN(raw) || qty.value === '') return;

  const clamped = Math.min(MAX, Math.max(MIN, raw));
  if (clamped === raw) return;

  qty.value = String(clamped);
  // RAWeb 11.10 — do not silently rewrite the user's input.
  status.textContent = `Quantity adjusted to ${clamped}. Maximum ${MAX} per order.`;
}

qty.addEventListener('change', clampAndAnnounce);

// The +/- buttons dispatch a real `input` event so any listener sees the change.
const step = (delta) => {
  delta > 0 ? qty.stepUp() : qty.stepDown();
  qty.dispatchEvent(new Event('input', { bubbles: true }));
};
document.getElementById('qty-up').addEventListener('click', () => step(1));
document.getElementById('qty-down').addEventListener('click', () => step(-1));
```

`stepUp()`/`stepDown()` respect `min`, `max` and `step` automatically — don't
reimplement the arithmetic.

### Do — a digit string, which is not a spinbutton

```html
<!-- Not type="number": a postcode is not a quantity. inputmode gives the
     numeric keypad without the wheel bug or the leading-zero loss. -->
<label for="postcode">Postcode</label>
<input type="text" id="postcode" name="postcode"
       inputmode="numeric" pattern="[0-9]{4}"
       autocomplete="postal-code"
       aria-describedby="postcode-help">
<p id="postcode-help">4 digits, for example 1234.</p>
```

### Don't

```html
<!-- DON'T: type="number" for a card number.
     → Leading zeros lost, wheel changes it, spinner arrows on a card number are
       nonsense, and it is not a quantity. -->
<input type="number" id="card" name="card" autocomplete="cc-number">

<!-- DON'T: type="number" for a phone number.
     → "+352" is not a number. Use type="tel". -->
<input type="number" id="phone" name="phone">

<!-- DON'T: an unlabelled spinbutton (RAWeb 11.1).
     → "spin button, 1" — of what? -->
<input type="number" min="1" max="10" value="1">

<!-- DON'T: +/- buttons with no name, exposed to AT.
     → Announced "minus, button" / "plus, button" — and they duplicate the
       arrows the input already provides. Either name them properly, or hide
       them from AT as above. -->
<button type="button">−</button>
<input type="number" id="qty">
<button type="button">+</button>

<!-- DON'T: div spinbutton.
     → No value, no arrows, no typing, no form value. -->
<div role="spinbutton" aria-valuenow="1">
  <span>1</span>
</div>

<!-- DON'T: role="spinbutton" with no aria-valuenow.
     → The role promises a value and there is none. -->
<div role="spinbutton" tabindex="0" aria-labelledby="qty-label"></div>

<!-- DON'T: readonly input with only +/- buttons.
     → Typing "7" is faster than pressing + six times. Keyboard users lose the
       quickest route to a value for no benefit. -->
<input type="number" id="qty" value="1" readonly>
```

```js
// DON'T: leave the wheel enabled.
//     → Focus the quantity, scroll the page, silently order 7 of something.
//       This is the single worst type="number" bug and it ships constantly.

// DON'T: clamp silently (RAWeb 11.10).
//     → The user types 999 and it becomes 10 with no explanation. Nothing tells
//       them why, and a screen reader user never learns it changed at all.
qty.addEventListener('change', () => {
  qty.value = Math.min(10, Number(qty.value));
});

// DON'T: reimplement stepping arithmetic.
//     → stepUp()/stepDown() already respect min/max/step, including decimal
//       steps where floating-point maths will bite you.
qty.value = Number(qty.value) + 1;

// DON'T: block non-digits with keydown.
//     → Breaks paste, Backspace, Tab, arrows, and every screen reader
//       passthrough key. Validate on input/change instead.
qty.addEventListener('keydown', (e) => {
  if (!/[0-9]/.test(e.key)) e.preventDefault();
});
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef, useState } from 'react';

export function QuantityInput({ label = 'Quantity', min = 1, max = 10 }) {
  const [value, setValue] = useState(1);
  const [message, setMessage] = useState('');
  const ref = useRef(null);
  const id = useId();

  // Must be a native listener: React's onWheel is passive, so preventDefault()
  // inside it does nothing. This is a real React-specific trap.
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const onWheel = (e) => { if (document.activeElement === el) e.preventDefault(); };
    el.addEventListener('wheel', onWheel, { passive: false });
    return () => el.removeEventListener('wheel', onWheel);
  }, []);

  const commit = () => {
    const clamped = Math.min(max, Math.max(min, value));
    if (clamped !== value) {
      setValue(clamped);
      setMessage(`Quantity adjusted to ${clamped}. Maximum ${max} per order.`);
    } else {
      setMessage('');
    }
  };

  return (
    <div className="quantity">
      <label htmlFor={id}>{label}</label>
      <button type="button" tabIndex={-1} aria-hidden="true"
              onClick={() => setValue((v) => Math.max(min, v - 1))}>−</button>
      <input
        ref={ref}
        type="number"
        id={id}
        inputMode="numeric"
        min={min}
        max={max}
        value={value}
        onChange={(e) => setValue(Number(e.target.value))}
        onBlur={commit}
      />
      <button type="button" tabIndex={-1} aria-hidden="true"
              onClick={() => setValue((v) => Math.min(max, v + 1))}>+</button>

      {/* Always mounted, empty when idle — see alert.md. */}
      <div role="status" aria-live="polite" className="sr-only">{message}</div>
    </div>
  );
}
```

### Don't

```jsx
// DON'T: onWheel={(e) => e.preventDefault()}.
//     → React attaches wheel listeners PASSIVELY. preventDefault() is a no-op
//       and the console warns. Use a ref + addEventListener with
//       { passive: false }.
<input type="number" onWheel={(e) => e.preventDefault()} />

// DON'T: type="number" with a string value.
//     → value={value} where value is "007" renders "7". Leading zeros gone.

// DON'T: clamp inside onChange.
//     → The user cannot type "10" because typing "1" clamps to min instantly,
//       then "0" makes "10"... maybe. Clamp on blur, not on every keystroke.
onChange={(e) => setValue(Math.min(max, Number(e.target.value)))}
```

That last one is subtle and very common: clamping per-keystroke makes multi-digit
entry impossible in ranges where an intermediate value is out of bounds.

---

## Angular

### Do

```ts
import { Component, ElementRef, input, model, signal, viewChild, afterNextRender } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-quantity',
  template: `
    <div class="quantity">
      <label [for]="id">{{ label() }}</label>
      <button type="button" [tabIndex]="-1" aria-hidden="true" (click)="step(-1)">−</button>
      <input
        #input
        type="number"
        [id]="id"
        inputmode="numeric"
        [min]="min()" [max]="max()"
        [value]="value()"
        (input)="value.set(+$any($event.target).value)"
        (blur)="commit()"
      >
      <button type="button" [tabIndex]="-1" aria-hidden="true" (click)="step(1)">+</button>

      <div role="status" aria-live="polite" class="sr-only">{{ message() }}</div>
    </div>
  `,
})
export class QuantityComponent {
  readonly label = input('Quantity');
  readonly min = input(1);
  readonly max = input(10);
  readonly value = model(1);

  protected readonly id = `qty-${uid++}`;
  protected readonly message = signal('');
  private readonly input = viewChild.required<ElementRef<HTMLInputElement>>('input');

  constructor() {
    afterNextRender(() => {
      // (wheel) in the template is passive in Angular too — bind natively.
      this.input().nativeElement.addEventListener('wheel', (e) => {
        if (document.activeElement === this.input().nativeElement) e.preventDefault();
      }, { passive: false });
    });
  }

  protected step(delta: number): void {
    const el = this.input().nativeElement;
    delta > 0 ? el.stepUp() : el.stepDown();
    this.value.set(Number(el.value));
  }

  protected commit(): void {
    const clamped = Math.min(this.max(), Math.max(this.min(), this.value()));
    if (clamped !== this.value()) {
      this.value.set(clamped);
      this.message.set(`Quantity adjusted to ${clamped}. Maximum ${this.max()} per order.`);
    } else {
      this.message.set('');
    }
  }
}
```

### Don't

```html
<!-- DON'T: (wheel)="$event.preventDefault()" — Angular binds wheel passively
     by default; the call is a no-op. Bind natively with { passive: false }. -->
<input type="number" (wheel)="$event.preventDefault()">

<!-- DON'T: [attr.value] — default-value attribute, not the live property. -->
<input type="number" [attr.value]="value()">
```

---

## Web Component

### Do

```js
// Wrap a real <input type="number">: it keeps arrows, stepping, validation and
// the form value.
class A11ySpinbutton extends HTMLElement {
  static formAssociated = true;
  #internals;
  #input;

  constructor() {
    super();
    this.#internals = this.attachInternals();
    const root = this.attachShadow({ mode: 'open', delegatesFocus: true });
    root.innerHTML = `
      <button type="button" tabindex="-1" aria-hidden="true" part="down">−</button>
      <input type="number" inputmode="numeric" part="input">
      <button type="button" tabindex="-1" aria-hidden="true" part="up">+</button>
    `;
    this.#input = root.querySelector('input');

    root.querySelector('[part="up"]').addEventListener('click', () => this.#step(1));
    root.querySelector('[part="down"]').addEventListener('click', () => this.#step(-1));

    this.#input.addEventListener('wheel', (e) => {
      if (this.#input === this.shadowRoot.activeElement) e.preventDefault();
    }, { passive: false });

    this.#input.addEventListener('input', () => {
      this.#internals.setFormValue(this.#input.value);
    });
  }

  connectedCallback() {
    // Name as TEXT — aria-labelledby is an IDREF and cannot cross the boundary.
    this.#input.setAttribute('aria-label', this.getAttribute('label') ?? '');
    this.#input.min = this.getAttribute('min') ?? '';
    this.#input.max = this.getAttribute('max') ?? '';
  }

  #step(delta) {
    delta > 0 ? this.#input.stepUp() : this.#input.stepDown();
    this.#input.dispatchEvent(new Event('input', { bubbles: true }));
  }
}

customElements.define('a11y-spinbutton', A11ySpinbutton);
```

Note `this.shadowRoot.activeElement` rather than `document.activeElement`: from
outside, `document.activeElement` returns the **host**, not the inner input.

### Don't

```js
// DON'T: document.activeElement to test focus inside a shadow root.
//     → Returns the HOST element, never the inner input. The comparison is
//       always false and the wheel guard silently never fires.
if (document.activeElement === this.#input) e.preventDefault();

// DON'T: a div spinbutton in a shadow root.
//     → No arrows, no typing, no form value, no validation.
```

---

## Verify

- **The wheel check — do this first.** Focus the field, then scroll the page with
  the mouse. If the value changes, you have a silent data-corruption bug.
- **The element check:** is it a *quantity*? If it's a card number, postcode,
  phone or PIN, `type="number"` is wrong. Type `007` — if it becomes `7`, that
  proves it.
- **Keyboard-only:** Up/Down step the value; typing a multi-digit number works
  (if `10` is impossible to type, you're clamping on every keystroke). Tab must
  not stop on the +/- buttons.
- **The clamping check (RAWeb 11.10):** type 999 with a max of 10. Something must
  *tell* you it was changed — visually and via a live region.
- **Screen reader:** expect "«label», spin button, 1". If you also hear "plus,
  button" / "minus, button", they're exposed and duplicating the arrows.
- **Automated:** axe catches an unlabelled input and `role="spinbutton"` with no
  `aria-valuenow`. It catches **nothing** about the wheel bug, `type="number"` on
  a card number, or silent clamping — all three are manual, and all three ship.
