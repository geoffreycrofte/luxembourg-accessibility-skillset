# Radio Group — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show radio`

> Read [`checkbox.md`](checkbox.md) alongside this: the labelling and
> `fieldset`/`legend` rules are identical. What radios add is **grouping
> behaviour** — and that is exactly what people rebuild badly.

---

## Universal rules

- **`<input type="radio">` with a shared `name`.** The shared `name` is what
  makes them a group. The browser then gives you — free — mutual exclusion, a
  single Tab stop, arrow-key navigation, and wrapping. Those are the hard parts,
  and they are the first casualties of a `<div>` implementation. (RAWeb 7.3)
- **A radio group is ONE Tab stop.** Tab enters on the checked option (or the
  first, if none is checked); **arrows** move within the group; Tab leaves. This
  surprises people — they expect Tab to visit each option. It shouldn't.
- **`<fieldset>` + `<legend>` is mandatory.** The legend is the *question*; the
  labels are the *answers*. Without it, "Standard delivery, radio button, 1 of 3"
  is announced with no idea what is being chosen. (RAWeb 11.5)
- **Radios cannot be unchecked by the user.** Once one is picked, there is no way
  back to "nothing selected". If "none" is a valid answer, give an explicit
  **"No preference"** option. If several answers can coexist, use
  [`checkbox`](checkbox.md).
- **Each label must stand alone.** (RAWeb 11.2) "Option 1" tells a screen reader
  user nothing.
- **`role="radiogroup"` + `role="radio"` only if a native input truly can't
  work.** You then owe the arrows, the roving tabindex, and the exclusion logic
  yourself — all things you had for free.

---

## Vanilla

### Do

```html
<!-- The shared name="delivery" IS the group. The browser handles exclusion,
     arrows, wrapping, and the single Tab stop. -->
<fieldset>
  <legend>Delivery method</legend>

  <div class="field">
    <input type="radio" id="delivery-standard" name="delivery" value="standard" checked>
    <label for="delivery-standard">Standard — 3 to 5 days, free</label>
  </div>

  <div class="field">
    <input type="radio" id="delivery-express" name="delivery" value="express">
    <label for="delivery-express">Express — next day, €4.90</label>
  </div>

  <div class="field">
    <input type="radio" id="delivery-pickup" name="delivery" value="pickup">
    <label for="delivery-pickup">Collect in store — free</label>
  </div>
</fieldset>

<!-- If "none" is valid, say so explicitly — the user cannot un-pick a radio. -->
<fieldset>
  <legend>Newsletter frequency</legend>
  <div class="field">
    <input type="radio" id="freq-none" name="freq" value="none" checked>
    <label for="freq-none">Don't send me anything</label>
  </div>
  <div class="field">
    <input type="radio" id="freq-weekly" name="freq" value="weekly">
    <label for="freq-weekly">Weekly</label>
  </div>
</fieldset>
```

```css
/* Style the real input — same approach as checkbox.md. */
input[type="radio"] {
  appearance: none;
  inline-size: 1.25rem;
  block-size: 1.25rem;
  border: 2px solid #767676;  /* ≥3:1 (RAWeb 3.3) */
  border-radius: 50%;
  display: inline-grid;
  place-content: center;
}

input[type="radio"]::before {
  content: "";
  inline-size: 0.65rem;
  block-size: 0.65rem;
  border-radius: 50%;
  transform: scale(0);
  background: #0056b3;
}

/* The inner dot APPEARS — a shape change, not only a colour change (RAWeb 3.1). */
input[type="radio"]:checked::before { transform: scale(1); }

input[type="radio"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

@media (forced-colors: active) {
  input[type="radio"]::before { background: Highlight; }
}
```

No JavaScript. That's the point.

### Don't

```html
<!-- DON'T: different `name` per radio.
     → They are no longer a group: every one is independently checkable, all can
       be on at once, arrows do nothing, and each is its own Tab stop. The
       control looks right and behaves like broken checkboxes. -->
<input type="radio" id="r1" name="standard" value="standard">
<input type="radio" id="r2" name="express" value="express">

<!-- DON'T: no fieldset/legend (RAWeb 11.5).
     → "Standard, radio button, 1 of 3" — one of three WHAT? -->
<h3>Delivery method</h3>
<input type="radio" id="r1" name="delivery"><label for="r1">Standard</label>
<input type="radio" id="r2" name="delivery"><label for="r2">Express</label>

<!-- DON'T: div radios.
     → You lose exclusion, arrows, wrapping, the single Tab stop, and the form
       value — every hard part — and must rebuild them all by hand. -->
<div role="radiogroup">
  <div role="radio" aria-checked="true" tabindex="0">Standard</div>
  <div role="radio" aria-checked="false" tabindex="0">Express</div>
</div>

<!-- DON'T: tabindex="0" on every radio in a role="radiogroup".
     → Even the ARIA version is one Tab stop: 0 on the checked option, -1 on the
       rest. This makes each option its own stop. -->
<div role="radio" aria-checked="false" tabindex="0">Express</div>

<!-- DON'T: meaningless labels (RAWeb 11.2).
     → Announced out of context, these carry no information. -->
<label for="r1">Option 1</label>
<label for="r2">Option 2</label>

<!-- DON'T: radios where checkboxes belong.
     → If more than one answer can be true, radios make it unanswerable — and
       the user cannot even clear their first pick. -->
<fieldset>
  <legend>Which languages do you speak?</legend>
  <input type="radio" name="lang" id="fr"><label for="fr">French</label>
  <input type="radio" name="lang" id="de"><label for="de">German</label>
</fieldset>

<!-- DON'T: a radio group with no default and no "none" option.
     → The user can never return to "unanswered" after touching it. If blank is
       valid, add an explicit option for it. -->
```

```js
// DON'T: rebuild exclusion by hand on native radios.
//     → The browser already does this, correctly, via the shared name. This
//       fights it and introduces races.
radios.forEach((r) => r.addEventListener('change', () => {
  radios.forEach((other) => { other.checked = other === r; });
}));
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

const DELIVERY = [
  { value: 'standard', label: 'Standard — 3 to 5 days, free' },
  { value: 'express', label: 'Express — next day, €4.90' },
  { value: 'pickup', label: 'Collect in store — free' },
];

export function DeliveryPicker() {
  const [delivery, setDelivery] = useState('standard');
  const name = useId(); // unique per instance — two pickers on a page must not merge

  return (
    <fieldset>
      <legend>Delivery method</legend>
      {DELIVERY.map((option) => {
        const id = `${name}-${option.value}`;
        return (
          <div className="field" key={option.value}>
            <input
              type="radio"
              id={id}
              name={name}
              value={option.value}
              checked={delivery === option.value}
              onChange={(e) => setDelivery(e.target.value)}
            />
            <label htmlFor={id}>{option.label}</label>
          </div>
        );
      })}
    </fieldset>
  );
}
```

The `name` comes from `useId()` deliberately: a hardcoded `name="delivery"` means
two `<DeliveryPicker>`s on one page silently become **one** radio group, and
choosing in the second clears the first.

### Don't

```jsx
// DON'T: a hardcoded name in a reusable component.
//     → Two instances on a page merge into one group. Selecting in one clears
//       the other. Nothing errors; it just behaves inexplicably.
<input type="radio" name="delivery" value={option.value} />

// DON'T: no fieldset/legend (RAWeb 11.5).
<div className="group-label">Delivery method</div>

// DON'T: checked without onChange — React makes it read-only.
<input type="radio" checked={delivery === option.value} />

// DON'T: onClick instead of onChange.
//     → Does not fire when the selection changes via ARROW KEYS, which is the
//       primary way keyboard users move through a radio group. The state
//       silently desyncs from the DOM.
<input type="radio" onClick={() => setDelivery(option.value)} />
```

That last one is worth dwelling on: it works perfectly with a mouse and fails
only for keyboard users, so it survives testing and ships.

---

## Angular

### Do

```ts
import { Component, model } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-delivery-picker',
  template: `
    <fieldset>
      <legend>Delivery method</legend>
      @for (option of options; track option.value) {
        <div class="field">
          <input
            type="radio"
            [id]="name + '-' + option.value"
            [name]="name"
            [value]="option.value"
            [checked]="delivery() === option.value"
            (change)="delivery.set(option.value)"
          >
          <label [for]="name + '-' + option.value">{{ option.label }}</label>
        </div>
      }
    </fieldset>
  `,
})
export class DeliveryPickerComponent {
  readonly delivery = model('standard');
  // Unique per instance, for the same reason as React's useId().
  protected readonly name = `delivery-${uid++}`;
  protected readonly options = [
    { value: 'standard', label: 'Standard — 3 to 5 days, free' },
    { value: 'express', label: 'Express — next day, €4.90' },
  ];
}
```

### Don't

```html
<!-- DON'T: [attr.checked] — sets the default-checked ATTRIBUTE, not the live
     property. The group stops reflecting state after the first interaction. -->
<input type="radio" [attr.checked]="delivery() === option.value">

<!-- DON'T: a fixed name in a reusable component — two instances merge. -->
<input type="radio" name="delivery" [value]="option.value">

<!-- DON'T: (click) instead of (change) — misses arrow-key selection. -->
<input type="radio" (click)="delivery.set(option.value)">
```

---

## Web Component

### Do

**Don't.** This is the pattern where a custom element costs the most and gains
the least:

- The shared `name` grouping **does not work across shadow boundaries** — radios
  in separate shadow roots are separate groups, so mutual exclusion breaks.
- Each `<a11y-radio>` in its own shadow root means the browser's arrow-key
  navigation, wrapping, and single-Tab-stop behaviour are all gone.
- `<label for>` cannot cross the boundary.

You would be reimplementing everything native radios do, and the failure is
**silent**: they look right and behave like independent checkboxes.

If you must ship a design-system radio group, put the whole group in **one**
component with the inputs in the **light DOM**:

```js
// Light DOM: the browser's native grouping keeps working untouched.
class A11yRadioGroup extends HTMLElement {
  connectedCallback() {
    this.addEventListener('change', (event) => {
      if (event.target.type !== 'radio') return;
      this.dispatchEvent(new CustomEvent('value-change', {
        detail: { value: event.target.value }, bubbles: true, composed: true,
      }));
    });
  }

  get value() {
    return this.querySelector('input[type="radio"]:checked')?.value ?? null;
  }
}

customElements.define('a11y-radio-group', A11yRadioGroup);
```

```html
<a11y-radio-group>
  <fieldset>
    <legend>Delivery method</legend>
    <div class="field">
      <input type="radio" id="d1" name="delivery" value="standard" checked>
      <label for="d1">Standard</label>
    </div>
    <div class="field">
      <input type="radio" id="d2" name="delivery" value="express">
      <label for="d2">Express</label>
    </div>
  </fieldset>
</a11y-radio-group>
```

### Don't

```js
// DON'T: one custom element per radio, each with its own shadow root.
//     → The shared `name` does not group across shadow boundaries. Every radio
//       becomes its own group: all of them can be selected at once, arrows do
//       nothing, and each is a separate Tab stop. It looks perfect and behaves
//       like broken checkboxes.
class A11yRadio extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' }).innerHTML = `<input type="radio" name="${this.getAttribute('name')}">`;
  }
}
// <a11y-radio name="delivery" value="standard"></a11y-radio>
// <a11y-radio name="delivery" value="express"></a11y-radio>   ← NOT a group
```

---

## Verify

- **The grouping check, and it's the important one:** Tab into the group. It must
  be **one** Tab stop. Then press **arrow keys** — the selection must move and
  wrap. If Tab visits every option, or arrows do nothing, they aren't grouped:
  usually a mismatched `name` or a shadow boundary between them.
- **The RAWeb 11.5 check:** with a screen reader, focus an option. You must hear
  the **legend** — "Delivery method: Standard, radio button, 1 of 3". Just
  "Standard, radio button" means no legend.
- **Arrow-key state check:** change the selection with arrows only, then read
  your app state. If it didn't update, you bound `click` instead of `change` —
  a mouse-only bug that passes every mouse test.
- **The "none" check:** can the user get back to no answer? If not, and blank is
  valid, add an explicit option.
- **Automated:** axe catches unlabelled radios and duplicate ids. It does **not**
  catch a missing legend, a mismatched `name`, or `click`-instead-of-`change`.
  All three are manual.
