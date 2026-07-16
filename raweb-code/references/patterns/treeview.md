# Treeview — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show treeview`

---

## Do you need a tree?

`role="tree"` switches screen readers into **application mode**: normal reading
keys stop working, and the user must know the tree keyboard model (Right expands,
Left collapses, arrows skip collapsed children). That's a real cost, paid by
every user, on every visit.

| What you have | Use |
|---|---|
| Nav sidebar with expandable sections | `<nav>` + nested `<ul>` + [`disclosure`](disclosure.md) buttons |
| Table of contents | `<nav>` + nested `<ul>` + `<a>` |
| A category picker | [`listbox`](listbox.md), or nested `<select>` |
| A **file browser** — hundreds of nodes, expand/collapse, selection, keyboard-driven | **treeview** (this file) |

The honest test: **would a desktop application use a tree widget here?** A file
explorer, yes. Your docs sidebar, no.

> A nav sidebar of nested `<ul>`s with disclosure buttons keeps normal link
> semantics, needs no arrow keys, and every user already knows how to use it.
> That is almost always the better answer.

---

## Universal rules

- **One Tab stop, roving tabindex.** `tabindex="0"` on the focused item, `-1` on
  every other. (RAWeb 12.8)
- **Arrows move through *visible* items only** — never into collapsed children.
- **Right expands or steps into the first child; Left collapses or steps to the
  parent.** This is the model users bring from the desktop; deviating from it is
  worse than not using a tree.
- **`aria-expanded` only on nodes that *have* children.** A leaf with
  `aria-expanded="false"` claims children it doesn't have.
- **Nest real `<ul>`s with `role="group"` and the browser computes `aria-level`
  for you.** Only a flattened DOM needs `aria-level`/`aria-setsize`/
  `aria-posinset` by hand — and hand-maintained values go stale.
- **Collapsed branches must be `hidden` or absent.** (RAWeb 10.8)
- **Type-ahead is expected** — typing a letter jumps to the next visible match.
- **Tab must leave.** (RAWeb 12.9)

---

## Vanilla

### Do — the alternative you probably want

```html
<!-- Nested lists + disclosure buttons. No application mode, no arrow keys, no
     roving tabindex. Every user already knows how this works. -->
<nav aria-label="Documentation">
  <ul>
    <li>
      <button type="button" aria-expanded="true" aria-controls="guides-list">Guides</button>
      <ul id="guides-list">
        <li><a href="/guides/start">Getting started</a></li>
        <li><a href="/guides/forms">Forms</a></li>
      </ul>
    </li>
    <li><a href="/reference">Reference</a></li>
  </ul>
</nav>
```

### Do — a real tree, when you need one

```html
<span id="files-label">Project files</span>

<!-- One Tab stop. The <ul>/role="group" nesting means the browser computes
     aria-level, aria-setsize and aria-posinset — do not hand-maintain them. -->
<ul role="tree" aria-labelledby="files-label" id="file-tree">
  <li role="treeitem" aria-expanded="true" tabindex="0">
    <span class="tree__label">src</span>
    <ul role="group">
      <li role="treeitem" tabindex="-1"><span class="tree__label">index.js</span></li>
      <li role="treeitem" aria-expanded="false" tabindex="-1">
        <span class="tree__label">components</span>
        <!-- Collapsed: hidden, not just visually closed (RAWeb 10.8). -->
        <ul role="group" hidden>
          <li role="treeitem" tabindex="-1"><span class="tree__label">Button.js</span></li>
        </ul>
      </li>
    </ul>
  </li>
  <!-- A LEAF: no aria-expanded. It has no children to expand. -->
  <li role="treeitem" tabindex="-1"><span class="tree__label">README.md</span></li>
</ul>
```

```css
[role="tree"], [role="group"] { list-style: none; padding-inline-start: 1rem; }

/* Real focus moves here, so :focus-visible works (RAWeb 10.7). */
[role="treeitem"]:focus-visible > .tree__label {
  outline: 2px solid #0056b3;
  outline-offset: -2px;
}

/* State-driven from the attribute: the twisty and the announced state cannot
   drift apart. */
[role="treeitem"][aria-expanded="true"] > .tree__label::before { content: "▾ "; }
[role="treeitem"][aria-expanded="false"] > .tree__label::before { content: "▸ "; }
```

```js
const tree = document.getElementById('file-tree');

// Only VISIBLE items — an item inside a hidden group is not navigable.
const visibleItems = () =>
  [...tree.querySelectorAll('[role="treeitem"]')]
    .filter((item) => !item.closest('[role="group"][hidden]'));

const isExpandable = (item) => item.hasAttribute('aria-expanded');
const isExpanded = (item) => item.getAttribute('aria-expanded') === 'true';
const groupOf = (item) => item.querySelector(':scope > [role="group"]');
const parentOf = (item) => item.parentElement.closest('[role="treeitem"]');

function focusItem(item) {
  for (const other of tree.querySelectorAll('[role="treeitem"]')) {
    other.setAttribute('tabindex', other === item ? '0' : '-1');
  }
  item.focus();
}

function setExpanded(item, expanded) {
  if (!isExpandable(item)) return;
  item.setAttribute('aria-expanded', String(expanded));
  const group = groupOf(item);
  if (group) group.hidden = !expanded;
}

tree.addEventListener('keydown', (event) => {
  const item = document.activeElement.closest('[role="treeitem"]');
  if (!item) return;

  const items = visibleItems();
  const index = items.indexOf(item);

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      if (items[index + 1]) focusItem(items[index + 1]);
      break;

    case 'ArrowUp':
      event.preventDefault();
      if (items[index - 1]) focusItem(items[index - 1]);
      break;

    // Right: expand if collapsed, else step INTO the first child.
    case 'ArrowRight':
      event.preventDefault();
      if (isExpandable(item) && !isExpanded(item)) setExpanded(item, true);
      else if (isExpanded(item)) {
        const first = groupOf(item)?.querySelector('[role="treeitem"]');
        if (first) focusItem(first);
      }
      break;

    // Left: collapse if expanded, else step OUT to the parent.
    case 'ArrowLeft':
      event.preventDefault();
      if (isExpandable(item) && isExpanded(item)) setExpanded(item, false);
      else {
        const parent = parentOf(item);
        if (parent) focusItem(parent);
      }
      break;

    case 'Home': event.preventDefault(); focusItem(items[0]); break;
    case 'End': event.preventDefault(); focusItem(items.at(-1)); break;

    case 'Enter':
    case ' ':
      event.preventDefault();
      isExpandable(item) ? setExpanded(item, !isExpanded(item)) : activate(item);
      break;

    // Tab: not handled — it must leave (RAWeb 12.9).
  }
});

// Type-ahead: expected in a tree, and free in a native <select>.
let buffer = '';
let bufferTimer;
tree.addEventListener('keydown', (event) => {
  if (event.key.length !== 1 || event.ctrlKey || event.metaKey || event.altKey) return;
  clearTimeout(bufferTimer);
  buffer += event.key.toLowerCase();
  bufferTimer = setTimeout(() => { buffer = ''; }, 500);

  const match = visibleItems().find((item) =>
    item.querySelector(':scope > .tree__label').textContent.toLowerCase().startsWith(buffer),
  );
  if (match) focusItem(match);
});
```

### Don't

```html
<!-- DON'T: role="tree" on a nav sidebar.
     → Application mode for a list of links. Reading keys stop working; the user
       must learn the tree model to read your docs menu. Nested <ul> +
       disclosure buttons does the same job with none of the cost. -->
<nav>
  <ul role="tree" aria-label="Documentation">
    <li role="treeitem"><a href="/guides">Guides</a></li>
  </ul>
</nav>

<!-- DON'T: aria-expanded on a leaf.
     → Announces "collapsed" for something with nothing to expand. The user
       presses Right and nothing happens. -->
<li role="treeitem" aria-expanded="false" tabindex="-1">README.md</li>

<!-- DON'T: every item tabbable.
     → A 200-node tree becomes 200 Tab stops (RAWeb 12.8). -->
<li role="treeitem" tabindex="0">index.js</li>

<!-- DON'T: hand-maintained aria-level on a properly nested tree.
     → The browser already computes it from the <ul>/role="group" structure.
       Yours will go stale the first time someone reorders a branch, and then it
       lies confidently. -->
<li role="treeitem" aria-level="2" aria-setsize="3" aria-posinset="1">index.js</li>

<!-- DON'T: collapse with CSS only.
     → Children stay in the accessibility tree and the arrow-key sequence walks
       through nodes nobody can see (RAWeb 10.8). -->
<ul role="group" style="display: none">…</ul>   <!-- ok -->
<ul role="group" style="height: 0; overflow: hidden">…</ul>   <!-- NOT ok -->

<!-- DON'T: interactive controls inside a treeitem.
     → Arrows move between items and never into them, so the button is
       unreachable. If nodes need actions, that is a treegrid. -->
<li role="treeitem" tabindex="-1">
  index.js <button type="button">Delete</button>
</li>
```

```js
// DON'T: arrow through ALL items, including collapsed children.
//     → Focus lands inside a collapsed branch. The user sees nothing move and
//       the screen reader announces a node that is not on screen.
const items = [...tree.querySelectorAll('[role="treeitem"]')];   // no filter

// DON'T: make Right always step into a child.
//     → On a collapsed node, Right must EXPAND first. Skipping straight in
//       leaves the state and the focus disagreeing.

// DON'T: trap Tab. Arrows navigate; Tab leaves (RAWeb 12.9).
if (event.key === 'Tab') event.preventDefault();
```

---

## React

### Do

```jsx
import { useId, useRef, useState } from 'react';

// A flat map of node → parent keeps focus/expansion logic simple; the DOM stays
// genuinely nested so the browser computes aria-level.
export function Tree({ label, nodes }) {
  const [expanded, setExpanded] = useState(() => new Set(['src']));
  const [focusKey, setFocusKey] = useState(nodes[0]?.key);
  const labelId = useId();
  const itemRefs = useRef(new Map());

  const toggle = (key) =>
    setExpanded((prev) => {
      const next = new Set(prev);
      next.has(key) ? next.delete(key) : next.add(key);
      return next;
    });

  const focus = (key) => {
    setFocusKey(key);
    itemRefs.current.get(key)?.focus();
  };

  const renderNodes = (list) =>
    list.map((node) => {
      const hasChildren = Boolean(node.children?.length);
      const isExpanded = expanded.has(node.key);
      return (
        <li
          key={node.key}
          ref={(n) => {
            itemRefs.current.set(node.key, n);
            return () => itemRefs.current.delete(node.key);
          }}
          role="treeitem"
          // Only on nodes that HAVE children.
          aria-expanded={hasChildren ? isExpanded : undefined}
          tabIndex={node.key === focusKey ? 0 : -1}
          onClick={(e) => { e.stopPropagation(); setFocusKey(node.key); if (hasChildren) toggle(node.key); }}
        >
          <span className="tree__label">{node.label}</span>
          {hasChildren && (
            <ul role="group" hidden={!isExpanded}>
              {renderNodes(node.children)}
            </ul>
          )}
        </li>
      );
    });

  return (
    <>
      <span id={labelId}>{label}</span>
      <ul role="tree" aria-labelledby={labelId} onKeyDown={(e) => handleKeys(e, { expanded, toggle, focus })}>
        {renderNodes(nodes)}
      </ul>
    </>
  );
}
```

`aria-expanded={hasChildren ? isExpanded : undefined}` is the key line:
`undefined` removes the attribute entirely, so leaves don't claim children.

### Don't

```jsx
// DON'T: aria-expanded={false} on leaves.
//     → React renders aria-expanded="false", so every file claims to be an
//       expandable folder. Use undefined.
<li role="treeitem" aria-expanded={isExpanded}>{node.label}</li>

// DON'T: flatten the tree into divs and hand-set aria-level.
//     → Now you maintain level, setsize and posinset by hand across every
//       insert, delete and reorder. Nest real <ul role="group">.
<div role="treeitem" aria-level={depth} aria-posinset={i + 1} aria-setsize={siblings.length} />

// DON'T: tabIndex={0} on every item.
```

---

## Angular

### Do

**Use the CDK.** `@angular/cdk/tree` implements roving tabindex, the arrow model,
expansion state, and type-ahead. This pattern has enough surface that
hand-rolling it in Angular is rarely justified:

```ts
import { Component } from '@angular/core';
import { CdkTree, CdkTreeNode, CdkTreeNodeDef, CdkTreeNodeToggle, CdkTreeNodePadding } from '@angular/cdk/tree';

@Component({
  selector: 'app-file-tree',
  imports: [CdkTree, CdkTreeNode, CdkTreeNodeDef, CdkTreeNodeToggle, CdkTreeNodePadding],
  template: `
    <cdk-tree [dataSource]="dataSource" [treeControl]="treeControl" aria-label="Project files">
      <cdk-tree-node *cdkTreeNodeDef="let node" cdkTreeNodePadding>
        {{ node.name }}
      </cdk-tree-node>

      <cdk-tree-node *cdkTreeNodeDef="let node; when: hasChild" cdkTreeNodePadding>
        <button type="button" cdkTreeNodeToggle [attr.aria-label]="'Toggle ' + node.name">
          <span aria-hidden="true">{{ treeControl.isExpanded(node) ? '▾' : '▸' }}</span>
        </button>
        {{ node.name }}
      </cdk-tree-node>
    </cdk-tree>
  `,
})
export class FileTreeComponent { /* … */ }
```

### Don't

```html
<!-- DON'T: role="tree" on a nav menu, CDK or not. The implementation being
     correct does not make the pattern right. -->
<cdk-tree aria-label="Site navigation">…</cdk-tree>

<!-- DON'T: [attr.hidden] on groups — renders hidden="false" and still hides.
     Use [hidden]. -->
<ul role="group" [attr.hidden]="!isExpanded()">…</ul>
```

---

## Web Component

### Do

```js
// Light DOM: aria-labelledby (tree → label) is an IDREF, and the author owns
// the node markup. A shadow tree would also hide the nesting the browser needs
// to compute aria-level.
class A11yTree extends HTMLElement {
  connectedCallback() {
    this.#tree = this.querySelector('[role="tree"]');
    this.#tree.addEventListener('keydown', (e) => this.#onKeyDown(e));
    this.#tree.addEventListener('click', (e) => {
      const item = e.target.closest('[role="treeitem"]');
      if (item) this.#focus(item);
    });
  }

  #tree;

  get #visible() {
    return [...this.#tree.querySelectorAll('[role="treeitem"]')]
      .filter((i) => !i.closest('[role="group"][hidden]'));
  }

  #focus(item) {
    for (const other of this.#tree.querySelectorAll('[role="treeitem"]')) {
      other.setAttribute('tabindex', other === item ? '0' : '-1');
    }
    item.focus();
  }

  #setExpanded(item, expanded) {
    if (!item.hasAttribute('aria-expanded')) return;
    item.setAttribute('aria-expanded', String(expanded));
    const group = item.querySelector(':scope > [role="group"]');
    if (group) group.hidden = !expanded;
  }

  #onKeyDown(event) { /* same model as the vanilla example */ }
}

customElements.define('a11y-tree', A11yTree);
```

### Don't

```js
// DON'T: render tree nodes into a shadow root.
//     → The browser computes aria-level from the nesting; a slotted flat list
//       inside a shadow structure breaks that, and aria-labelledby cannot cross
//       the boundary either.
```

---

## Verify

- **First: should it be a tree?** If it's navigation, it shouldn't. That's the
  most likely defect by a wide margin.
- **The collapsed-branch check:** collapse a folder, then arrow past it. Focus
  must **skip** its children entirely. If focus lands on an invisible node, you
  hid the group with CSS instead of `hidden`, or you're not filtering to visible
  items.
- **Keyboard:** one Tab stop. Right expands then steps in; Left collapses then
  steps out; Home/End jump; typing jumps. Tab exits (RAWeb 12.9).
- **The leaf check:** focus a file (not a folder). It must **not** announce
  "collapsed". If it does, `aria-expanded` is on a leaf.
- **Screen reader:** "src, tree item, expanded, level 1, 1 of 2". If the level or
  position is wrong, you're hand-maintaining `aria-level` on a nested tree —
  delete those attributes and let the browser do it.
- **Automated:** axe catches `role="treeitem"` outside a tree and missing names.
  It does **not** catch a tree used for navigation, `aria-expanded` on leaves, or
  focus walking into collapsed branches.
