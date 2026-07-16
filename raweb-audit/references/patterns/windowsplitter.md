# Window Splitter — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show windowsplitter`

> **RAWeb 13.10 test 2 is the criterion for this pattern**, and it is the one
> everyone misses — because 13.10 reads like it's about pinch gestures. It isn't:
> `scripts/raweb-lookup.sh methodology 13.10.2`.

---

## Universal rules

- **Dragging is a path-based gesture (RAWeb 13.10, test 2).** The resize must
  *also* be achievable with a **single-point operation**: a double-click to
  reset, or explicit collapse/expand buttons.
  **A keyboard alternative does not satisfy 13.10** — the criterion is
  specifically about pointer operation. This trips people up: they add arrow keys,
  assume they're covered, and still fail.
- **A focusable `separator` is a widget; an `<hr>` is not.** `role="separator"`
  with `tabindex="0"` and a value is the splitter. The same role without
  `tabindex` is a plain divider that takes no value. Don't confuse them.
- **`aria-valuenow` is the primary pane's size as a percentage**, with
  `aria-valuemin`/`max` as its bounds. `aria-controls` names that pane.
- **`aria-valuetext` makes it comprehensible.** "Sidebar 30% of width" beats
  "30". (RAWeb 7.1)
- **A 1px line needs a ≥24px hit area.** Untargetable otherwise, for anyone with
  a tremor. (RAWeb 3.3)
- **Enter toggles collapse and restores the previous size.** Useful, and it
  doubles as a single-point-friendly affordance.
- **Commit on pointer release; allow abort mid-drag.** (RAWeb 13.11)
- **Ask whether you need it.** A resizable pane is a convenience. Fixed widths,
  or a persisted user preference, are often enough.

---

## Vanilla

### Do

```html
<div class="split-view">
  <div id="sidebar" class="split-view__pane" style="inline-size: 30%">
    <h2>Files</h2>
    …
  </div>

  <!-- The splitter. tabindex="0" is what makes it a widget rather than a
       decorative divider. aria-controls names the pane aria-valuenow describes. -->
  <div
    role="separator"
    id="splitter"
    tabindex="0"
    aria-label="Resize sidebar"
    aria-controls="sidebar"
    aria-orientation="vertical"
    aria-valuenow="30"
    aria-valuemin="15"
    aria-valuemax="60"
    aria-valuetext="Sidebar 30% of width"
  ></div>

  <div class="split-view__pane">
    <h2>Editor</h2>
    …
  </div>
</div>

<!-- RAWeb 13.10.2 — the single-point alternative. Not a nicety: without one of
     these (or the double-click below), the ONLY pointer route to a resize is a
     path-based gesture, and the pattern fails. -->
<div class="split-view__controls">
  <button type="button" id="splitter-collapse">Collapse sidebar</button>
  <button type="button" id="splitter-reset">Reset sidebar width</button>
</div>
```

```css
.split-view { display: flex; }
.split-view__pane { overflow: auto; }

/* Renders as a hairline, targets as 24px. Without this it is untargetable for
   anyone with a tremor (RAWeb 3.3). */
#splitter {
  position: relative;
  inline-size: 1px;
  background: #ddd;
  cursor: col-resize;
  flex: 0 0 auto;
}
#splitter::before {
  content: "";
  position: absolute;
  inset-block: 0;
  inset-inline: -12px;   /* 24px of hit area around a 1px line */
  cursor: col-resize;
}

/* A thin line needs an unusually deliberate focus indicator (RAWeb 10.7). */
#splitter:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
  background: #0056b3;
}

@media (forced-colors: active) {
  #splitter { background: CanvasText; }
}
```

```js
const splitter = document.getElementById('splitter');
const sidebar = document.getElementById('sidebar');
const container = document.querySelector('.split-view');
const MIN = 15, MAX = 60, DEFAULT = 30;
let lastExpanded = DEFAULT;

function setSize(percent, { collapsed = false } = {}) {
  const value = collapsed ? 0 : Math.min(MAX, Math.max(MIN, Math.round(percent)));
  sidebar.style.inlineSize = `${value}%`;
  splitter.setAttribute('aria-valuenow', String(value));
  // "30" alone is meaningless; this is what actually gets announced.
  splitter.setAttribute(
    'aria-valuetext',
    collapsed ? 'Sidebar collapsed' : `Sidebar ${value}% of width`,
  );
  return value;
}

// Keyboard. Note: this does NOT satisfy RAWeb 13.10 — that criterion is about
// pointer operation. It satisfies 7.3.
splitter.addEventListener('keydown', (event) => {
  const current = Number(splitter.getAttribute('aria-valuenow'));
  let next = null;

  if (event.key === 'ArrowRight') next = current + 1;
  if (event.key === 'ArrowLeft') next = current - 1;
  if (event.key === 'Home') next = MIN;
  if (event.key === 'End') next = MAX;

  // Enter toggles collapse, remembering where we were.
  if (event.key === 'Enter') {
    event.preventDefault();
    if (current === 0) setSize(lastExpanded);
    else { lastExpanded = current; setSize(0, { collapsed: true }); }
    return;
  }

  if (next === null) return;   // Tab passes through
  event.preventDefault();
  setSize(next);
});

// RAWeb 13.10.2 — single-point alternatives. Each of these resizes with ONE
// tap, no path.
document.getElementById('splitter-collapse').addEventListener('click', () => {
  const current = Number(splitter.getAttribute('aria-valuenow'));
  if (current > 0) lastExpanded = current;
  setSize(current > 0 ? 0 : lastExpanded, { collapsed: current > 0 });
});

document.getElementById('splitter-reset').addEventListener('click', () => setSize(DEFAULT));

// Double-click to reset: another single-point route, and a desktop convention.
splitter.addEventListener('dblclick', () => setSize(DEFAULT));

// Drag, as an ENHANCEMENT on top — never as the only pointer input.
splitter.addEventListener('pointerdown', (event) => {
  splitter.setPointerCapture(event.pointerId);
  const startValue = Number(splitter.getAttribute('aria-valuenow'));

  const onMove = (e) => {
    const rect = container.getBoundingClientRect();
    setSize(((e.clientX - rect.left) / rect.width) * 100);
  };

  const onUp = () => {
    splitter.removeEventListener('pointermove', onMove);
    // Commit on release (RAWeb 13.11).
    persistPreference(Number(splitter.getAttribute('aria-valuenow')));
  };

  // Escape aborts the drag and restores the starting size (RAWeb 13.11).
  const onKey = (e) => {
    if (e.key !== 'Escape') return;
    splitter.removeEventListener('pointermove', onMove);
    setSize(startValue);
  };

  splitter.addEventListener('pointermove', onMove);
  splitter.addEventListener('pointerup', onUp, { once: true });
  document.addEventListener('keydown', onKey, { once: true });
});
```

### Don't

```html
<!-- DON'T: a splitter you can only drag. THE RAWeb 13.10.2 failure.
     → Dragging is a path-based gesture. With no double-click, no reset button
       and no collapse button, the only pointer route to a resize is a path-based
       gesture. Fails — and adding arrow keys does NOT fix it, because 13.10 is
       about POINTER operation. -->
<div class="splitter" onmousedown="startDrag()"></div>

<!-- DON'T: a non-focusable splitter.
     → role="separator" without tabindex is a decorative divider, not a widget.
       It takes no value and no keyboard (RAWeb 7.3). -->
<div role="separator" aria-valuenow="30"></div>

<!-- DON'T: an <hr> with splitter attributes.
     → <hr> is role="separator" but is not focusable and is not a widget. The
       value attributes are ignored. -->
<hr role="separator" tabindex="0" aria-valuenow="30">

<!-- DON'T: a splitter with no accessible name.
     → "separator, 30" — resizing what? -->
<div role="separator" tabindex="0" aria-valuenow="30" aria-controls="sidebar"></div>

<!-- DON'T: no aria-valuetext.
     → Announced as a bare "30". Thirty what? Per cent of what? -->
<div role="separator" tabindex="0" aria-valuenow="30" aria-label="Resize sidebar"></div>

<!-- DON'T: aria-controls pointing at the wrong pane.
     → aria-valuenow describes the PRIMARY pane. If it points at the editor while
       the value describes the sidebar, the announcement is backwards. -->
<div role="separator" aria-controls="editor" aria-valuenow="30"></div>
```

```css
/* DON'T: a 1px hit area.
   → Untargetable for anyone with a tremor, and on touch it is invisible in
     practice. Render 1px, target 24px (RAWeb 3.3). */
.splitter {
  inline-size: 1px;
  cursor: col-resize;
}

/* DON'T: a focus indicator that a 1px element cannot show.
   → An inset outline on a 1px-wide element is invisible. Use an offset outline,
     or widen the splitter on focus (RAWeb 10.7). */
.splitter:focus-visible { outline: 1px solid #0056b3; outline-offset: -1px; }
```

```js
// DON'T: assume keyboard support satisfies RAWeb 13.10.
//     → It does not. 13.10 is about POINTER operation: a user who can tap but
//       cannot drag needs a single-point route. Arrow keys do not help them.
//       This is the most common misreading of the criterion.
splitter.addEventListener('keydown', handleArrows);
// ...and drag is still the only pointer input

// DON'T: commit continuously while dragging.
//     → One persisted preference per pixel, and no way to abort (RAWeb 13.11).
const onMove = (e) => { setSize(...); persistPreference(...); };

// DON'T: collapse without remembering the previous size.
//     → Collapse then expand and the pane jumps to a default the user never
//       chose. Store lastExpanded.
setSize(0);
```

---

## React

### Do

```jsx
import { useId, useRef, useState } from 'react';

const MIN = 15, MAX = 60, DEFAULT = 30;

export function SplitView({ children }) {
  const [size, setSize] = useState(DEFAULT);
  const lastExpanded = useRef(DEFAULT);
  const containerRef = useRef(null);
  const sidebarId = useId();

  const clamp = (v) => Math.min(MAX, Math.max(MIN, Math.round(v)));
  const isCollapsed = size === 0;

  const toggleCollapse = () => {
    if (isCollapsed) setSize(lastExpanded.current);
    else { lastExpanded.current = size; setSize(0); }
  };

  const onKeyDown = (event) => {
    if (event.key === 'Enter') { event.preventDefault(); toggleCollapse(); return; }
    let next = null;
    if (event.key === 'ArrowRight') next = size + 1;
    if (event.key === 'ArrowLeft') next = size - 1;
    if (event.key === 'Home') next = MIN;
    if (event.key === 'End') next = MAX;
    if (next === null) return;
    event.preventDefault();
    setSize(clamp(next));
  };

  const onPointerDown = (event) => {
    event.currentTarget.setPointerCapture(event.pointerId);
    const onMove = (e) => {
      const rect = containerRef.current.getBoundingClientRect();
      setSize(clamp(((e.clientX - rect.left) / rect.width) * 100));
    };
    const onUp = () => {
      window.removeEventListener('pointermove', onMove);
      window.removeEventListener('pointerup', onUp);
    };
    window.addEventListener('pointermove', onMove);
    window.addEventListener('pointerup', onUp);
  };

  return (
    <>
      <div className="split-view" ref={containerRef}>
        <div id={sidebarId} style={{ inlineSize: `${size}%` }}>{children[0]}</div>

        <div
          role="separator"
          tabIndex={0}
          aria-label="Resize sidebar"
          aria-controls={sidebarId}
          aria-orientation="vertical"
          aria-valuenow={size}
          aria-valuemin={MIN}
          aria-valuemax={MAX}
          aria-valuetext={isCollapsed ? 'Sidebar collapsed' : `Sidebar ${size}% of width`}
          onKeyDown={onKeyDown}
          onPointerDown={onPointerDown}
          onDoubleClick={() => setSize(DEFAULT)}   // single-point route
        />

        <div>{children[1]}</div>
      </div>

      {/* RAWeb 13.10.2 — single-point alternatives. */}
      <button type="button" onClick={toggleCollapse}>
        {isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
      </button>
      <button type="button" onClick={() => setSize(DEFAULT)}>Reset sidebar width</button>
    </>
  );
}
```

### Don't

```jsx
// DON'T: adopt a resizable-panel library without checking 13.10.2.
//     → Most are drag-only. Check for a double-click reset or collapse buttons
//       BEFORE adopting; bolting them on afterwards means fighting the library's
//       own state.

// DON'T: onMouseDown instead of onPointerDown.
//     → No touch support at all. Pointer events cover mouse, touch and pen.
<div role="separator" onMouseDown={startDrag} />

// DON'T: setSize on every pointermove AND persist on every setSize.
//     → One request per pixel of drag.
```

---

## Angular

### Do

```ts
import { Component, ElementRef, signal, viewChild } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-split-view',
  template: `
    <div class="split-view" #container>
      <div [id]="sidebarId" [style.inline-size.%]="size()">
        <ng-content select="[slot=sidebar]" />
      </div>

      <div
        role="separator"
        [tabIndex]="0"
        aria-label="Resize sidebar"
        [attr.aria-controls]="sidebarId"
        aria-orientation="vertical"
        [attr.aria-valuenow]="size()"
        [attr.aria-valuemin]="MIN"
        [attr.aria-valuemax]="MAX"
        [attr.aria-valuetext]="valueText()"
        (keydown)="onKeyDown($event)"
        (pointerdown)="onPointerDown($event)"
        (dblclick)="size.set(DEFAULT)"
      ></div>

      <div><ng-content select="[slot=main]" /></div>
    </div>

    <!-- RAWeb 13.10.2 single-point alternatives -->
    <button type="button" (click)="toggleCollapse()">
      {{ size() === 0 ? 'Expand sidebar' : 'Collapse sidebar' }}
    </button>
    <button type="button" (click)="size.set(DEFAULT)">Reset sidebar width</button>
  `,
})
export class SplitViewComponent {
  protected readonly MIN = 15;
  protected readonly MAX = 60;
  protected readonly DEFAULT = 30;
  protected readonly sidebarId = `sidebar-${uid++}`;
  protected readonly size = signal(this.DEFAULT);
  private lastExpanded = this.DEFAULT;
  private readonly container = viewChild.required<ElementRef<HTMLElement>>('container');

  protected valueText(): string {
    return this.size() === 0 ? 'Sidebar collapsed' : `Sidebar ${this.size()}% of width`;
  }

  protected toggleCollapse(): void {
    if (this.size() === 0) this.size.set(this.lastExpanded);
    else { this.lastExpanded = this.size(); this.size.set(0); }
  }

  protected onKeyDown(event: KeyboardEvent): void {
    if (event.key === 'Enter') { event.preventDefault(); this.toggleCollapse(); return; }
    let next: number | null = null;
    if (event.key === 'ArrowRight') next = this.size() + 1;
    if (event.key === 'ArrowLeft') next = this.size() - 1;
    if (event.key === 'Home') next = this.MIN;
    if (event.key === 'End') next = this.MAX;
    if (next === null) return;
    event.preventDefault();
    this.size.set(Math.min(this.MAX, Math.max(this.MIN, next)));
  }

  protected onPointerDown(event: PointerEvent): void { /* as in the vanilla example */ }
}
```

**Or use the CDK.** `@angular/cdk/drag-drop` handles the drag mechanics — but it
gives you a *drag*, which is exactly the thing RAWeb 13.10.2 says cannot be your
only pointer route. The buttons are still yours to add.

### Don't

```html
<!-- DON'T: [attr.tabindex]="0" — works, but [tabIndex] is the property and is
     less prone to the "false" trap seen elsewhere in these patterns. -->

<!-- DON'T: a drag-only splitter, CDK or not. The library being good does not
     make a path-based-only gesture pass 13.10.2. -->
```

---

## Web Component

### Do

```js
const styles = new CSSStyleSheet();
styles.replaceSync(`
  :host { display: block; inline-size: 1px; background: #ddd; cursor: col-resize; position: relative; }
  :host::before { content: ""; position: absolute; inset-block: 0; inset-inline: -12px; }
  :host(:focus-visible) { outline: 2px solid #0056b3; outline-offset: 2px; }
`);

class A11ySplitter extends HTMLElement {
  static observedAttributes = ['value'];

  constructor() {
    super();
    this.attachShadow({ mode: 'open' }).adoptedStyleSheets = [styles];
  }

  connectedCallback() {
    // The ARIA lives on the HOST, in the light DOM, so aria-controls can
    // reference the author's pane. Putting the separator inside a shadow root
    // would break that IDREF silently.
    this.setAttribute('role', 'separator');
    this.setAttribute('tabindex', '0');
    this.#update(Number(this.getAttribute('value') ?? 30));

    this.addEventListener('keydown', (e) => this.#onKeyDown(e));
    this.addEventListener('dblclick', () => this.#update(30));   // single-point route
  }

  #update(value) {
    const clamped = Math.min(60, Math.max(15, Math.round(value)));
    this.setAttribute('aria-valuenow', String(clamped));
    this.setAttribute('aria-valuemin', '15');
    this.setAttribute('aria-valuemax', '60');
    this.setAttribute('aria-valuetext', `Sidebar ${clamped}% of width`);
    this.dispatchEvent(new CustomEvent('resize', {
      detail: { value: clamped }, bubbles: true, composed: true,
    }));
  }

  #onKeyDown(event) {
    const current = Number(this.getAttribute('aria-valuenow'));
    let next = null;
    if (event.key === 'ArrowRight') next = current + 1;
    if (event.key === 'ArrowLeft') next = current - 1;
    if (event.key === 'Home') next = 15;
    if (event.key === 'End') next = 60;
    if (next === null) return;
    event.preventDefault();
    this.#update(next);
  }
}

customElements.define('a11y-splitter', A11ySplitter);
```

```html
<div class="split-view">
  <div id="sidebar">…</div>
  <a11y-splitter aria-label="Resize sidebar" aria-controls="sidebar" value="30"></a11y-splitter>
  <div id="editor">…</div>
</div>
<button type="button" id="collapse">Collapse sidebar</button>
```

### Don't

```js
// DON'T: put role="separator" on an element inside the shadow root.
//     → aria-controls must reference the author's pane, which lives in the light
//       DOM. An IDREF cannot cross the boundary: the splitter would control
//       nothing, silently. Put the ARIA on the host.
root.innerHTML = `<div role="separator" tabindex="0" aria-controls="sidebar"></div>`;
```

---

## Verify

- **The RAWeb 13.10.2 check — and read it carefully.** Resize the pane using
  **single taps only**: double-click to reset, or the collapse/reset buttons. If
  the *only* pointer route is a drag, it fails. **Arrow keys do not rescue this**
  — 13.10 is about pointer operation, and this is the most common misreading of
  the criterion.
- **The widget check:** can you Tab to the splitter? If not, it's a decorative
  divider with delusions — `tabindex="0"` is what makes it a widget.
- **The hit-area check:** try to grab it on a touch screen, or with the pointer
  moving imprecisely. A 1px target is not operable.
- **Screen reader:** expect "Resize sidebar, separator, Sidebar 30% of width". If
  you hear a bare "30", `aria-valuetext` is missing.
- **The collapse memory check:** collapse, then expand. It must return to where
  it was, not to a default.
- **Automated:** axe catches `role="separator"` with `tabindex` but no
  `aria-valuenow`. It catches **nothing** about 13.10.2, the hit area, or the
  focus indicator on a hairline.
