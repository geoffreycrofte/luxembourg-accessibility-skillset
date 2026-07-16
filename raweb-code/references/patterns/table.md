# Table — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show table`

> **No framework sections.** A `<table>` is a `<table>` everywhere. This is
> Topic 5 of RAWeb — six criteria, all about markup.
> For an *editable* or *interactive* table, that's a different pattern:
> `show grid`.

---

## Universal rules

- **`<caption>` is the table's name, and must be the first child of `<table>`.**
  A nearby `<h2>` is not associated with anything. (RAWeb 5.4, 5.5)
- **Every header is a `<th>` with a `scope`.** (RAWeb 5.6, 5.7) Without `scope`,
  browsers guess — and guess wrong on anything non-trivial.
- **The first cell of a row is usually `<th scope="row">`, not `<td>`.** This is
  the most commonly missed one: people mark up the column headers and forget the
  row headers, so a screen reader announces "€2.4M" with no idea which region.
- **Complex tables need `headers`/`id`, not `scope`.** When headers span or
  nest, `scope` cannot express the relationship. (RAWeb 5.7)
- **Layout tables must not use `<th>`, `<caption>`, `scope` or `headers`.**
  (RAWeb 5.8) Better: don't use layout tables. CSS grid exists.
- **A scrolling table container needs `tabindex="0"` and a name.** Otherwise
  keyboard users cannot scroll it. (RAWeb 10.11)
- **Empty header cells announce nothing.** The top-left corner cell is the usual
  culprit.

---

## Vanilla

### Do — simple data table

```html
<table>
  <!-- FIRST child of <table>. This is the table's accessible name
       (RAWeb 5.4). It is not interchangeable with a heading above the table. -->
  <caption>Revenue by region, Q3 2024</caption>

  <thead>
    <tr>
      <!-- The corner cell. Empty would announce as nothing — give it text, or
           visually hidden text if the design demands a blank corner. -->
      <th scope="col">Region</th>
      <th scope="col">Revenue</th>
      <th scope="col">Growth</th>
    </tr>
  </thead>

  <tbody>
    <tr>
      <!-- scope="row": THE commonly-forgotten one. Without it, "€2.4M" is
           announced with no region attached (RAWeb 5.6, 5.7). -->
      <th scope="row">Europe</th>
      <td>€2.4M</td>
      <td>+12%</td>
    </tr>
    <tr>
      <th scope="row">Asia-Pacific</th>
      <td>€1.8M</td>
      <td>+31%</td>
    </tr>
  </tbody>

  <tfoot>
    <tr>
      <th scope="row">Total</th>
      <td>€4.2M</td>
      <td>+19%</td>
    </tr>
  </tfoot>
</table>
```

With `scope` in place, a screen reader announces "Europe, Revenue, €2.4M" as the
user moves across the row — the headers travel with the cell. That's the whole
point of Topic 5.

### Do — complex table with spanning headers

```html
<table>
  <caption>Revenue and headcount by region and quarter, 2024</caption>
  <thead>
    <tr>
      <td></td>
      <!-- Spanning headers: scope cannot express "this cell belongs to Q3 AND
           Revenue AND Europe". Use ids + headers (RAWeb 5.7). -->
      <th id="q3" colspan="2" scope="colgroup">Q3</th>
      <th id="q4" colspan="2" scope="colgroup">Q4</th>
    </tr>
    <tr>
      <td></td>
      <th id="q3-rev">Revenue</th>
      <th id="q3-hc">Headcount</th>
      <th id="q4-rev">Revenue</th>
      <th id="q4-hc">Headcount</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th id="europe" scope="row">Europe</th>
      <!-- Each cell names every header that applies, in reading order. -->
      <td headers="europe q3 q3-rev">€2.4M</td>
      <td headers="europe q3 q3-hc">120</td>
      <td headers="europe q4 q4-rev">€2.9M</td>
      <td headers="europe q4 q4-hc">134</td>
    </tr>
  </tbody>
</table>
```

### Do — scrollable table (RAWeb 10.11)

```html
<!-- Tables are the number-one cause of horizontal scroll at 320px. The wrapper
     makes it scrollable; tabindex="0" makes it scrollable BY KEYBOARD; role
     and name make that scrollable thing announced rather than a mystery. -->
<div role="region" aria-labelledby="revenue-caption" tabindex="0" class="table-scroll">
  <table>
    <caption id="revenue-caption">Revenue by region, Q3 2024</caption>
    …
  </table>
</div>
```

```css
.table-scroll {
  overflow-x: auto;
}

.table-scroll:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

th, td {
  text-align: start;
  padding: 0.5rem;
  border-block-end: 1px solid #ddd;
}

/* Zebra striping must not be the only way to tell rows apart, and must keep
   text contrast in BOTH stripes (RAWeb 3.2). */
tbody tr:nth-child(even) {
  background: #f5f5f5;
}
```

### Don't

```html
<!-- DON'T: a heading instead of a caption.
     → The <h2> names nothing. The table is announced as "table, 3 columns, 4
       rows" with no title (RAWeb 5.4). -->
<h2>Revenue by region</h2>
<table>
  <tr><th scope="col">Region</th></tr>
</table>

<!-- DON'T: <caption> anywhere but first.
     → Invalid; browsers relocate or drop it. -->
<table>
  <thead>…</thead>
  <caption>Revenue by region</caption>
</table>

<!-- DON'T: <th> with no scope.
     → The browser guesses. On any table with row headers, or more than one
       header row, it guesses wrong (RAWeb 5.7). -->
<th>Region</th>

<!-- DON'T: <td> for row headers. THE most common Topic 5 failure.
     → Moving across the row announces "€2.4M, +12%" — of WHAT? The region is
       never attached. Column headers alone are half the job. -->
<tr>
  <td>Europe</td>
  <td>€2.4M</td>
</tr>

<!-- DON'T: styled divs as a table.
     → No rows, no columns, no headers, no cell-to-header association. A screen
       reader reads it as one flat run of text with no structure at all. -->
<div class="table">
  <div class="row"><div class="cell">Region</div><div class="cell">Revenue</div></div>
  <div class="row"><div class="cell">Europe</div><div class="cell">€2.4M</div></div>
</div>

<!-- DON'T: a layout table with data-table markup (RAWeb 5.8).
     → If it really is layout, it must have NO <th>, <caption>, scope or
       headers, and needs role="presentation". Better: use CSS grid. -->
<table>
  <caption>Page layout</caption>
  <tr><th>Sidebar</th><td>Main content</td></tr>
</table>

<!-- DON'T: an empty corner header.
     → Announced as nothing, so the row-header column has no name. If the design
       needs it blank, use visually hidden text. -->
<th scope="col"></th>

<!-- DO instead: -->
<th scope="col"><span class="sr-only">Region</span></th>

<!-- DON'T: scope on a complex spanning table.
     → scope cannot express two-dimensional header relationships. Cells get
       associated with the wrong headers — worse than none, because it is
       confidently wrong (RAWeb 5.7). Use headers/id. -->
<th colspan="2" scope="col">Q3</th>

<!-- DON'T: nested tables.
     → Announced as a table inside a cell of a table. Navigation becomes
       impossible to follow. Flatten, or use separate tables. -->
<td><table>…</table></td>

<!-- DON'T: a scroll wrapper with no tabindex.
     → overflow-x: auto scrolls with a mouse wheel or a swipe. A keyboard user
       has no way to scroll it at all — the right-hand columns are unreachable
       (RAWeb 10.11). -->
<div style="overflow-x: auto">
  <table>…</table>
</div>
```

---

## Verify

- **The row-header check — the one people fail.** With a screen reader, put the
  cursor on a data cell in the middle of the table. It must announce **both** its
  column header and its row header: "Europe, Revenue, €2.4M". If you only hear
  "Revenue, €2.4M", your row headers are `<td>`s.
- **The caption check:** the table must announce with its title. If it announces
  as a bare "table", the `<caption>` is missing or is really a heading
  (RAWeb 5.4).
- **The 320px check (RAWeb 10.11):** narrow the viewport to 320px. If the table
  forces the *page* to scroll sideways, it needs a scroll wrapper. Then Tab to
  that wrapper and try to scroll it **with arrow keys only**.
- **Automated:** axe catches `<th>` with no scope, empty header cells, and
  captions in the wrong place — Topic 5 is one of the better-automated areas. It
  does **not** catch row headers marked as `<td>` (perfectly valid HTML), a
  caption that doesn't describe the table (RAWeb 5.5), or wrong `headers`
  associations.
