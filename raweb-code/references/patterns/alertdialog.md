# Alert Dialog — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show alertdialog`

> **An alertdialog is a [`dialog-modal`](dialog-modal.md) with exactly two
> differences.** Read that file first — every rule there applies here unchanged
> (`<dialog>` + `.showModal()`, never the `open` attribute, focus trap, focus
> restoration). This file covers only the differences.

---

## The only two differences

| | `dialog` | `alertdialog` |
|---|---|---|
| `role` | `dialog` (implicit on `<dialog>`) | **`alertdialog`** (must be set explicitly) |
| `aria-describedby` | optional | **required** |

That's it. Everything else is identical.

**Why they matter:** `role="alertdialog"` tells the screen reader this is an
urgent interruption, so on open it announces the **description immediately** —
like a live region — instead of waiting for the user to explore. That's why
`aria-describedby` is required: without it, the user hears the title and learns
nothing about what they're being asked to confirm. (RAWeb 7.5)

---

## When to use it

| Situation | Use |
|---|---|
| Confirm a destructive action ("Delete this account?") | **alertdialog** |
| An operation failed and needs a decision ("Retry or cancel?") | **alertdialog** |
| A form in a modal | [`dialog-modal`](dialog-modal.md) |
| A message with no decision to make | [`alert`](alert.md) — a live region, which doesn't steal focus |

That last row is the common mistake. An alertdialog **takes focus and blocks the
page**. If the user has no decision to make, that's an interruption for nothing —
announce it in a live region instead.

---

## Vanilla

### Do

```html
<button type="button" id="delete-account-button">Delete account</button>

<!-- role="alertdialog" must be explicit: <dialog> implies role="dialog", and
     showModal() does not upgrade it. -->
<dialog id="delete-confirm"
        role="alertdialog"
        aria-labelledby="delete-confirm-title"
        aria-describedby="delete-confirm-desc">
  <div class="dialog__box">
    <h2 id="delete-confirm-title">Delete your account?</h2>

    <!-- REQUIRED. Announced immediately on open — this is the sentence the
         user's decision rests on. -->
    <p id="delete-confirm-desc">
      This permanently deletes your account and all 47 projects.
      This cannot be undone.
    </p>

    <form method="dialog" class="dialog__actions">
      <!-- autofocus on the SAFE action. An Enter keypress still in flight from
           the previous screen must not delete the account. -->
      <button type="submit" value="cancel" autofocus>Cancel</button>
      <button type="submit" value="delete" class="button--destructive">
        Delete account
      </button>
    </form>
  </div>
</dialog>
```

```js
const dialog = document.getElementById('delete-confirm');

document.getElementById('delete-account-button').addEventListener('click', () => {
  dialog.showModal(); // never dialog.open = true — see dialog-modal.md
});

dialog.addEventListener('close', () => {
  if (dialog.returnValue === 'delete') deleteAccount();
  // Focus returns to the trigger automatically — showModal() handles it.
});
```

### Don't

```html
<!-- DON'T: role="dialog" for a destructive confirmation.
     → The description is not announced on open. The user hears "Delete your
       account?, dialog" and must go hunting for what it actually does. -->
<dialog role="dialog" aria-labelledby="title">…</dialog>

<!-- DON'T: alertdialog with no aria-describedby.
     → The role promises an urgent message and there is none to announce. The
       user hears only the title. This is what makes it REQUIRED here. -->
<dialog role="alertdialog" aria-labelledby="delete-confirm-title">
  <h2 id="delete-confirm-title">Delete your account?</h2>
  <p>This permanently deletes all 47 projects.</p>  <!-- never announced -->
</dialog>

<!-- DON'T: autofocus the destructive button.
     → A user holding Enter, or pressing it as the dialog appears, deletes the
       account. Focus the least destructive action. -->
<button type="submit" value="delete" autofocus>Delete account</button>

<!-- DON'T: alertdialog for a message with no decision.
     → Steals focus and blocks the page to say something the user cannot act on.
       That is a live region (patterns/alert.md). -->
<dialog role="alertdialog" aria-describedby="msg">
  <p id="msg">Your changes were saved.</p>
  <button>OK</button>
</dialog>

<!-- DON'T: aria-describedby pointing at the whole dialog body.
     → Announces the title, the buttons, and every word of markup on open.
       Point it at the ONE sentence carrying the decision. -->
<dialog role="alertdialog" aria-describedby="dialog-body">
  <div id="dialog-body">…everything…</div>
</dialog>
```

---

## React

### Do

```jsx
import { useEffect, useId, useRef } from 'react';

export function ConfirmDialog({ open, title, description, confirmLabel, onConfirm, onCancel }) {
  const dialogRef = useRef(null);
  const id = useId();

  useEffect(() => {
    const el = dialogRef.current;
    if (!el) return;
    if (open && !el.open) el.showModal();   // NOT the open attribute
    if (!open && el.open) el.close();
  }, [open]);

  useEffect(() => {
    const el = dialogRef.current;
    if (!el) return;
    const handleClose = () => {
      el.returnValue === 'confirm' ? onConfirm() : onCancel();
    };
    el.addEventListener('close', handleClose);
    return () => el.removeEventListener('close', handleClose);
  }, [onConfirm, onCancel]);

  return (
    <dialog
      ref={dialogRef}
      role="alertdialog"
      aria-labelledby={`${id}-title`}
      aria-describedby={`${id}-desc`}
    >
      <div className="dialog__box">
        <h2 id={`${id}-title`}>{title}</h2>
        <p id={`${id}-desc`}>{description}</p>
        <form method="dialog" className="dialog__actions">
          <button type="submit" value="cancel" autoFocus>Cancel</button>
          <button type="submit" value="confirm" className="button--destructive">
            {confirmLabel}
          </button>
        </form>
      </div>
    </dialog>
  );
}
```

### Don't

```jsx
// DON'T: <dialog open={isOpen} role="alertdialog"> — the open attribute makes it
//        non-modal. Same trap as dialog-modal.md; the role changes nothing.
<dialog open={isOpen} role="alertdialog">…</dialog>

// DON'T: a generic description that says nothing.
//     → Announced immediately on open, so it is the user's ONE chance to learn
//       the stakes. "Are you sure?" wastes it. Say what will happen.
<p id={descId}>Are you sure?</p>
```

---

## Angular

### Do

```ts
import { Component, ElementRef, effect, input, output, viewChild } from '@angular/core';

let uid = 0;

@Component({
  selector: 'app-confirm-dialog',
  template: `
    <dialog
      #dialogEl
      role="alertdialog"
      [attr.aria-labelledby]="id + '-title'"
      [attr.aria-describedby]="id + '-desc'"
      (close)="onClose()"
    >
      <div class="dialog__box">
        <h2 [id]="id + '-title'">{{ title() }}</h2>
        <p [id]="id + '-desc'">{{ description() }}</p>
        <form method="dialog" class="dialog__actions">
          <button type="submit" value="cancel" autofocus>Cancel</button>
          <button type="submit" value="confirm" class="button--destructive">
            {{ confirmLabel() }}
          </button>
        </form>
      </div>
    </dialog>
  `,
})
export class ConfirmDialogComponent {
  readonly open = input.required<boolean>();
  readonly title = input.required<string>();
  readonly description = input.required<string>();
  readonly confirmLabel = input('Confirm');
  readonly confirmed = output<void>();
  readonly cancelled = output<void>();

  protected readonly id = `confirm-${uid++}`;
  private readonly dialogEl = viewChild.required<ElementRef<HTMLDialogElement>>('dialogEl');

  constructor() {
    effect(() => {
      const el = this.dialogEl().nativeElement;
      if (this.open() && !el.open) el.showModal();
      if (!this.open() && el.open) el.close();
    });
  }

  protected onClose(): void {
    this.dialogEl().nativeElement.returnValue === 'confirm'
      ? this.confirmed.emit()
      : this.cancelled.emit();
  }
}
```

**Or use the CDK.** `@angular/cdk/dialog` accepts a `role: 'alertdialog'` option
and handles the rest.

### Don't

```html
<!-- DON'T: [open]="isOpen" — non-modal, exactly as in dialog-modal.md. -->
<dialog [open]="isOpen()" role="alertdialog">…</dialog>
```

---

## Web Component

See [`dialog-modal.md`](dialog-modal.md) — the component is identical. Only two
things change:

```js
// role="alertdialog" instead of the implicit role="dialog", and a REQUIRED
// aria-describedby. Both IDREF ends stay inside the same shadow root.
template.innerHTML = `
  <dialog role="alertdialog" aria-labelledby="dialog-title" aria-describedby="dialog-desc">
    <div class="box">
      <h2 id="dialog-title"><slot name="title"></slot></h2>
      <p id="dialog-desc"><slot name="description"></slot></p>
      <slot name="actions"></slot>
    </div>
  </dialog>
`;
```

The same shadow-DOM rule applies: `aria-labelledby` and `aria-describedby` are
IDREFs and cannot cross the boundary — which is why both `id`s live in the shadow
root and only the *text* is slotted in.

---

## Verify

- **Everything in [`dialog-modal.md`](dialog-modal.md)'s Verify section still
  applies.** Run it first.
- **The alertdialog-specific check:** open it with a screen reader running. The
  **description must be announced immediately**, without you navigating to it. If
  you hear only the title, `aria-describedby` is missing or points at the wrong
  element.
- **The autofocus check:** open it and press **Enter** straight away. Nothing
  destructive may happen. If the account is gone, you focused the wrong button.
- **The judgement check:** does the user actually have a decision to make? If not,
  this shouldn't be an alertdialog at all.
- **Automated:** axe catches `role="alertdialog"` with no accessible name. It does
  **not** catch a missing `aria-describedby`, a destructive `autofocus`, or an
  alertdialog used where a live region belongs.
