# Combobox — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show combobox`

**Read this whole file** before building one. This is the most complex pattern in
the APG and the most consistently broken. Use `code combobox <framework>` only
when you already know the universal rules.

---

## Universal rules

- **First, don't.** For a select-only combobox, native `<select>` is
  keyboard-complete, screen-reader-complete, works on mobile, and costs zero
  lines. Build the ARIA pattern only when you genuinely need filtering, chips, or
  rich option markup. Most "custom selects" exist for a border-radius.
- **`role="combobox"` goes on the `<input>`.** ARIA 1.2. The old ARIA 1.0 pattern
  wrapped the input in a `<div role="combobox">` — that is **obsolete** and
  breaks in current screen readers. Most tutorials online still show it. (RAWeb 7.1)
- **`aria-activedescendant` means DOM focus never leaves the input.** You point at
  the active option's id; focus stays put. The option is *not* focused — it just
  looks it. (RAWeb 7.1)
- **Therefore: never call `.focus()` on an option.** Doing both is the defining
  combobox bug — the input loses focus, typing stops working, and the screen
  reader's model of the widget falls apart. Pick one mechanism. This pattern
  uses `aria-activedescendant`.
- **Therefore: you must scroll the active option into view yourself.** No real
  focus means no automatic scrolling. `scrollIntoView({ block: 'nearest' })`.
- **Therefore: `:focus-visible` will never fire on an option.** Style
  `[aria-selected="true"]` or the keyboard user watches a list that never
  visibly moves. (RAWeb 10.7)
- **Announce the result count in a live region.** Typing filters the list; if
  nothing is announced, a screen reader user types into silence. "3 results
  available." (RAWeb 7.5)
- **Never put `aria-live` on the listbox itself.** It re-announces every option
  on every keystroke. Use a separate, visually hidden polite region.
- **The input needs a real `<label>`.** It is a form field. (RAWeb 11.1)
- **Tab must always close the popup and leave.** (RAWeb 12.9)

### Which variant?

| Need | Use |
|---|---|
| Pick one of a known list | **`<select>`** — stop here |
| Pick one, list is long, typing filters it | editable combobox, `aria-autocomplete="list"` |
| Free text *plus* suggestions | editable combobox, `aria-autocomplete="list"` |
| Inline completion of the typed text | `aria-autocomplete="both"` |
| Multi-select with chips | combobox + separate removable chip buttons |

---

## Vanilla

### Do — native, when it fits

```html
<!-- Keyboard, typeahead, mobile pickers, screen reader support: all free. -->
<label for="country">Country</label>
<select id="country" name="country">
  <option value="">Choose a country</option>
  <option value="lu">Luxembourg</option>
  <option value="be">Belgium</option>
  <option value="fr">France</option>
</select>
```

### Do — the ARIA pattern, when you need filtering

```html
<label for="country-input">Country</label>

<div class="combobox">
  <!-- role, aria-expanded, aria-controls, aria-activedescendant ALL live on the
       input. Not on this wrapper — the wrapper is for layout only. -->
  <input
    type="text"
    id="country-input"
    role="combobox"
    aria-expanded="false"
    aria-controls="country-listbox"
    aria-autocomplete="list"
    autocomplete="off"
  >

  <!-- Stays in the DOM so aria-controls resolves; `hidden` when closed. -->
  <ul id="country-listbox" role="listbox" aria-label="Countries" hidden></ul>
</div>

<!-- Separate live region. NOT aria-live on the listbox, which would re-read
     every option on every keystroke (RAWeb 7.5). -->
<div id="country-status" role="status" aria-live="polite" class="sr-only"></div>
```

```css
/* The active option has NO real focus, so :focus-visible never fires here.
   This rule is the only thing the keyboard user sees move (RAWeb 10.7). */
[role="option"][aria-selected="true"] {
  background: #0056b3;
  color: #fff;
}

#country-input:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

[role="listbox"] {
  max-block-size: 15rem;
  overflow-y: auto;
}
```

```js
const input = document.getElementById('country-input');
const listbox = document.getElementById('country-listbox');
const status = document.getElementById('country-status');
const COUNTRIES = ['Luxembourg', 'Belgium', 'France', 'Germany', 'Netherlands'];

let activeIndex = -1;
let options = [];

function open() {
  input.setAttribute('aria-expanded', 'true');
  listbox.hidden = false;
}

function close() {
  input.setAttribute('aria-expanded', 'false');
  listbox.hidden = true;
  // Clear it, or the input keeps announcing an option that is no longer shown.
  input.removeAttribute('aria-activedescendant');
  activeIndex = -1;
}

function setActive(index) {
  options.forEach((option, i) => option.setAttribute('aria-selected', String(i === index)));
  activeIndex = index;

  if (index === -1) {
    input.removeAttribute('aria-activedescendant');
    return;
  }
  // DOM focus stays on the input. This is what tells assistive technologies
  // which option is active — we never call options[index].focus().
  input.setAttribute('aria-activedescendant', options[index].id);
  // No real focus means no automatic scrolling. Do it by hand.
  options[index].scrollIntoView({ block: 'nearest' });
}

function filter(query) {
  const matches = COUNTRIES.filter((c) => c.toLowerCase().includes(query.toLowerCase()));

  listbox.innerHTML = '';
  matches.forEach((name, i) => {
    const li = document.createElement('li');
    li.id = `country-option-${i}`;
    li.setAttribute('role', 'option');
    li.setAttribute('aria-selected', 'false');
    li.textContent = name; // textContent, never innerHTML — this is user-adjacent data
    listbox.append(li);
  });

  options = [...listbox.querySelectorAll('[role="option"]')];
  // RAWeb 7.5 — otherwise the user types and hears nothing.
  status.textContent = matches.length
    ? `${matches.length} result${matches.length > 1 ? 's' : ''} available.`
    : 'No results.';

  matches.length ? open() : close();
  setActive(-1);
}

input.addEventListener('input', () => filter(input.value));

input.addEventListener('keydown', (event) => {
  const isOpen = input.getAttribute('aria-expanded') === 'true';

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      if (!isOpen) { filter(input.value); return; }
      setActive((activeIndex + 1) % options.length);
      break;
    case 'ArrowUp':
      event.preventDefault();
      if (!isOpen) { filter(input.value); setActive(options.length - 1); return; }
      setActive((activeIndex - 1 + options.length) % options.length);
      break;
    case 'Enter':
      if (isOpen && activeIndex > -1) {
        event.preventDefault();
        input.value = options[activeIndex].textContent;
        close();
      }
      break;
    case 'Escape':
      close();
      break;
    case 'Tab':
      close(); // never preventDefault — Tab is the way out (RAWeb 12.9)
      break;
  }
});

// Pointer parity: everything the keyboard can do, the mouse must too (RAWeb 7.3).
listbox.addEventListener('click', (event) => {
  const option = event.target.closest('[role="option"]');
  if (!option) return;
  input.value = option.textContent;
  close();
  input.focus();
});
```

### Don't

```html
<!-- DON'T: the obsolete ARIA 1.0 shape — role="combobox" on a WRAPPER.
     → Current screen readers announce the group, not the input; aria-expanded
       on a div means nothing. Most tutorials still show this. role="combobox"
       belongs on the <input> (ARIA 1.2). -->
<div role="combobox" aria-expanded="false" aria-haspopup="listbox">
  <input type="text">
  <ul role="listbox">…</ul>
</div>

<!-- DON'T: tabbable options.
     → Every option becomes a Tab stop and DOM focus leaves the input. Options
       are addressed by aria-activedescendant; they are never focusable. -->
<li role="option" tabindex="0">Luxembourg</li>

<!-- DON'T: aria-live on the listbox.
     → Every option is re-announced on every keystroke. Typing "lux" reads the
       whole list three times. Use a separate status region. -->
<ul role="listbox" aria-live="polite">…</ul>

<!-- DON'T: an unlabelled input (RAWeb 11.1).
     → Announced "combobox" with no idea what it is for. Placeholder is not a
       label: it vanishes on typing and many screen readers ignore it. -->
<input type="text" role="combobox" placeholder="Country">

<!-- DON'T: a div pretending to be an input.
     → Not focusable, not typeable, no value. -->
<div role="combobox" contenteditable></div>
```

```js
// DON'T: focus the option AND set aria-activedescendant.
//     → THE combobox bug. DOM focus leaves the input, so typing stops working
//       and the input's own keydown handler never fires again. Use one
//       mechanism. This pattern uses aria-activedescendant, so focus stays put.
options[index].focus();
input.setAttribute('aria-activedescendant', options[index].id);

// DON'T: set aria-activedescendant and expect the list to scroll.
//     → It is not real focus, so the browser will not scroll it into view. The
//       active option silently sits below the fold.
input.setAttribute('aria-activedescendant', options[index].id);
// missing: options[index].scrollIntoView({ block: 'nearest' })

// DON'T: leave aria-activedescendant set after closing.
//     → The input keeps announcing an option that is no longer on screen.
function close() {
  listbox.hidden = true;
  input.setAttribute('aria-expanded', 'false');
  // missing: input.removeAttribute('aria-activedescendant')
}

// DON'T: preventDefault on Tab.
//     → Keyboard trap (RAWeb 12.9). Tab closes the popup and leaves.
if (event.key === 'Tab') event.preventDefault();

// DON'T: build options with innerHTML from fetched data.
//     → Injection. A result named `<img src=x onerror=…>` executes.
li.innerHTML = name;
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef, useState } from 'react';

const COUNTRIES = ['Luxembourg', 'Belgium', 'France', 'Germany', 'Netherlands'];

export function Combobox({ label }) {
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const id = useId();
  const listRef = useRef(null);

  const matches = COUNTRIES.filter((c) => c.toLowerCase().includes(query.toLowerCase()));
  const activeId = activeIndex > -1 ? `${id}-option-${activeIndex}` : undefined;

  // Not real focus, so React will not scroll it either. Do it after paint.
  useEffect(() => {
    if (activeIndex < 0) return;
    listRef.current
      ?.querySelector(`#${CSS.escape(`${id}-option-${activeIndex}`)}`)
      ?.scrollIntoView({ block: 'nearest' });
  }, [activeIndex, id]);

  const onKeyDown = (event) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        setIsOpen(true);
        setActiveIndex((i) => (i + 1) % matches.length);
        break;
      case 'ArrowUp':
        event.preventDefault();
        setIsOpen(true);
        setActiveIndex((i) => (i - 1 + matches.length) % matches.length);
        break;
      case 'Enter':
        if (isOpen && activeIndex > -1) {
          event.preventDefault();
          setQuery(matches[activeIndex]);
          setIsOpen(false);
          setActiveIndex(-1);
        }
        break;
      case 'Escape':
        setIsOpen(false);
        setActiveIndex(-1);
        break;
      case 'Tab':
        setIsOpen(false); // no preventDefault — Tab must leave
        break;
      default:
    }
  };

  return (
    <>
      <label htmlFor={`${id}-input`}>{label}</label>
      <input
        id={`${id}-input`}
        type="text"
        role="combobox"
        aria-expanded={isOpen}
        aria-controls={`${id}-listbox`}
        aria-autocomplete="list"
        // undefined removes the attribute entirely — "" would leave a dangling
        // aria-activedescendant="" pointing at nothing.
        aria-activedescendant={activeId}
        autoComplete="off"
        value={query}
        onChange={(e) => { setQuery(e.target.value); setIsOpen(true); setActiveIndex(-1); }}
        onKeyDown={onKeyDown}
      />

      <ul id={`${id}-listbox`} ref={listRef} role="listbox" aria-label={label} hidden={!isOpen}>
        {matches.map((name, i) => (
          <li
            key={name}
            id={`${id}-option-${i}`}
            role="option"
            aria-selected={i === activeIndex}
            onClick={() => { setQuery(name); setIsOpen(false); setActiveIndex(-1); }}
          >
            {name}
          </li>
        ))}
      </ul>

      {/* RAWeb 7.5 — result count, announced politely, off-screen. */}
      <div role="status" aria-live="polite" className="sr-only">
        {isOpen ? `${matches.length} result${matches.length === 1 ? '' : 's'} available.` : ''}
      </div>
    </>
  );
}
```

### Don't

```jsx
// DON'T: aria-activedescendant="" when nothing is active.
//     → An empty IDREF is still an IDREF pointing at nothing. Use undefined so
//       React removes the attribute.
<input role="combobox" aria-activedescendant={activeId ?? ''} />

// DON'T: refs + .focus() on options.
//     → Focus leaves the input; onKeyDown stops firing; the widget dies.
optionRefs.current[activeIndex]?.focus();

// DON'T: onBlur to close.
//     → Clicking an option blurs the input BEFORE the click registers, so the
//       list closes and the selection never happens. Close on Escape, Tab, and
//       an outside pointerdown instead.
<input onBlur={() => setIsOpen(false)} />

// DON'T: an aria-live region whose content is always present.
//     → Mounting a live region already containing text announces nothing;
//       worse, a region that re-renders identical text may announce repeatedly.
//       Keep it empty when closed, as above.
```

---

## Angular

### Do

```ts
import { Component, computed, effect, ElementRef, input, signal, viewChild } from '@angular/core';

const COUNTRIES = ['Luxembourg', 'Belgium', 'France', 'Germany', 'Netherlands'];
let uid = 0;

@Component({
  selector: 'app-combobox',
  template: `
    <label [for]="id + '-input'">{{ label() }}</label>
    <input
      [id]="id + '-input'"
      type="text"
      role="combobox"
      autocomplete="off"
      aria-autocomplete="list"
      [attr.aria-expanded]="isOpen()"
      [attr.aria-controls]="id + '-listbox'"
      [attr.aria-activedescendant]="activeId()"
      [value]="query()"
      (input)="onInput($event)"
      (keydown)="onKeyDown($event)"
    >

    <ul #listbox [id]="id + '-listbox'" role="listbox" [attr.aria-label]="label()" [hidden]="!isOpen()">
      @for (name of matches(); track name; let i = $index) {
        <li
          [id]="id + '-option-' + i"
          role="option"
          [attr.aria-selected]="i === activeIndex()"
          (click)="select(name)"
        >{{ name }}</li>
      }
    </ul>

    <div role="status" aria-live="polite" class="sr-only">
      {{ isOpen() ? matches().length + ' results available.' : '' }}
    </div>
  `,
})
export class ComboboxComponent {
  readonly label = input.required<string>();
  protected readonly id = `combobox-${uid++}`;
  protected readonly query = signal('');
  protected readonly isOpen = signal(false);
  protected readonly activeIndex = signal(-1);
  private readonly listbox = viewChild<ElementRef<HTMLUListElement>>('listbox');

  protected readonly matches = computed(() =>
    COUNTRIES.filter((c) => c.toLowerCase().includes(this.query().toLowerCase())),
  );

  // null (not '') so Angular REMOVES the attribute rather than rendering
  // aria-activedescendant="" — a dangling reference to nothing.
  protected readonly activeId = computed(() =>
    this.activeIndex() > -1 ? `${this.id}-option-${this.activeIndex()}` : null,
  );

  constructor() {
    effect(() => {
      const index = this.activeIndex();
      if (index < 0) return;
      this.listbox()?.nativeElement
        .querySelector(`#${CSS.escape(`${this.id}-option-${index}`)}`)
        ?.scrollIntoView({ block: 'nearest' });
    });
  }

  protected onInput(event: Event): void {
    this.query.set((event.target as HTMLInputElement).value);
    this.isOpen.set(true);
    this.activeIndex.set(-1);
  }

  protected select(name: string): void {
    this.query.set(name);
    this.isOpen.set(false);
    this.activeIndex.set(-1);
  }

  protected onKeyDown(event: KeyboardEvent): void {
    const count = this.matches().length;
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.isOpen.set(true);
        this.activeIndex.update((i) => (i + 1) % count);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.isOpen.set(true);
        this.activeIndex.update((i) => (i - 1 + count) % count);
        break;
      case 'Enter':
        if (this.isOpen() && this.activeIndex() > -1) {
          event.preventDefault();
          this.select(this.matches()[this.activeIndex()]);
        }
        break;
      case 'Escape':
        this.isOpen.set(false);
        this.activeIndex.set(-1);
        break;
      case 'Tab':
        this.isOpen.set(false); // no preventDefault
        break;
    }
  }
}
```

**Or use the CDK.** `@angular/cdk/listbox` and `MatAutocomplete` implement this
pattern including `aria-activedescendant` handling. Given how much there is to get
wrong here, reach for them before hand-rolling.

### Don't

```html
<!-- DON'T: [attr.aria-activedescendant]="''" — renders the attribute pointing
     at nothing. Return null so Angular removes it. -->
<input role="combobox" [attr.aria-activedescendant]="activeId() || ''">

<!-- DON'T: [attr.hidden] on the listbox — renders hidden="false" and still
     hides it. Use [hidden]. -->
<ul role="listbox" [attr.hidden]="!isOpen()">…</ul>
```

---

## Web Component

### Do

```js
// Light DOM. A combobox is built almost entirely from IDREFs — aria-controls
// (input → listbox) and aria-activedescendant (input → option). None of them
// cross a shadow boundary, so a shadow root here would silently break the
// widget's entire wiring. This is the pattern where shadow DOM hurts most.
class A11yCombobox extends HTMLElement {
  #input;
  #listbox;
  #status;
  #activeIndex = -1;

  connectedCallback() {
    this.#input = this.querySelector('[role="combobox"]');
    this.#listbox = this.querySelector('[role="listbox"]');
    this.#status = this.querySelector('[role="status"]');

    this.#input.addEventListener('keydown', (e) => this.#onKeyDown(e));
    this.#listbox.addEventListener('click', (e) => {
      const option = e.target.closest('[role="option"]');
      if (!option) return;
      this.#input.value = option.textContent;
      this.#close();
      this.#input.focus();
    });
  }

  get #options() {
    return [...this.#listbox.querySelectorAll('[role="option"]:not([hidden])')];
  }

  #setActive(index) {
    const options = this.#options;
    options.forEach((o, i) => o.setAttribute('aria-selected', String(i === index)));
    this.#activeIndex = index;
    if (index === -1) {
      this.#input.removeAttribute('aria-activedescendant');
      return;
    }
    this.#input.setAttribute('aria-activedescendant', options[index].id);
    options[index].scrollIntoView({ block: 'nearest' });
  }

  #open() {
    this.#input.setAttribute('aria-expanded', 'true');
    this.#listbox.hidden = false;
  }

  #close() {
    this.#input.setAttribute('aria-expanded', 'false');
    this.#listbox.hidden = true;
    this.#input.removeAttribute('aria-activedescendant');
    this.#activeIndex = -1;
  }

  #onKeyDown(event) {
    const count = this.#options.length;
    if (event.key === 'ArrowDown') {
      event.preventDefault(); this.#open(); this.#setActive((this.#activeIndex + 1) % count);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault(); this.#open(); this.#setActive((this.#activeIndex - 1 + count) % count);
    } else if (event.key === 'Escape') {
      this.#close();
    } else if (event.key === 'Tab') {
      this.#close();
    } else if (event.key === 'Enter' && this.#activeIndex > -1) {
      event.preventDefault();
      this.#input.value = this.#options[this.#activeIndex].textContent;
      this.#close();
    }
  }
}

customElements.define('a11y-combobox', A11yCombobox);
```

```html
<a11y-combobox>
  <label for="c-input">Country</label>
  <input id="c-input" type="text" role="combobox" aria-expanded="false"
         aria-controls="c-listbox" aria-autocomplete="list" autocomplete="off">
  <ul id="c-listbox" role="listbox" aria-label="Countries" hidden>
    <li id="c-opt-0" role="option" aria-selected="false">Luxembourg</li>
    <li id="c-opt-1" role="option" aria-selected="false">Belgium</li>
  </ul>
  <div role="status" aria-live="polite" class="sr-only"></div>
</a11y-combobox>
```

### Don't

```js
// DON'T: input in the shadow root, options slotted from the light DOM.
//     → aria-controls and aria-activedescendant are IDREFs. Neither crosses the
//       boundary. The combobox controls nothing and can never mark an option
//       active — silently. Every arrow key does nothing for a screen reader.
root.innerHTML = `<input role="combobox" aria-controls="listbox">
                  <ul id="listbox" role="listbox"><slot></slot></ul>`;
```

---

## Verify

- **Keyboard-only:** Down opens and moves through options; the highlight must
  *visibly* move (if not, you're relying on `:focus-visible`, which never fires
  here). Escape closes. Enter selects. **Tab must close and leave** (RAWeb 12.9).
- **The `aria-activedescendant` check:** with the popup open and an option
  active, run `document.activeElement` in the console. It must be the **input**.
  If it is an `<li>`, you are focusing options and the pattern is broken.
- **Scroll check:** arrow down past the visible list. The active option must
  scroll into view. If it doesn't, you skipped `scrollIntoView`.
- **Screen reader:** typing must announce the result count (RAWeb 7.5). Arrowing
  must announce each option. If typing is silent, the live region is missing; if
  the whole list is re-read on each keystroke, `aria-live` is on the listbox.
- **Automated:** axe catches `role="option"` outside a listbox, a missing label,
  and a dangling `aria-activedescendant`. It catches **none** of the real bugs
  here — obsolete ARIA 1.0 shape, focused options, missing scroll, missing status
  message. This pattern must be tested by hand with a screen reader.
