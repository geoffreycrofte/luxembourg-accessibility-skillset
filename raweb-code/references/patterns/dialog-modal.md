# Dialog (Modal) — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show dialog-modal`

**Read this whole file** when building a modal. Use
`code dialog-modal <framework>` only when you already know the universal rules
and just want the snippet.

---

## Universal rules

- **Use the native `<dialog>` element and open it with `.showModal()`.** Everything
  below comes free and correct, in every browser, with no library:
  focus moves into the dialog, Tab/Shift+Tab are trapped, <kbd>Escape</kbd> closes
  it, the rest of the page becomes inert, it renders in the top layer (no
  `z-index` wars), and **focus returns to the element that opened it** on close.
  (RAWeb 7.3, 12.8, 12.9)
- **Never open a dialog with the `open` attribute.** `<dialog open>` and
  `dialog.open = true` produce a **non-modal** dialog: no focus trap, no inert
  background, no top layer, Escape does nothing. This is the single most common
  modal bug, and it is silent — it looks right on screen. (RAWeb 7.3, 12.9)
- **The dialog needs an accessible name**, via `aria-labelledby` pointing at the
  visible title. Without it a screen reader announces "dialog" and nothing else.
  (RAWeb 7.1)
- **A modal must only ever open from a deliberate user action.** Auto-opening on
  page load, on a timer, or on focus is a change of context the user did not
  request. (RAWeb 7.4)
- **Escape and a visible close button are what make the Tab loop legal.** Trapping
  Tab is correct for a modal; trapping the user is not. RAWeb 12.9 is satisfied
  because the keyboard user can always leave. (RAWeb 12.9)
- **Use `inert`, never `aria-hidden="true"`, to neutralise the background.**
  `aria-hidden` hides the semantics but leaves the elements tabbable, so a
  keyboard user tabs into content a screen reader insists is not there.
  `showModal()` already handles this — you only need `inert` if you build from a
  `<div>`. (RAWeb 7.3)
- **Focus must stay visible against the backdrop.** A dim overlay plus a subtle
  focus ring often drops below the required contrast. (RAWeb 10.7)

---

## Vanilla

### Do

```html
<button type="button" id="edit-profile-open">Edit profile</button>

<!-- No role="dialog", no aria-modal: both are implicit on <dialog> + showModal().
     Adding them by hand is redundant and can confuse some screen readers. -->
<dialog id="edit-profile" aria-labelledby="edit-profile-title">
  <div class="dialog__box">
    <h2 id="edit-profile-title">Edit your profile</h2>

    <!-- method="dialog" closes the dialog on submit with no navigation,
         and sets dialog.returnValue to the pressed button's value. -->
    <form method="dialog" id="edit-profile-form">
      <div>
        <label for="display-name">Display name</label>
        <input type="text" id="display-name" name="displayName" autocomplete="nickname" required>
      </div>

      <div class="dialog__actions">
        <!-- formnovalidate: Cancel must never be blocked by field validation. -->
        <button type="submit" value="cancel" formnovalidate>Cancel</button>
        <button type="submit" value="save">Save</button>
      </div>
    </form>

    <button type="submit" form="edit-profile-form" value="cancel"
            formnovalidate class="dialog__close">
      <svg aria-hidden="true" focusable="false" width="16" height="16"><use href="#icon-close"/></svg>
      <span class="sr-only">Close</span>
    </button>
  </div>
</dialog>
```

```css
/* Padding on <dialog> itself would swallow backdrop clicks (the padding area
   still resolves to event.target === dialog). Pad the inner box instead. */
dialog {
  padding: 0;
  border: none;
  max-width: min(90vw, 40rem);
}

.dialog__box {
  padding: 1.5rem;
}

dialog::backdrop {
  background: rgb(0 0 0 / 0.5);
}

/* RAWeb 10.7 — the ring must clear 3:1 against the dialog surface, not just
   against the page behind the backdrop. */
dialog :focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  dialog,
  dialog::backdrop {
    animation: none;
    transition: none;
  }
}
```

```js
const dialog = document.getElementById('edit-profile');
const openButton = document.getElementById('edit-profile-open');

// RAWeb 7.4 — user-initiated only.
openButton.addEventListener('click', () => {
  dialog.showModal(); // NOT dialog.open = true
});

// Click-outside-to-close. The backdrop is painted by the dialog itself, so a
// click on it resolves to event.target === dialog. Pointer-only affordance —
// legal because Escape is the keyboard equivalent (RAWeb 7.3).
dialog.addEventListener('click', (event) => {
  if (event.target === dialog) dialog.close('dismiss');
});

// Escape fires 'cancel' then 'close'. Handle 'close' for both paths.
dialog.addEventListener('close', () => {
  if (dialog.returnValue === 'save') {
    // persist…
  }
  // Do NOT restore focus here — showModal() already returns focus to openButton.
});
```

**Not written above, on purpose:** no focus-trap loop, no `keydown` Escape
handler, no `previouslyFocused` variable, no `z-index`, no `aria-hidden` toggling
on `<body>`. `showModal()` does all of it. If you find yourself writing that code,
you opened the dialog wrong.

### Don't

```html
<!-- DON'T: the open attribute renders a NON-modal dialog.
     → Tab walks straight out into the page behind, Escape does nothing,
       and the background is never inert. Looks identical on screen. -->
<dialog open>…</dialog>

<!-- DON'T: div soup.
     → Screen reader announces nothing; it is not a dialog, has no name,
       and the user has no idea a layer opened. -->
<div class="modal">
  <div class="modal-header">Edit your profile</div>
</div>

<!-- DON'T: role without a name.
     → Announced as a bare "dialog". -->
<div role="dialog" aria-modal="true">…</div>

<!-- DON'T: aria-hidden on a background that is still tabbable.
     → Keyboard focus lands on links a screen reader claims don't exist.
       Use inert. This is axe's `aria-hidden-focus` violation. -->
<div id="app" aria-hidden="true">…</div>

<!-- DON'T: an icon-only close button with no accessible name.
     → Announced as "button". -->
<button class="dialog__close">×</button>

<!-- DON'T: autofocus the destructive action.
     → An Enter keypress meant for the previous page deletes the account. -->
<button value="delete" autofocus>Delete account</button>
```

```js
// DON'T: showModal() on an already-open dialog throws InvalidStateError
//     → an uncaught exception kills the rest of your click handler.
dialog.showModal();
dialog.showModal();

// DO: guard it.
if (!dialog.open) dialog.showModal();

// DON'T: open a modal nobody asked for (RAWeb 7.4).
//     → yanks focus mid-task; a screen reader user loses their place entirely.
setTimeout(() => newsletterDialog.showModal(), 5000);
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef } from 'react';

export function EditProfileDialog({ open, onClose }) {
  const dialogRef = useRef(null);
  const titleId = useId(); // stable across SSR/hydration; never hand-roll ids

  // Drive the imperative API from the declarative prop.
  useEffect(() => {
    const el = dialogRef.current;
    if (!el) return;
    if (open && !el.open) el.showModal();   // guard: showModal() throws if already open
    if (!open && el.open) el.close();
  }, [open]);

  // The native 'close' event does not bubble, so it is not reliably reachable
  // through React's synthetic event system across versions. A ref listener is
  // unambiguous — and it also catches Escape, which never goes through onClick.
  useEffect(() => {
    const el = dialogRef.current;
    if (!el) return;
    const handleClose = () => onClose(el.returnValue);
    el.addEventListener('close', handleClose);
    return () => el.removeEventListener('close', handleClose);
  }, [onClose]);

  return (
    <dialog ref={dialogRef} aria-labelledby={titleId}>
      <div className="dialog__box">
        <h2 id={titleId}>Edit your profile</h2>
        <form method="dialog">
          <button type="submit" value="cancel" formNoValidate>Cancel</button>
          <button type="submit" value="save">Save</button>
        </form>
      </div>
    </dialog>
  );
}
```

**No portal needed.** `showModal()` promotes the dialog to the top layer, so it
escapes ancestor `overflow: hidden` and stacking contexts on its own — the usual
reason to reach for `createPortal` doesn't apply.

### Don't

```jsx
// DON'T: the `open` prop. This is THE React modal bug.
//     → React sets the open ATTRIBUTE, which renders a non-modal dialog:
//       no focus trap, no inert background, Escape dead. Renders fine, so it
//       ships. You must call showModal() imperatively.
<dialog open={isOpen}>…</dialog>

// DON'T: hand-rolled focus restore.
//     → Fights the browser, which already restores focus on close. The usual
//       result is focus landing on <body>, dumping the user at the page top.
useEffect(() => {
  const previous = document.activeElement;
  return () => previous?.focus();
}, []);

// DON'T: conditional render as the only close path.
//     → Unmounting an open dialog skips 'close' entirely: focus is never
//       restored and lands on <body>. Close it, then unmount.
{isOpen && <dialog ref={ref}>…</dialog>}

// DON'T: hardcoded ids in a component rendered more than once.
//     → Duplicate ids (RAWeb 8.2); aria-labelledby resolves to the first match,
//       so every dialog claims the same name. Use useId().
<dialog aria-labelledby="dialog-title">
  <h2 id="dialog-title">…</h2>
</dialog>
```

---

## Angular

### Do

```ts
import { Component, ElementRef, effect, input, output, viewChild } from '@angular/core';

@Component({
  selector: 'app-edit-profile-dialog',
  template: `
    <dialog #dialogEl [attr.aria-labelledby]="titleId" (close)="onClose()">
      <div class="dialog__box">
        <h2 [id]="titleId">Edit your profile</h2>
        <form method="dialog">
          <button type="submit" value="cancel" formnovalidate>Cancel</button>
          <button type="submit" value="save">Save</button>
        </form>
      </div>
    </dialog>
  `,
})
export class EditProfileDialogComponent {
  readonly open = input.required<boolean>();
  readonly closed = output<string>();

  private readonly dialogEl = viewChild.required<ElementRef<HTMLDialogElement>>('dialogEl');
  protected readonly titleId = `edit-profile-title-${crypto.randomUUID()}`;

  constructor() {
    effect(() => {
      const el = this.dialogEl().nativeElement;
      if (this.open() && !el.open) el.showModal();
      if (!this.open() && el.open) el.close();
    });
  }

  protected onClose(): void {
    this.closed.emit(this.dialogEl().nativeElement.returnValue);
  }
}
```

**Or use the CDK.** `@angular/cdk/dialog` implements the whole contract
(focus trap, restore, Escape, `aria-modal`, background inertness) and is the
right call if you're already on Material/CDK — don't hand-roll alongside it:

```ts
import { Dialog } from '@angular/cdk/dialog';

private readonly dialog = inject(Dialog);
this.dialog.open(EditProfileComponent, { ariaLabelledBy: 'edit-profile-title' });
```

Note `(close)` above binds the **native** `close` event — Angular's `(event)`
syntax attaches a real `addEventListener`, so unlike React it catches
non-bubbling events without ceremony.

### Don't

```html
<!-- DON'T: property-bind `open`. Same trap as React.
     → Non-modal dialog: no focus trap, no inert background, Escape dead. -->
<dialog [open]="isOpen">…</dialog>
```

```ts
// DON'T: a template-static id on a component used more than once per page.
//     → Duplicate ids (RAWeb 8.2). Derive a unique one per instance.
protected readonly titleId = 'dialog-title';

// DON'T: mix CDK's cdkTrapFocus with a native <dialog> + showModal().
//     → Two focus traps fight; Shift+Tab typically stalls on the first element.
//       Pick one: native dialog, or CDK.
```

---

## Web Component

### Do

```js
// Parsed ONCE for the whole page, then cloned per instance — not re-parsed
// inside every constructor. Note the markup is a static literal: nothing is
// interpolated into it, so there is no injection surface.
const template = document.createElement('template');
template.innerHTML = `
  <!-- Two DIFFERENT mechanisms, deliberately named apart:
       • aria-labelledby="dialog-title" → id="dialog-title". A plain IDREF.
         Both ends live in THIS shadow root, so it resolves. The <h2> is
         permanent — it is never replaced.
       • <slot name="title"> → filled by <span slot="title"> from the light
         DOM. Only the h2's CONTENT is projected, not the h2 itself.
       The name still resolves to the slotted text, because name computation
       walks the flattened tree. IDREFs do not. That asymmetry is the whole
       point: text crosses the boundary, references don't. -->
  <dialog aria-labelledby="dialog-title">
    <div class="box">
      <h2 id="dialog-title"><slot name="title"></slot></h2>
      <slot></slot>
    </div>
  </dialog>
`;

// One stylesheet object shared by every instance, instead of a <style> element
// re-parsed inside each shadow root.
const styles = new CSSStyleSheet();
styles.replaceSync(`
  dialog { padding: 0; border: none; max-width: min(90vw, 40rem); }
  dialog::backdrop { background: rgb(0 0 0 / 0.5); }
  .box { padding: 1.5rem; }
  dialog :focus-visible { outline: 3px solid #0056b3; outline-offset: 2px; }
`);

class A11yDialog extends HTMLElement {
  #dialog;

  constructor() {
    super();
    // Legal in a constructor: we attach and populate our own shadow root, but
    // never read attributes or light-DOM children — that is what the spec bans.
    const root = this.attachShadow({ mode: 'open' });
    root.adoptedStyleSheets = [styles];
    root.append(template.content.cloneNode(true));
    this.#dialog = root.querySelector('dialog');

    // Bound here, not in connectedCallback: the constructor runs exactly once,
    // whereas connectedCallback fires again every time the element is moved in
    // the DOM — which would stack duplicate listeners.
    this.#dialog.addEventListener('click', (e) => {
      if (e.target === this.#dialog) this.#dialog.close('dismiss');
    });
    // Re-emit as a composed event so light-DOM consumers can listen.
    this.#dialog.addEventListener('close', () => {
      this.dispatchEvent(new CustomEvent('dialog-close', {
        detail: this.#dialog.returnValue,
        bubbles: true,
        composed: true,
      }));
    });
  }

  showModal() { if (!this.#dialog.open) this.#dialog.showModal(); }
  close(value) { if (this.#dialog.open) this.#dialog.close(value); }
}

customElements.define('a11y-dialog', A11yDialog);
```

**On `innerHTML` here.** One `template.innerHTML` at module scope is the
conventional idiom, and it is safe *because the string is a static literal*. Two
things to know:

- **It becomes an XSS hole the instant you interpolate** — `` `<h2>${this.getAttribute('label')}</h2>` ``
  is an injection. Pass text through a slot (as above) or assign `.textContent`.
  Never build shadow markup by concatenating attribute values.
- **It throws under Trusted Types.** On a site sending
  `Content-Security-Policy: require-trusted-types-for 'script'`, any `innerHTML`
  assignment raises a TypeError and the component renders nothing — a total
  accessibility failure on exactly the hardened public-sector sites RAWeb
  applies to. If you ship into that environment, put the `<template>` in the
  document and read it with `document.getElementById('…').content`, or mint a
  `trustedTypes.createPolicy()`.

`setHTML()` is **not** the tool for this. It sanitizes *untrusted* HTML; using it
on your own static template pays sanitizer cost to defend against yourself, and
it may strip your own markup. Save it for HTML that arrives from a user or an API.

```html
<a11y-dialog id="edit-profile">
  <span slot="title">Edit your profile</span>
  <p>…</p>
</a11y-dialog>
```

**The shadow DOM rule that governs this pattern:** `aria-labelledby`,
`aria-describedby`, `aria-controls` and `aria-activedescendant` are **IDREF**
attributes, and IDREFs **do not cross a shadow boundary**. Keep both ends of
every ARIA reference inside the same root — as above, where `aria-labelledby`
and `id="dialog-title"` are both in the shadow root, and only the *text* is
slotted in.

Do not confuse the two mechanisms just because both can be called "title":
an **id** is an IDREF target and is blocked by the shadow boundary; a **slot
name** is a projection point and is not. They live in separate namespaces and
never refer to each other.

### Don't

```html
<!-- DON'T: point an ARIA reference across the boundary.
     → The IDREF silently fails to resolve: the dialog has NO accessible name.
       Nothing errors, nothing warns. -->
<h2 id="my-title">Edit your profile</h2>
<a11y-dialog aria-labelledby="my-title">…</a11y-dialog>
```

```js
// DON'T: forward the consumer's aria-labelledby onto the inner dialog.
//     → Same silent failure: the id lives in the light DOM, the attribute now
//       lives in the shadow root, and they cannot see each other. If you must
//       accept a name from outside, copy the TEXT in, or use aria-label.
this.#dialog.setAttribute('aria-labelledby', this.getAttribute('aria-labelledby'));

// DON'T: attachShadow({ mode: 'open', delegatesFocus: true }) on a modal.
//     → delegatesFocus redirects focus to the first focusable element on every
//       host focus, which fights showModal()'s own initial focus and can defeat
//       focus restoration on close.

// DON'T: interpolate anything into shadow markup.
//     → This is a real XSS: a label of `<img src=x onerror=alert(1)>` executes.
//       It also throws outright under a Trusted Types CSP. Slot the text in, or
//       set .textContent — both treat it as text, never as markup.
root.innerHTML = `<h2 id="dialog-title">${this.getAttribute('label')}</h2>`;

// DON'T: re-parse the same markup inside every instance.
//     → Not a correctness bug, but it re-parses identical HTML once per element
//       and re-parses the <style> into every shadow root. Clone a <template> and
//       share one adoptedStyleSheets object instead.
connectedCallback() {
  this.attachShadow({ mode: 'open' }).innerHTML = `<style>…</style><dialog>…</dialog>`;
}
```

---

## Verify

- **Keyboard-only:** Tab to the trigger → <kbd>Enter</kbd> → focus must land
  inside the dialog. Tab past the last control → must wrap to the first, never
  reach the page behind. <kbd>Escape</kbd> → closes, and focus must return to
  the trigger (RAWeb 12.8, 12.9).
- **Screen reader:** on open, expect the accessible name then "dialog". If you
  hear only "dialog", `aria-labelledby` is broken — in a web component that
  almost always means the IDREF crossed a shadow boundary.
- **Automated:** axe catches a missing accessible name and `aria-hidden-focus`.
  It does **not** catch the `open`-attribute bug, a broken focus return, or a
  modal that opens unprompted — those are the three that actually ship. Test by
  hand.
