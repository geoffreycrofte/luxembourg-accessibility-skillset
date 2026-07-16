# Slider — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show slider`

> **RAWeb 13.10 test 2 is the criterion people miss here**, because everyone
> reads 13.10 as "pinch gestures". It is not:
> `scripts/raweb-lookup.sh methodology 13.10.2`.

---

## Universal rules

- **`<input type="range">`.** Arrows, Home/End, Page Up/Down, the value
  announcement, the form value — and **click-anywhere-on-the-track**, which is
  what passes 13.10.2. All free.
- **Dragging is a path-based gesture (RAWeb 13.10, test 2).** The value must
  *also* be settable with a single-point operation — tapping the track. A custom
  slider that only responds to drag **fails**. Native range passes without you
  doing anything, which is the strongest argument for it.
- **A slider needs a real `<label for>`.** The value is not the label.
  (RAWeb 11.1)
- **`aria-valuetext` replaces the announced number.** Use it whenever the raw
  number isn't self-explanatory: `aria-valuenow="2"` announces "2";
  `aria-valuetext="Medium"` announces "Medium".
- **Commit on pointer *up*, not down.** So the user can drag away to abort.
  (RAWeb 13.11)
- **Only the thumb is focusable.** Never `tabindex` the track. With
  `<input type="range">`, the input *is* the thumb.
- **Vertical sliders: use `writing-mode`, not `rotate()`.** A rotated slider
  keeps horizontal arrow semantics, so Right-arrow moves the thumb *up* — the
  visual and the keyboard model contradict each other.

---

## Vanilla

### Do

```html
<div class="slider-row">
  <label for="volume">Volume</label>
  <input type="range" id="volume" name="volume"
         min="0" max="100" step="1" value="50"
         aria-describedby="volume-output">
  <!-- The visible value is a separate element. The input cannot both be
       labelled "Volume" and announce its own value from the same text. -->
  <output id="volume-output" for="volume">50%</output>
</div>
```

```html
<!-- Non-numeric scale: aria-valuetext carries meaning the number cannot.
     Announced as "Medium", not "2". -->
<div class="slider-row">
  <label for="spice">Spice level</label>
  <input type="range" id="spice" name="spice"
         min="1" max="4" step="1" value="2"
         aria-valuetext="Medium">
  <output id="spice-output" for="spice">Medium</output>
</div>
```

```css
input[type="range"] {
  inline-size: 100%;
  /* A generous hit area: the track must be tappable, since tapping it is what
     satisfies RAWeb 13.10.2. A 2px-tall track is technically compliant and
     practically unusable. */
  block-size: 44px;
}

input[type="range"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

/* Thumb needs ≥3:1 against the track, and the track ≥3:1 against the page
   (RAWeb 3.3). */
input[type="range"]::-webkit-slider-thumb {
  inline-size: 24px;
  block-size: 24px;
  background: #0056b3;
  border-radius: 50%;
}

/* Vertical: writing-mode keeps the arrow-key semantics matching the visual.
   A transform: rotate(-90deg) does NOT — Right would still increase, moving
   the thumb upward, which nobody expects. */
input[type="range"].vertical {
  writing-mode: vertical-rl;
  direction: rtl;         /* so "up" is the high end
                             (older engines: appearance: slider-vertical) */
  block-size: 12rem;
  inline-size: 44px;
}

@media (forced-colors: active) {
  input[type="range"]::-webkit-slider-thumb { forced-color-adjust: none; background: Highlight; }
}
```

```js
const volume = document.getElementById('volume');
const output = document.getElementById('volume-output');

// `input` fires continuously while dragging AND on every arrow key.
volume.addEventListener('input', () => {
  output.textContent = `${volume.value}%`;
});

// `change` fires on commit — pointer release, or blur after keyboard changes.
// Do expensive/irreversible work here, not on every `input` (RAWeb 13.11).
volume.addEventListener('change', () => {
  savePreference({ volume: Number(volume.value) });
});

// Non-numeric scale: keep aria-valuetext in sync with the value.
const SPICE = { 1: 'Mild', 2: 'Medium', 3: 'Hot', 4: 'Very hot' };
const spice = document.getElementById('spice');
spice.addEventListener('input', () => {
  const text = SPICE[spice.value];
  spice.setAttribute('aria-valuetext', text);
  document.getElementById('spice-output').textContent = text;
});
```

### Do — custom slider, when you truly cannot style the native one

```html
<span id="price-label">Maximum price</span>
<div class="slider">
  <div class="slider__track" id="price-track">
    <div
      role="slider"
      id="price-thumb"
      tabindex="0"
      aria-labelledby="price-label"
      aria-valuemin="0"
      aria-valuemax="1000"
      aria-valuenow="250"
      aria-valuetext="€250"
      class="slider__thumb"
    ></div>
  </div>
  <output for="price-thumb">€250</output>
</div>
```

```js
const thumb = document.getElementById('price-thumb');
const track = document.getElementById('price-track');
const MIN = 0, MAX = 1000, STEP = 10;

function setValue(value) {
  const clamped = Math.min(MAX, Math.max(MIN, Math.round(value / STEP) * STEP));
  thumb.setAttribute('aria-valuenow', String(clamped));
  thumb.setAttribute('aria-valuetext', `€${clamped}`);
  thumb.style.insetInlineStart = `${((clamped - MIN) / (MAX - MIN)) * 100}%`;
  return clamped;
}

// Keyboard: every key <input type="range"> would have given us for free.
thumb.addEventListener('keydown', (event) => {
  const current = Number(thumb.getAttribute('aria-valuenow'));
  let next = null;

  if (event.key === 'ArrowRight' || event.key === 'ArrowUp') next = current + STEP;
  if (event.key === 'ArrowLeft' || event.key === 'ArrowDown') next = current - STEP;
  if (event.key === 'PageUp') next = current + STEP * 10;
  if (event.key === 'PageDown') next = current - STEP * 10;
  if (event.key === 'Home') next = MIN;
  if (event.key === 'End') next = MAX;

  if (next === null) return;   // Tab passes through
  event.preventDefault();
  setValue(next);
});

// RAWeb 13.10.2 — THE rule custom sliders break. Tapping a point on the track
// must set the value, with no dragging. Without this handler, the only way to
// operate the slider by pointer is a path-based gesture, and the pattern fails.
track.addEventListener('pointerdown', (event) => {
  const rect = track.getBoundingClientRect();
  setValue(MIN + ((event.clientX - rect.left) / rect.width) * (MAX - MIN));
  thumb.focus();
});

// Drag, as an enhancement on top — never as the only input method.
thumb.addEventListener('pointerdown', (event) => {
  thumb.setPointerCapture(event.pointerId);
  const onMove = (e) => {
    const rect = track.getBoundingClientRect();
    setValue(MIN + ((e.clientX - rect.left) / rect.width) * (MAX - MIN));
  };
  const onUp = () => {
    thumb.removeEventListener('pointermove', onMove);
    commit(Number(thumb.getAttribute('aria-valuenow'))); // commit on UP (13.11)
  };
  thumb.addEventListener('pointermove', onMove);
  thumb.addEventListener('pointerup', onUp, { once: true });
});
```

### Don't

```html
<!-- DON'T: an unlabelled slider (RAWeb 11.1).
     → "slider, 50" — 50 of what? -->
<input type="range" min="0" max="100" value="50">

<!-- DON'T: the value as the label.
     → The name becomes "50", which changes as the user drags. The slider's name
       must be stable — it is what the thing IS, not what it says. -->
<label for="volume">50%</label>
<input type="range" id="volume" min="0" max="100" value="50">

<!-- DON'T: aria-valuenow on a native range.
     → The browser already derives it from `value`. Two sources of truth, and
       yours will go stale. -->
<input type="range" min="0" max="100" value="50" aria-valuenow="50">

<!-- DON'T: tabindex on the track.
     → Two Tab stops for one control. Only the thumb is focusable. -->
<div class="slider__track" tabindex="0">
  <div role="slider" tabindex="0"></div>
</div>

<!-- DON'T: role="slider" with no aria-valuenow.
     → The role promises a value and there is none. -->
<div role="slider" tabindex="0" aria-labelledby="price-label"></div>

<!-- DON'T: a numeric value where the number is meaningless.
     → Announced "slider, 2". Two what? aria-valuetext="Medium" fixes it. -->
<input type="range" min="1" max="4" value="2" id="spice">
```

```css
/* DON'T: rotate a range input to make it vertical.
   → The arrow-key semantics do NOT rotate. Right-arrow still increases the
     value, which now moves the thumb UP. The visual and the keyboard model
     contradict each other, and screen readers still say "horizontal". Use
     writing-mode. */
input[type="range"].vertical {
  transform: rotate(-90deg);
}

/* DON'T: a 2px track.
   → Tapping the track is what satisfies RAWeb 13.10.2. If the track is a
     hairline, the single-point alternative exists in theory and is unusable in
     practice — especially for anyone with a tremor. */
input[type="range"] { block-size: 2px; }
```

```js
// DON'T: drag-only. THE RAWeb 13.10.2 failure.
//     → Dragging is a path-based gesture. Without a track-tap (or +/- buttons),
//       the only pointer route to a value is a path-based gesture. Fails.
thumb.addEventListener('pointerdown', startDrag);
// ...and no pointerdown handler on the track

// DON'T: commit on every `input` event when the work is expensive or
//        irreversible.
//     → Dragging from 0 to 100 fires ~100 times. Each one a network request, or
//       an undo entry. Use `change` for the commit (RAWeb 13.11).
volume.addEventListener('input', () => savePreference(volume.value));

// DON'T: handle only ArrowLeft/ArrowRight on a custom slider.
//     → Home, End, Page Up and Page Down are all expected, and free with
//       <input type="range">. This is what you sign up for by going custom.
```

---

## React

### Do

```jsx
import { useId, useState } from 'react';

export function VolumeSlider({ label = 'Volume', defaultValue = 50, onCommit }) {
  const [value, setValue] = useState(defaultValue);
  const id = useId();

  return (
    <div className="slider-row">
      <label htmlFor={id}>{label}</label>
      <input
        type="range"
        id={id}
        min={0}
        max={100}
        step={1}
        value={value}
        // Fires on drag AND on arrow keys — keep the UI in sync here.
        onChange={(e) => setValue(Number(e.target.value))}
        // React's onChange maps to the native `input` event, so it fires
        // continuously. For commit-on-release, use the native change event.
        onPointerUp={() => onCommit?.(value)}
        onBlur={() => onCommit?.(value)}
      />
      <output htmlFor={id}>{value}%</output>
    </div>
  );
}
```

React's `onChange` on an `<input type="range">` is the **native `input` event**,
not native `change` — it fires on every pixel of a drag. There is no `onCommit`
in React; `onPointerUp` + `onBlur` covers pointer and keyboard respectively.

```jsx
// Non-numeric scale.
const SPICE = ['Mild', 'Medium', 'Hot', 'Very hot'];

export function SpiceSlider() {
  const [index, setIndex] = useState(1);
  const id = useId();

  return (
    <div className="slider-row">
      <label htmlFor={id}>Spice level</label>
      <input
        type="range"
        id={id}
        min={0}
        max={SPICE.length - 1}
        step={1}
        value={index}
        aria-valuetext={SPICE[index]}   // announced INSTEAD of the number
        onChange={(e) => setIndex(Number(e.target.value))}
      />
      <output htmlFor={id}>{SPICE[index]}</output>
    </div>
  );
}
```

### Don't

```jsx
// DON'T: expensive work in onChange.
//     → Fires on every pixel of a drag. One network request per pixel.
<input type="range" onChange={(e) => saveToServer(e.target.value)} />

// DON'T: value without onChange — React makes it read-only and warns.
<input type="range" value={value} />

// DON'T: a div slider because the native one "can't be styled".
//     → ::-webkit-slider-thumb and ::-moz-range-thumb style it almost
//       arbitrarily. Going custom means owning six keys and the 13.10.2
//       track-tap.
<div role="slider" tabIndex={0} onKeyDown={handleKeys} />

// DON'T: aria-valuetext that duplicates the number.
//     → "50" announced as "50". Pointless. Use it for MEANING: "€250", "Medium".
<input type="range" value={value} aria-valuetext={String(value)} />
```

---

## Angular

### Do

```ts
import { Component, input, model } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-slider',
  template: `
    <div class="slider-row">
      <label [for]="id">{{ label() }}</label>
      <input
        type="range"
        [id]="id"
        [min]="min()"
        [max]="max()"
        [step]="step()"
        [value]="value()"
        [attr.aria-valuetext]="valueText()"
        (input)="onInput($event)"
        (change)="committed.emit(value())"
      >
      <output [attr.for]="id">{{ valueText() ?? value() }}</output>
    </div>
  `,
})
export class SliderComponent {
  readonly label = input.required<string>();
  readonly min = input(0);
  readonly max = input(100);
  readonly step = input(1);
  readonly value = model(50);
  // null so Angular REMOVES the attribute rather than rendering
  // aria-valuetext="null".
  readonly valueText = input<string | null>(null);
  readonly committed = output<number>();

  protected readonly id = `slider-${uid++}`;

  protected onInput(event: Event): void {
    this.value.set(Number((event.target as HTMLInputElement).value));
  }
}
```

Angular binds `(input)` and `(change)` as the real DOM events, so unlike React
you get commit-on-release for free from `(change)`.

### Don't

```html
<!-- DON'T: [attr.value] — sets the DEFAULT-value attribute, not the live
     property. The slider stops reflecting state after first interaction. -->
<input type="range" [attr.value]="value()">

<!-- DON'T: expensive work in (input) — fires continuously while dragging.
     Use (change). -->
<input type="range" (input)="saveToServer($event)">
```

---

## Web Component

### Do

```js
// Wrap a real <input type="range">. It keeps the keyboard model, the value
// announcement and — importantly — the native track-tap that satisfies
// RAWeb 13.10.2. A div-based shadow slider throws all of that away.
class A11ySlider extends HTMLElement {
  static formAssociated = true;   // or it submits nothing
  #internals;
  #input;

  constructor() {
    super();
    this.#internals = this.attachInternals();
    const root = this.attachShadow({ mode: 'open', delegatesFocus: true });
    root.innerHTML = `
      <input type="range" part="input">
      <output part="output"></output>
    `;
    this.#input = root.querySelector('input');
    const output = root.querySelector('output');

    this.#input.addEventListener('input', () => {
      output.textContent = this.valueText ?? this.#input.value;
      this.#internals.setFormValue(this.#input.value);
    });
  }

  connectedCallback() {
    // The name is TEXT, so it can cross the boundary via aria-label.
    // aria-labelledby (an IDREF) could not.
    this.#input.setAttribute('aria-label', this.getAttribute('label') ?? '');
    this.#input.min = this.getAttribute('min') ?? '0';
    this.#input.max = this.getAttribute('max') ?? '100';
    this.#input.value = this.getAttribute('value') ?? '50';
  }

  get valueText() { return this.getAttribute('value-text'); }
  get value() { return this.#input.value; }
}

customElements.define('a11y-slider', A11ySlider);
```

### Don't

```js
// DON'T: a div thumb in a shadow root.
//     → You lose: arrows, Home/End, Page Up/Down, the form value, and the
//       native track-tap (RAWeb 13.10.2). All to restyle something
//       ::-webkit-slider-thumb would have styled.
root.innerHTML = `<div class="track"><div role="slider" tabindex="0"></div></div>`;

// DON'T: <label for> pointing at the host.
//     → `for` is an IDREF and cannot reach the input inside the shadow root.
//       The slider is unnamed. Pass the label in as text.
```

---

## Verify

- **The RAWeb 13.10.2 check — the one everyone misses.** Operate the slider
  **with a single tap or click on the track**, no dragging. If the value only
  changes by dragging, it fails. Native `<input type="range">` passes for free;
  a custom slider needs an explicit `pointerdown` handler on the track.
- **Keyboard-only:** arrows step; **Home/End** jump to min/max; **Page Up/Down**
  take a bigger step. All four are expected — a custom slider that only does
  arrows is incomplete.
- **Screen reader:** expect "«label», slider, 50". If you hear a number where a
  word belongs ("2" for spice level), add `aria-valuetext`.
- **Vertical check:** if it's vertical, does Up-arrow move the thumb up? With a
  `rotate()` transform it won't.
- **Commit check:** drag from 0 to 100 and count network requests. One, not a
  hundred.
- **Automated:** axe catches an unlabelled slider and `role="slider"` with no
  `aria-valuenow`. It catches **nothing** about 13.10.2, the missing Home/End
  keys, or a rotated-vertical slider.
