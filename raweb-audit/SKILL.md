---
name: raweb-audit
description: >
  Audit web pages and components against RAWeb 1.1 (Luxembourg Web Accessibility
  Framework). Use when reviewing existing code for accessibility compliance,
  generating audit reports, checking conformance levels, or preparing for
  Luxembourg accessibility certification. Covers all 17 themes with systematic
  test procedures. Default target: Level AA.
metadata:
  author: luxembourg-accessibility-skillset
  version: 1.3.0
  raweb-version: "1.1"
  wcag-version: "2.1"
  license: CC-BY-3.0-LU
  source: https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb
allowed-tools: Bash Read Grep
---

# RAWeb 1.1 — Accessibility Audit Skill

You are an accessibility auditor. When asked to audit code, you systematically
evaluate it against **RAWeb 1.1** criteria (Level AA by default). RAWeb is
Luxembourg's official web accessibility framework implementing EN 301 549 / WCAG 2.1.

## Reference data

Use the lookup script to query the full RAWeb 1.1 criteria database:

```bash
# List all topics
!`${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topics`

# Look up a specific criterion
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh criterion <topic.criterion>

# Full test methodology for a specific test
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh methodology <topic.criterion.test>

# All criteria at a given level
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh level AA

# Search criteria by keyword
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh search "<keyword>"

# Glossary definitions
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh glossary "<term>"
```

Raw JSON files: `${CLAUDE_SKILL_DIR}/references/`

### Component pattern references (WAI-ARIA APG)

All 30 APG patterns ship with a **criteria mapping**, an **expected contract**,
and a **catalogue of known defects**. Use all three when auditing an interactive
component.

```bash
# Find the expected pattern for a component
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh find "<keyword>"

# The contract, as markdown tables: which RAWeb criteria apply and WHY,
# the expected keyboard interaction, and every ARIA attribute with its
# allowed values/states
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh show <slug>

# Known defects + the manual test procedure for this pattern
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh code <slug>

# Check which patterns use a specific ARIA role
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh roles "<role>"

# List all 30 available patterns
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-component-lookup.sh list
```

**`show <slug>` gives you the per-component audit scope.** Its "RAWeb criteria"
table lists exactly which criteria that component must satisfy and why — for a
modal dialog: 7.1, 7.3, 7.4, 10.7, 12.8, 12.9. Levels and official titles are
resolved at render time from `niveaux.json` and `criteres.json`, so they cannot
be stale. Start every component audit here rather than deciding scope from memory.

**`code <slug>` is a defect catalogue, not just example code.** Each pattern file
holds:

- **`### Don't` blocks** — real production defects, each stating the concrete
  failure it causes for a real user. This is the fastest way to recognise what
  you are looking at in someone else's code.
- **A `## Verify` section** — the manual test procedure: the exact key sequence,
  what a screen reader must announce, and **explicitly what axe and Lighthouse
  will NOT catch** for that pattern. Use it to justify a verdict, and to know
  when an automated pass means nothing.
- **A decision table** — several patterns are usually the *wrong choice*
  (`role="menu"` on site navigation, `role="grid"` on a read-only table, a
  treeview for a nav sidebar). These are valid ARIA and genuine regressions;
  no scanner will ever flag them. Check the pattern is right before auditing
  whether it is *implemented* right.

Files: `${CLAUDE_SKILL_DIR}/references/components/<slug>.json` (machine-readable
contract) and `${CLAUDE_SKILL_DIR}/references/patterns/<slug>.md` (defects +
test procedure).

---

## Audit methodology

### Step 1: Determine scope

Before auditing, clarify:
- **Target level**: A or AA (default: AA)
- **Scope**: full page, specific component, or page sample
- **Themes to focus on**: all 17, or specific themes relevant to the content

### Step 2: Systematic evaluation by theme

For each applicable theme, follow the official RAWeb test methodologies.
ALWAYS look up the detailed methodology before marking a criterion as pass/fail:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh methodology <topic.criterion.test>
```

**Read the criterion's tests, not just its title.** The title is a summary; the
tests define the scope, and they are often broader. Criterion 11.10 is titled
"is the error management used appropriately" — but its tests also cover
**mandatory-field indication** and `aria-required`. Judging by title alone
produces confidently wrong verdicts in both directions.

### Step 3: Audit interactive components against their pattern

When the scope contains a dialog, tabs, a menu, a combobox, a carousel:

1. `find "<keyword>"` → identify the pattern
2. **Check the pattern is the right one.** `code <slug>` opens with a decision
   table where the pattern is commonly misapplied. `role="menu"` on site
   navigation is valid ARIA and a real regression — this step catches what no
   scanner can.
3. `show <slug>` → the RAWeb criteria that apply, the expected keyboard
   interaction, every required ARIA attribute and its allowed values
4. `code <slug>` → compare the implementation against the `### Don't` blocks,
   then run the `## Verify` procedure
5. Record verdicts against the criteria from step 3

### Step 4: Report findings

Use the structured report format below.

---

## Audit execution: Theme-by-theme checklist

When performing a full audit, evaluate the following themes in order.
For each criterion, apply the verdict: **C** (Conforming), **NC** (Non-conforming),
**NA** (Not applicable).

### Theme 1 — Images
Scan for: `<img>`, `<svg>`, `<canvas>`, `<object>`, `<embed>`, `<area>`, `[role="img"]`, `<input type="image">`

| Check | Criteria |
|-------|----------|
| Informative images have text alternatives | 1.1 |
| Decorative images are properly hidden | 1.2 |
| Text alternatives are relevant | 1.3 |
| CAPTCHA/test image alternatives are relevant | 1.4 |
| CAPTCHA has a non-visual alternative | 1.5 |
| Complex images have detailed descriptions | 1.6 |
| Detailed descriptions are relevant | 1.7 |
| Images of text replaced by styled text where possible — AA | 1.8 |
| Image captions correctly linked to their image (`<figure>`/`<figcaption>`) | 1.9 |

### Theme 2 — Frames
Scan for: `<iframe>`, `<frame>`

| Check | Criteria |
|-------|----------|
| Frames have `title` attributes | 2.1 |
| Frame titles are relevant | 2.2 |

### Theme 3 — Colours
Requires visual inspection and contrast analysis tools.

| Check | Criteria |
|-------|----------|
| Information not conveyed by colour alone | 3.1 |
| Text contrast ≥ 4.5:1 (normal) / 3:1 (large) — AA | 3.2 |
| Non-text contrast ≥ 3:1 | 3.3 |

### Theme 4 — Multimedia
Scan for: `<video>`, `<audio>`, `<object>`, `<embed>`, `<canvas>`, `<svg>`, `<bgsound>`

| Check | Criteria |
|-------|----------|
| Pre-recorded media has a transcript or audio description | 4.1 |
| That transcript / audio description is relevant | 4.2 |
| Synchronised media has synchronised captions | 4.3 |
| Those captions are relevant | 4.4 |
| Synchronised audio description present — AA | 4.5 |
| That audio description is relevant — AA | 4.6 |
| Time-based media is clearly identifiable | 4.7 |
| Automatically triggered sound is controllable by the user | 4.10 |
| Media viewing controls operable by keyboard and pointer | 4.11 |
| Media is compatible with assistive technologies | 4.13 |

### Theme 5 — Tables
Scan for: `<table>`, `<th>`, `<td>`, `<caption>`, `[role="table"]`

| Check | Criteria |
|-------|----------|
| Complex data tables have a summary | 5.1 |
| That summary is relevant | 5.2 |
| Layout tables: linearised content still comprehensible | 5.3 |
| Where a data table has a title, it is correctly associated (`<caption>`) | 5.4 |
| That title is relevant | 5.5 |
| Column and row headers declared with `<th>` | 5.6 |
| Cells associated with their headers (`scope`, or `headers`/`id` when complex) | 5.7 |
| Layout tables do not use data-table semantics | 5.8 |

### Theme 6 — Links
Scan for: `<a>`, `[role="link"]`

| Check | Criteria |
|-------|----------|
| Every link is explicit — purpose clear from text or context | 6.1 |
| Every link has an accessible name | 6.2 |
| Link whose nature is not obvious is visible against surrounding text | 10.6 |

Note: indicating a link's file format and size is **good practice, not a RAWeb
criterion**. Recommend it, but do not record it as a 13.3 failure.

### Theme 7 — Scripts
Scan for: `onclick`, `onkeydown`, `addEventListener`, `[role]`, `[aria-*]`, `[tabindex]`

| Check | Criteria |
|-------|----------|
| Script-driven UI is compatible with AT (correct role, name, value) | 7.1 |
| Where a script has an alternative, that alternative is relevant | 7.2 |
| Scripts operable by keyboard AND any pointing device | 7.3 |
| Change of context is announced or user-controlled | 7.4 |
| Status messages correctly rendered to AT — AA | 7.5 |

Do **not** look for these under Theme 7 — they live elsewhere, and citing 7.x for
them is a reporting error:

| Frequently misfiled here | Actually |
|--------------------------|----------|
| Moving/blinking content has pause-stop-hide controls | **13.8** |
| Flashing more than 3 times per second | **13.7** |
| Keyboard traps | **12.9** |

### Theme 8 — Mandatory Elements
Full-page checks.

| Check | Criteria |
|-------|----------|
| Page has a defined document type (`<!DOCTYPE html>`) | 8.1 |
| Source code is valid — nesting, no duplicate `id` | 8.2 |
| Default language present on `<html>` | 8.3 |
| That language code is relevant | 8.4 |
| Page has a `<title>` | 8.5 |
| That title is relevant | 8.6 |
| Each language change indicated in the source — AA | 8.7 |
| Each language-change code valid and relevant — AA | 8.8 |
| Tags not used only for layout purposes | 8.9 |
| Changes in reading direction indicated | 8.10 |

### Theme 9 — Information Structure
Scan for: `<h1>`–`<h6>`, `<ul>`, `<ol>`, `<dl>`, `<blockquote>`, `<header>`, `<nav>`, `<main>`, `<footer>`, `<aside>`, `<section>`, `<article>`

| Check | Criteria |
|-------|----------|
| Headings logically ordered (no skipped levels) | 9.1 |
| Document structure uses landmarks | 9.2 |
| Lists use proper markup | 9.3 |
| Quotations properly marked | 9.4 |

### Theme 10 — Presentation of Information
CSS and layout checks.

| Check | Criteria |
|-------|----------|
| Style sheets used to control presentation | 10.1 |
| Visible content conveying information is accessible to AT | 10.2 |
| Information remains understandable with style sheets disabled | 10.3 |
| Text readable at 200% font size — AA | 10.4 |
| Background and font colour declarations used together — AA | 10.5 |
| Links whose nature is not obvious are visible against surrounding text | 10.6 |
| Visible focus on every element receiving keyboard focus | 10.7 |
| Hidden content is correctly ignored by AT | 10.8 |
| Information not conveyed by shape, size or location alone | 10.9, 10.10 |
| Content reflows at 320px width / 256px height — AA | 10.11 |
| Text spacing can be redefined without loss — AA | 10.12 |
| Additional content on hover/focus is dismissible, hoverable, persistent — AA | 10.13 |
| CSS-only additional content can be made visible by keyboard | 10.14 |

### Theme 11 — Forms
Scan for: `<form>`, `<input>`, `<select>`, `<textarea>`, `<button>`, `<fieldset>`, `<legend>`, `<label>`, `[role="form"]`

| Check | Criteria |
|-------|----------|
| All fields have associated labels | 11.1 |
| Labels are relevant | 11.2 |
| Labels include visible text in accessible name | 11.2 |
| Grouped fields use `<fieldset>/<legend>` | 11.5 |
| Required fields indicated before or at field | 11.10 |
| Error messages linked to fields and descriptive (AA) | 11.11 |
| `autocomplete` used for personal data (AA) | 11.13 |

### Theme 12 — Navigation
Full-page/site checks.

| Check | Criteria |
|-------|----------|
| ≥2 navigation systems across the set of pages — AA | 12.1 |
| Menus and navigation bars always in the same place — AA | 12.2 |
| Site map page is relevant — AA | 12.3 |
| Site map reachable identically across pages — AA | 12.4 |
| Search engine reachable in the same way — AA | 12.5 |
| Repeated content-grouping blocks can be reached or bypassed | 12.6 |
| Skip link to the main content region present and functional | 12.7 |
| Navigation sequence is consistent (tab order; no positive `tabindex`) | 12.8 |
| **No keyboard traps** | 12.9 |
| Single-key shortcuts are remappable or disableable | 12.10 |
| Content appearing on hover/focus/activation is keyboard reachable — AA | 12.11 |

### Theme 13 — Consultation
Behavioural and interaction checks.

| Check | Criteria |
|-------|----------|
| User controls every time limit — refreshes, redirects, session limits | 13.1 |
| A new window is never opened without user action | 13.2 |
| Downloadable office documents have an accessible version | 13.3 |
| That accessible version offers the same information | 13.4 |
| Cryptic content is identified | 13.5 |
| Alternatives to cryptic content are relevant | 13.6 |
| No flashing more than 3 times per second | 13.7 |
| Moving or blinking content is controllable — pause, stop, hide | 13.8 |
| Content viewable in any screen orientation — AA | 13.9 |
| Complex gestures have a single-point alternative (multi-touch **and path-based**) | 13.10 |
| Single-point actions can be cancelled | 13.11 |
| Motion-triggered features have a non-motion alternative | 13.12 |

Note: warning the user before a **change of context** is **7.4**, not 13.1.
Test **13.10.2** covers *path-based* gestures — a drag with no single-point
alternative (a slider that only drags, a splitter with no reset) fails it. This
is widely missed because 13.10 reads as though it were only about pinch.

### Themes 14–17 (EN 301 549 Extended)
These themes go beyond standard WCAG web testing and cover documentation,
editing tools, support services, and real-time communication. Query them
individually when relevant:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topic 14  # Documentation & accessibility features
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topic 15  # Editing tools
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topic 16  # Support services
bash ${CLAUDE_SKILL_DIR}/scripts/raweb-lookup.sh topic 17  # Real-time communication
```

---

## Report format

When presenting audit results, use this structured format:

```markdown
# RAWeb 1.1 Accessibility Audit Report

**Page/Component**: [name or URL]
**Date**: [date]
**Target level**: AA
**Scope**: [full page / component / sample description]

## Summary

| Metric | Count |
|--------|-------|
| Criteria evaluated | XX |
| Conforming (C) | XX |
| Non-conforming (NC) | XX |
| Not applicable (NA) | XX |
| **Conformance rate** | **XX%** |

## Critical issues (must fix)

### Issue 1: [Short title]
- **Criterion**: RAWeb X.X (Level A/AA) — [criterion title]
- **WCAG**: X.X.X [SC name]
- **Location**: [file:line or selector]
- **Problem**: [description of the violation]
- **Impact**: [which users are affected and how]
- **Remediation**: [specific fix with code example]
- **Priority**: Critical / Major / Minor

## Detailed results by theme

### Theme X: [Name]

| Criterion | Level | Verdict | Notes |
|-----------|-------|---------|-------|
| X.1 | A | C / NC / NA | [detail] |
| X.2 | AA | C / NC / NA | [detail] |

## Recommendations

[Prioritised list of improvements beyond strict compliance]
```

---

## Code scanning patterns

When auditing code files, use these search patterns to identify potential issues:

```bash
# Images without alt
grep -rn '<img ' --include="*.html" --include="*.jsx" --include="*.tsx" --include="*.vue" | grep -v 'alt='

# Empty links
grep -rn '<a[^>]*>[[:space:]]*</a>' --include="*.html" --include="*.jsx" --include="*.tsx"

# Positive tabindex
grep -rn 'tabindex="[1-9]' --include="*.html" --include="*.jsx" --include="*.tsx"

# onclick without keyboard equivalent
grep -rn 'onclick' --include="*.html" | grep -v '<button\|<a '

# Missing form labels
grep -rn '<input\|<select\|<textarea' --include="*.html" --include="*.jsx" --include="*.tsx" | grep -v 'aria-label\|aria-labelledby\|id='

# Autoplaying media
grep -rn 'autoplay' --include="*.html" --include="*.jsx" --include="*.tsx"

# Iframes without title
grep -rn '<iframe' --include="*.html" --include="*.jsx" --include="*.tsx" | grep -v 'title='

# Missing lang attribute
grep -rn '<html' --include="*.html" | grep -v 'lang='

# Colour-only indicators (potential — needs manual review)
grep -rn 'color:.*red\|color:.*green\|text-red\|text-green\|text-danger\|text-success' --include="*.css" --include="*.scss"
```

---

## Severity classification

| Level | Description | Example |
|-------|-------------|---------|
| **Critical** | Blocks access entirely for some users | Missing form labels, keyboard traps, no alt on critical images |
| **Major** | Significant barrier but workaround exists | Poor contrast, missing skip links, ambiguous link text |
| **Minor** | Inconvenience but does not block access | Missing `lang` on inline foreign text, redundant ARIA |

---

## When auditing, ALWAYS:

1. **Look up the exact criterion** before rendering a verdict — never from memory.
   RAWeb numbering is **not** WCAG numbering: RAWeb 7.3 is keyboard operability;
   WCAG 2.1.1 is. A wrong number in a report is worse than no number, because it
   is confidently wrong and the reader cannot tell
2. **Read the criterion's tests, not just its title** — the title summarises, the
   tests define the scope (see 11.10, which covers mandatory-field indication
   despite being titled "error management")
3. **Apply the official test methodology** from `methodologies.json`
4. **For interactive components, start with `show <slug>`** — its RAWeb criteria
   table *is* the audit scope for that component. Then `code <slug>` for the
   known defects and the manual test procedure
5. **Check the pattern itself is right**, not only its implementation. A
   `role="menu"` site nav, a `role="grid"` read-only table, or a treeview used
   for navigation are all valid ARIA and genuine regressions. `code <slug>` opens
   with the decision table for this
6. **Use precise RAWeb criterion numbers** (e.g., "RAWeb 11.1", not just "WCAG 1.3.1")
7. **Include the WCAG mapping** for cross-reference — note that one RAWeb
   criterion usually maps to **several** WCAG success criteria; cite them all
8. **Provide actionable remediation** with code examples — the `### Do` blocks in
   `references/patterns/<slug>.md` are ready to quote
9. **Distinguish between Level A and AA** violations — both are required for
   conformance, but Level A failures are more critical
10. **State what automation cannot decide.** Each pattern's `## Verify` section
    lists explicitly what axe and Lighthouse miss for it. A clean automated scan
    is not a pass — say so in the report rather than letting silence imply it
