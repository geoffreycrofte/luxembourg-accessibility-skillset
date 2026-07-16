# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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

[1.3.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.3.0
[1.2.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/v1.2.0
[1.1.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/e5547c4f2227e525da043104275ce0c03c2174bb
[1.0.0]: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset/tree/b16b50e80a8e66387d7a6b0dfb87286804a0cb48
