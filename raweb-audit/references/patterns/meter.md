# Meter — code examples

**Contract (ARIA, states, keyboard, RAWeb criteria):** run
`scripts/raweb-component-lookup.sh show meter`

> **No framework sections.** `<meter>` is static markup. If the user can *change*
> the value, it's a slider, not a meter: `show slider`.

---

## Universal rules

- **`<meter>` vs `<progress>` are not interchangeable.** `<meter>` is a
  *measurement within a known range* (disk usage, a score, fuel). `<progress>` is
  *how far a task has got*. Using a meter for a file upload is wrong.
- **Neither is focusable, and neither is a form control.** Don't add `tabindex`.
- **Always render the value as visible text.** Screen reader support for
  `role="meter"` has been historically patchy — do not rely on the element alone
  to convey the number. This is the rule that matters most here. (RAWeb 7.1)
- **A colour-coded gauge is colour-only information.** Green/amber/red with no
  text fails RAWeb 3.1 outright.
- **`aria-valuenow`/`min`/`max` are only for div-built meters.** `<meter>`
  derives them from `value`/`min`/`max`.
- **`<progress>` with no `value` is indeterminate** — a spinner. Omitting it by
  accident is a real bug.

---

## Vanilla

### Do

```html
<!-- A measurement in a known range. The label is associated, and the value is
     TEXT — the element is the visual, the text is the information. -->
<div class="meter-row">
  <label for="disk">Disk usage</label>
  <meter id="disk" min="0" max="100" low="60" high="85" optimum="0" value="72">
    72%
  </meter>
  <!-- Not optional. role="meter" support is uneven; this is what guarantees
       the value is available to everyone (RAWeb 7.1, 3.1). -->
  <span class="meter-value">72% of 500 GB used</span>
</div>

<!-- Task completion → <progress>, not <meter>. -->
<div class="progress-row">
  <label for="upload">Uploading report.pdf</label>
  <progress id="upload" max="100" value="43">43%</progress>
  <span>43% complete</span>
</div>

<!-- Indeterminate: no value attribute. Deliberate here. -->
<label for="loading">Loading results</label>
<progress id="loading"></progress>
<span>Loading…</span>
```

The text between `<meter>` and `</meter>` is **fallback for browsers that don't
support the element** — it is *not* an accessible name and it is not announced by
supporting browsers. That's why the separate `<span>` exists.

### Do — when you must build it from divs

```html
<!-- Only if <meter> cannot be styled to the design. You now owe every attribute
     the native element gave you. -->
<div class="meter-row">
  <span id="score-label">Accessibility score</span>
  <div
    role="meter"
    aria-labelledby="score-label"
    aria-valuenow="87"
    aria-valuemin="0"
    aria-valuemax="100"
    aria-valuetext="87 out of 100, good"
  >
    <div class="meter__fill" style="inline-size: 87%"></div>
  </div>
  <span>87 / 100 — good</span>
</div>
```

`aria-valuetext` is worth it whenever the bare number isn't self-explanatory —
"87" alone doesn't say out of what, or whether that's good.

```css
meter {
  inline-size: 12rem;
  block-size: 1rem;
}

/* <meter> internals are styled with vendor pseudo-elements; support varies.
   This is a legitimate reason to build from divs — but keep the text value. */
meter::-webkit-meter-optimum-value { background: #1a7f37; }
meter::-webkit-meter-suboptimum-value { background: #9a6700; }
meter::-webkit-meter-even-less-good-value { background: #b3261e; }

.meter__fill {
  block-size: 1rem;
  background: #0056b3;
}

/* Forced colors drops these backgrounds entirely — another reason the text
   value is what actually carries the information. */
@media (forced-colors: active) {
  .meter__fill { forced-color-adjust: none; background: Highlight; }
}
```

### Don't

```html
<!-- DON'T: a gauge with no text value.
     → The number exists only as a coloured bar length. Fails RAWeb 3.1
       (colour/visual alone), and given uneven role="meter" support, many users
       get nothing at all (RAWeb 7.1). -->
<meter min="0" max="100" value="72"></meter>

<!-- DON'T: colour as the only status signal.
     → Red vs green is the entire message. Invisible to anyone who cannot
       distinguish them, and gone in forced-colors mode (RAWeb 3.1). -->
<div class="gauge gauge--danger"></div>

<!-- DON'T: <meter> for task progress.
     → Wrong semantics: a meter is a measurement in a range, not completion.
       Screen readers announce them differently, and users rely on that. -->
<meter min="0" max="100" value="43">Uploading</meter>

<!-- DON'T: <progress> for a static measurement.
     → Announces as a progress bar, implying something is in flight. Disk usage
       is not progressing anywhere. -->
<progress max="100" value="72">Disk usage</progress>

<!-- DON'T: tabindex on a meter.
     → It is not interactive. A Tab stop that does nothing is noise. If the user
       CAN change it, it is a slider — different pattern entirely. -->
<meter tabindex="0" min="0" max="100" value="72"></meter>

<!-- DON'T: aria-valuenow on a native <meter>.
     → Redundant, and now two sources of truth. The browser derives it from
       value/min/max. -->
<meter min="0" max="100" value="72" aria-valuenow="72"></meter>

<!-- DON'T: rely on the fallback text as the accessible name.
     → The text between the tags is only shown by browsers that do NOT support
       <meter>. Supporting browsers never announce it. This meter is unnamed. -->
<meter min="0" max="100" value="72">Disk usage: 72%</meter>

<!-- DON'T: role="meter" with no aria-valuenow.
     → The role promises a value and there is none. Announced as an empty meter. -->
<div role="meter" aria-labelledby="score-label">
  <div class="meter__fill" style="inline-size: 87%"></div>
</div>

<!-- DON'T: forget value on a determinate <progress>.
     → No value = INDETERMINATE. It renders as an endless spinner and announces
       "busy", even though you know it is at 43%. A real bug when the value is
       set asynchronously and arrives late. -->
<progress max="100"></progress>

<!-- DON'T: an unlabelled meter.
     → "meter, 72" — 72 of what? -->
<meter min="0" max="100" value="72"></meter>
```

---

## Verify

- **The text-value check — the important one.** Turn the meter to greyscale, or
  just delete the element from the DOM. Is the value still readable as text? If
  not, the information exists only as a coloured bar, and it fails both
  RAWeb 3.1 and (given patchy `role="meter"` support) 7.1 for a real slice of
  users.
- **Semantics check:** is it *progressing toward completion* (`<progress>`) or a
  *measurement in a range* (`<meter>`)? Getting this backwards is the most common
  bug here.
- **Keyboard:** it must **not** be a Tab stop. If it is, either remove the
  `tabindex` or admit it's a slider.
- **Screen reader:** expect "«label», meter, 72". If you hear nothing, it's
  unnamed — remember the fallback text between the tags is *not* a name.
- **Forced colors:** turn on Windows High Contrast Mode. A colour-only gauge
  goes blank. The text value survives.
- **Automated:** axe catches an unlabelled `<meter>` and `role="meter"` with no
  `aria-valuenow`. It does **not** catch meter/progress confusion, a
  colour-only gauge, or a missing text value.
