# Checkbox — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show checkbox`

---

## Universal rules

- **`<input type="checkbox">`.** Focusable, toggles on Space, announces
  correctly, posts a form value, works with autofill and password managers.
  `role="checkbox"` on a `<div>` re-creates all of that, worse. (RAWeb 7.3)
- **Style the native input — don't hide it behind a fake one.** `appearance: none`
  plus `:checked` styling gets you any design you want while keeping the real
  control. The old "visually hide the input and style a `<span>`" trick separates
  the focusable thing from the visible thing.
- **Every checkbox needs its own `<label for>`.** (RAWeb 11.1)
- **Related checkboxes go in `<fieldset><legend>`.** Without it, "Email" is
  announced with no hint that the question was "How should we contact you?" —
  a screen reader user hears the answers and never the question. (RAWeb 11.5)
- **Tri-state is a JS *property*, not an attribute.** `el.indeterminate = true`.
  There is no `indeterminate` HTML attribute — setting one does nothing. The
  browser maps the property to `aria-checked="mixed"` for you.
- **Never set `aria-checked` on a native checkbox.** The browser derives it from
  `.checked`. Setting both invites them to disagree.
- **Applies immediately? It's probably a [`switch`](switch.md).** Checkbox =
  submitted with a form. Switch = takes effect now.

---

## Vanilla

### Do

```html
<!-- Single checkbox: label + for. Nothing else needed. -->
<div class="field">
  <input type="checkbox" id="terms" name="terms" required>
  <label for="terms">I accept the terms of service</label>
</div>

<!-- A GROUP needs the question in a legend (RAWeb 11.5). Without the legend,
     a screen reader user hears "Email, checkbox" with no idea what it answers. -->
<fieldset>
  <legend>How should we contact you?</legend>

  <div class="field">
    <input type="checkbox" id="contact-email" name="contact" value="email">
    <label for="contact-email">Email</label>
  </div>
  <div class="field">
    <input type="checkbox" id="contact-phone" name="contact" value="phone">
    <label for="contact-phone">Phone</label>
  </div>
  <div class="field">
    <input type="checkbox" id="contact-post" name="contact" value="post">
    <label for="contact-post">Post</label>
  </div>
</fieldset>

<!-- Tri-state "select all". aria-checked="mixed" comes from the .indeterminate
     PROPERTY set in JS — it cannot be written in HTML. -->
<fieldset>
  <legend>Permissions</legend>

  <div class="field">
    <input type="checkbox" id="perm-all">
    <label for="perm-all">All permissions</label>
  </div>

  <div class="field"><input type="checkbox" id="perm-read" data-perm><label for="perm-read">Read</label></div>
  <div class="field"><input type="checkbox" id="perm-write" data-perm><label for="perm-write">Write</label></div>
  <div class="field"><input type="checkbox" id="perm-delete" data-perm><label for="perm-delete">Delete</label></div>
</fieldset>
```

```css
/* Style the REAL input. appearance: none strips the OS rendering and leaves a
   fully styleable element that is still a checkbox to the browser and to AT. */
input[type="checkbox"] {
  appearance: none;
  inline-size: 1.25rem;
  block-size: 1.25rem;
  border: 2px solid #767676;  /* ≥3:1 against the page (RAWeb 3.3) */
  border-radius: 3px;
  display: inline-grid;
  place-content: center;
}

input[type="checkbox"]::before {
  content: "";
  inline-size: 0.65rem;
  block-size: 0.65rem;
  transform: scale(0);
  background: #fff;
  clip-path: polygon(14% 44%, 0 65%, 50% 100%, 100% 16%, 80% 0%, 43% 62%);
}

input[type="checkbox"]:checked {
  background: #0056b3;
  border-color: #0056b3;
}
input[type="checkbox"]:checked::before { transform: scale(1); }

/* :indeterminate is a real CSS pseudo-class — it matches when the JS property
   is set. A dash, not a tick: the shape differs, not just the colour (RAWeb 3.1). */
input[type="checkbox"]:indeterminate {
  background: #0056b3;
  border-color: #0056b3;
}
input[type="checkbox"]:indeterminate::before {
  transform: scale(1);
  clip-path: polygon(10% 40%, 90% 40%, 90% 60%, 10% 60%);
}

input[type="checkbox"]:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

/* Forced colors drops background-color — keep the tick visible via the system
   palette, or the checked state disappears in High Contrast Mode. */
@media (forced-colors: active) {
  input[type="checkbox"]:checked::before { background: Highlight; }
}
```

```js
const selectAll = document.getElementById('perm-all');
const perms = [...document.querySelectorAll('[data-perm]')];

function syncSelectAll() {
  const checkedCount = perms.filter((p) => p.checked).length;

  // indeterminate is a PROPERTY. There is no HTML attribute for it, and
  // setAttribute('indeterminate', …) does nothing at all.
  selectAll.indeterminate = checkedCount > 0 && checkedCount < perms.length;
  selectAll.checked = checkedCount === perms.length;
  // We never touch aria-checked — the browser derives it, including 'mixed'.
}

selectAll.addEventListener('change', () => {
  // Clicking a mixed checkbox checks all: the user's intent is "give me all".
  for (const perm of perms) perm.checked = selectAll.checked;
  selectAll.indeterminate = false;
});

for (const perm of perms) perm.addEventListener('change', syncSelectAll);
syncSelectAll();
```

### Don't

```html
<!-- DON'T: a group with no legend (RAWeb 11.5).
     → Announced "Email, checkbox" / "Phone, checkbox". The question they answer
       is never spoken. Sighted users read the nearby heading; nobody else does. -->
<p>How should we contact you?</p>
<input type="checkbox" id="c1"><label for="c1">Email</label>
<input type="checkbox" id="c2"><label for="c2">Phone</label>

<!-- DON'T: a fieldset with no legend.
     → A fieldset alone draws a border; the legend is what names the group.
       An unnamed fieldset is announced as an unnamed group — noise. -->
<fieldset>
  <input type="checkbox" id="c1"><label for="c1">Email</label>
</fieldset>

<!-- DON'T: a div checkbox.
     → Not focusable, no Space, no state, no form value. -->
<div role="checkbox" aria-checked="false" onclick="toggle()">Email</div>

<!-- DON'T: the hidden-input + fake-span pattern.
     → The input is off-screen; the span is what people see. Focus goes to the
       invisible input, so :focus-visible styles nothing the user can see.
       Use appearance: none on the real input instead. -->
<input type="checkbox" id="c1" class="sr-only">
<label for="c1"><span class="fake-checkbox"></span> Email</label>

<!-- DON'T: aria-checked on a native checkbox.
     → The browser already derives it from .checked. Now there are two sources
       of truth and they will diverge. -->
<input type="checkbox" aria-checked="false" id="c1">

<!-- DON'T: an indeterminate ATTRIBUTE.
     → No such thing in HTML. This is inert; the checkbox renders unchecked. -->
<input type="checkbox" indeterminate id="perm-all">

<!-- DON'T: a label that is not associated.
     → Clicking the text does not toggle, and nothing is announced as the name.
       The `for` must match the input's id — not its name. -->
<input type="checkbox" name="terms">
<label>I accept the terms</label>
```

```js
// DON'T: setAttribute for indeterminate.
//     → Silently does nothing. It is a property.
selectAll.setAttribute('indeterminate', 'true');

// DON'T: manage aria-checked="mixed" by hand on a native input.
//     → Fights the browser's own mapping. Set .indeterminate and stop.
selectAll.setAttribute('aria-checked', 'mixed');
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef } from 'react';

export function TriStateCheckbox({ label, checked, indeterminate, onChange }) {
  const ref = useRef(null);
  const id = useId();

  // `indeterminate` is a DOM property with no JSX attribute — React cannot set
  // it declaratively. A ref + effect is the only way.
  useEffect(() => {
    if (ref.current) ref.current.indeterminate = indeterminate;
  }, [indeterminate]);

  return (
    <div className="field">
      <input
        ref={ref}
        type="checkbox"
        id={id}
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
      />
      <label htmlFor={id}>{label}</label>
    </div>
  );
}
```

```jsx
export function PermissionsGroup() {
  const [perms, setPerms] = useState({ read: false, write: false, delete: false });
  const values = Object.values(perms);
  const allChecked = values.every(Boolean);
  const someChecked = values.some(Boolean);

  return (
    // fieldset + legend — the group's question (RAWeb 11.5).
    <fieldset>
      <legend>Permissions</legend>

      <TriStateCheckbox
        label="All permissions"
        checked={allChecked}
        indeterminate={someChecked && !allChecked}
        onChange={(checked) =>
          setPerms({ read: checked, write: checked, delete: checked })
        }
      />

      {Object.keys(perms).map((key) => (
        <Checkbox
          key={key}
          label={key}
          checked={perms[key]}
          onChange={(checked) => setPerms((p) => ({ ...p, [key]: checked }))}
        />
      ))}
    </fieldset>
  );
}
```

### Don't

```jsx
// DON'T: indeterminate as a JSX prop.
//     → React passes unknown props through to the DOM as ATTRIBUTES. There is
//       no indeterminate attribute, so this does nothing. Ref + effect.
<input type="checkbox" indeterminate={someChecked && !allChecked} />

// DON'T: checked without onChange.
//     → React warns, and the input becomes read-only: clicking does nothing.
//       Use defaultChecked for uncontrolled, or supply onChange.
<input type="checkbox" checked={isChecked} />

// DON'T: a group with no fieldset (RAWeb 11.5).
//     → A styled <div> heading is not a group name.
<div className="group-title">Permissions</div>
{options.map((o) => <Checkbox key={o} label={o} />)}

// DON'T: div + role="checkbox" because the design "needs" custom styling.
//     → appearance: none does the same styling on the real input.
<div role="checkbox" aria-checked={isChecked} tabIndex={0} onClick={toggle} />
```

---

## Angular

### Do

```ts
import { Component, ElementRef, effect, input, model, viewChild } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-checkbox',
  template: `
    <div class="field">
      <input #input type="checkbox" [id]="id" [checked]="checked()" (change)="onChange($event)">
      <label [for]="id">{{ label() }}</label>
    </div>
  `,
})
export class CheckboxComponent {
  readonly label = input.required<string>();
  readonly checked = model(false);
  readonly indeterminate = input(false);

  protected readonly id = `checkbox-${uid++}`;
  private readonly input = viewChild.required<ElementRef<HTMLInputElement>>('input');

  constructor() {
    // Property, not attribute — so no [attr.indeterminate] binding exists.
    effect(() => {
      this.input().nativeElement.indeterminate = this.indeterminate();
    });
  }

  protected onChange(event: Event): void {
    this.checked.set((event.target as HTMLInputElement).checked);
  }
}
```

```html
<fieldset>
  <legend>Permissions</legend>
  <app-checkbox label="All permissions" [(checked)]="allChecked" [indeterminate]="someButNotAll()" />
  <app-checkbox label="Read" [(checked)]="perms.read" />
</fieldset>
```

### Don't

```html
<!-- DON'T: [attr.indeterminate] — no such attribute. Silently inert. -->
<input type="checkbox" [attr.indeterminate]="someButNotAll()">

<!-- DON'T: [attr.checked] — sets the DEFAULT-checked attribute, not the live
     property. The checkbox stops reflecting your state after first interaction. -->
<input type="checkbox" [attr.checked]="isChecked()">
```

---

## Web Component

### Do

**Prefer not to.** A checkbox in a shadow root does not participate in the outer
form, and `<label for>` cannot cross the boundary. If you need a design-system
checkbox, it must be form-associated:

```js
class A11yCheckbox extends HTMLElement {
  // Without this, the checkbox submits nothing — the shadow boundary cuts it
  // off from the surrounding <form>.
  static formAssociated = true;
  #internals;
  #input;

  constructor() {
    super();
    this.#internals = this.attachInternals();
    const root = this.attachShadow({ mode: 'open', delegatesFocus: true });
    root.innerHTML = `<input type="checkbox" part="input"><slot></slot>`;
    this.#input = root.querySelector('input');

    this.#input.addEventListener('change', () => {
      // Push the value back out to the form the host lives in.
      this.#internals.setFormValue(this.#input.checked ? this.value ?? 'on' : null);
      this.dispatchEvent(new Event('change', { bubbles: true }));
    });
  }

  get checked() { return this.#input.checked; }
  set checked(v) { this.#input.checked = Boolean(v); }
  get indeterminate() { return this.#input.indeterminate; }
  set indeterminate(v) { this.#input.indeterminate = Boolean(v); }
}

customElements.define('a11y-checkbox', A11yCheckbox);
```

### Don't

```js
// DON'T: a shadow checkbox with no formAssociated.
//     → Renders and toggles perfectly, submits absolutely nothing. The bug
//       surfaces in production, not in the component's own tests.
root.innerHTML = `<input type="checkbox">`;

// DON'T: expect <label for> to reach into the shadow root.
//     → `for` is an IDREF. It cannot cross the boundary — the label associates
//       with nothing and clicking it does not toggle.
//   <label for="my-checkbox">Email</label>
//   <a11y-checkbox id="my-checkbox"></a11y-checkbox>   ← label does nothing
```

---

## Verify

- **Keyboard-only:** Tab to it, **Space** toggles. (Enter must *not* — Enter
  submits the form. If Enter toggles, it isn't a real checkbox.) Focus ring
  visible on the thing you can actually see.
- **The RAWeb 11.5 check:** with a screen reader, focus a checkbox in a group.
  You must hear the **legend** as well as the label — "How should we contact you?
  Email, checkbox, not checked". If you only hear "Email, checkbox", the group
  has no legend.
- **Click the label text.** It must toggle. If not, `for`/`id` don't match.
- **Tri-state:** with some but not all children checked, the parent must announce
  "**mixed**" (or "partially checked"). If it says "not checked", you set an
  attribute instead of the property.
- **Automated:** axe catches unlabelled inputs reliably. It does **not** catch a
  missing `fieldset`/`legend` — a group of unrelated checkboxes and a group
  missing its legend look identical to a scanner. RAWeb 11.5 is a manual check.
