# Treegrid — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show treegrid`

> **Read [`grid.md`](grid.md) and [`treeview.md`](treeview.md) first.** A treegrid
> is their intersection: a grid whose rows are hierarchical. It adds no new
> ideas — only more surface to get wrong. This file covers only the joins.

---

## This is the most complex pattern in the APG

And almost every treegrid in the wild would have been better as something else:

| What you actually have | Use |
|---|---|
| Hierarchy, one column of labels | [`treeview`](treeview.md) |
| Tabular data, flat rows, interactive cells | [`grid`](grid.md) |
| Tabular data, read-only, some rows expand | **`<table>` + [`disclosure`](disclosure.md) buttons in a cell** |
| Hierarchy **and** multiple columns **and** cell-level interaction | **treegrid** (this file) |

That third row is the one people miss. A read-only table where rows expand to
reveal child rows is just a table with disclosure buttons — no `role="treegrid"`,
no application mode, no arrow model, and every user already knows how to use it.

> **Budget honestly.** A treegrid costs two keyboard models, a mode switch, and
> hand-maintained hierarchy attributes. If a table with disclosure buttons will
> do, it will do.

---

## Universal rules

Everything in [`grid.md`](grid.md) and [`treeview.md`](treeview.md) applies. The
joins:

- **`aria-expanded` goes on the `<tr>` (`role="row"`), not on a cell.** This is
  the single most common treegrid error.
- **`aria-level`, `aria-posinset` and `aria-setsize` go on the row, and are
  mandatory.** Unlike a treeview, the DOM is **flat** — `<tr>`s cannot nest, so
  nothing else conveys the hierarchy. This is the one place hand-maintaining
  them is correct.
- **Two focus modes: row-focus and cell-focus.** Pick one model and be
  consistent. Arrows move between rows in row-focus; Enter drops into cell-focus;
  Escape returns.
- **Left/Right do double duty.** In row-focus: collapse/expand. In cell-focus:
  move between cells. Getting this wrong makes the widget feel broken.
- **Collapsed child rows must be `hidden` or removed.** (RAWeb 10.8)
- **Tab is still the only way out.** (RAWeb 12.9)

---

## Vanilla

### Do — the alternative you probably want

```html
<!-- A table with disclosure buttons. No treegrid, no application mode, no
     arrow model. Read-only hierarchy is just this. -->
<table>
  <caption>Project budget by department</caption>
  <thead>
    <tr><th scope="col">Department</th><th scope="col">Budget</th></tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">
        <button type="button" aria-expanded="true" aria-controls="eng-rows">Engineering</button>
      </th>
      <td>120,000</td>
    </tr>
    <!-- Child rows: a tbody so one aria-controls can target them all. -->
  </tbody>
  <tbody id="eng-rows">
    <tr><th scope="row">Frontend</th><td>70,000</td></tr>
    <tr><th scope="row">Backend</th><td>50,000</td></tr>
  </tbody>
</table>
```

### Do — a real treegrid

```html
<table role="treegrid" aria-label="Project files" id="files-treegrid">
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Size</th>
      <th scope="col">Modified</th>
    </tr>
  </thead>
  <tbody>
    <!-- aria-expanded on the ROW. aria-level/posinset/setsize are mandatory
         here: <tr> cannot nest, so the DOM carries no hierarchy at all. -->
    <tr role="row" aria-expanded="true" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="0">
      <th scope="row" tabindex="-1">src</th>
      <td tabindex="-1">—</td>
      <td tabindex="-1">2026-03-01</td>
    </tr>

    <tr role="row" aria-level="2" aria-posinset="1" aria-setsize="2" tabindex="-1">
      <th scope="row" tabindex="-1">index.js</th>
      <td tabindex="-1">2.4 KB</td>
      <td tabindex="-1">2026-03-02</td>
    </tr>

    <tr role="row" aria-expanded="false" aria-level="2" aria-posinset="2" aria-setsize="2" tabindex="-1">
      <th scope="row" tabindex="-1">components</th>
      <td tabindex="-1">—</td>
      <td tabindex="-1">2026-02-28</td>
    </tr>

    <!-- Collapsed child: hidden, not just visually absent (RAWeb 10.8). -->
    <tr role="row" aria-level="3" aria-posinset="1" aria-setsize="1" tabindex="-1" hidden>
      <th scope="row" tabindex="-1">Button.js</th>
      <td tabindex="-1">1.1 KB</td>
      <td tabindex="-1">2026-02-28</td>
    </tr>

    <tr role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1">
      <th scope="row" tabindex="-1">README.md</th>
      <td tabindex="-1">4.0 KB</td>
      <td tabindex="-1">2026-01-15</td>
    </tr>
  </tbody>
</table>
```

```css
/* Indentation is presentational — aria-level carries the real hierarchy. */
[role="treegrid"] tr[aria-level="2"] th { padding-inline-start: 1.5rem; }
[role="treegrid"] tr[aria-level="3"] th { padding-inline-start: 3rem; }

[role="treegrid"] tr[aria-expanded="true"] th::before { content: "▾ "; }
[role="treegrid"] tr[aria-expanded="false"] th::before { content: "▸ "; }

/* Both focus modes need a visible indicator, and they must look DIFFERENT —
   the user has to know which mode they are in (RAWeb 10.7). */
[role="treegrid"] tr:focus-visible { outline: 2px solid #0056b3; outline-offset: -2px; }
[role="treegrid"] td:focus-visible,
[role="treegrid"] th:focus-visible { outline: 2px dashed #1a7f37; outline-offset: -2px; }
```

```js
const treegrid = document.getElementById('files-treegrid');
let mode = 'row';   // 'row' | 'cell'

const visibleRows = () => [...treegrid.querySelectorAll('tbody tr:not([hidden])')];
const cellsIn = (row) => [...row.querySelectorAll('th, td')];
const isExpandable = (row) => row.hasAttribute('aria-expanded');
const isExpanded = (row) => row.getAttribute('aria-expanded') === 'true';

// Children are the following rows at a deeper level, until the level returns.
function childRowsOf(row) {
  const level = Number(row.getAttribute('aria-level'));
  const out = [];
  let next = row.nextElementSibling;
  while (next && Number(next.getAttribute('aria-level')) > level) {
    out.push(next);
    next = next.nextElementSibling;
  }
  return out;
}

function setExpanded(row, expanded) {
  if (!isExpandable(row)) return;
  row.setAttribute('aria-expanded', String(expanded));
  const level = Number(row.getAttribute('aria-level'));
  for (const child of childRowsOf(row)) {
    // Only direct children reappear; grandchildren stay hidden if their own
    // parent is still collapsed.
    const childLevel = Number(child.getAttribute('aria-level'));
    if (childLevel === level + 1) child.hidden = !expanded;
    else if (!expanded) child.hidden = true;
  }
}

function focusRow(row) {
  for (const r of treegrid.querySelectorAll('tr')) r.setAttribute('tabindex', '-1');
  row.setAttribute('tabindex', '0');
  row.focus();
  mode = 'row';
}

function focusCell(cell) {
  for (const c of treegrid.querySelectorAll('th, td')) c.setAttribute('tabindex', '-1');
  cell.setAttribute('tabindex', '0');
  cell.focus();
  mode = 'cell';
}

treegrid.addEventListener('keydown', (event) => {
  const row = event.target.closest('tr');
  if (!row) return;
  const rows = visibleRows();
  const index = rows.indexOf(row);

  // ROW MODE: the treeview model.
  if (mode === 'row') {
    if (event.key === 'ArrowDown') { event.preventDefault(); rows[index + 1] && focusRow(rows[index + 1]); }
    else if (event.key === 'ArrowUp') { event.preventDefault(); rows[index - 1] && focusRow(rows[index - 1]); }
    else if (event.key === 'ArrowRight') {
      event.preventDefault();
      // Right: expand → else drop into the row's cells.
      if (isExpandable(row) && !isExpanded(row)) setExpanded(row, true);
      else focusCell(cellsIn(row)[0]);
    }
    else if (event.key === 'ArrowLeft') {
      event.preventDefault();
      if (isExpandable(row) && isExpanded(row)) setExpanded(row, false);
      // else: step to parent row (omitted for brevity — see treeview.md)
    }
    else if (event.key === 'Enter') { event.preventDefault(); focusCell(cellsIn(row)[0]); }
    // Tab: untouched (RAWeb 12.9).
    return;
  }

  // CELL MODE: the grid model.
  const cell = event.target.closest('th, td');
  const cells = cellsIn(row);
  const col = cells.indexOf(cell);

  if (event.key === 'ArrowRight') { event.preventDefault(); cells[col + 1] && focusCell(cells[col + 1]); }
  else if (event.key === 'ArrowLeft') {
    event.preventDefault();
    // Left at column 0 returns to row mode — the way back out.
    col === 0 ? focusRow(row) : focusCell(cells[col - 1]);
  }
  else if (event.key === 'ArrowDown') { event.preventDefault(); rows[index + 1] && focusCell(cellsIn(rows[index + 1])[col]); }
  else if (event.key === 'ArrowUp') { event.preventDefault(); rows[index - 1] && focusCell(cellsIn(rows[index - 1])[col]); }
  else if (event.key === 'Escape') { event.preventDefault(); focusRow(row); }
});
```

### Don't

```html
<!-- DON'T: aria-expanded on a cell. THE treegrid error.
     → The expandable thing is the ROW. On a cell it announces the wrong element
       as expandable, and the row itself announces no state. -->
<tr role="row">
  <th scope="row" aria-expanded="true">src</th>
</tr>

<!-- DON'T: omit aria-level on a treegrid.
     → <tr> cannot nest, so the DOM carries NO hierarchy. Without aria-level the
       treegrid is announced as a flat table and the whole point is gone. This
       is the one pattern where hand-maintaining it is correct. -->
<tr role="row" aria-expanded="true" tabindex="0">
  <th scope="row">src</th>
</tr>

<!-- DON'T: role="treegrid" on a read-only expandable table.
     → Application mode, two keyboard models, and hand-maintained hierarchy
       attributes — for something a <table> with disclosure buttons does with
       none of it. -->
<table role="treegrid">
  <tr role="row" aria-expanded="false"><th scope="row">Engineering</th><td>120,000</td></tr>
</table>

<!-- DON'T: aria-expanded on a leaf row.
     → Claims children it does not have. -->
<tr role="row" aria-expanded="false" aria-level="2">
  <th scope="row">index.js</th>
</tr>

<!-- DON'T: collapse child rows with CSS.
     → They stay in the accessibility tree and in the arrow sequence
       (RAWeb 10.8). Use hidden. -->
<tr role="row" style="display: none">…</tr>   <!-- ok-ish, but `hidden` is clearer -->
<tr role="row" style="visibility: collapse">…</tr>   <!-- NOT ok -->
```

```js
// DON'T: one focus model that tries to be both.
//     → Left/Right cannot simultaneously collapse the row AND move between
//       cells. Without an explicit mode, every Left is ambiguous and the widget
//       feels broken. Row mode and cell mode, with Enter/Escape between them.

// DON'T: recompute aria-posinset/setsize only on load.
//     → Insert or remove a row and every sibling's position is now wrong. The
//       screen reader confidently announces "3 of 7" in a branch of 4.

// DON'T: unhide ALL descendants when expanding a row.
//     → Expanding `src` should reveal its direct children only. Grandchildren
//       whose own parent is still collapsed must stay hidden.
for (const child of childRowsOf(row)) child.hidden = false;
```

---

## React

The state model is the whole job: expansion set, focus mode, focused row, focused
column. Everything else follows [`grid.md`](grid.md) and
[`treeview.md`](treeview.md).

```jsx
import { useMemo, useRef, useState } from 'react';

// Flat data with an explicit level — the shape a treegrid actually needs.
// [{ id, name, size, modified, level, parentId, hasChildren }]
export function FileTreegrid({ nodes }) {
  const [expanded, setExpanded] = useState(() => new Set(['src']));
  const [mode, setMode] = useState('row');
  const [focusRow, setFocusRow] = useState(0);
  const [focusCol, setFocusCol] = useState(0);
  const rowRefs = useRef([]);

  // A row is visible only if every ancestor is expanded.
  const visible = useMemo(() => {
    const byId = new Map(nodes.map((n) => [n.id, n]));
    return nodes.filter((node) => {
      let parent = node.parentId ? byId.get(node.parentId) : null;
      while (parent) {
        if (!expanded.has(parent.id)) return false;
        parent = parent.parentId ? byId.get(parent.parentId) : null;
      }
      return true;
    });
  }, [nodes, expanded]);

  // posinset/setsize computed from the CURRENT visible siblings — never
  // hardcoded, or they go stale on every insert.
  const siblingInfo = (node) => {
    const siblings = nodes.filter((n) => n.parentId === node.parentId);
    return { pos: siblings.indexOf(node) + 1, size: siblings.length };
  };

  return (
    <table role="treegrid" aria-label="Project files" onKeyDown={/* … */ undefined}>
      <thead>
        <tr><th scope="col">Name</th><th scope="col">Size</th><th scope="col">Modified</th></tr>
      </thead>
      <tbody>
        {visible.map((node, r) => {
          const { pos, size } = siblingInfo(node);
          return (
            <tr
              key={node.id}
              ref={(n) => { rowRefs.current[r] = n; }}
              role="row"
              // undefined removes it — leaves must not claim children.
              aria-expanded={node.hasChildren ? expanded.has(node.id) : undefined}
              aria-level={node.level}
              aria-posinset={pos}
              aria-setsize={size}
              tabIndex={mode === 'row' && focusRow === r ? 0 : -1}
            >
              <th scope="row" tabIndex={mode === 'cell' && focusRow === r && focusCol === 0 ? 0 : -1}>
                {node.name}
              </th>
              <td tabIndex={mode === 'cell' && focusRow === r && focusCol === 1 ? 0 : -1}>{node.size}</td>
              <td tabIndex={mode === 'cell' && focusRow === r && focusCol === 2 ? 0 : -1}>{node.modified}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
```

### Don't

```jsx
// DON'T: aria-expanded={expanded.has(node.id)} on every row.
//     → Renders aria-expanded="false" on leaves, which then claim children.
//       Use undefined for leaves.

// DON'T: hardcode aria-setsize from the original data.
//     → Filter the tree and every count is wrong. Derive from current siblings.

// DON'T: nest <tr> inside <tr> to express hierarchy.
//     → Invalid HTML. The browser will unnest it, silently. Hierarchy in a
//       treegrid lives in aria-level, not in the DOM.
```

---

## Angular

Same model. **The CDK has no treegrid primitive** — `@angular/cdk/tree` is a
treeview and `cdk-table` is a table. You would be composing them by hand, which
is another reason to check the table above and see whether you need this at all.

```ts
import { Component, input, signal } from '@angular/core';

@Component({
  selector: 'app-file-treegrid',
  template: `
    <table role="treegrid" aria-label="Project files" (keydown)="onKeyDown($event)">
      <thead>
        <tr><th scope="col">Name</th><th scope="col">Size</th><th scope="col">Modified</th></tr>
      </thead>
      <tbody>
        @for (node of visible(); track node.id; let r = $index) {
          <tr
            role="row"
            [attr.aria-expanded]="node.hasChildren ? expanded().has(node.id) : null"
            [attr.aria-level]="node.level"
            [attr.aria-posinset]="posInSet(node)"
            [attr.aria-setsize]="setSize(node)"
            [tabIndex]="mode() === 'row' && focusRow() === r ? 0 : -1"
          >
            <th scope="row" [tabIndex]="cellTabIndex(r, 0)">{{ node.name }}</th>
            <td [tabIndex]="cellTabIndex(r, 1)">{{ node.size }}</td>
            <td [tabIndex]="cellTabIndex(r, 2)">{{ node.modified }}</td>
          </tr>
        }
      </tbody>
    </table>
  `,
})
export class FileTreegridComponent {
  readonly nodes = input.required<FileNode[]>();
  protected readonly expanded = signal(new Set<string>(['src']));
  protected readonly mode = signal<'row' | 'cell'>('row');
  protected readonly focusRow = signal(0);
  protected readonly focusCol = signal(0);
  // visible(), posInSet(), setSize(), onKeyDown() as in the vanilla example
}
```

`[attr.aria-expanded]="… : null"` — **null** removes the attribute. `false` would
render `aria-expanded="false"` and make every leaf claim children.

### Don't

```html
<!-- DON'T: [attr.aria-expanded]="expanded().has(node.id)" on all rows.
     → Leaves get aria-expanded="false". Return null for leaves. -->
<tr role="row" [attr.aria-expanded]="expanded().has(node.id)">

<!-- DON'T: [attr.hidden] on collapsed rows — renders hidden="false" and hides
     everything. Use [hidden], or filter the list as above. -->
<tr role="row" [attr.hidden]="!isVisible(node)">
```

---

## Web Component

See [`grid.md`](grid.md) — light DOM, for the same reasons: the `<table>`
relationships depend on real DOM nesting, and `aria-labelledby` cannot cross a
shadow boundary. The only addition is the row-level hierarchy state:

```js
class A11yTreegrid extends HTMLElement {
  connectedCallback() {
    this.#treegrid = this.querySelector('[role="treegrid"]');
    this.#treegrid.addEventListener('keydown', (e) => this.#onKeyDown(e));
  }

  #treegrid;
  #mode = 'row';

  #childRowsOf(row) {
    const level = Number(row.getAttribute('aria-level'));
    const out = [];
    let next = row.nextElementSibling;
    while (next && Number(next.getAttribute('aria-level')) > level) {
      out.push(next);
      next = next.nextElementSibling;
    }
    return out;
  }

  #onKeyDown(event) { /* row mode / cell mode, as in the vanilla example */ }
}

customElements.define('a11y-treegrid', A11yTreegrid);
```

### Don't

```js
// DON'T: build the table structure in a shadow root — see grid.md.
```

---

## Verify

- **First, and most importantly: does this need to be a treegrid?** If the rows
  are read-only, it's a `<table>` with disclosure buttons. If there's one column,
  it's a treeview. If the rows are flat, it's a grid. The pattern being *correct*
  doesn't make it *right*.
- **The `aria-expanded` placement check:** focus an expandable row. The **row**
  must announce "expanded", not a cell. This is the most common defect.
- **The hierarchy check:** with a screen reader, focus a nested row. Expect
  "level 2, 1 of 2". If you hear no level, `aria-level` is missing — and because
  `<tr>` can't nest, nothing else conveys it.
- **The mode check:** in row mode, Left must collapse. In cell mode, Left must
  move a cell. If one Left does both, or the wrong one, the modes aren't
  separated.
- **The stale-count check:** collapse a branch, then read a sibling's position.
  If it says "3 of 7" when 4 are visible, you're computing `setsize` from the raw
  data instead of the current siblings.
- **Tab:** still the only way out (RAWeb 12.9).
- **Automated:** axe catches invalid `role="treegrid"` structure and missing
  names. It catches **nothing** else here — not `aria-expanded` on a cell, not
  missing levels, not stale counts, not a treegrid that should have been a table.
