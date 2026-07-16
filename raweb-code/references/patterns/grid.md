# Grid — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show grid`

> **If your table is read-only, you want [`table.md`](table.md), not this.**
> That's the whole first decision.

---

## Grid or table?

| | `<table>` ([table.md](table.md)) | `role="grid"` (this file) |
|---|---|---|
| Purpose | read data | **navigate and interact** |
| Keyboard | normal reading keys | arrows move cell to cell |
| Screen reader mode | reading mode | **application mode** |
| Example | a price list, a report | a spreadsheet, an editable data grid |

**Adding `role="grid"` to a static table is a downgrade.** It switches screen
readers into application mode and forces users to learn arrow navigation for
content they could already read perfectly well with their normal keys. A table
of data is a table.

Use `role="grid"` when cells contain controls the user operates, or when
cell-by-cell navigation and selection are the point.

---

## Universal rules

- **Build it on a real `<table>` with `<th scope>`.** `role="grid"` on `<table>`
  keeps the header associations (RAWeb 5.6, 5.7) *and* adds the interaction
  model. Div grids throw the headers away and rebuild them worse.
- **One Tab stop, roving tabindex on cells.** `tabindex="0"` on the focused
  cell, `-1` on all others. (RAWeb 12.8)
- **Because arrows are captured, Tab is the only way out.** Never intercept it.
  (RAWeb 12.9)
- **A cell with an interactive control needs a mode switch.** Enter to *enter*
  the cell and use the control; Escape to return to grid navigation. Otherwise
  arrow keys inside a text input fight the grid for the same keys.
- **Real focus moves.** `.focus()`, not `aria-activedescendant`.
- **`aria-colcount`/`aria-rowcount` only when virtualising.** If every row is in
  the DOM, the browser counts them; hand-maintained counts go stale.

---

## Vanilla

### Do

```html
<!-- A real <table>: role="grid" adds interaction WITHOUT discarding the header
     semantics (RAWeb 5.6, 5.7). -->
<table role="grid" aria-labelledby="budget-caption" id="budget-grid">
  <caption id="budget-caption">Q3 budget by department (editable)</caption>
  <thead>
    <tr>
      <th scope="col">Department</th>
      <th scope="col">Budget</th>
      <th scope="col">Spent</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <!-- Row headers stay <th scope="row"> — the grid role does not excuse you
           from Topic 5. -->
      <th scope="row" tabindex="0">Engineering</th>
      <td tabindex="-1"><input type="text" value="120000" tabindex="-1" aria-label="Engineering budget"></td>
      <td tabindex="-1">98,400</td>
    </tr>
    <tr>
      <th scope="row" tabindex="-1">Design</th>
      <td tabindex="-1"><input type="text" value="45000" tabindex="-1" aria-label="Design budget"></td>
      <td tabindex="-1">41,200</td>
    </tr>
  </tbody>
</table>

<div id="grid-status" role="status" aria-live="polite" class="sr-only"></div>
```

The inner `<input>` is `tabindex="-1"`: the **cell** is the Tab target, and the
input only becomes reachable once the user presses Enter to enter the cell. That
is the mode switch, and it is what stops the input's arrow keys from fighting the
grid's.

```css
[role="grid"] td, [role="grid"] th {
  padding: 0.5rem;
  border: 1px solid #ddd;
}

/* Real focus moves, so :focus-visible works (RAWeb 10.7). */
[role="grid"] td:focus-visible,
[role="grid"] th:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}

/* Edit mode is a distinct state — the user must see which mode they are in. */
[role="grid"] td[data-editing] {
  outline: 2px solid #1a7f37;
}
```

```js
const grid = document.getElementById('budget-grid');
const status = document.getElementById('grid-status');
const rows = () => [...grid.querySelectorAll('tbody tr, thead tr')];
const cellsIn = (row) => [...row.querySelectorAll('th, td')];

let editing = false;

function focusCell(rowIndex, colIndex) {
  const allRows = rows();
  const row = allRows[Math.max(0, Math.min(rowIndex, allRows.length - 1))];
  const cells = cellsIn(row);
  const cell = cells[Math.max(0, Math.min(colIndex, cells.length - 1))];

  // Roving tabindex across the whole grid: exactly one cell is the Tab stop.
  for (const r of allRows) for (const c of cellsIn(r)) c.setAttribute('tabindex', '-1');
  cell.setAttribute('tabindex', '0');
  cell.focus();
}

function position(cell) {
  const row = cell.closest('tr');
  return { row: rows().indexOf(row), col: cellsIn(row).indexOf(cell) };
}

grid.addEventListener('keydown', (event) => {
  const cell = event.target.closest('th, td');
  if (!cell) return;

  // EDIT MODE: the grid steps back and lets the control have its keys.
  if (editing) {
    if (event.key === 'Escape') {
      editing = false;
      cell.removeAttribute('data-editing');
      cell.querySelector('input')?.setAttribute('tabindex', '-1');
      cell.focus();                       // back to grid navigation
      status.textContent = 'Editing cancelled.';
    }
    return;   // arrows, Home, End all belong to the input right now
  }

  const { row, col } = position(cell);
  let target = null;

  if (event.key === 'ArrowRight') target = [row, col + 1];
  if (event.key === 'ArrowLeft') target = [row, col - 1];
  if (event.key === 'ArrowDown') target = [row + 1, col];
  if (event.key === 'ArrowUp') target = [row - 1, col];
  if (event.key === 'Home') target = [row, 0];
  if (event.key === 'End') target = [row, cellsIn(cell.closest('tr')).length - 1];
  if (event.key === 'PageDown') target = [rows().length - 1, col];
  if (event.key === 'PageUp') target = [0, col];
  if (event.ctrlKey && event.key === 'Home') target = [0, 0];

  if (target) {
    event.preventDefault();
    focusCell(target[0], target[1]);
    return;
  }

  // Enter the cell: the input becomes reachable and takes the keyboard.
  if (event.key === 'Enter') {
    const input = cell.querySelector('input');
    if (!input) return;
    event.preventDefault();
    editing = true;
    cell.setAttribute('data-editing', '');
    input.setAttribute('tabindex', '0');
    input.focus();
    input.select();
    status.textContent = 'Editing. Press Escape to stop editing.';
  }

  // Tab: NOT handled. It is the only way out of a grid (RAWeb 12.9).
});
```

### Don't

```html
<!-- DON'T: role="grid" on a read-only table. THE grid mistake.
     → Switches screen readers into application mode. The user must now arrow
       cell by cell through content their normal reading keys handled perfectly
       well. You made a readable table harder to read. -->
<table role="grid">
  <caption>Revenue by region</caption>
  <tr><th scope="col">Region</th><td>€2.4M</td></tr>
</table>

<!-- DON'T: a div grid.
     → No header associations (RAWeb 5.6, 5.7), no row/column semantics from the
       platform. You now rebuild everything <table> gave you, worse. -->
<div role="grid">
  <div role="row"><div role="gridcell">Engineering</div></div>
</div>

<!-- DON'T: tabbable controls inside cells with no mode switch.
     → The input is a Tab stop AND the cell is a Tab stop. Worse: pressing Left
       inside the input moves the text cursor, and your grid handler ALSO moves
       the focused cell. Both fire. Use tabindex="-1" + Enter to enter. -->
<td tabindex="-1"><input type="text" value="120000"></td>

<!-- DON'T: every cell tabbable.
     → A 20×10 grid becomes 200 Tab stops (RAWeb 12.8). -->
<td tabindex="0">98,400</td>

<!-- DON'T: drop the row headers because "it's a grid now".
     → Topic 5 still applies. Without scope="row", a cell announces its value
       with no idea which department it belongs to (RAWeb 5.7). -->
<tr><td tabindex="-1">Engineering</td><td tabindex="-1">120000</td></tr>

<!-- DON'T: an unnamed grid.
     → "grid, 3 columns, 5 rows" — of what? -->
<table role="grid">…</table>
```

```js
// DON'T: intercept Tab.
//     → The grid already owns every arrow key. Tab is the ONLY exit. Capturing
//       it is a total keyboard trap (RAWeb 12.9).
if (event.key === 'Tab') { event.preventDefault(); focusNextCell(); }

// DON'T: handle arrows while a cell is in edit mode.
//     → Left/Right must move the TEXT CURSOR inside the input, not the focused
//       cell. Without the `if (editing) return` guard, both happen and the user
//       cannot position their cursor at all.
grid.addEventListener('keydown', (event) => {
  if (event.key === 'ArrowLeft') focusCell(row, col - 1);   // fires while typing
});

// DON'T: hand-maintain aria-rowcount on a fully-rendered grid.
//     → The browser counts the rows. Yours goes stale after the first filter and
//       then announces "row 3 of 50" in a grid of 3.
grid.setAttribute('aria-rowcount', '50');
```

---

## React

### Do

```jsx
import { useRef, useState } from 'react';

export function BudgetGrid({ rows, onEdit }) {
  const [focus, setFocus] = useState({ row: 0, col: 0 });
  const [editing, setEditing] = useState(false);
  const cellRefs = useRef(new Map());

  const key = (r, c) => `${r}-${c}`;
  const move = (r, c) => {
    const clamped = {
      row: Math.max(0, Math.min(r, rows.length - 1)),
      col: Math.max(0, Math.min(c, 2)),
    };
    setFocus(clamped);
    cellRefs.current.get(key(clamped.row, clamped.col))?.focus();
  };

  const onKeyDown = (event) => {
    if (editing) {
      if (event.key === 'Escape') {
        setEditing(false);
        cellRefs.current.get(key(focus.row, focus.col))?.focus();
      }
      return;   // the input owns the keyboard in edit mode
    }

    const { row, col } = focus;
    if (event.key === 'ArrowRight') { event.preventDefault(); move(row, col + 1); }
    else if (event.key === 'ArrowLeft') { event.preventDefault(); move(row, col - 1); }
    else if (event.key === 'ArrowDown') { event.preventDefault(); move(row + 1, col); }
    else if (event.key === 'ArrowUp') { event.preventDefault(); move(row - 1, col); }
    else if (event.key === 'Home') { event.preventDefault(); move(row, 0); }
    else if (event.key === 'End') { event.preventDefault(); move(row, 2); }
    else if (event.key === 'Enter') { event.preventDefault(); setEditing(true); }
    // Tab: untouched.
  };

  return (
    <table role="grid" aria-label="Q3 budget by department" onKeyDown={onKeyDown}>
      <thead>
        <tr>
          <th scope="col">Department</th>
          <th scope="col">Budget</th>
          <th scope="col">Spent</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row, r) => (
          <tr key={row.id}>
            <th
              scope="row"
              ref={(n) => { cellRefs.current.set(key(r, 0), n); }}
              tabIndex={focus.row === r && focus.col === 0 ? 0 : -1}
            >
              {row.department}
            </th>
            <td
              ref={(n) => { cellRefs.current.set(key(r, 1), n); }}
              tabIndex={focus.row === r && focus.col === 1 ? 0 : -1}
            >
              {editing && focus.row === r && focus.col === 1 ? (
                <input
                  autoFocus
                  defaultValue={row.budget}
                  aria-label={`${row.department} budget`}
                  onBlur={(e) => { onEdit(row.id, e.target.value); setEditing(false); }}
                />
              ) : (
                row.budget
              )}
            </td>
            <td
              ref={(n) => { cellRefs.current.set(key(r, 2), n); }}
              tabIndex={focus.row === r && focus.col === 2 ? 0 : -1}
            >
              {row.spent}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

### Don't

```jsx
// DON'T: role="grid" on a read-only data table because a library said so.
//     → Many React table libraries apply role="grid" by default. For a
//       read-only table that is a downgrade — check, and remove it.

// DON'T: a div grid with role attributes.
//     → react-table and friends render divs by default. You lose <th scope>,
//       and RAWeb 5.6/5.7 with it. Render a real <table>.
<div role="grid"><div role="row"><div role="gridcell">…</div></div></div>

// DON'T: no editing guard in the key handler.
//     → Arrow keys move the focused cell WHILE the user is trying to move the
//       text cursor inside an input.
```

---

## Angular

### Do

```ts
import { Component, ElementRef, input, signal, viewChildren } from '@angular/core';

@Component({
  selector: 'app-budget-grid',
  template: `
    <table role="grid" aria-label="Q3 budget by department" (keydown)="onKeyDown($event)">
      <thead>
        <tr>
          <th scope="col">Department</th>
          <th scope="col">Budget</th>
          <th scope="col">Spent</th>
        </tr>
      </thead>
      <tbody>
        @for (row of rows(); track row.id; let r = $index) {
          <tr>
            <th scope="row" #cell [tabIndex]="isFocused(r, 0) ? 0 : -1">{{ row.department }}</th>
            <td #cell [tabIndex]="isFocused(r, 1) ? 0 : -1">{{ row.budget }}</td>
            <td #cell [tabIndex]="isFocused(r, 2) ? 0 : -1">{{ row.spent }}</td>
          </tr>
        }
      </tbody>
    </table>
  `,
})
export class BudgetGridComponent {
  readonly rows = input.required<{ id: string; department: string; budget: number; spent: number }[]>();
  protected readonly focusRow = signal(0);
  protected readonly focusCol = signal(0);
  private readonly cells = viewChildren<ElementRef<HTMLTableCellElement>>('cell');

  protected isFocused(r: number, c: number): boolean {
    return this.focusRow() === r && this.focusCol() === c;
  }

  protected onKeyDown(event: KeyboardEvent): void {
    const maxRow = this.rows().length - 1;
    let r = this.focusRow(), c = this.focusCol(), moved = true;

    if (event.key === 'ArrowRight') c = Math.min(c + 1, 2);
    else if (event.key === 'ArrowLeft') c = Math.max(c - 1, 0);
    else if (event.key === 'ArrowDown') r = Math.min(r + 1, maxRow);
    else if (event.key === 'ArrowUp') r = Math.max(r - 1, 0);
    else if (event.key === 'Home') c = 0;
    else if (event.key === 'End') c = 2;
    else moved = false;   // Tab and everything else pass through

    if (!moved) return;
    event.preventDefault();
    this.focusRow.set(r);
    this.focusCol.set(c);
    queueMicrotask(() => this.cells()[r * 3 + c]?.nativeElement.focus());
  }
}
```

### Don't

```html
<!-- DON'T: [attr.tabindex] with a boolean — renders tabindex="false", parsed
     as 0, so every cell is a Tab stop. Use [tabIndex]. -->
<td [attr.tabindex]="isFocused(r, c)">{{ row.budget }}</td>
```

---

## Web Component

### Do

```js
// Light DOM. The author supplies a real <table> with real <th scope>; the
// component adds only the roving tabindex and the arrow model. A shadow grid
// would hide the table semantics the pattern depends on.
class A11yGrid extends HTMLElement {
  connectedCallback() {
    this.#grid = this.querySelector('[role="grid"]');
    this.#grid.addEventListener('keydown', (e) => this.#onKeyDown(e));
    this.#focusCell(0, 0);
  }

  #grid;
  #editing = false;

  get #rows() { return [...this.#grid.querySelectorAll('tr')]; }
  #cells(row) { return [...row.querySelectorAll('th, td')]; }

  #focusCell(r, c) {
    const rows = this.#rows;
    const row = rows[Math.max(0, Math.min(r, rows.length - 1))];
    const cells = this.#cells(row);
    const cell = cells[Math.max(0, Math.min(c, cells.length - 1))];
    for (const rr of rows) for (const cc of this.#cells(rr)) cc.setAttribute('tabindex', '-1');
    cell.setAttribute('tabindex', '0');
    cell.focus();
  }

  #onKeyDown(event) {
    if (this.#editing) {
      if (event.key === 'Escape') { this.#editing = false; event.target.closest('td').focus(); }
      return;
    }
    const cell = event.target.closest('th, td');
    if (!cell) return;
    const row = cell.closest('tr');
    const r = this.#rows.indexOf(row);
    const c = this.#cells(row).indexOf(cell);

    if (event.key === 'ArrowRight') { event.preventDefault(); this.#focusCell(r, c + 1); }
    else if (event.key === 'ArrowLeft') { event.preventDefault(); this.#focusCell(r, c - 1); }
    else if (event.key === 'ArrowDown') { event.preventDefault(); this.#focusCell(r + 1, c); }
    else if (event.key === 'ArrowUp') { event.preventDefault(); this.#focusCell(r - 1, c); }
    // Tab untouched.
  }
}

customElements.define('a11y-grid', A11yGrid);
```

### Don't

```js
// DON'T: build the table inside a shadow root from slotted cells.
//     → The <table>/<tr>/<th> relationships depend on real DOM nesting. Slotting
//       cells into a shadow table structure breaks the header associations —
//       and aria-labelledby cannot cross the boundary either.
```

---

## Verify

- **First: does this need to be a grid?** If nothing in the cells is
  interactive, remove `role="grid"` and let it be a table. That's the most
  common defect.
- **The Tab check (RAWeb 12.9):** Tab into the grid, Tab again. You must be
  **out**. The grid owns every arrow key, so if Tab is also captured the user is
  trapped with no exit at all — the worst version of this bug.
- **The edit-mode check:** enter a cell with an input, press Left. The **text
  cursor** must move, not the focused cell. If the grid moves, you're missing the
  editing guard.
- **The header check:** arrow to a cell in the middle. It must still announce its
  row and column headers — `role="grid"` doesn't excuse RAWeb 5.6/5.7.
- **Screen reader:** "«name», grid" then "Engineering, Budget, 120000, row 2,
  column 2".
- **Automated:** axe catches invalid `role="grid"` children and missing names. It
  does **not** catch `role="grid"` on a read-only table, a captured Tab, or arrow
  keys fighting an input.
