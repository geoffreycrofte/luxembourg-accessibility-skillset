# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.5.0] - 2026-07-16

Version 1.4.0 verified every criterion **number** in both RAWeb skills against the
official data. It did not verify the **prose** against the 304 official test
methodologies, and said so. This release closes that gap: all 304 methodologies were
read end-to-end and every claim in both skills adjudicated against the tests, not the
titles.

The distinction matters because RAWeb titles summarise and **tests define scope**.
Criterion 11.10 is the canonical case — titled *"is the error management used
appropriately"*, its tests also cover mandatory-field indication and `aria-required`.
1.4.0 called this out as guidance; every finding below is an instance of it that had
survived in the skills' own rows.

Method: the 213 criterion claims across both skills were extracted mechanically (not by
reading), so coverage is provable rather than asserted — 196/196 distinct claim
locations adjudicated, none skipped. Each finding is grounded in three independently
authored sources that must agree: the criterion's title, its test text + methodology,
and its WCAG mapping.

### Fixed

**Criterion coverage in Themes 1–13 went from 119/136 to 136/136.** Seventeen criteria
— ten of them Level **A** — were absent from the checklists entirely.

- **Theme 11 (Forms) — 7 of 13 criteria were missing, 5 at Level A** • Added **11.3**
  (consistent labels across pages), **11.4** (label/field adjacency, with its exact
  geometry: above/left for normal fields, **below/right** for checkbox/radio/switch),
  **11.6** (each group has a legend), **11.7** (that legend is relevant), **11.8**
  (`<optgroup>` grouping and labels), **11.9** (button labels — the theme had *no*
  button coverage despite the scan hint listing `<button>`), and **11.12** (Error
  Prevention — forms that modify/delete data or carry legal/financial consequences).
- **Error identification filed under the wrong criterion, at the wrong level** • Both
  skills put "error messages linked to fields" under **11.11**, whose only two tests
  cover *suggestions* (data types/formats, examples — WCAG 3.3.3, AA). Linking an error
  to its field is **11.10** (tests .3/.4/.6/.7, via `aria-invalid` — WCAG 3.3.1,
  **Level A**). Both rows also labelled it "(AA)", so a Level A failure was
  systematically mis-prioritised as AA — against the skills' own rule that Level A
  failures are more critical. This sat two rows below the 11.10 warning added in 1.4.0.
- **`<legend>` attributed to 11.5** • 11.5 is the *grouping* alone, and accepts
  `<fieldset>`, `role="group"` or `role="radiogroup"`. The legend is **11.6**, its
  relevance **11.7** — both of which were missing, so the requirement was attributed to
  a criterion that does not test it.
- **The `required` trap** • `required`/`aria-required` alone satisfies 11.10.1, but
  *triggers* 11.10.2, which demands a **visible** mandatory indication. Attribute-only
  marking passes one test and fails the next; neither skill said so.
- **Theme 4 (Multimedia) — 8 of 18 criteria were missing** • Added **4.8**, **4.9**,
  **4.12** (non-time-based media — interactive `<canvas>`/`<svg>`: charts, data-viz,
  games; all Level A, and the theme's scan hint already listed both elements), and
  **4.14–4.18** (see EN 301 549 below).
- **Captions cited as 4.1** • Captions are **4.3** only; 4.1 requires a *transcript* or
  *audio description* and never mentions captions. Also added 4.3.2 (`<track>` needs
  `kind="captions"`) and 4.3.3 (live media).
- **4.11 reduced to operability** • Test 4.11.1 mandates the controls **exist** — play/
  pause or stop, sound on/off, a captions toggle, and an **audio-description toggle** —
  before 4.11.2/4.11.3 require they be keyboard- and pointer-operable. A player with no
  caption toggle fails 4.11.1 even if everything present is operable.
- **Theme 13 — 13.13 and 13.14 were missing** • **13.14 is Level A**: biometric
  identification (fingerprint, face, voice) needs an alternative, and if that alternative
  is also biometric it must use a *sufficiently different* characteristic.
- **Status messages: a technique RAWeb does not recognise** • `raweb-code` listed
  `aria-relevant` for 7.5. It appears in no test and no methodology branch, and satisfies
  nothing. It also omitted **`aria-atomic="true"`**, which RAWeb requires alongside
  `aria-live` in *every* branch — so bare `aria-live="polite"` fails 7.5.1 — and omitted
  `role="progressbar"`. Replaced with RAWeb's actual **message-type → technique** mapping;
  using `role="status"` for an error fails 7.5.2.
- **Landmark list inverted against test 9.2.1** • `raweb-code` omitted **`<search>` /
  `role="search"`** (which 9.2.1 requires) and listed `<aside>` (which 9.2 never
  requires). Added 9.2.2 (only **one visible** `main`/`banner`/`contentinfo`;
  `navigation` reserved for real navigation) and 9.2.3/9.2.4 (a `<header>`/`<footer>`
  without an explicit role must not nest inside `article`/`complementary`/`main`/
  `navigation`/`section`).
- **Criterion 1.3 — the ~80-character guidance is the criterion** • 1.4.0 recorded
  "the ~80-character guidance is good practice, not the criterion". That was wrong.
  **Test 1.3.9** is *"is the text alternative short and concise?"*, and RAWeb's glossary
  defines the term as *"a maximum length of 80 characters is strongly recommended"*.
  Brevity is tested by 1.3; only the specific number is a recommendation.
- **Headings reduced to hierarchy** • 9.1 has three tests. Added **9.1.2** (heading text
  is relevant) and **9.1.3** (every passage of text acting as a heading is marked up as
  one — a styled `<div class="title">` fails it while the hierarchy checks out clean).
  Also: "no skipped levels" is an interpretation; 9.1.1 says only that the hierarchy is
  *appropriate*.
- **Quotations: `<q>` was missing** • 9.4 has two tests — **9.4.1** (short inline
  quotations use `<q>`) and 9.4.2 (`<blockquote>` for blocks). Only the second was
  covered. `cite` is good practice; 9.4 does not test it.
- **1.6 detailed descriptions — routes differ by element type** • `aria-describedby` is
  accepted for `<input type="image">` (1.6.4), `<svg>` (1.6.5) and `role="img"` (1.6.10),
  but **not** for `<img>`, `<object>`, `<embed>` or `<canvas>` — so the guidance was wrong
  for the commonest case, a chart shipped as a plain `<img>`. Tests 1.6.6/1.6.8/1.6.9
  validate that the technique resolves; they do not grant a route.
- **Layout tables: `role="presentation"` is required** • 5.3 asks for *both* conditions —
  linearised content understandable **and** `role="presentation"` on the `<table>`. Only
  the first was stated. (5.3 says what a layout table must *have*; 5.8 says what it must
  *not*.)
- **Table headers: `<th>` is not the only route** • 5.6.1/5.6.2 accept `<th>` **or**
  `role="columnheader"`/`role="rowheader"` for full-span headers; 5.6.3 allows **only**
  `<th>` for partial ones. Added `scope="rowgroup"`/`scope="colgroup"` (5.7.6), the ARIA
  association route (5.7.1/5.7.5), and 5.7.3's anti-pattern. 5.4 accepts four title
  routes, not just `<caption>`; 5.8's prohibition list also covers `summary`, `<thead>`,
  `<tfoot>`, the header roles, and `axis`.
- **Contrast stated in the wrong units, and missing a conformance route** • RAWeb defines
  3.2's thresholds in **px**: ≥24px non-bold / **≥18.5px** bold (not 18pt/14pt). Both 3.2
  and 3.3 also accept a **user-activatable mechanism** as an alternative to a raw ratio —
  which makes tests **3.2.5** and **3.3.4** (the mechanism must itself be compliant)
  applicable. Four tests' worth of scope was invisible.
- **3.1 needs *both* complements** • Methodologies 3.1.1–3.1.6 require additional
  information **in the code** *and* an additional **visual** cue. An icon alone, or an
  `aria-label` alone, does not discharge 3.1.
- **Focus indicator has a number** • Methodology 10.7.1 requires the focus indication be
  *"sufficiently contrasted (contrast ratio equal to or greater than 3:1)"*. A visible but
  low-contrast focus ring fails 10.7.
- **10.6 is three conditions, not one** • A colour-only link needs ≥3:1 against
  surrounding text **and** a non-colour **hover** indication **and** a non-colour **focus**
  indication — checked across every state.
- **10.9/10.10 collapsed into one row** • 10.9 asks whether an alternative *exists*;
  10.10 asks whether it is *relevant*. The skills split this presence/relevance pattern
  correctly everywhere else (1.1/1.3, 4.1/4.2, 5.4/5.5, 8.5/8.6).
- **10.1: `width`/`height` are allowed** • Methodology 10.1.2 explicitly permits them on
  `<canvas>`, `<embed>`, `<iframe>`, `<img>`, `<object>`, `<source>`, `<svg>` — so the
  blanket "no HTML presentation attributes" told developers to remove the very attributes
  that prevent layout shift. Added 10.1.3 (spaces must not separate letters in a word or
  simulate tables/columns).
- **10.2 and 10.3 conflated as "no loss when CSS is disabled"** • 10.2 is about **AT
  access to visible content** with CSS *on* (a CSS background image conveying meaning
  needs a text alternative); 10.3 is specifically about **reading order** with CSS off.
- **Nesting validity cited as 8.1** • 8.1 is DOCTYPE presence only. Source-code validity
  and nesting are **8.2**.
- **12.2 does not test the active page** • `raweb-code` stated "the active page must be
  indicated in navigation menus (12.2)". 12.2 tests only that menus stay in the same
  **place** and the same relative **source order** (WCAG 3.2.3). `aria-current` is good
  practice — no RAWeb criterion requires it.
- **Bypassing repeated blocks is 12.6, not 12.7** • 12.7 is specifically a skip link to
  the **main content region**; 12.6 covers repeated content blocks and accepts five
  routes (landmark role, heading, hide button, skip link, bypass link).
- **12.8 does not mention `tabindex`** • Positive `tabindex` is a reliable smell, not the
  criterion — RAWeb explicitly notes the sequence *"does not have to follow the natural
  reading order ... as long as the elements are accessible in a coherent order"*. Added
  **12.8.2**: the sequence must stay consistent after a script inserts content, with focus
  repositioned correctly — the most common SPA defect, previously in neither skill.
- **Missing exemptions that produce false NC verdicts** • 13.7 also passes when the
  cumulative flash area is **≤ 21824 px²**; 13.8 exempts movement lasting **≤ 5 s** (and
  pausing **on focus only** is explicitly *not* compliant; a progress bar is **NA**); 4.10
  exempts sounds of **≤ 3 s**. Added 13.12.3 (the user must be able to **disable motion
  detection**, not merely have an alternative) and 13.1.2 (a `<meta refresh>` redirect
  must be immediate or ≥ 20 hours — no user control applies).
- **Scripts must not steal focus** • Test **7.3.2** — *"a script must not remove the focus
  of an element which receives it"* — was in neither skill.
- **Smaller corrections** • 6.2 is the *presence* of a link's accessible name (6.1 is its
  explicitness); "aria-label must contain the visible label" is test 6.1.5 alone, not 6.2;
  added 6.1.6 (identical link names must lead to the same destination). 1.1.5 accepts
  `<svg><title>`; 1.8 accepts a **replacement mechanism** as well as the CSS escape; 1.5
  accepts a **non-graphical** CAPTCHA *or* another route to the secured function. 8.6
  tests title *relevance* — the SPA update rule is its consequence, not its text. 12.3
  also tests that the site map's links work and go where their text says.

### Added

- **The EN 301 549-only criteria, named as a group** (`raweb-audit/SKILL.md`) • RAWeb has
  **30 criteria with no WCAG mapping at all** — the ones no axe/Lighthouse/WAVE rule will
  ever report, and the reason a RAWeb audit is not a WCAG audit. The "Themes 14–17
  (EN 301 549 Extended)" section already caught 23 of them. The other **7 were orphaned**
  inside ordinary themes — 4.14–4.18, 13.13, **13.14 (Level A)** — reachable by neither
  the theme tables nor the 14–17 escape hatch. They are now tabulated explicitly, because
  nothing around them looks unusual enough to prompt a lookup.
- **Trigger conditions for Themes 14–17** • "Query them individually when relevant" left
  relevance to the auditor with no criteria. Now: a CMS or rich-text editor → theme 15;
  chat/voice/RTT → theme 17; a support channel → theme 16; accessibility documentation →
  theme 14. Noted that these themes contain **Level A** criteria too, so skipping them
  silently omits Level A material.
- **"Read the tests, not just the title" — the other three forms of the trap** • 1.4.0
  documented the trap via 11.10 (the tests are *broader* than the title). Added: the title
  **omits a whole test** (1.3.9); the tests offer **escapes** the title never mentions
  (the 21824 px², 5 s and 3 s exemptions — these cause false **NC** verdicts, the opposite
  failure); and **adjacent criteria split presence from relevance**, where one verdict for
  both leaves one criterion unevaluated.
- **11.10 vs 11.11 note**, in both skills — the most misfiled pair in the referential.

### Changed

- `raweb-audit/SKILL.md` and `raweb-code/SKILL.md` → **v1.3.0 → v1.4.0**.
- Scan hints corrected where they disagreed with the tests: Theme 9 gained `<q>` (9.4.1),
  `<search>` (9.2.1) and `[role="heading"]` (9.1.3); Theme 6 gained image, composite and
  SVG links (`<area href>`, `<svg><a>` — tests 6.1.2/6.1.3/6.1.4).

### Notes

Verified correct and left unchanged: every `— AA` annotation (zero level errors across
136 criteria); the 11.10, 13.3 (file format/size is not a criterion) and 7.4-not-13.1
notes; the 13.10.2 path-based-gesture note; the 5.4 association-vs-mandate note; and the
modal-dialog criteria list, which matches `dialog-modal.json` exactly.

Two source-level observations, reported rather than "fixed" — the skills follow
`niveaux.json` faithfully in both cases:

- **12.11** is Level **AA** in RAWeb but maps solely to WCAG **2.1.1 Keyboard (A)** — a
  WCAG Level A requirement sitting at AA inside a framework implementing EN 301 549.
  **3.3** runs the other way (Level A against WCAG 1.4.11's AA), which reads as a
  deliberate national tightening. These are the only two of 136 where RAWeb's level
  disagrees with its mapped SC.
- **4.3** is Level A and its test 4.3.3 covers **live** captions, yet it maps only to
  WCAG 1.2.2 Captions (**Prerecorded**); WCAG puts live captions at 1.2.4 (AA).

## [1.4.0] - 2026-07-16

### Added
- **Code example patterns** (`raweb-code/references/patterns/`) • Per-component code references with dos **and** don'ts. Each don't states the concrete failure it causes for a real user. **All 30 APG patterns** covered, ~12,800 lines:
  - *Interactive (vanilla + React + Angular + Web Components)* — `dialog-modal`, `alertdialog`, `disclosure`, `accordion`, `tabs`, `switch`, `combobox`, `menu-button`, `menubar`, `tooltip`, `alert`, `checkbox`, `radio`, `button`, `listbox`, `carousel`, `slider`, `slider-multithumb`, `spinbutton`, `toolbar`, `treeview`, `treegrid`, `grid`, `feed`, `windowsplitter`
  - *Static (vanilla only — no JS required, so no framework sections)* — `landmarks`, `link`, `breadcrumb`, `table`, `meter`
  - Patterns cross-link rather than repeat: `accordion` builds on `disclosure`, `alertdialog` on `dialog-modal`, `treegrid` on `grid` + `treeview`.
- **Decision tables where the pattern is usually the wrong choice** • `menu-button` and `menubar` (most "menus" are navigation or a disclosure), `tooltip` (anything interactive inside is not a tooltip), `combobox`/`listbox` (use `<select>`), `grid` (a read-only table is a `<table>`), `treeview` (a nav sidebar is nested `<ul>` + disclosures), `treegrid` (usually a table with disclosure buttons), `feed` (usually a list + "Load more"), `spinbutton` (`type="number"` is wrong for digit strings), `switch` vs `checkbox`, `button` vs link.
- **Pattern authoring contract** (`raweb-code/references/patterns/_TEMPLATE.md`) • Section headings are an API consumed by the `code` command; ARIA/keyboard/criteria tables must never be retyped into markdown.
- **`code` command** (`raweb-component-lookup.sh`) • `code <slug> [vanilla|react|angular|web-component]` extracts a single framework section. Reports which patterns have examples when one is missing.
- **RAWeb criteria mapping in component JSON** • New `raweb_criteria` field maps each component pattern to the criteria it must satisfy, with a per-component reason. Levels and official titles are resolved at render time from `niveaux.json`/`criteres.json`, so they cannot go stale.
- **`values` field on ARIA attributes** • Documents allowed values/states (e.g. `aria-modal` → `true`), rendered as a "Values / states" column.
- **Reference validator** (`scripts/validate-references.sh`, shipped in every RAWeb skill) • Fails on criterion numbers that don't exist, level annotations that contradict the official data, unresolvable criteria mappings, dangling `code_examples` pointers, unpaired pattern files, and **`### Do` code examples whose JavaScript does not parse** (`### Don't` blocks are exempt — they are deliberately fragments). Exit 1 on drift — CI-ready. Skips the JS check gracefully when `node` is absent. Understands both skills' citation styles — prose `(7.3)` and markdown-table `| … | 3.3 |` — and **fails when it finds no citations at all**, since a vacuous pass looks identical to a real one.
- **Skill sync script** (`scripts/sync-skills.sh`) • Each skill ships its own `references/` and `scripts/` so single-skill installs work (CHANGELOG 1.3.0). That duplication is deliberate; the risk is silent drift, which had already happened. The `-code` skill of each pair is the source of truth; `sync-skills.sh` copies, `sync-skills.sh --check` exits 1 on divergence for CI. Covers `raweb-code → raweb-audit` and `raam-code → raam-audit`. `SKILL.md` is never copied.

### Fixed

Both `raweb-code` and `raweb-audit` cited criterion numbers that did not match
the criteria they described. Every number in both skills has now been checked
against the official data, and the validator enforces it going forward. A wrong
criterion number is the worst failure mode for these skills: it is confidently
authoritative and the reader has no way to tell.

- **Topic/Theme 7 (Scripts) — every number was wrong, in *both* skills** • Keyboard/pointer operability is **7.3** (was cited as 7.1); status messages are **7.5** (was 7.4); 7.2 is the relevance of a script's *alternative*; pause/stop/hide is **13.8**, not 7.5. Criterion **7.4** (change of context) was missing entirely.
- **Topic/Theme 5 (Tables) — the summary requirement is 5.1, not 5.5** • 5.5 is *"is the title relevant?"*. 5.2 covers the summary's relevance. 5.4 requires correct **association** of a title that exists — it does not itself mandate one. **5.1, 5.2 and 5.3** (layout-table linearisation) were missing from both skills; `raweb-audit` additionally cited 5.1/5.3 for "data tables identified with appropriate markup", which is neither.
- **Topic/Theme 4 — 4.10 and 4.11 were swapped** • 4.10 is *"is each automatically triggered sound controllable?"*; 4.11 is *"is media viewing operable by keyboard and pointer?"*. Both skills had them the wrong way round. Added 4.2, 4.4, 4.7 and 4.13.
- **Criterion 1.9 is about image captions, not images of text** • 1.9 is *"is each image caption correctly linked to the corresponding image?"* (`<figure>`/`<figcaption>`). Images of text is **1.8** alone.
- **Criterion 1.3 mischaracterised** • 1.3 is *"is the text alternative relevant?"*. The ~80-character guidance is good practice, not the criterion.
- **Topic/Theme 13 (Consultation)** • 13.3 is about accessible versions of office documents, not indicating link file format/size (good practice, not a criterion); flashing is **13.7**, not 13.8; warning before a context change is **7.4**, not 13.1.
- **`raweb-audit` Theme 10 — 10.13 mischaracterised** • 10.13 is *"additional content on hover/focus is dismissible, hoverable, persistent"*, not "custom user properties can override". Added 10.2, 10.3, 10.5, 10.6, 10.9, 10.10, 10.14.
- **`raweb-audit` Theme 12 — 12.3 mischaracterised** • 12.3 is *"is the site map page relevant?"*, not "navigation landmarks labelled when multiple". Added 12.4, 12.5, 12.6, **12.9 (keyboard traps)**, 12.10 and 12.11.
- **`raweb-audit` Theme 6** • Link accessible name is **6.2**; 6.1 is whether the link is *explicit*. Link visibility against surrounding text is **10.6**.
- **`raweb-audit` Theme 8** • Split the conflated pairs into their real criteria (8.1 doctype / 8.2 validity / 8.3 language present / 8.4 language relevant / 8.5 title present / 8.6 title relevant / 8.7 changes indicated / 8.8 change codes valid), and added 8.9 and 8.10.
- **Wrong conformance levels** • 3.3 (non-text contrast) and 1.9 are Level **A**, not AA — in `raweb-code/SKILL.md`, and 3.3 again in `raweb-audit/SKILL.md`.
- **Missing criteria in `raweb-code/SKILL.md` Topic 12 (Navigation)** • Added 12.9 (keyboard traps — the criterion that governs modal focus traps), 12.10 (single-key shortcuts), and 12.11 (content on hover/focus).
- **Lossy WCAG mapping in `topic` output** • A RAWeb criterion usually maps to several WCAG success criteria; only the first was shown, making correct data look wrong (7.3 displayed as "1.3.1 Info and Relationships" while hiding "2.1.1 Keyboard").
- **`raweb-audit` running stale scripts** • Its `references/` and `scripts/` had diverged from `raweb-code`, leaving it on an older `raweb-lookup.sh` with the lossy WCAG mapping. Now enforced by `scripts/sync-skills.sh --check`.

### Changed
- **`show <slug>` now renders markdown tables** by default — RAWeb criteria, keyboard interaction, ARIA roles, and required/optional attributes with their values and states. `show <slug> --plain` keeps the previous terminal output.
- **`raweb-audit/SKILL.md` rewired to the new reference data** (v1.2.0 → v1.3.0):
  - Every theme checklist rebuilt against the official criteria — see *Fixed*. Themes 4, 5, 6, 7, 8, 10, 12 and 13 gained the criteria they were missing (notably **12.9 keyboard traps**, absent entirely).
  - **`show <slug>` is now the per-component audit scope.** Its RAWeb criteria table states which criteria a component must satisfy and why, resolved live from `niveaux.json`/`criteres.json`.
  - **`code <slug>` documented as a defect catalogue**, not example code: the `### Don't` blocks are real production defects with their user impact, and each `## Verify` section is a manual test procedure that states explicitly **what axe and Lighthouse will not catch** for that pattern.
  - **New step 3 in the audit methodology**: check the *pattern itself* is right before auditing whether it is implemented right. `role="menu"` on site navigation, `role="grid"` on a read-only table, and a treeview used for navigation are all valid ARIA and genuine regressions that no scanner flags.
  - **"Read the tests, not just the title"** added to the methodology and the ALWAYS rules. Criterion 11.10 is titled *"is the error management used appropriately"* but its tests also cover mandatory-field indication and `aria-required` — judging by title alone produces confidently wrong verdicts in both directions.
  - Theme 7 and 13 gained "frequently misfiled here" tables pointing at the criteria those checks actually belong to.

## [1.3.0] - 2026-05-17

### Changed
- **Self-contained skills** • Each skill folder now ships its own `references/` and `scripts/` instead of sharing root-level directories. Installing a single skill (e.g. `npx skills add geoffreycrofte/luxembourg-accessibility-skillset --skill raweb-code`) or copying one folder gives you everything that skill needs to run.
- **`raweb-code/`, `raweb-audit/`, `raam-code/`, `raam-audit/`** • Each now contains its own `scripts/` (lookup CLIs) and `references/` (criteria, glossary, methodologies, and — for RAWeb — themes, niveaux, and 30 WAI-ARIA APG component patterns).
- **SKILL.md path updates** • All four skills now reference `${CLAUDE_SKILL_DIR}/scripts/...` and `${CLAUDE_SKILL_DIR}/references/...` (previously `${CLAUDE_SKILL_DIR}/../scripts/...`).
- **README** • Updated repository structure diagram, install instructions (added single-skill example), and lookup script invocations to reflect per-skill paths.

### Removed
- **Root-level `references/` and `scripts/` directories** • Replaced by per-skill copies inside each skill folder.

## [1.2.0] - 2026-03-27

### Added
- **WAI-ARIA APG component patterns** • 30 individual JSON files in `references/raweb/components/`, each containing keyboard interactions, ARIA roles, required/optional attributes, and implementation notes. Extracted from the [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/patterns/).
- **Component pattern index** (`references/raweb/components/index.json`) • keyword-to-slug mapping for fast pattern lookup (200+ keywords across 30 patterns).
- **Component lookup script** (`scripts/raweb-component-lookup.sh`) • CLI tool to find, show, list, and search component patterns by keyword or ARIA role.
- **Contributing section** in README with contribution guidelines.
- **Contributors section** in README crediting project author and reference data publishers.
- **Reflections section** in README about standardised audit result formats.

### Changed
- **raweb-code/SKILL.md** • Replaced static "Component patterns quick reference" table (10 entries) with dynamic component lookup system (30 patterns). Updated "When in doubt" section with component lookup instructions.
- **raweb-audit/SKILL.md** • Added "Component pattern references" section with lookup commands. Updated "When auditing, ALWAYS" section to include ARIA pattern verification.
- **README.md** • Updated repository structure to reflect new `components/` directory and `raweb-component-lookup.sh` script. Added component lookup examples to "Lookup scripts" section.

### Fixed
- **macOS compatibility** • Fixed `${1,,}` bash 4+ syntax in `raweb-component-lookup.sh` to use `tr` for bash 3 compatibility (macOS default shell).

## [1.1.0] - 2026-03-26

### Added
- **RAAM 1.1 skills** • `raam-code` and `raam-audit` for mobile accessibility (iOS/Android/React Native/Flutter).
- **RAAM reference data** • `criteres.json`, `glossaire.json`, `methodologies.json` in `references/raam/`.
- **RAAM lookup script** (`scripts/raam-lookup.sh`) • CLI tool for querying RAAM criteria, methodologies, and glossary.

## [1.0.0] - 2026-03-26

### Added
- **RAWeb 1.1 skills** • `raweb-code` (accessible web development guide) and `raweb-audit` (accessibility audit skill).
- **RAWeb reference data** • `criteres.json`, `glossaire.json`, `methodologies.json`, `themes.json`, `niveaux.json` in `references/raweb/`, sourced from [accessibility-luxembourg/ReferentielAccessibiliteWeb](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb).
- **RAWeb lookup script** (`scripts/raweb-lookup.sh`) • CLI tool for querying RAWeb criteria, test methodologies, glossary, and conformance levels.
- **README** with installation instructions (npx + manual), usage guide, and reference data documentation.
- **LICENSE** file.

[1.5.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.5.0
[1.4.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.4.0
[1.3.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.3.0
[1.2.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.2.0
[1.1.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/e5547c4f2227e525da043104275ce0c03c2174bb
[1.0.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/b16b50e80a8e66387d7a6b0dfb87286804a0cb48
