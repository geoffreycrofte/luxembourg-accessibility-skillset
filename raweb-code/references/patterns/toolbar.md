# Toolbar — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show toolbar`

---

## Universal rules

- **`role="toolbar"` exists to turn twenty Tab stops into one.** That is its
  entire purpose. With three buttons you don't need it — plain `<button>`s are
  better, and a toolbar with no roving tabindex is strictly worse than no
  toolbar at all.
- **Roving tabindex is not optional.** `tabindex="0"` on exactly one control,
  `-1` on the rest. Without it, `role="toolbar"` *claims* to be one Tab stop and
  isn't — the role becomes a lie. (RAWeb 12.8)
- **Real focus moves.** Call `.focus()`. Not `aria-activedescendant`.
- **Tab must always leave.** Arrows navigate within. (RAWeb 12.9)
- **Name it.** `aria-label="Text formatting"`. Two unnamed toolbars are
  indistinguishable. (RAWeb 7.1)
- **`aria-orientation="vertical"` if it's vertical** — then Up/Down are the
  expected keys, not Left/Right.
- **Don't nest arrow-hungry widgets.** A listbox or combobox inside a toolbar
  fights it for arrow keys.
- **A toolbar of only links is navigation.** Use `<nav>`.

---

## Vanilla

### Do

```html
<!-- Named, because a page may have several. Roving tabindex makes the whole bar
     one Tab stop (RAWeb 12.8). -->
<div role="toolbar" aria-label="Text formatting" id="format-toolbar">
  <!-- Exactly one tabindex="0" — the entry point. -->
  <button type="button" tabindex="0" aria-pressed="false">
    <svg aria-hidden="true" focusable="false"><use href="#icon-bold"/></svg>
    <span class="sr-only">Bold</span>
  </button>
  <button type="button" tabindex="-1" aria-pressed="false">
    <svg aria-hidden="true" focusable="false"><use href="#icon-italic"/></svg>
    <span class="sr-only">Italic</span>
  </button>
  <button type="button" tabindex="-1" aria-pressed="false">
    <svg aria-hidden="true" focusable="false"><use href="#icon-underline"/></svg>
    <span class="sr-only">Underline</span>
  </button>

  <!-- Separators are decorative. role="separator" without tabindex is NOT the
       windowsplitter widget — it is just a divider. -->
  <span role="separator" aria-orientation="vertical"></span>

  <button type="button" tabindex="-1">
    <svg aria-hidden="true" focusable="false"><use href="#icon-link"/></svg>
    <span class="sr-only">Insert link</span>
  </button>
</div>
```

```css
[role="toolbar"] {
  display: flex;
  gap: 0.25rem;
}

[role="toolbar"] button {
  min-inline-size: 44px;
  min-block-size: 44px;
}

/* Real focus moves here, so :focus-visible works (RAWeb 10.7). */
[role="toolbar"] button:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}

/* Pressed state must not be colour alone (RAWeb 3.1). */
[role="toolbar"] button[aria-pressed="true"] {
  background: #0056b3;
  color: #fff;
  box-shadow: inset 0 0 0 2px #003d80;
}
```

```js
const toolbar = document.getElementById('format-toolbar');
const items = [...toolbar.querySelectorAll('button')];

function focusItem(index) {
  // tabindex and focus move together: the toolbar's single Tab stop must always
  // be the item the user last used.
  items.forEach((item, i) => item.setAttribute('tabindex', i === index ? '0' : '-1'));
  items[index].focus();
}

toolbar.addEventListener('keydown', (event) => {
  const index = items.indexOf(document.activeElement);
  if (index === -1) return;

  let next = null;
  if (event.key === 'ArrowRight') next = (index + 1) % items.length;
  if (event.key === 'ArrowLeft') next = (index - 1 + items.length) % items.length;
  if (event.key === 'Home') next = 0;
  if (event.key === 'End') next = items.length - 1;

  if (next === null) return;   // Tab, Enter, Space all pass through
  event.preventDefault();      // only for keys we handled
  focusItem(next);
});

// Returning to the toolbar by Tab lands on the last-used item, because its
// tabindex="0" persisted. That is the point of roving tabindex.
toolbar.addEventListener('click', (event) => {
  const button = event.target.closest('button');
  if (!button) return;
  const index = items.indexOf(button);
  items.forEach((item, i) => item.setAttribute('tabindex', i === index ? '0' : '-1'));
  // Toggle buttons keep their own state — see button.md.
  if (button.hasAttribute('aria-pressed')) {
    const pressed = button.getAttribute('aria-pressed') === 'true';
    button.setAttribute('aria-pressed', String(!pressed));
  }
});
```

### Don't

```html
<!-- DON'T: role="toolbar" with no roving tabindex. THE toolbar bug.
     → The role announces "toolbar" and promises one Tab stop. Every button is
       still a separate stop. You have added a promise and broken it — worse
       than no role at all (RAWeb 12.8). -->
<div role="toolbar" aria-label="Text formatting">
  <button type="button">Bold</button>
  <button type="button">Italic</button>
  <button type="button">Underline</button>
</div>

<!-- DON'T: role="toolbar" on three buttons.
     → Nothing to save. Three Tab stops is fine; a toolbar means the user must
       now know the arrow-key model. Cost, no benefit. -->
<div role="toolbar" aria-label="Actions">
  <button type="button">Save</button>
  <button type="button">Cancel</button>
</div>

<!-- DON'T: an unnamed toolbar (RAWeb 7.1).
     → "toolbar" / "toolbar". Which one is formatting? -->
<div role="toolbar">…</div>

<!-- DON'T: several tabindex="0".
     → Defeats the roving model — those become separate Tab stops. Exactly one. -->
<button type="button" tabindex="0">Bold</button>
<button type="button" tabindex="0">Italic</button>

<!-- DON'T: a toolbar of links.
     → Links in a toolbar are announced as a toolbar of links and demand arrows.
       This is navigation. Use <nav><ul><a>. -->
<div role="toolbar" aria-label="Site sections">
  <a href="/">Home</a>
  <a href="/about">About</a>
</div>

<!-- DON'T: a horizontal toolbar with aria-orientation="vertical".
     → Announces "vertical", so the user tries Up/Down while you handle
       Left/Right. -->
<div role="toolbar" aria-orientation="vertical" class="horizontal-bar">…</div>

<!-- DON'T: nest an arrow-driven widget directly in a toolbar.
     → The listbox wants Up/Down; the toolbar wants Left/Right; both fire. Wrap
       it, or use a menu-button in the toolbar instead. -->
<div role="toolbar">
  <ul role="listbox"><li role="option">…</li></ul>
</div>
```

```js
// DON'T: reset tabindex to the first item on blur.
//     → Tabbing away and back should return you to where you were. Resetting
//       to item 1 loses the user's place every time.
toolbar.addEventListener('focusout', () => focusItem(0));

// DON'T: blanket preventDefault.
//     → Kills Tab (the only way out — RAWeb 12.9), Enter and Space.
toolbar.addEventListener('keydown', (event) => {
  event.preventDefault();
  handleKey(event);
});
```

---

## React

### Do

```jsx
import { useId, useRef, useState } from 'react';

const TOOLS = [
  { key: 'bold', label: 'Bold' },
  { key: 'italic', label: 'Italic' },
  { key: 'underline', label: 'Underline' },
];

export function FormatToolbar({ label = 'Text formatting' }) {
  const [focusIndex, setFocusIndex] = useState(0);
  const [pressed, setPressed] = useState({});
  const itemRefs = useRef([]);

  const focusItem = (index) => {
    setFocusIndex(index);
    itemRefs.current[index]?.focus();
  };

  const onKeyDown = (event) => {
    let next = null;
    if (event.key === 'ArrowRight') next = (focusIndex + 1) % TOOLS.length;
    if (event.key === 'ArrowLeft') next = (focusIndex - 1 + TOOLS.length) % TOOLS.length;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = TOOLS.length - 1;

    if (next === null) return;
    event.preventDefault();
    focusItem(next);
  };

  return (
    <div role="toolbar" aria-label={label} onKeyDown={onKeyDown}>
      {TOOLS.map((tool, i) => (
        <button
          key={tool.key}
          ref={(node) => { itemRefs.current[i] = node; }}
          type="button"
          // Exactly one 0 — the roving Tab stop.
          tabIndex={i === focusIndex ? 0 : -1}
          aria-pressed={Boolean(pressed[tool.key])}
          onClick={() => {
            setFocusIndex(i);   // clicking also moves the roving stop
            setPressed((p) => ({ ...p, [tool.key]: !p[tool.key] }));
          }}
        >
          {tool.label}
        </button>
      ))}
    </div>
  );
}
```

### Don't

```jsx
// DON'T: tabIndex={0} on every button — the role promises one stop, you gave
//        three.
<button type="button" tabIndex={0} aria-pressed={isPressed}>{label}</button>

// DON'T: role="toolbar" with no key handling at all.
//     → Announced as a toolbar; arrows do nothing. Users who know the pattern
//       are stranded.
<div role="toolbar" aria-label="Formatting">
  {TOOLS.map((t) => <button key={t.key}>{t.label}</button>)}
</div>

// DON'T: reset focusIndex on blur — loses the user's place.
<div role="toolbar" onBlur={() => setFocusIndex(0)}>
```

---

## Angular

### Do

```ts
import { Component, ElementRef, input, signal, viewChildren } from '@angular/core';

@Component({
  selector: 'app-format-toolbar',
  template: `
    <div role="toolbar" [attr.aria-label]="label()" (keydown)="onKeyDown($event)">
      @for (tool of tools; track tool.key; let i = $index) {
        <button
          #item
          type="button"
          [tabIndex]="i === focusIndex() ? 0 : -1"
          [attr.aria-pressed]="pressed()[tool.key] ?? false"
          (click)="activate(i, tool.key)"
        >
          {{ tool.label }}
        </button>
      }
    </div>
  `,
})
export class FormatToolbarComponent {
  readonly label = input('Text formatting');
  protected readonly tools = [
    { key: 'bold', label: 'Bold' },
    { key: 'italic', label: 'Italic' },
    { key: 'underline', label: 'Underline' },
  ];
  protected readonly focusIndex = signal(0);
  protected readonly pressed = signal<Record<string, boolean>>({});
  private readonly items = viewChildren<ElementRef<HTMLButtonElement>>('item');

  protected activate(index: number, key: string): void {
    this.focusIndex.set(index);
    this.pressed.update((p) => ({ ...p, [key]: !p[key] }));
  }

  protected onKeyDown(event: KeyboardEvent): void {
    const count = this.tools.length;
    let next: number | null = null;
    if (event.key === 'ArrowRight') next = (this.focusIndex() + 1) % count;
    if (event.key === 'ArrowLeft') next = (this.focusIndex() - 1 + count) % count;
    if (event.key === 'Home') next = 0;
    if (event.key === 'End') next = count - 1;

    if (next === null) return;
    event.preventDefault();
    this.focusIndex.set(next);
    queueMicrotask(() => this.items()[next!]?.nativeElement.focus());
  }
}
```

**Or use the CDK.** `FocusKeyManager` from `@angular/cdk/a11y` implements roving
tabindex, arrows, wrapping and typeahead. For a toolbar it is a clean fit.

### Don't

```html
<!-- DON'T: [attr.tabindex] with a boolean — renders tabindex="false", parsed as
     0, so every button is a Tab stop. Use [tabIndex]. -->
<button role="toolbar-item" [attr.tabindex]="i === focusIndex()">
```

---

## Web Component

### Do

```js
// Light DOM: the author supplies the buttons, and the component only manages
// the roving tabindex. aria-label on the host would not reach a shadow toolbar.
class A11yToolbar extends HTMLElement {
  connectedCallback() {
    this.addEventListener('keydown', (event) => {
      const items = this.#items;
      const index = items.indexOf(document.activeElement);
      if (index === -1) return;

      let next = null;
      if (event.key === 'ArrowRight') next = (index + 1) % items.length;
      if (event.key === 'ArrowLeft') next = (index - 1 + items.length) % items.length;
      if (event.key === 'Home') next = 0;
      if (event.key === 'End') next = items.length - 1;

      if (next === null) return;
      event.preventDefault();
      this.#focus(next);
    });

    this.addEventListener('click', (event) => {
      const index = this.#items.indexOf(event.target.closest('button'));
      if (index > -1) this.#setRovingStop(index);
    });

    this.#setRovingStop(0);
  }

  get #items() {
    return [...this.querySelectorAll('button')];
  }

  #setRovingStop(index) {
    this.#items.forEach((item, i) => item.setAttribute('tabindex', i === index ? '0' : '-1'));
  }

  #focus(index) {
    this.#setRovingStop(index);
    this.#items[index].focus();
  }
}

customElements.define('a11y-toolbar', A11yToolbar);
```

```html
<a11y-toolbar role="toolbar" aria-label="Text formatting">
  <button type="button">Bold</button>
  <button type="button">Italic</button>
</a11y-toolbar>
```

### Don't

```js
// DON'T: buttons in a shadow root with role="toolbar" on the host.
//     → The role and the buttons are in different trees. The toolbar's own
//       accessible name is fine (aria-label is text), but authors then cannot
//       style or script their own buttons, and the whole point of a toolbar —
//       being a container for the author's controls — is lost.
```

---

## Verify

- **The one-Tab-stop check — the whole reason this pattern exists.** Tab into
  the toolbar. Tab **again**. You must be *past* the entire toolbar. If you land
  on the second button, roving tabindex is missing and the role is lying.
- **The return check:** move to the third button with arrows, Tab away, then
  Shift+Tab back. You must land on the **third** button, not the first.
- **Keyboard:** arrows move and wrap; Home/End jump; **Tab always exits**
  (RAWeb 12.9).
- **Screen reader:** "«name», toolbar" then "Bold, toggle button, not pressed".
  If you hear no toolbar name, add `aria-label`.
- **Automated:** axe catches an unnamed toolbar. It does **not** catch missing
  roving tabindex — the single defect this pattern is prone to. `role="toolbar"`
  with twenty Tab stops is perfectly valid ARIA and completely pointless.
