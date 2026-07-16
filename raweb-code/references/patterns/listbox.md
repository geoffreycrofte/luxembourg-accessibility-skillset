# Listbox — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show listbox`

> Closely related to [`combobox`](combobox.md) — a combobox *contains* a listbox,
> but wires it differently. If you have a text input, you want that file.

---

## Universal rules

- **First, use `<select>`.** It is keyboard-complete, screen-reader-complete, has
  free type-ahead, and gets the **native picker on mobile** — which no ARIA
  listbox can match. Build this pattern only for rich option markup (avatars,
  two-line options) or multi-select UX `<select multiple>` genuinely can't
  express. "It doesn't match the design" is usually solved by CSS.
- **Pick ONE focus model and commit.** Mixing them is the defining bug:
  - **Roving tabindex** — real focus moves to the option. Simpler. Use this when
    the listbox is standalone.
  - **`aria-activedescendant`** — focus stays on the container; you point at the
    active option's id. Necessary when focus must remain in a text input (that
    is, in a [`combobox`](combobox.md)).
- **With `aria-activedescendant`, `:focus-visible` never fires on the option.**
  Style `[aria-selected="true"]` yourself, and call `scrollIntoView` yourself —
  there's no real focus to scroll to. (RAWeb 10.7)
- **The listbox needs an accessible name.** `aria-labelledby` pointing at a
  visible label. (RAWeb 11.1)
- **Tab must always leave.** Arrows navigate; Tab exits. (RAWeb 12.9)
- **`aria-setsize`/`aria-posinset` only for virtualised lists.** If every option
  is in the DOM, the browser counts them — adding these by hand just invites them
  to be wrong.

---

## Vanilla

### Do — native, when it fits

```html
<label for="delivery">Delivery method</label>
<select id="delivery" name="delivery">
  <option value="standard">Standard — 3 to 5 days</option>
  <option value="express">Express — next day</option>
</select>

<!-- Multi-select. Genuinely poor UX in most designs, which is the honest reason
     to build the ARIA version — not the styling. -->
<label for="tags">Tags</label>
<select id="tags" name="tags" multiple size="5">
  <option value="a11y">Accessibility</option>
  <option value="css">CSS</option>
</select>
```

### Do — ARIA listbox with roving tabindex

```html
<span id="country-label">Country</span>

<!-- Roving tabindex: the LISTBOX itself is not focusable; the selected OPTION
     carries tabindex="0" and everything else -1. One Tab stop for the widget. -->
<ul id="country-list" role="listbox" aria-labelledby="country-label" tabindex="-1">
  <li role="option" id="opt-lu" aria-selected="true" tabindex="0">Luxembourg</li>
  <li role="option" id="opt-be" aria-selected="false" tabindex="-1">Belgium</li>
  <li role="option" id="opt-fr" aria-selected="false" tabindex="-1">France</li>
</ul>
```

```css
[role="listbox"] {
  list-style: none;
  margin: 0;
  padding: 0;
  max-block-size: 15rem;
  overflow-y: auto;
  border: 1px solid #767676;
}

/* Selection and focus are different things — with roving tabindex real focus
   moves, so :focus-visible works here (unlike aria-activedescendant). */
[role="option"][aria-selected="true"] {
  background: #0056b3;
  color: #fff;
}

[role="option"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}
```

```js
const listbox = document.getElementById('country-list');
const options = [...listbox.querySelectorAll('[role="option"]')];

function select(newOption) {
  for (const option of options) {
    const isSelected = option === newOption;
    // aria-selected and tabindex move together — always.
    option.setAttribute('aria-selected', String(isSelected));
    option.setAttribute('tabindex', isSelected ? '0' : '-1');
  }
  newOption.focus(); // real focus — the browser scrolls it into view for us
}

listbox.addEventListener('click', (event) => {
  const option = event.target.closest('[role="option"]');
  if (option) select(option);
});

listbox.addEventListener('keydown', (event) => {
  const index = options.indexOf(document.activeElement);
  if (index === -1) return;

  let newIndex = null;
  if (event.key === 'ArrowDown') newIndex = Math.min(index + 1, options.length - 1);
  if (event.key === 'ArrowUp') newIndex = Math.max(index - 1, 0);
  if (event.key === 'Home') newIndex = 0;
  if (event.key === 'End') newIndex = options.length - 1;

  if (newIndex === null) return; // Tab and everything else pass through
  event.preventDefault();
  select(options[newIndex]);
});

// Type-ahead. Free with <select>; here you owe it, and users expect it.
let typeBuffer = '';
let typeTimer;
listbox.addEventListener('keydown', (event) => {
  if (event.key.length !== 1 || event.ctrlKey || event.metaKey) return;
  clearTimeout(typeTimer);
  typeBuffer += event.key.toLowerCase();
  typeTimer = setTimeout(() => { typeBuffer = ''; }, 500);

  const match = options.find((o) => o.textContent.toLowerCase().startsWith(typeBuffer));
  if (match) select(match);
});
```

### Don't

```html
<!-- DON'T: divs with no roles.
     → Not a listbox, not focusable, no selection state. -->
<div class="listbox">
  <div class="option selected">Luxembourg</div>
</div>

<!-- DON'T: tabindex="0" on every option.
     → Defeats roving tabindex — each option becomes its own Tab stop. -->
<li role="option" tabindex="0">Belgium</li>

<!-- DON'T: an unnamed listbox (RAWeb 11.1).
     → Announced "list box" with no idea what it selects. -->
<ul role="listbox">…</ul>

<!-- DON'T: interactive children inside an option.
     → role="option" may only contain text. A button inside is unreachable —
       arrows move between options, never into them. If options need actions,
       this is a grid, not a listbox. -->
<li role="option">
  Luxembourg <button type="button">Remove</button>
</li>

<!-- DON'T: aria-setsize/posinset on a fully-rendered list.
     → The browser already counts. Hand-maintained numbers go stale the moment
       the list is filtered, and then actively lie: "3 of 12" in a list of 3. -->
<li role="option" aria-setsize="12" aria-posinset="1">Luxembourg</li>

<!-- DON'T: <option> outside a <select>.
     → Native <option> has no meaning here; use role="option" on an <li>. -->
<div role="listbox"><option>Luxembourg</option></div>
```

```js
// DON'T: mix the two focus models. THE listbox bug.
//     → Real focus moves AND you claim an active descendant. Screen readers get
//       two contradictory answers about where the user is. Pick one.
options[index].focus();
listbox.setAttribute('aria-activedescendant', options[index].id);

// DON'T: aria-activedescendant without scrollIntoView.
//     → No real focus means the browser will not scroll. The active option sits
//       silently below the fold.

// DON'T: preventDefault on Tab. Keyboard trap (RAWeb 12.9).
if (event.key === 'Tab') event.preventDefault();
```

---

## React

### Do

```jsx
import { useId, useRef, useState } from 'react';

const COUNTRIES = ['Luxembourg', 'Belgium', 'France', 'Germany'];

export function Listbox({ label }) {
  const [selected, setSelected] = useState(0);
  const id = useId();
  const optionRefs = useRef([]);

  const select = (index) => {
    setSelected(index);
    optionRefs.current[index]?.focus(); // roving tabindex → real focus
  };

  const onKeyDown = (event) => {
    let next = null;
    if (event.key === 'ArrowDown') next = Math.min(selected + 1, COUNTRIES.length - 1);
    if (event.key === 'ArrowUp') next = Math.max(selected - 1, 0);
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = COUNTRIES.length - 1;

    if (next === null) return;
    event.preventDefault();
    select(next);
  };

  return (
    <>
      <span id={`${id}-label`}>{label}</span>
      <ul role="listbox" aria-labelledby={`${id}-label`} onKeyDown={onKeyDown}>
        {COUNTRIES.map((country, i) => (
          <li
            key={country}
            ref={(node) => { optionRefs.current[i] = node; }}
            role="option"
            id={`${id}-option-${i}`}
            aria-selected={i === selected}
            tabIndex={i === selected ? 0 : -1}
            onClick={() => select(i)}
          >
            {country}
          </li>
        ))}
      </ul>
    </>
  );
}
```

### Don't

```jsx
// DON'T: onClick without keyboard handling.
//     → Mouse-only. Arrows do nothing.
<li role="option" onClick={() => select(i)}>{country}</li>

// DON'T: tabIndex={0} on every option — defeats roving tabindex.

// DON'T: reinvent <select> because of styling.
//     → <select> can be styled far more than people assume, and it is the only
//       version that gets the native mobile picker. Try CSS first.
```

---

## Angular

### Do

```ts
import { Component, ElementRef, input, signal, viewChildren } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-listbox',
  template: `
    <span [id]="id + '-label'">{{ label() }}</span>
    <ul role="listbox" [attr.aria-labelledby]="id + '-label'" (keydown)="onKeyDown($event)">
      @for (country of countries; track country; let i = $index) {
        <li
          #option
          role="option"
          [id]="id + '-option-' + i"
          [attr.aria-selected]="i === selected()"
          [tabIndex]="i === selected() ? 0 : -1"
          (click)="select(i)"
        >{{ country }}</li>
      }
    </ul>
  `,
})
export class ListboxComponent {
  readonly label = input.required<string>();
  protected readonly countries = ['Luxembourg', 'Belgium', 'France', 'Germany'];
  protected readonly selected = signal(0);
  protected readonly id = `listbox-${uid++}`;
  private readonly optionEls = viewChildren<ElementRef<HTMLLIElement>>('option');

  protected select(index: number): void {
    this.selected.set(index);
    queueMicrotask(() => this.optionEls()[index]?.nativeElement.focus());
  }

  protected onKeyDown(event: KeyboardEvent): void {
    let next: number | null = null;
    if (event.key === 'ArrowDown') next = Math.min(this.selected() + 1, this.countries.length - 1);
    if (event.key === 'ArrowUp') next = Math.max(this.selected() - 1, 0);
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = this.countries.length - 1;

    if (next === null) return;
    event.preventDefault();
    this.select(next);
  }
}
```

**Or use the CDK.** `@angular/cdk/listbox` (`cdkListbox`, `cdkOption`) implements
this pattern including roving focus and type-ahead.

### Don't

```html
<!-- DON'T: [attr.tabindex] with a boolean — renders tabindex="false", parsed as
     0, so every option is a Tab stop. Use [tabIndex]. -->
<li role="option" [attr.tabindex]="i === selected()">{{ country }}</li>
```

---

## Web Component

### Do

```js
// Light DOM: aria-labelledby (listbox → label) and, in the combobox variant,
// aria-activedescendant (input → option) are IDREFs that cannot cross a shadow
// boundary.
class A11yListbox extends HTMLElement {
  #listbox;

  connectedCallback() {
    this.#listbox = this.querySelector('[role="listbox"]');
    this.#listbox.addEventListener('click', (e) => {
      const option = e.target.closest('[role="option"]');
      if (option) this.#select(option);
    });
    this.#listbox.addEventListener('keydown', (e) => this.#onKeyDown(e));
  }

  get #options() {
    return [...this.#listbox.querySelectorAll('[role="option"]')];
  }

  #select(newOption) {
    for (const option of this.#options) {
      const isSelected = option === newOption;
      option.setAttribute('aria-selected', String(isSelected));
      option.setAttribute('tabindex', isSelected ? '0' : '-1');
    }
    newOption.focus();
    this.dispatchEvent(new CustomEvent('select', {
      detail: { value: newOption.textContent }, bubbles: true, composed: true,
    }));
  }

  #onKeyDown(event) {
    const options = this.#options;
    const index = options.indexOf(document.activeElement);
    if (index === -1) return;

    let next = null;
    if (event.key === 'ArrowDown') next = Math.min(index + 1, options.length - 1);
    if (event.key === 'ArrowUp') next = Math.max(index - 1, 0);
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = options.length - 1;

    if (next === null) return;
    event.preventDefault();
    this.#select(options[next]);
  }
}

customElements.define('a11y-listbox', A11yListbox);
```

### Don't

```js
// DON'T: listbox in a shadow root with a light-DOM label.
//     → aria-labelledby cannot cross. The listbox has no accessible name and
//       nothing warns you.
```

---

## Verify

- **First: should this be a `<select>`?** If the only reason it isn't is styling,
  reconsider — you're giving up the mobile picker and free type-ahead.
- **Focus model check:** with an option active, run `document.activeElement`.
  Roving tabindex → it's the `<li>`. `aria-activedescendant` → it's the container
  or the input. If you're using `aria-activedescendant` *and* `activeElement` is
  the `<li>`, you've mixed both models.
- **Keyboard-only:** one Tab stop for the whole listbox, landing on the selected
  option. Arrows move. Type-ahead jumps. **Tab leaves** (RAWeb 12.9).
- **Screen reader:** expect "«label», list box" then "Luxembourg, selected, 1 of
  4". If the position is wrong, you're hand-maintaining `aria-posinset`.
- **Automated:** axe catches `role="option"` outside a listbox and a missing name.
  It does **not** catch mixed focus models, a missing scroll, or absent
  type-ahead.
