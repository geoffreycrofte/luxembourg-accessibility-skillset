# Tabs — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show tabs`

**Read this whole file** when building tabs. Use `code tabs <framework>` only
when you already know the universal rules and just want the snippet.

> **There is no native tabs element.** Unlike [`disclosure`](disclosure.md) or
> [`dialog-modal`](dialog-modal.md), you cannot fall back on the platform here —
> every role, state and key is yours to get right.

---

## Universal rules

- **The whole tablist is ONE Tab stop.** Not one per tab. Tab lands on the
  selected tab; arrows move between tabs; Tab again leaves for the panel. This
  is *roving tabindex*: `tabindex="0"` on the selected tab, `tabindex="-1"` on
  every other. Without it, a 9-tab bar costs a keyboard user 9 Tab presses to
  cross. (RAWeb 12.8)
- **`aria-selected` does not move focus.** It is a state, not a command. Moving
  focus is a separate `.focus()` call you make yourself. Setting `aria-selected`
  and expecting focus to follow is the most common tabs bug. (RAWeb 7.1)
- **`aria-selected` and `tabindex` must always agree.** The selected tab is the
  one with `tabindex="0"`. If they drift apart, Tab returns the user to a tab
  that isn't the open one.
- **Tab must always escape the tablist.** Arrow keys navigate; Tab exits. If you
  capture Tab, you have built a keyboard trap. (RAWeb 12.9)
- **Hide inactive panels with `hidden`.** Not `opacity: 0`, not z-index
  stacking, not off-screen positioning — those leave every panel's content in
  the accessibility tree and the tab order simultaneously. (RAWeb 10.8)
- **Style focus and selection separately.** They are different states and, with
  manual activation, live on different tabs at the same time. A focus ring that
  only appears on the selected tab makes arrow navigation invisible. (RAWeb 10.7)
- **Only call `preventDefault()` for keys you actually handle.** A blanket
  `preventDefault` in the keydown handler kills Tab, Escape, and screen reader
  passthrough keys.

### Automatic vs manual activation

| | Automatic | Manual |
|---|---|---|
| Arrow key | moves focus **and** selects | moves focus only |
| Enter / Space | — | selects |
| Use when | panels are cheap and instant | switching is slow, destructive, or fires a request |

Automatic is the APG default and feels better. Go manual when arrowing across
five tabs would fire five network requests.

---

## Vanilla

### Do

```html
<div class="tabs">
  <!-- Name the tablist: several tab bars on one page are otherwise
       indistinguishable to a screen reader user. -->
  <div role="tablist" aria-label="Account settings">
    <!-- Selected tab: aria-selected="true" AND tabindex="0". Always together. -->
    <button type="button" role="tab" id="tab-profile"
            aria-selected="true" aria-controls="panel-profile" tabindex="0">
      Profile
    </button>
    <button type="button" role="tab" id="tab-billing"
            aria-selected="false" aria-controls="panel-billing" tabindex="-1">
      Billing
    </button>
    <button type="button" role="tab" id="tab-security"
            aria-selected="false" aria-controls="panel-security" tabindex="-1">
      Security
    </button>
  </div>

  <!-- tabindex="0" on the panel: it holds no focusable element, so without this
       a keyboard user cannot reach or scroll its content. -->
  <div role="tabpanel" id="panel-profile" aria-labelledby="tab-profile" tabindex="0">
    <p>Profile settings.</p>
  </div>

  <!-- This panel HAS a focusable element, so no tabindex on the panel itself. -->
  <div role="tabpanel" id="panel-billing" aria-labelledby="tab-billing" hidden>
    <a href="/invoices">View invoices</a>
  </div>

  <div role="tabpanel" id="panel-security" aria-labelledby="tab-security" tabindex="0" hidden>
    <p>Security settings.</p>
  </div>
</div>
```

```css
/* Selection and focus are DIFFERENT states. With manual activation they sit on
   different tabs at once, and the user must see both. */
[role="tab"][aria-selected="true"] {
  border-bottom: 3px solid #0056b3;
  font-weight: 600;
}

[role="tab"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}

/* The panel is focusable only to be scrollable — no ring needed on click,
   but keep it for keyboard (RAWeb 10.7). */
[role="tabpanel"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

```js
const tablist = document.querySelector('[role="tablist"]');
const tabs = [...tablist.querySelectorAll('[role="tab"]')];

function selectTab(newTab, { moveFocus = true } = {}) {
  for (const tab of tabs) {
    const isSelected = tab === newTab;
    // aria-selected and tabindex move together — always. If they diverge, Tab
    // returns the user to a tab that is not the open one.
    tab.setAttribute('aria-selected', String(isSelected));
    tab.setAttribute('tabindex', isSelected ? '0' : '-1');
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !isSelected;
  }
  // aria-selected does NOT move focus. This does.
  if (moveFocus) newTab.focus();
}

tablist.addEventListener('click', (event) => {
  const tab = event.target.closest('[role="tab"]');
  if (tab) selectTab(tab);
});

tablist.addEventListener('keydown', (event) => {
  const index = tabs.indexOf(event.target);
  if (index === -1) return;

  let newIndex = null;
  if (event.key === 'ArrowRight') newIndex = (index + 1) % tabs.length;
  if (event.key === 'ArrowLeft') newIndex = (index - 1 + tabs.length) % tabs.length;
  if (event.key === 'Home') newIndex = 0;
  if (event.key === 'End') newIndex = tabs.length - 1;

  if (newIndex === null) return; // Tab, Escape, everything else passes through
  event.preventDefault();        // only for keys we handled
  selectTab(tabs[newIndex]);     // automatic activation
});
```

**For manual activation** instead: on arrow keys call `tabs[newIndex].focus()`
only, and select on `click` plus `Enter`/`Space`. A native `<button>` fires
`click` for both keys, so the existing click handler already covers it — no
keydown branch needed.

### Don't

```html
<!-- DON'T: every tab in the tab order.
     → Nine tabs = nine Tab presses to get past the bar. Roving tabindex makes
       the whole tablist one stop (RAWeb 12.8). -->
<button role="tab" aria-selected="true">Profile</button>
<button role="tab" aria-selected="false">Billing</button>
<button role="tab" aria-selected="false">Security</button>

<!-- DON'T: tabindex="0" on a tab that is not selected.
     → aria-selected and tabindex now contradict each other. Tab lands on
       "Billing" while "Profile" is the open panel. -->
<button role="tab" aria-selected="false" tabindex="0">Billing</button>

<!-- DON'T: divs with roles bolted on.
     → role="tab" on a div is not focusable and fires nothing on Enter/Space.
       Use <button>, and the roles are all you need to add. -->
<div role="tab" aria-selected="true" onclick="select()">Profile</div>

<!-- DON'T: an unnamed tablist when the page has more than one.
     → Both announce as "tab list" with nothing to tell them apart. -->
<div role="tablist">…</div>

<!-- DON'T: role="tab" on an <a href>.
     → Announced as a tab but behaves as a link; Enter navigates instead of
       switching. If it really navigates, they are links — not tabs. -->
<a href="#profile" role="tab" aria-selected="true">Profile</a>
```

```js
// DON'T: set aria-selected and expect focus to follow.
//     → Focus stays on the old tab. Arrow keys appear to do nothing for a
//       screen reader user, because the virtual cursor never moves.
tab.setAttribute('aria-selected', 'true');

// DON'T: blanket preventDefault.
//     → Kills Tab (the only way out — a keyboard trap, RAWeb 12.9), Escape, and
//       screen reader passthrough. Only preventDefault keys you handled.
tablist.addEventListener('keydown', (event) => {
  event.preventDefault();
  handleKey(event);
});

// DON'T: capture Tab to move between tabs.
//     → Tab is how the user leaves. Arrows move between tabs; Tab is not yours.
if (event.key === 'Tab') {
  event.preventDefault();
  focusNextTab();
}
```

```css
/* DON'T: hide inactive panels visually.
   → All three panels stay in the accessibility tree and the tab order at once.
     A screen reader reads every panel, in sequence, as one wall of content
     (RAWeb 10.8). Use the `hidden` attribute. */
[role="tabpanel"][data-inactive] {
  opacity: 0;
  position: absolute;
  z-index: -1;
}
```

---

## React

### Do

```jsx
import { useId, useRef, useState } from 'react';

const TABS = [
  { key: 'profile', label: 'Profile' },
  { key: 'billing', label: 'Billing' },
  { key: 'security', label: 'Security' },
];

export function Tabs() {
  const [selected, setSelected] = useState(TABS[0].key);
  const id = useId();
  const tabRefs = useRef(new Map());

  const select = (key, { moveFocus = true } = {}) => {
    setSelected(key);
    // Focus must be moved imperatively — React re-rendering with a new
    // aria-selected does not move the user's focus.
    if (moveFocus) tabRefs.current.get(key)?.focus();
  };

  const onKeyDown = (event) => {
    const index = TABS.findIndex((tab) => tab.key === selected);
    let newIndex = null;
    if (event.key === 'ArrowRight') newIndex = (index + 1) % TABS.length;
    if (event.key === 'ArrowLeft') newIndex = (index - 1 + TABS.length) % TABS.length;
    if (event.key === 'Home') newIndex = 0;
    if (event.key === 'End') newIndex = TABS.length - 1;

    if (newIndex === null) return; // let Tab and everything else through
    event.preventDefault();
    select(TABS[newIndex].key);
  };

  return (
    <div className="tabs">
      <div role="tablist" aria-label="Account settings" onKeyDown={onKeyDown}>
        {TABS.map((tab) => {
          const isSelected = tab.key === selected;
          return (
            <button
              key={tab.key}
              ref={(node) => {
                // Callback ref: store on mount, delete on unmount. Returning a
                // cleanup keeps the Map from leaking detached nodes.
                tabRefs.current.set(tab.key, node);
                return () => tabRefs.current.delete(tab.key);
              }}
              type="button"
              role="tab"
              id={`${id}-tab-${tab.key}`}
              aria-selected={isSelected}
              aria-controls={`${id}-panel-${tab.key}`}
              tabIndex={isSelected ? 0 : -1}
              onClick={() => select(tab.key)}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* All panels rendered, inactive ones `hidden`. Conditional rendering
          would dangle every inactive aria-controls reference. */}
      {TABS.map((tab) => (
        <div
          key={tab.key}
          role="tabpanel"
          id={`${id}-panel-${tab.key}`}
          aria-labelledby={`${id}-tab-${tab.key}`}
          tabIndex={0}
          hidden={tab.key !== selected}
        >
          <Panel tabKey={tab.key} />
        </div>
      ))}
    </div>
  );
}
```

### Don't

```jsx
// DON'T: expect focus to follow state.
//     → setSelected re-renders with the new aria-selected, but focus stays put.
//       Arrow keys then do nothing for a keyboard or screen reader user.
const onKeyDown = (event) => {
  if (event.key === 'ArrowRight') setSelected(next); // focus never moves
};

// DON'T: tabIndex={0} on every tab.
//     → Defeats roving tabindex; each tab becomes its own Tab stop.
<button role="tab" tabIndex={0} aria-selected={isSelected}>{label}</button>

// DON'T: render only the active panel while using aria-controls.
//     → Every inactive tab's aria-controls points at a non-existent id.
{TABS.map((tab) => tab.key === selected && <div id={`panel-${tab.key}`}>…</div>)}

// DON'T: reach for a11y-critical DOM through querySelector in an effect.
//     → Breaks under StrictMode double-invocation and concurrent rendering,
//       and grabs the wrong instance when two tab bars are on one page. Use refs.
useEffect(() => {
  document.querySelector('[role="tab"][aria-selected="true"]').focus();
});
```

---

## Angular

### Do

```ts
import { Component, ElementRef, signal, viewChildren } from '@angular/core';

interface Tab { key: string; label: string; }

let uid = 0;

@Component({
  selector: 'app-tabs',
  template: `
    <div role="tablist" aria-label="Account settings" (keydown)="onKeyDown($event)">
      @for (tab of tabs; track tab.key) {
        <button
          #tabButton
          type="button"
          role="tab"
          [id]="id + '-tab-' + tab.key"
          [attr.aria-selected]="tab.key === selected()"
          [attr.aria-controls]="id + '-panel-' + tab.key"
          [tabIndex]="tab.key === selected() ? 0 : -1"
          (click)="select(tab.key)"
        >
          {{ tab.label }}
        </button>
      }
    </div>

    @for (tab of tabs; track tab.key) {
      <!-- [hidden] property binding, not [attr.hidden] — see disclosure.md -->
      <div
        role="tabpanel"
        [id]="id + '-panel-' + tab.key"
        [attr.aria-labelledby]="id + '-tab-' + tab.key"
        [tabIndex]="0"
        [hidden]="tab.key !== selected()"
      >
        <ng-content [select]="'[data-tab=' + tab.key + ']'" />
      </div>
    }
  `,
})
export class TabsComponent {
  protected readonly tabs: Tab[] = [
    { key: 'profile', label: 'Profile' },
    { key: 'billing', label: 'Billing' },
    { key: 'security', label: 'Security' },
  ];

  protected readonly selected = signal('profile');
  protected readonly id = `tabs-${uid++}`;
  private readonly tabButtons = viewChildren<ElementRef<HTMLButtonElement>>('tabButton');

  protected select(key: string, moveFocus = true): void {
    this.selected.set(key);
    if (!moveFocus) return;
    const index = this.tabs.findIndex((tab) => tab.key === key);
    // Focus after the signal has rendered the new tabindex.
    queueMicrotask(() => this.tabButtons()[index]?.nativeElement.focus());
  }

  protected onKeyDown(event: KeyboardEvent): void {
    const index = this.tabs.findIndex((tab) => tab.key === this.selected());
    let newIndex: number | null = null;

    if (event.key === 'ArrowRight') newIndex = (index + 1) % this.tabs.length;
    if (event.key === 'ArrowLeft') newIndex = (index - 1 + this.tabs.length) % this.tabs.length;
    if (event.key === 'Home') newIndex = 0;
    if (event.key === 'End') newIndex = this.tabs.length - 1;

    if (newIndex === null) return; // Tab and the rest pass through
    event.preventDefault();
    this.select(this.tabs[newIndex].key);
  }
}
```

**Or use the CDK.** `@angular/cdk/a11y` ships `FocusKeyManager`, which implements
roving tabindex, arrow handling, wrapping and typeahead. If you're on the CDK,
use it rather than hand-rolling the key handler above — and if you want the whole
widget, Angular Material's `MatTabGroup` already implements this pattern.

### Don't

```html
<!-- DON'T: [attr.tabindex] with a boolean-ish expression.
     → [attr.tabindex]="false" renders tabindex="false", which the browser
       parses as 0 — every tab lands back in the tab order. Use [tabIndex]. -->
<button role="tab" [attr.tabindex]="tab.key === selected()">{{ tab.label }}</button>

<!-- DON'T: [attr.hidden]="…" on panels — renders hidden="false" and still
     hides. Use the [hidden] property binding. -->
<div role="tabpanel" [attr.hidden]="tab.key !== selected()">…</div>
```

```ts
// DON'T: focus synchronously right after setting the signal.
//     → The DOM has not re-rendered, so tabindex is still -1 on the target and
//       the focus call can be dropped. Defer it (queueMicrotask / afterNextRender).
select(key: string): void {
  this.selected.set(key);
  this.tabButtons()[index].nativeElement.focus(); // too early
}
```

---

## Web Component

### Do

```js
// Light DOM. Tabs need aria-controls and aria-labelledby to connect the tab bar
// to the panels; if the component owned a shadow root and the author's panels
// lived outside it, every one of those IDREFs would silently fail.
class A11yTabs extends HTMLElement {
  #tabs = [];

  connectedCallback() {
    this.#tabs = [...this.querySelectorAll('[role="tab"]')];

    this.addEventListener('click', (event) => {
      const tab = event.target.closest('[role="tab"]');
      if (tab) this.#select(tab);
    });

    this.addEventListener('keydown', (event) => {
      const index = this.#tabs.indexOf(event.target);
      if (index === -1) return;

      let newIndex = null;
      if (event.key === 'ArrowRight') newIndex = (index + 1) % this.#tabs.length;
      if (event.key === 'ArrowLeft') newIndex = (index - 1 + this.#tabs.length) % this.#tabs.length;
      if (event.key === 'Home') newIndex = 0;
      if (event.key === 'End') newIndex = this.#tabs.length - 1;

      if (newIndex === null) return;
      event.preventDefault();
      this.#select(this.#tabs[newIndex]);
    });
  }

  #select(newTab) {
    for (const tab of this.#tabs) {
      const isSelected = tab === newTab;
      tab.setAttribute('aria-selected', String(isSelected));
      tab.setAttribute('tabindex', isSelected ? '0' : '-1');
      const panel = this.querySelector(`#${CSS.escape(tab.getAttribute('aria-controls'))}`);
      if (panel) panel.hidden = !isSelected;
    }
    newTab.focus();
  }
}

customElements.define('a11y-tabs', A11yTabs);
```

```html
<a11y-tabs>
  <div role="tablist" aria-label="Account settings">
    <button type="button" role="tab" id="t1" aria-controls="p1" aria-selected="true" tabindex="0">Profile</button>
    <button type="button" role="tab" id="t2" aria-controls="p2" aria-selected="false" tabindex="-1">Billing</button>
  </div>
  <div role="tabpanel" id="p1" aria-labelledby="t1" tabindex="0"><p>Profile settings.</p></div>
  <div role="tabpanel" id="p2" aria-labelledby="t2" tabindex="0" hidden><p>Billing settings.</p></div>
</a11y-tabs>
```

### Don't

```js
// DON'T: tabs in a shadow root, panels slotted from the light DOM.
//     → aria-controls (tab → panel) and aria-labelledby (panel → tab) are
//       IDREFs. They cannot cross the boundary. Both silently resolve to
//       nothing: the panel has no name and the tab controls nothing. Nothing
//       errors. Keep the whole widget in one tree — light DOM is the simplest
//       way for a pattern this reference-heavy.
root.innerHTML = `<div role="tablist"><slot name="tab"></slot></div><slot name="panel"></slot>`;
```

---

## Verify

- **Keyboard-only:** Tab must land on the **selected** tab and reach the tablist
  exactly once. Arrows move between tabs and wrap. Tab again must leave for the
  panel — never cycle back into the bar (RAWeb 12.9). Shift+Tab must exit
  backwards.
- **The roving tabindex check:** with tab 3 selected, Tab into the bar. You must
  land on tab 3, not tab 1. If you land on tab 1, `aria-selected` and `tabindex`
  have drifted apart.
- **Screen reader:** expect "«label», tab, selected, 1 of 3". Arrowing must
  announce each tab as focus moves. If arrows announce nothing, you set
  `aria-selected` without calling `.focus()`.
- **Automated:** axe catches `role="tab"` outside a `tablist`, and missing
  `aria-controls` targets. It does **not** catch missing roving tabindex, focus
  that never moves, or panels hidden with `opacity` — the three that actually
  ship. Test by hand.
