# Slider (Multi-Thumb) — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show slider-multithumb`

> **Read [`slider.md`](slider.md) first.** Every rule there applies to each thumb
> — including RAWeb 13.10.2 (dragging is a path-based gesture and needs a
> single-point alternative). This file covers only what a second thumb adds.

---

## Universal rules

- **Two overlaid `<input type="range">` beats a div implementation.** You keep
  the native keyboard model, the native value announcement, the native
  track-tap (13.10.2), and two real form values. Almost nobody realises this
  works; it does, and it is far less code than the alternative.
- **Each thumb is its own slider with its OWN name.** "Price" on both is
  useless — a screen reader user hears "Price, slider, 250" twice and cannot
  tell which end they're on. Use **"Minimum price"** and **"Maximum price"**.
  (RAWeb 11.1)
- **Constrain each thumb's range to the other's value.** The min thumb's
  `aria-valuemax` is the max thumb's current value, and vice versa — updated as
  they move. Otherwise the announced range includes values the user cannot
  actually reach.
- **Decide what happens when thumbs meet, and be consistent.** Blocking is
  easier to understand and to announce than swapping.
- **Always provide number inputs alongside.** It is the single-point alternative
  (RAWeb 13.10.2), it's exact, and it's what most people would rather use anyway.

---

## Vanilla

### Do

```html
<fieldset class="range-slider">
  <!-- The legend is the group's question; each thumb gets its own label. -->
  <legend>Price range</legend>

  <div class="range-slider__track">
    <!-- Two real range inputs, overlaid. Each keeps arrows, Home/End,
         Page Up/Down, track-tap, and its own form value. -->
    <label for="price-min" class="sr-only">Minimum price</label>
    <input type="range" id="price-min" name="priceMin"
           min="0" max="1000" step="10" value="200"
           aria-valuetext="€200">

    <label for="price-max" class="sr-only">Maximum price</label>
    <input type="range" id="price-max" name="priceMax"
           min="0" max="1000" step="10" value="800"
           aria-valuetext="€800">
  </div>

  <!-- The single-point alternative, and the better UX for exact values
       (RAWeb 13.10.2). Not a fallback — a first-class path. -->
  <div class="range-slider__inputs">
    <label for="price-min-num">Minimum</label>
    <input type="number" id="price-min-num" min="0" max="1000" step="10" value="200">

    <label for="price-max-num">Maximum</label>
    <input type="number" id="price-max-num" min="0" max="1000" step="10" value="800">
  </div>

  <output for="price-min price-max">€200 – €800</output>
</fieldset>
```

```css
.range-slider__track {
  position: relative;
  block-size: 44px;
}

/* Overlay the two inputs. pointer-events: none on the track, re-enabled on the
   thumbs, so each thumb stays independently grabbable. */
.range-slider__track input[type="range"] {
  position: absolute;
  inset-inline: 0;
  inline-size: 100%;
  margin: 0;
  background: none;
  pointer-events: none;
}

.range-slider__track input[type="range"]::-webkit-slider-thumb {
  pointer-events: auto;
  inline-size: 24px;
  block-size: 24px;
  border-radius: 50%;
  background: #0056b3;
}

.range-slider__track input[type="range"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 4px;
}
```

```js
const minRange = document.getElementById('price-min');
const maxRange = document.getElementById('price-max');
const minNum = document.getElementById('price-min-num');
const maxNum = document.getElementById('price-max-num');
const output = document.querySelector('output');

function sync(source) {
  let min = Number(minRange.value);
  let max = Number(maxRange.value);

  // Block rather than swap: easier to understand, and easier to announce.
  if (min > max) {
    source === 'min' ? (min = max, minRange.value = max) : (max = min, maxRange.value = min);
  }

  // Constrain each thumb's ANNOUNCED range to the other's position. Without
  // this, the min thumb claims a max of 1000 while it can only reach 800.
  minRange.setAttribute('aria-valuemax', String(max));
  maxRange.setAttribute('aria-valuemin', String(min));

  // aria-valuetext: "€200" is comprehensible, "200" is not (RAWeb 7.1).
  minRange.setAttribute('aria-valuetext', `€${min}`);
  maxRange.setAttribute('aria-valuetext', `€${max}`);

  minNum.value = String(min);
  maxNum.value = String(max);
  output.textContent = `€${min} – €${max}`;
}

minRange.addEventListener('input', () => sync('min'));
maxRange.addEventListener('input', () => sync('max'));

// The number inputs drive the sliders — the single-point path.
minNum.addEventListener('change', () => { minRange.value = minNum.value; sync('min'); });
maxNum.addEventListener('change', () => { maxRange.value = maxNum.value; sync('max'); });

sync('min');
```

### Don't

```html
<!-- DON'T: the same label on both thumbs.
     → "Price, slider, 200" then "Price, slider, 800". Which is the minimum?
       The user has to infer it from the numbers (RAWeb 11.1). -->
<label for="price-min" class="sr-only">Price</label>
<input type="range" id="price-min">
<label for="price-max" class="sr-only">Price</label>
<input type="range" id="price-max">

<!-- DON'T: one range input plus a fake second thumb.
     → The fake thumb has no role, no value, no keyboard. Half the control is
       invisible to assistive technologies. -->
<input type="range" id="price-min">
<div class="fake-thumb" style="left: 80%"></div>

<!-- DON'T: sliders with no numeric alternative.
     → For an exact value ("exactly €500") dragging is miserable for everyone,
       and it leaves the path-based gesture as the only pointer route
       (RAWeb 13.10.2). -->
```

```js
// DON'T: leave aria-valuemin/max at the absolute bounds.
//     → The min thumb announces "0 to 1000" while it can physically only reach
//       800. The announced range is a lie.
minRange.setAttribute('aria-valuemax', '1000'); // static

// DON'T: let the thumbs cross with no rule.
//     → The min becomes larger than the max. Your filter now returns nothing,
//       and the announced values are nonsense.
minRange.addEventListener('input', () => filter(minRange.value, maxRange.value));

// DON'T: silently swap the thumbs on crossing.
//     → Focus is now on the thumb that used to be the minimum and is now the
//       maximum. A screen reader user hears the name change under their hands.
//       Block instead.
if (min > max) { [minRange.value, maxRange.value] = [max, min]; }
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

export function PriceRange({ min = 0, max = 1000, step = 10 }) {
  const [range, setRange] = useState({ low: 200, high: 800 });
  const id = useId();

  const setLow = (value) => setRange((r) => ({ ...r, low: Math.min(value, r.high) }));
  const setHigh = (value) => setRange((r) => ({ ...r, high: Math.max(value, r.low) }));

  return (
    <fieldset>
      <legend>Price range</legend>

      <div className="range-slider__track">
        <label htmlFor={`${id}-low`} className="sr-only">Minimum price</label>
        <input
          type="range" id={`${id}-low`}
          min={min} max={max} step={step}
          value={range.low}
          // Constrain the ANNOUNCED range to where the thumb can actually go.
          aria-valuemax={range.high}
          aria-valuetext={`€${range.low}`}
          onChange={(e) => setLow(Number(e.target.value))}
        />

        <label htmlFor={`${id}-high`} className="sr-only">Maximum price</label>
        <input
          type="range" id={`${id}-high`}
          min={min} max={max} step={step}
          value={range.high}
          aria-valuemin={range.low}
          aria-valuetext={`€${range.high}`}
          onChange={(e) => setHigh(Number(e.target.value))}
        />
      </div>

      {/* The single-point alternative (RAWeb 13.10.2). */}
      <label htmlFor={`${id}-low-num`}>Minimum</label>
      <input type="number" id={`${id}-low-num`} value={range.low}
             onChange={(e) => setLow(Number(e.target.value))} />

      <label htmlFor={`${id}-high-num`}>Maximum</label>
      <input type="number" id={`${id}-high-num`} value={range.high}
             onChange={(e) => setHigh(Number(e.target.value))} />

      <output>€{range.low} – €{range.high}</output>
    </fieldset>
  );
}
```

### Don't

```jsx
// DON'T: reach for a drag-only range library.
//     → Most popular range-slider libraries are div-based, drag-only, and fail
//       RAWeb 13.10.2 out of the box. Check for a track-tap and full keyboard
//       support BEFORE adopting one — two overlaid <input type="range"> is
//       usually less work than fixing a library.

// DON'T: one piece of state per thumb, updated independently.
//     → Nothing enforces low <= high. Derive both from one object, as above.
const [low, setLow] = useState(200);
const [high, setHigh] = useState(800);
```

---

## Angular

### Do

```ts
import { Component, computed, signal } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-price-range',
  template: `
    <fieldset>
      <legend>Price range</legend>

      <div class="range-slider__track">
        <label [for]="id + '-low'" class="sr-only">Minimum price</label>
        <input
          type="range" [id]="id + '-low'"
          [min]="min" [max]="max" [step]="step"
          [value]="low()"
          [attr.aria-valuemax]="high()"
          [attr.aria-valuetext]="'€' + low()"
          (input)="setLow($event)"
        >

        <label [for]="id + '-high'" class="sr-only">Maximum price</label>
        <input
          type="range" [id]="id + '-high'"
          [min]="min" [max]="max" [step]="step"
          [value]="high()"
          [attr.aria-valuemin]="low()"
          [attr.aria-valuetext]="'€' + high()"
          (input)="setHigh($event)"
        >
      </div>

      <label [for]="id + '-low-num'">Minimum</label>
      <input type="number" [id]="id + '-low-num'" [value]="low()" (change)="setLow($event)">

      <label [for]="id + '-high-num'">Maximum</label>
      <input type="number" [id]="id + '-high-num'" [value]="high()" (change)="setHigh($event)">

      <output>{{ '€' + low() + ' – €' + high() }}</output>
    </fieldset>
  `,
})
export class PriceRangeComponent {
  protected readonly min = 0;
  protected readonly max = 1000;
  protected readonly step = 10;
  protected readonly id = `range-${uid++}`;

  protected readonly low = signal(200);
  protected readonly high = signal(800);

  protected setLow(event: Event): void {
    const value = Number((event.target as HTMLInputElement).value);
    this.low.set(Math.min(value, this.high()));
  }

  protected setHigh(event: Event): void {
    const value = Number((event.target as HTMLInputElement).value);
    this.high.set(Math.max(value, this.low()));
  }
}
```

### Don't

```html
<!-- DON'T: [attr.value] — sets the default-value attribute, not the property.
     The thumb stops tracking state after the first interaction. -->
<input type="range" [attr.value]="low()">
```

---

## Web Component

See [`slider.md`](slider.md) — the component is the same, twice. The only
additions:

```js
// Two inputs, two names, cross-constrained bounds.
root.innerHTML = `
  <input type="range" part="low" aria-label="Minimum price">
  <input type="range" part="high" aria-label="Maximum price">
`;
```

The names come in as **text** via `aria-label`, because `aria-labelledby` is an
IDREF and cannot reach a light-DOM `<label>`. And `formAssociated` needs
`setFormValue` with a `FormData` to submit **two** values from one element:

```js
static formAssociated = true;

#commit() {
  const data = new FormData();
  data.append(`${this.name}Min`, this.#low.value);
  data.append(`${this.name}Max`, this.#high.value);
  this.#internals.setFormValue(data);   // FormData, not a string, for 2 values
}
```

### Don't

```js
// DON'T: setFormValue with a single string for a two-value control.
//     → Only one value reaches the form. Pass FormData.
this.#internals.setFormValue(`${this.#low.value},${this.#high.value}`);
```

---

## Verify

- **The naming check — the one that matters here.** With a screen reader, focus
  each thumb. You must hear **"Minimum price"** and **"Maximum price"**, not
  "Price" twice. If both say the same thing, the control is unusable without
  sight.
- **The bounds check:** put the max thumb at €800, then focus the min thumb and
  press **End**. It must stop at 800 and announce a max of 800 — not claim 1000.
- **RAWeb 13.10.2:** set the range using **only single taps** — on the track, or
  via the number inputs. No dragging. If that's impossible, it fails.
- **Crossing check:** drive both thumbs to the same value with arrows. Nothing
  should swap under the user's focus.
- **Keyboard:** each thumb independently reachable by Tab, each with full
  arrows/Home/End/Page Up/Down.
- **Automated:** axe catches unlabelled inputs. It cannot tell that two sliders
  share one meaningless name, that the bounds lie, or that the only pointer path
  is a drag.
