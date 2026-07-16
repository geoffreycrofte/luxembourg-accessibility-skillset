# Menu Button — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show menu-button`

**Read this whole file** before building one — starting with the table below,
because **most things called "menus" are not this pattern.**

---

## Is it actually a menu?

`role="menu"` models a **desktop application menu**: a list of *actions* you
invoke, like File → Save. It is not the word "menu" as used in web design.

| What the popup contains | Pattern | Why |
|---|---|---|
| Actions on a thing — Edit, Duplicate, Delete | **menu-button** (this file) | Real actions, arrow-key navigation |
| Site navigation links — Home, About, Contact | [`landmarks`](landmarks.md) — `<nav>` + `<ul>` + `<a>` | Links are not menu items |
| A "hamburger" opening site nav | [`disclosure`](disclosure.md) wrapping a `<nav>` | It shows/hides content |
| Arbitrary content — a form, text, a panel | [`disclosure`](disclosure.md) | Not actions |
| Choosing a value that gets submitted | [`combobox`](combobox.md) / `<select>` | It sets a value |
| Filter/sort options that change a view | [`disclosure`](disclosure.md) + checkboxes/radios | They are form controls |

**The cost of getting this wrong is real.** Put `role="menu"` on your site
navigation and a screen reader announces "menu, 5 items", switches into
application mode, and the user's normal reading keys stop working — they now
expect arrow keys, which plain links don't implement. A nav bar wrapped in
`role="menu"` is *less* accessible than the same markup with no ARIA at all.

> **If in doubt, it's a [`disclosure`](disclosure.md).** Disclosure is almost
> always the right answer for web UI, and it is far harder to get wrong.

---

## Universal rules

- **`aria-haspopup="menu"` + `aria-expanded` on the button.** Together they
  announce "menu button, collapsed" — the user learns it opens a menu before
  pressing it. (RAWeb 7.1)
- **Real focus moves here.** Unlike [`combobox`](combobox.md), you call
  `.focus()` on the menu item. Do **not** use `aria-activedescendant` in this
  pattern.
- **Roving tabindex: every item is `tabindex="-1"`.** Items are reached with
  arrows, never Tab.
- **Only `menuitem` children.** Inside `role="menu"`, valid children are
  `menuitem`, `menuitemradio`, `menuitemcheckbox`. An `<a href>` or `<button>`
  inside `role="menu"` is invalid and announced inconsistently.
- **Escape closes and returns focus to the button.** Always. (RAWeb 12.9, 12.8)
- **Tab closes the menu and moves on.** Never trap it. (RAWeb 12.9)
- **Hide the closed menu with `hidden`,** not `opacity`. (RAWeb 10.8)

---

## Vanilla

### Do

```html
<div class="menu-button">
  <button type="button" id="actions-button"
          aria-haspopup="menu" aria-expanded="false" aria-controls="actions-menu">
    Actions
    <svg aria-hidden="true" focusable="false" width="12" height="12"><use href="#icon-chevron-down"/></svg>
  </button>

  <!-- Menu items are <button role="menuitem">: a real button gives us focus and
       activation; role="menuitem" replaces the button role with the one
       role="menu" requires of its children. tabindex="-1" keeps them out of the
       tab order — arrows reach them. -->
  <ul id="actions-menu" role="menu" aria-labelledby="actions-button" hidden>
    <li role="none">
      <button type="button" role="menuitem" tabindex="-1">Edit</button>
    </li>
    <li role="none">
      <button type="button" role="menuitem" tabindex="-1">Duplicate</button>
    </li>
    <li role="none">
      <button type="button" role="menuitem" tabindex="-1">Delete</button>
    </li>
  </ul>
</div>
```

`role="none"` on the `<li>`: `role="menu"` only permits `menuitem` children, but
a `<ul>` contributes `listitem` semantics that would sit between them. `role="none"`
removes the `<li>` from the accessibility tree while keeping the markup valid.

```css
/* Real focus moves here, so :focus-visible works — unlike combobox (RAWeb 10.7). */
[role="menuitem"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
  background: #eef4fb;
}

[role="menu"] {
  list-style: none;
  margin: 0;
  padding: 0;
}
```

```js
const button = document.getElementById('actions-button');
const menu = document.getElementById('actions-menu');
const items = [...menu.querySelectorAll('[role="menuitem"]')];

function openMenu(focusIndex = 0) {
  button.setAttribute('aria-expanded', 'true');
  menu.hidden = false;
  items[focusIndex].focus(); // REAL focus — not aria-activedescendant
}

function closeMenu({ restoreFocus = true } = {}) {
  button.setAttribute('aria-expanded', 'false');
  menu.hidden = true;
  if (restoreFocus) button.focus(); // RAWeb 12.8
}

button.addEventListener('click', () => {
  menu.hidden ? openMenu() : closeMenu();
});

button.addEventListener('keydown', (event) => {
  if (event.key === 'ArrowDown') { event.preventDefault(); openMenu(0); }
  if (event.key === 'ArrowUp') { event.preventDefault(); openMenu(items.length - 1); }
  // Enter and Space already fire click on a native button — nothing to add.
});

menu.addEventListener('keydown', (event) => {
  const index = items.indexOf(document.activeElement);
  if (index === -1) return;

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      items[(index + 1) % items.length].focus();
      break;
    case 'ArrowUp':
      event.preventDefault();
      items[(index - 1 + items.length) % items.length].focus();
      break;
    case 'Home':
      event.preventDefault();
      items[0].focus();
      break;
    case 'End':
      event.preventDefault();
      items.at(-1).focus();
      break;
    case 'Escape':
      closeMenu(); // focus back to the button
      break;
    case 'Tab':
      closeMenu({ restoreFocus: false }); // let Tab through (RAWeb 12.9)
      break;
  }
});

// Clicking an item runs the action and closes.
menu.addEventListener('click', (event) => {
  const item = event.target.closest('[role="menuitem"]');
  if (!item) return;
  runAction(item.textContent.trim());
  closeMenu();
});

// Outside click closes. pointerdown, not click — see the Don't below.
document.addEventListener('pointerdown', (event) => {
  if (!menu.hidden && !event.target.closest('.menu-button')) {
    closeMenu({ restoreFocus: false });
  }
});
```

### Don't

```html
<!-- DON'T: role="menu" on site navigation. THE mistake this pattern invites.
     → Screen readers announce "menu, 5 items" and switch to application mode.
       Normal reading keys stop working; the user is told to arrow, but these are
       links, which do not implement arrows. WORSE than no ARIA at all.
       Site nav is <nav><ul><li><a> — with nothing added. -->
<nav>
  <ul role="menu">
    <li role="none"><a role="menuitem" href="/">Home</a></li>
    <li role="none"><a role="menuitem" href="/about">About</a></li>
  </ul>
</nav>

<!-- DON'T: links inside role="menu".
     → role="menu" permits only menuitem/menuitemradio/menuitemcheckbox. An
       <a href> announces as a link where a menuitem is required; behaviour
       varies by screen reader. If they navigate, it is not a menu. -->
<ul role="menu">
  <li role="none"><a href="/edit">Edit</a></li>
</ul>

<!-- DON'T: aria-expanded on the menu instead of the button.
     → The button announces no state; the user never learns it opens anything. -->
<button aria-haspopup="menu">Actions</button>
<ul role="menu" aria-expanded="false">…</ul>

<!-- DON'T: aria-haspopup="true" on a button whose popup is a dialog.
     → "true" is a synonym for "menu". If the popup is a dialog, say
       aria-haspopup="dialog" — or the user is promised a menu and gets a dialog. -->
<button aria-haspopup="true" aria-expanded="false">Settings</button>

<!-- DON'T: tabbable menu items.
     → Every item becomes a Tab stop. Arrows are the navigation here. -->
<button type="button" role="menuitem" tabindex="0">Edit</button>

<!-- DON'T: role="menu" on a hamburger that reveals site nav.
     → It shows/hides content: that is a disclosure wrapping a <nav>. -->
<button aria-haspopup="menu" aria-expanded="false">☰</button>
```

```js
// DON'T: aria-activedescendant in a menu.
//     → Wrong pattern. Menus move REAL focus. aria-activedescendant belongs to
//       combobox/listbox, where focus must stay in a text input.
button.setAttribute('aria-activedescendant', items[index].id);

// DON'T: open the menu without moving focus into it.
//     → A keyboard user presses Enter, the menu appears, and focus is still on
//       the button. They must Tab into it — but items are tabindex="-1", so they
//       cannot reach the menu at all.
function openMenu() {
  menu.hidden = false;
  button.setAttribute('aria-expanded', 'true');
  // missing: items[0].focus()
}

// DON'T: close on the button's blur.
//     → Focus moving INTO the menu blurs the button, so the menu closes the
//       instant it opens. Close on Escape, Tab, item activation, and outside
//       pointerdown.
button.addEventListener('blur', closeMenu);

// DON'T: outside-close on 'click'.
//     → click fires after mouseup. Pressing on an item can close the menu on
//       mousedown-ordering in some flows, and the item's own click never lands.
//       pointerdown + a containment check is predictable.
document.addEventListener('click', () => closeMenu());

// DON'T: restore focus to the button when Tab closed the menu.
//     → Tab means "move forward". Sending focus back to the button makes Tab
//       appear to do nothing — the user is stuck in a loop (RAWeb 12.9).
case 'Tab':
  closeMenu({ restoreFocus: true });
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef, useState } from 'react';

const ACTIONS = ['Edit', 'Duplicate', 'Delete'];

export function MenuButton({ label, onAction }) {
  const [isOpen, setIsOpen] = useState(false);
  const [focusIndex, setFocusIndex] = useState(0);
  const id = useId();
  const buttonRef = useRef(null);
  const itemRefs = useRef([]);
  const wrapperRef = useRef(null);

  // Move real focus whenever the menu opens or the index changes.
  useEffect(() => {
    if (isOpen) itemRefs.current[focusIndex]?.focus();
  }, [isOpen, focusIndex]);

  // Outside pointerdown closes.
  useEffect(() => {
    if (!isOpen) return;
    const onPointerDown = (event) => {
      if (!wrapperRef.current?.contains(event.target)) setIsOpen(false);
    };
    document.addEventListener('pointerdown', onPointerDown);
    return () => document.removeEventListener('pointerdown', onPointerDown);
  }, [isOpen]);

  const close = ({ restoreFocus = true } = {}) => {
    setIsOpen(false);
    if (restoreFocus) buttonRef.current?.focus();
  };

  const onMenuKeyDown = (event) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        setFocusIndex((i) => (i + 1) % ACTIONS.length);
        break;
      case 'ArrowUp':
        event.preventDefault();
        setFocusIndex((i) => (i - 1 + ACTIONS.length) % ACTIONS.length);
        break;
      case 'Home': event.preventDefault(); setFocusIndex(0); break;
      case 'End': event.preventDefault(); setFocusIndex(ACTIONS.length - 1); break;
      case 'Escape': close(); break;
      case 'Tab': close({ restoreFocus: false }); break; // no preventDefault
      default:
    }
  };

  return (
    <div className="menu-button" ref={wrapperRef}>
      <button
        ref={buttonRef}
        type="button"
        id={`${id}-button`}
        aria-haspopup="menu"
        aria-expanded={isOpen}
        aria-controls={`${id}-menu`}
        onClick={() => { setFocusIndex(0); setIsOpen((v) => !v); }}
        onKeyDown={(e) => {
          if (e.key === 'ArrowDown') { e.preventDefault(); setFocusIndex(0); setIsOpen(true); }
          if (e.key === 'ArrowUp') { e.preventDefault(); setFocusIndex(ACTIONS.length - 1); setIsOpen(true); }
        }}
      >
        {label}
      </button>

      <ul
        id={`${id}-menu`}
        role="menu"
        aria-labelledby={`${id}-button`}
        hidden={!isOpen}
        onKeyDown={onMenuKeyDown}
      >
        {ACTIONS.map((action, i) => (
          <li role="none" key={action}>
            <button
              ref={(node) => { itemRefs.current[i] = node; }}
              type="button"
              role="menuitem"
              tabIndex={-1}
              onClick={() => { onAction(action); close(); }}
            >
              {action}
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Don't

```jsx
// DON'T: render the menu only when open, then try to focus it.
//     → The effect runs before the items exist on the very first open in some
//       orderings, so focus silently never moves. Keep it mounted with `hidden`.
{isOpen && <ul role="menu">…</ul>}

// DON'T: onBlur on the wrapper to close.
//     → Fires as focus moves BETWEEN items inside the menu, closing it mid-arrow.
<div onBlur={() => setIsOpen(false)}>…</div>

// DON'T: <a> items for actions.
//     → Invalid inside role="menu", and if they really navigate it is not a menu.
<a role="menuitem" href="/edit">Edit</a>
```

---

## Angular

### Do

```ts
import { Component, ElementRef, effect, inject, input, output, signal, viewChild, viewChildren } from '@angular/core';

const ACTIONS = ['Edit', 'Duplicate', 'Delete'];
let uid = 0;

@Component({
  selector: 'app-menu-button',
  host: { '(document:pointerdown)': 'onDocumentPointerDown($event)' },
  template: `
    <div class="menu-button">
      <button
        #trigger
        type="button"
        [id]="id + '-button'"
        aria-haspopup="menu"
        [attr.aria-expanded]="isOpen()"
        [attr.aria-controls]="id + '-menu'"
        (click)="toggle()"
        (keydown.arrowdown)="open(0, $event)"
        (keydown.arrowup)="open(actions.length - 1, $event)"
      >
        {{ label() }}
      </button>

      <ul
        [id]="id + '-menu'"
        role="menu"
        [attr.aria-labelledby]="id + '-button'"
        [hidden]="!isOpen()"
        (keydown)="onMenuKeyDown($event)"
      >
        @for (action of actions; track action; let i = $index) {
          <li role="none">
            <button #item type="button" role="menuitem" [tabIndex]="-1" (click)="select(action)">
              {{ action }}
            </button>
          </li>
        }
      </ul>
    </div>
  `,
})
export class MenuButtonComponent {
  readonly label = input.required<string>();
  readonly action = output<string>();

  protected readonly actions = ACTIONS;
  protected readonly id = `menu-${uid++}`;
  protected readonly isOpen = signal(false);
  protected readonly focusIndex = signal(0);

  private readonly trigger = viewChild.required<ElementRef<HTMLButtonElement>>('trigger');
  private readonly items = viewChildren<ElementRef<HTMLButtonElement>>('item');
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);

  constructor() {
    effect(() => {
      if (!this.isOpen()) return;
      const index = this.focusIndex();
      // Defer: [hidden] has not been removed yet, and focus() on a hidden
      // element is a no-op.
      queueMicrotask(() => this.items()[index]?.nativeElement.focus());
    });
  }

  protected toggle(): void {
    this.focusIndex.set(0);
    this.isOpen.update((v) => !v);
  }

  protected open(index: number, event: Event): void {
    event.preventDefault();
    this.focusIndex.set(index);
    this.isOpen.set(true);
  }

  protected close(restoreFocus = true): void {
    this.isOpen.set(false);
    if (restoreFocus) this.trigger().nativeElement.focus();
  }

  protected select(action: string): void {
    this.action.emit(action);
    this.close();
  }

  protected onDocumentPointerDown(event: PointerEvent): void {
    if (this.isOpen() && !this.host.nativeElement.contains(event.target as Node)) {
      this.close(false);
    }
  }

  protected onMenuKeyDown(event: KeyboardEvent): void {
    const count = this.actions.length;
    switch (event.key) {
      case 'ArrowDown': event.preventDefault(); this.focusIndex.update((i) => (i + 1) % count); break;
      case 'ArrowUp': event.preventDefault(); this.focusIndex.update((i) => (i - 1 + count) % count); break;
      case 'Home': event.preventDefault(); this.focusIndex.set(0); break;
      case 'End': event.preventDefault(); this.focusIndex.set(count - 1); break;
      case 'Escape': this.close(); break;
      case 'Tab': this.close(false); break; // no preventDefault
    }
  }
}
```

**Or use the CDK.** `@angular/cdk/menu` implements this whole pattern —
`cdkMenu`, `cdkMenuItem`, roving focus, Escape, outside-click. Prefer it.

### Don't

```html
<!-- DON'T: [attr.hidden]="!isOpen()" — renders hidden="false" and still hides.
     Use [hidden]. -->
<ul role="menu" [attr.hidden]="!isOpen()">…</ul>

<!-- DON'T: (blur) on the trigger to close — fires when focus enters the menu. -->
<button (blur)="close()">Actions</button>
```

---

## Web Component

### Do

```js
// Light DOM: aria-controls (button → menu) and aria-labelledby (menu → button)
// are IDREFs and cannot cross a shadow boundary.
class A11yMenuButton extends HTMLElement {
  #button;
  #menu;

  connectedCallback() {
    this.#button = this.querySelector('[aria-haspopup="menu"]');
    this.#menu = this.querySelector('[role="menu"]');

    this.#button.addEventListener('click', () => this.#toggle());
    this.#button.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowDown') { e.preventDefault(); this.#open(0); }
      if (e.key === 'ArrowUp') { e.preventDefault(); this.#open(this.#items.length - 1); }
    });
    this.#menu.addEventListener('keydown', (e) => this.#onMenuKeyDown(e));
    this.#menu.addEventListener('click', (e) => {
      if (e.target.closest('[role="menuitem"]')) this.#close();
    });

    this.#onDocPointerDown = (e) => {
      if (!this.#menu.hidden && !this.contains(e.target)) this.#close(false);
    };
    document.addEventListener('pointerdown', this.#onDocPointerDown);
  }

  disconnectedCallback() {
    // Document-level listener: must be removed, or the element leaks after removal.
    document.removeEventListener('pointerdown', this.#onDocPointerDown);
  }

  #onDocPointerDown;

  get #items() {
    return [...this.#menu.querySelectorAll('[role="menuitem"]')];
  }

  #open(index = 0) {
    this.#button.setAttribute('aria-expanded', 'true');
    this.#menu.hidden = false;
    this.#items[index]?.focus();
  }

  #close(restoreFocus = true) {
    this.#button.setAttribute('aria-expanded', 'false');
    this.#menu.hidden = true;
    if (restoreFocus) this.#button.focus();
  }

  #toggle() {
    this.#menu.hidden ? this.#open(0) : this.#close();
  }

  #onMenuKeyDown(event) {
    const items = this.#items;
    const index = items.indexOf(document.activeElement);
    if (index === -1) return;

    if (event.key === 'ArrowDown') { event.preventDefault(); items[(index + 1) % items.length].focus(); }
    else if (event.key === 'ArrowUp') { event.preventDefault(); items[(index - 1 + items.length) % items.length].focus(); }
    else if (event.key === 'Home') { event.preventDefault(); items[0].focus(); }
    else if (event.key === 'End') { event.preventDefault(); items.at(-1).focus(); }
    else if (event.key === 'Escape') { this.#close(); }
    else if (event.key === 'Tab') { this.#close(false); }
  }
}

customElements.define('a11y-menu-button', A11yMenuButton);
```

### Don't

```js
// DON'T: forget to remove the document listener.
//     → Every mounted-then-removed menu leaves a listener holding a reference
//       to the element. In a SPA that is a genuine leak.
connectedCallback() {
  document.addEventListener('pointerdown', (e) => this.#close());
  // no disconnectedCallback
}

// DON'T: menu in a shadow root, items slotted.
//     → aria-labelledby (menu → button) cannot cross the boundary: the menu
//       loses its accessible name, silently.
```

---

## Verify

- **First, re-read the table at the top.** The most likely defect is that this
  shouldn't be a menu at all.
- **Keyboard-only:** Enter/Space/Down opens **and focus lands on the first
  item** — if focus is still on the button, the menu is unreachable, because
  items are `tabindex="-1"`. Arrows wrap. Escape closes **and returns focus to
  the button**. Tab closes and moves *forward*, never back to the button.
- **Screen reader:** the button must announce "«label», menu button, collapsed".
  If you hear just "button", `aria-haspopup` is missing.
- **Automated:** axe catches invalid children of `role="menu"` and a missing
  accessible name. It does **not** catch the big one — `role="menu"` on site
  navigation is perfectly valid ARIA and completely wrong. Only judgement catches
  that.
