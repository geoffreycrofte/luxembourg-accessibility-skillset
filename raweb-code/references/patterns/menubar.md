# Menubar — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show menubar`

> **Read [`menu-button.md`](menu-button.md) first.** This is the same mistake one
> level up, and the decision table there is the important part.

---

## Almost certainly not this pattern

`role="menubar"` models a **desktop application menu bar** — File, Edit, View,
Help. Not "the menu at the top of the website".

| What you have | Use |
|---|---|
| Site navigation, even with dropdowns | **`<nav>` + `<ul>` + `<a>`**, no ARIA. See [`landmarks.md`](landmarks.md) |
| A hamburger revealing site nav | [`disclosure`](disclosure.md) wrapping a `<nav>` |
| A row of dropdowns of *links* | `<nav>` + [`disclosure`](disclosure.md) per group |
| A genuine application menu bar in an editor / IDE / design tool | **menubar** (this file) |

**What goes wrong if you use it for site nav:** the screen reader announces
"menu bar" and switches into **application mode**. The user's normal reading
keys stop working. They're now expected to navigate with Left/Right and Up/Down
— but `<a href>` elements don't implement those keys, so nothing happens. They
are stuck in a mode they didn't ask for, on a widget that doesn't honour its own
contract. **This is strictly worse than the same markup with no ARIA at all.**

Nothing will flag this. It's valid ARIA. Only judgement catches it.

> **If you're building a website, stop here and use `<nav>`.** The rest of this
> file is for the rare case where you really are building an application menu bar.

---

## Universal rules

- **One Tab stop, roving tabindex.** Left/Right along the bar, Down opens a
  submenu and focuses its first item, Escape closes back to the bar.
  (RAWeb 12.8)
- **Real focus moves.** `.focus()`, not `aria-activedescendant`.
- **`aria-haspopup="menu"` + `aria-expanded` on menuitems that open submenus.**
  (RAWeb 7.1)
- **Only `menuitem`/`menuitemcheckbox`/`menuitemradio`/`separator` children.**
  An `<a href>` inside `role="menu"` is invalid.
- **Never hover-only.** Submenus must open on Enter/Space/Down. (RAWeb 7.3)
- **Escape and Tab always let the user out.** (RAWeb 12.9)
- **Hide closed submenus with `hidden`.** (RAWeb 10.8)

---

## Vanilla

### Do

```html
<!-- A genuine application menu bar: these are ACTIONS, not destinations. -->
<div role="menubar" aria-label="Editor" id="editor-menubar">
  <!-- Roving tabindex: exactly one 0 on the bar. -->
  <button type="button" role="menuitem" tabindex="0"
          aria-haspopup="menu" aria-expanded="false" aria-controls="menu-file">
    File
  </button>
  <ul role="menu" id="menu-file" aria-label="File" hidden>
    <li role="none"><button type="button" role="menuitem" tabindex="-1">New</button></li>
    <li role="none"><button type="button" role="menuitem" tabindex="-1">Open…</button></li>
    <li role="none"><span role="separator"></span></li>
    <li role="none"><button type="button" role="menuitem" tabindex="-1">Save</button></li>
  </ul>

  <button type="button" role="menuitem" tabindex="-1"
          aria-haspopup="menu" aria-expanded="false" aria-controls="menu-view">
    View
  </button>
  <ul role="menu" id="menu-view" aria-label="View" hidden>
    <!-- menuitemcheckbox for a toggleable option — aria-checked, not
         aria-pressed. -->
    <li role="none">
      <button type="button" role="menuitemcheckbox" tabindex="-1" aria-checked="true">
        Show sidebar
      </button>
    </li>
    <li role="none">
      <button type="button" role="menuitemcheckbox" tabindex="-1" aria-checked="false">
        Show minimap
      </button>
    </li>
  </ul>
</div>
```

```css
[role="menubar"] { display: flex; }
[role="menu"] { list-style: none; margin: 0; padding: 0; position: absolute; }

[role="menuitem"]:focus-visible,
[role="menuitemcheckbox"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}

/* Checked state not by colour alone (RAWeb 3.1) — the ✓ is generated content
   keyed off the attribute, so visual and announced state cannot diverge. */
[role="menuitemcheckbox"][aria-checked="true"]::before { content: "✓ "; }
[role="menuitemcheckbox"][aria-checked="false"]::before { content: ""; }
```

```js
const menubar = document.getElementById('editor-menubar');
const topItems = [...menubar.querySelectorAll(':scope > [role="menuitem"]')];

const submenuOf = (item) => document.getElementById(item.getAttribute('aria-controls'));
const itemsIn = (menu) => [...menu.querySelectorAll('[role^="menuitem"]')];

function setRovingStop(index) {
  topItems.forEach((item, i) => item.setAttribute('tabindex', i === index ? '0' : '-1'));
}

function openSubmenu(topItem, focusIndex = 0) {
  closeAll({ except: topItem });
  const menu = submenuOf(topItem);
  if (!menu) return;
  topItem.setAttribute('aria-expanded', 'true');
  menu.hidden = false;
  itemsIn(menu)[focusIndex]?.focus();
}

function closeAll({ except = null, restoreFocusTo = null } = {}) {
  for (const item of topItems) {
    if (item === except) continue;
    const menu = submenuOf(item);
    if (!menu) continue;
    item.setAttribute('aria-expanded', 'false');
    menu.hidden = true;
  }
  restoreFocusTo?.focus();
}

// The menu bar itself: Left/Right move along; Down opens.
menubar.addEventListener('keydown', (event) => {
  const topIndex = topItems.indexOf(document.activeElement);
  if (topIndex === -1) return;

  const item = topItems[topIndex];
  let next = null;

  if (event.key === 'ArrowRight') next = (topIndex + 1) % topItems.length;
  if (event.key === 'ArrowLeft') next = (topIndex - 1 + topItems.length) % topItems.length;
  if (event.key === 'Home') next = 0;
  if (event.key === 'End') next = topItems.length - 1;

  if (next !== null) {
    event.preventDefault();
    closeAll();
    setRovingStop(next);
    topItems[next].focus();
    return;
  }

  if (event.key === 'ArrowDown') { event.preventDefault(); openSubmenu(item, 0); }
  if (event.key === 'ArrowUp') { event.preventDefault(); openSubmenu(item, itemsIn(submenuOf(item)).length - 1); }
  if (event.key === 'Escape') closeAll();
});

// Inside a submenu: Up/Down move; Escape returns to the bar; Left/Right move to
// the adjacent top-level menu — the desktop model users expect.
for (const topItem of topItems) {
  const menu = submenuOf(topItem);
  if (!menu) continue;

  menu.addEventListener('keydown', (event) => {
    const items = itemsIn(menu);
    const index = items.indexOf(document.activeElement);
    if (index === -1) return;

    if (event.key === 'ArrowDown') { event.preventDefault(); items[(index + 1) % items.length].focus(); }
    else if (event.key === 'ArrowUp') { event.preventDefault(); items[(index - 1 + items.length) % items.length].focus(); }
    else if (event.key === 'Home') { event.preventDefault(); items[0].focus(); }
    else if (event.key === 'End') { event.preventDefault(); items.at(-1).focus(); }
    else if (event.key === 'Escape') {
      event.preventDefault();
      closeAll({ restoreFocusTo: topItem });   // back to the bar (RAWeb 12.8)
    }
    else if (event.key === 'ArrowRight' || event.key === 'ArrowLeft') {
      event.preventDefault();
      const topIndex = topItems.indexOf(topItem);
      const delta = event.key === 'ArrowRight' ? 1 : -1;
      const nextTop = topItems[(topIndex + delta + topItems.length) % topItems.length];
      setRovingStop(topItems.indexOf(nextTop));
      openSubmenu(nextTop, 0);
    }
    else if (event.key === 'Tab') {
      closeAll();   // no preventDefault — Tab leaves (RAWeb 12.9)
    }
  });

  menu.addEventListener('click', (event) => {
    const item = event.target.closest('[role^="menuitem"]');
    if (!item) return;
    if (item.getAttribute('role') === 'menuitemcheckbox') {
      item.setAttribute('aria-checked', String(item.getAttribute('aria-checked') !== 'true'));
    }
    closeAll({ restoreFocusTo: topItem });
  });
}

menubar.addEventListener('click', (event) => {
  const item = event.target.closest(':scope > [role="menuitem"]');
  if (!item) return;
  setRovingStop(topItems.indexOf(item));
  submenuOf(item)?.hidden ? openSubmenu(item) : closeAll();
});

document.addEventListener('pointerdown', (event) => {
  if (!menubar.contains(event.target)) closeAll();
});
```

### Don't

```html
<!-- DON'T: menubar for site navigation. THE mistake.
     → Screen readers announce "menu bar", enter application mode, and the
       user's reading keys stop working. They are told to use arrows; <a>
       elements do not implement arrows; nothing happens. Worse than no ARIA.
       This is <nav><ul><li><a>. -->
<div role="menubar" aria-label="Main">
  <a role="menuitem" href="/">Home</a>
  <a role="menuitem" href="/about">About</a>
  <a role="menuitem" href="/contact">Contact</a>
</div>

<!-- DON'T: links inside role="menu".
     → Invalid: role="menu" permits only menuitem/menuitemcheckbox/
       menuitemradio/separator. And if it navigates, it is not a menu. -->
<ul role="menu">
  <li role="none"><a role="menuitem" href="/products">Products</a></li>
</ul>

<!-- DON'T: hover-only submenus.
     → Keyboard users can never open them (RAWeb 7.3). -->
<style>.menu-item:hover .submenu { display: block; }</style>

<!-- DON'T: aria-expanded on the submenu instead of the menuitem.
     → The menuitem announces no state. -->
<button role="menuitem" aria-haspopup="menu">File</button>
<ul role="menu" aria-expanded="false">…</ul>

<!-- DON'T: aria-pressed on a menuitemcheckbox.
     → menuitemcheckbox carries state via aria-checked. Two mechanisms = two
       announcements. -->
<button role="menuitemcheckbox" aria-checked="true" aria-pressed="true">Show sidebar</button>

<!-- DON'T: every top-level item tabbable.
     → A menubar is ONE Tab stop. Roving tabindex. -->
<button role="menuitem" tabindex="0">File</button>
<button role="menuitem" tabindex="0">Edit</button>
```

```js
// DON'T: trap Tab inside the menubar.
//     → Escape and Tab are the two exits. Capturing Tab is a keyboard trap
//       (RAWeb 12.9).
if (event.key === 'Tab') event.preventDefault();

// DON'T: leave focus in a closed submenu.
//     → Escape hides the menu while focus is still inside it. Focus falls to
//       <body> and the user is dumped at the top of the page. Restore to the
//       parent menuitem (RAWeb 12.8).
menu.hidden = true;
```

---

## React

For a genuine application menu bar, the state machine (open menu, roving stop,
focus target) is the whole job:

```jsx
import { useEffect, useRef, useState } from 'react';

const MENUS = [
  { key: 'file', label: 'File', items: ['New', 'Open…', 'Save'] },
  { key: 'view', label: 'View', items: ['Show sidebar', 'Show minimap'] },
];

export function Menubar({ label = 'Editor', onAction }) {
  const [openKey, setOpenKey] = useState(null);
  const [topIndex, setTopIndex] = useState(0);
  const [itemIndex, setItemIndex] = useState(0);
  const topRefs = useRef([]);
  const itemRefs = useRef({});

  // Real focus follows state — in a menubar, focus IS the state.
  useEffect(() => {
    if (openKey) itemRefs.current[openKey]?.[itemIndex]?.focus();
    else topRefs.current[topIndex]?.focus();
  }, [openKey, topIndex, itemIndex]);

  const close = () => { setOpenKey(null); setItemIndex(0); };

  return (
    <div role="menubar" aria-label={label}>
      {MENUS.map((menu, i) => (
        <div key={menu.key}>
          <button
            ref={(n) => { topRefs.current[i] = n; }}
            type="button"
            role="menuitem"
            tabIndex={i === topIndex ? 0 : -1}
            aria-haspopup="menu"
            aria-expanded={openKey === menu.key}
            onClick={() => { setTopIndex(i); setOpenKey((k) => (k === menu.key ? null : menu.key)); }}
            onKeyDown={(e) => {
              if (e.key === 'ArrowRight') { e.preventDefault(); close(); setTopIndex((i + 1) % MENUS.length); }
              if (e.key === 'ArrowLeft') { e.preventDefault(); close(); setTopIndex((i - 1 + MENUS.length) % MENUS.length); }
              if (e.key === 'ArrowDown') { e.preventDefault(); setItemIndex(0); setOpenKey(menu.key); }
            }}
          >
            {menu.label}
          </button>

          <ul role="menu" aria-label={menu.label} hidden={openKey !== menu.key}>
            {menu.items.map((item, j) => (
              <li role="none" key={item}>
                <button
                  ref={(n) => {
                    itemRefs.current[menu.key] ??= [];
                    itemRefs.current[menu.key][j] = n;
                  }}
                  type="button"
                  role="menuitem"
                  tabIndex={-1}
                  onClick={() => { onAction(item); close(); }}
                  onKeyDown={(e) => {
                    if (e.key === 'ArrowDown') { e.preventDefault(); setItemIndex((j + 1) % menu.items.length); }
                    if (e.key === 'ArrowUp') { e.preventDefault(); setItemIndex((j - 1 + menu.items.length) % menu.items.length); }
                    if (e.key === 'Escape') { e.preventDefault(); close(); }
                    if (e.key === 'Tab') close();   // no preventDefault
                  }}
                >
                  {item}
                </button>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}
```

### Don't

```jsx
// DON'T: role="menubar" on your site header. See the top of this file.
<header>
  <div role="menubar">
    <a role="menuitem" href="/">Home</a>
  </div>
</header>

// DON'T: render submenus conditionally while using aria-controls.
//     → Dangling IDREF whenever closed.
{openKey === menu.key && <ul role="menu" id={`menu-${menu.key}`}>…</ul>}
```

---

## Angular

The same state machine. **If you're on the CDK, use `@angular/cdk/menu`** —
`cdkMenuBar`, `cdkMenu`, `cdkMenuItem` implement the full model including
roving focus, Escape, and outside-click:

```ts
import { Component } from '@angular/core';
import { CdkMenu, CdkMenuBar, CdkMenuItem, CdkMenuTrigger } from '@angular/cdk/menu';

@Component({
  selector: 'app-editor-menubar',
  imports: [CdkMenuBar, CdkMenu, CdkMenuItem, CdkMenuTrigger],
  template: `
    <div cdkMenuBar aria-label="Editor">
      <button type="button" cdkMenuItem [cdkMenuTriggerFor]="fileMenu">File</button>
      <button type="button" cdkMenuItem [cdkMenuTriggerFor]="viewMenu">View</button>
    </div>

    <ng-template #fileMenu>
      <div cdkMenu aria-label="File">
        <button type="button" cdkMenuItem (cdkMenuItemTriggered)="action('new')">New</button>
        <button type="button" cdkMenuItem (cdkMenuItemTriggered)="action('open')">Open…</button>
      </div>
    </ng-template>

    <ng-template #viewMenu>
      <div cdkMenu aria-label="View">
        <button type="button" cdkMenuItemCheckbox>Show sidebar</button>
      </div>
    </ng-template>
  `,
})
export class EditorMenubarComponent {
  action(name: string): void { /* … */ }
}
```

Hand-rolling this in Angular means reimplementing the CDK. Don't, unless you
have a specific reason.

### Don't

```html
<!-- DON'T: cdkMenuBar on site navigation. The CDK will implement the menubar
     pattern perfectly — and the pattern is still wrong for nav. -->
<nav cdkMenuBar>
  <a cdkMenuItem href="/">Home</a>
</nav>
```

---

## Web Component

### Do

Light DOM, for the same reason as [`menu-button.md`](menu-button.md):
`aria-controls` (menuitem → submenu) and `aria-labelledby` (submenu → menuitem)
are IDREFs and cannot cross a shadow boundary.

```js
class A11yMenubar extends HTMLElement {
  connectedCallback() {
    this.#topItems = [...this.querySelectorAll(':scope > [role="menuitem"]')];
    this.addEventListener('keydown', (e) => this.#onKeyDown(e));
    this.#onDocPointerDown = (e) => { if (!this.contains(e.target)) this.#closeAll(); };
    document.addEventListener('pointerdown', this.#onDocPointerDown);
  }

  disconnectedCallback() {
    document.removeEventListener('pointerdown', this.#onDocPointerDown);
  }

  #topItems = [];
  #onDocPointerDown;

  #closeAll() {
    for (const item of this.#topItems) {
      item.setAttribute('aria-expanded', 'false');
      const menu = this.querySelector(`#${CSS.escape(item.getAttribute('aria-controls'))}`);
      if (menu) menu.hidden = true;
    }
  }

  #onKeyDown(event) { /* same model as the vanilla example */ }
}

customElements.define('a11y-menubar', A11yMenubar);
```

### Don't

```js
// DON'T: submenus in a shadow root.
//     → aria-controls and aria-labelledby both fail silently across the
//       boundary: the menuitem controls nothing and the submenu is unnamed.
```

---

## Verify

- **First: is it a menubar at all?** If the items navigate, it isn't. This is the
  only check that matters most of the time.
- **Keyboard:** the bar is **one** Tab stop. Left/Right move along it. Down opens
  a submenu **and focus lands on the first item**. Escape closes **and returns
  focus to the parent menuitem**. Tab exits entirely (RAWeb 12.9).
- **The focus-on-close check:** open a submenu, press Escape, then Tab. If focus
  went to `<body>` and you're at the top of the page, you hid the submenu with
  focus still inside it.
- **Screen reader:** "«name», menu bar" then "File, menu item, has pop-up,
  collapsed". If you hear "link", you have `<a>`s and this is navigation.
- **Automated:** axe catches invalid `role="menu"` children and missing names. It
  will **never** tell you that a menubar over site navigation is wrong — that's
  valid ARIA and a genuine accessibility regression at the same time.
