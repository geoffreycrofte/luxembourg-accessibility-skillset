# Accessibility Skillset <small><small>• [v1.5.0](./CHANGELOG.md)</small></small>

Agent skills for [RAWeb](https://accessibilite.public.lu/en/raweb1.1/index.html), [RAAM](https://accessibilite.public.lu/en/raam1.1/index.html), and RAPDF, Luxembourg's official accessibility frameworks based on EN 301 549 and WCAG 2.1.

Compatible with [skills.sh](https://skills.sh) and the [Agent Skills open standard](https://agentskills.io). Works with Claude Code, Cursor, Gemini CLI, GitHub Copilot, and 30+ other AI coding agents.

---
> **Important:** Always consider auditing your website by a human being. AI isn't ready to replace human evaluation, moreover on a topic as complex as accessibility. With or without skills, your AI is just a junior assistant with a lot of flaws. This skills set is only here as an experiment, and as guidelines to help your AI be better at accessibility, not perfect.
---

## Available Skills

| Skill | Framework | Description | Status |
|-------|-----------|-------------|--------|
| **raweb-code** | RAWeb 1.1 | Write accessible web code (HTML/CSS/JS) | ✅ Ready |
| **raweb-audit** | RAWeb 1.1 | Audit web code against RAWeb criteria | ✅ Ready |
| **raam-code** | RAAM 1.1 | Write accessible mobile apps (iOS/Android/RN/Flutter) | ✅ Ready |
| **raam-audit** | RAAM 1.1 | Audit mobile apps against RAAM criteria | ✅ Ready |
| **rapdf-code** | RAPDF | Generate accessible PDFs | 🔜 Planned |
| **rapdf-audit** | RAPDF | Audit PDFs against RAPDF criteria | 🔜 Planned |

---
## Installation

### Via npx (recommended)

```bash
# Install the full skillset
npx skills add geoffreycrofte/luxembourg-accessibility-skillset

# Install globally (available in all projects)
npx skills add geoffreycrofte/luxembourg-accessibility-skillset -g

# Install a single skill
npx skills add geoffreycrofte/luxembourg-accessibility-skillset --skill raweb-code
```

Each skill is self-contained — its `references/` and `scripts/` ship inside the skill folder, so installing individual skills works out of the box.

### Manual installation (Claude Code)

```bash
# Project-level
cp -r raweb-code raweb-audit raam-code raam-audit .claude/skills/

# User-level (all projects)
cp -r raweb-code raweb-audit raam-code raam-audit ~/.claude/skills/
```

## Usage

> **A note on criterion numbers.** RAWeb numbering is not WCAG numbering, and the
> two are easy to conflate — RAWeb 7.3 is keyboard operability; WCAG 2.1.1 is.
> Every criterion number cited by these skills is checked against the official
> data by `validate-references.sh`, because a wrong number in an audit report is
> worse than no number: it reads as authoritative and nothing contradicts it.

### Web development • RAWeb

The `raweb-code` skill activates automatically when you write front-end web code. It provides:
- Inline accessible code patterns for all 17 RAWeb themes
- Code references for **all 30 WAI-ARIA APG patterns**, with **dos and don'ts** in vanilla HTML/CSS/JS, React, Angular, and Web Components — each don't explains the concrete failure it causes for a real user
- Decision tables for the patterns that are usually the *wrong* choice (`role="menu"` on site navigation, `role="grid"` on a read-only table, a treeview for a nav sidebar…)
- ARIA attribute/state and keyboard-interaction tables, rendered from the reference data so they can't go stale
- Pre-commit accessibility checklist
- Lookup commands for specific RAWeb criteria and test methodologies

Invoke explicitly with `/raweb-code`.

The `raweb-audit` skill reviews existing code against RAWeb. It provides:
- Theme-by-theme checklists covering **every criterion in themes 1–13 (136/136)**, with each number *and* each description verified against the **304 official test methodologies** — not against the criterion titles, which summarise and routinely under-state scope
- **The 7 EN 301 549-only criteria that hide inside ordinary themes** (4.14–4.18, 13.13, and 13.14 at Level A) called out explicitly — no WCAG-based scanner reports them, and nothing around them looks unusual enough to prompt a lookup
- **Per-component audit scope** — `show <slug>` states which RAWeb criteria a component must satisfy and why, with levels resolved live so they can't be stale
- **A defect catalogue** — `code <slug>` gives real production failure modes with their user impact, plus a manual test procedure that states explicitly *what axe and Lighthouse will not catch* for that pattern
- Structured report format with verdicts (C / NC / NA), severity classification, and WCAG cross-references
- A methodology step for the failure no scanner catches: checking the *pattern itself* is right, not just its implementation

Invoke explicitly with `/raweb-audit`.

### Mobile development • RAAM

The `raam-code` skill activates when you write mobile app code. It provides:
- Platform-specific patterns for iOS (SwiftUI/UIKit), Android (Compose/XML), React Native, and Flutter
- Accessible component examples for all 15 RAAM themes
- Cross-platform accessibility API quick reference
- Pre-commit checklist covering screen reader, orientation, text scaling, and gesture requirements

Invoke explicitly with `/raam-code`. Audit with `/raam-audit`.

### Lookup scripts

Standalone CLI tools for querying criteria and component patterns:

Scripts live inside each skill folder. From the repo root (or from the installed skill directory), invoke them like:

```bash
# RAWeb criteria (web) — script lives in raweb-code/scripts/ and raweb-audit/scripts/
./raweb-code/scripts/raweb-lookup.sh topics                       # List all 17 topics
./raweb-code/scripts/raweb-lookup.sh stats                        # Summary statistics
./raweb-code/scripts/raweb-lookup.sh criterion 11.1               # Specific criterion
./raweb-code/scripts/raweb-lookup.sh topic 11                     # All criteria in a topic
./raweb-code/scripts/raweb-lookup.sh methodology 11.1.1           # Test procedure
./raweb-code/scripts/raweb-lookup.sh level AA                     # All Level AA criteria
./raweb-code/scripts/raweb-lookup.sh search "form"                # Search by keyword
./raweb-code/scripts/raweb-lookup.sh glossary "text alternative"  # Glossary lookup

# WAI-ARIA APG component patterns
./raweb-code/scripts/raweb-component-lookup.sh list               # List all 30 patterns
./raweb-code/scripts/raweb-component-lookup.sh find "modal"       # Find pattern by keyword
./raweb-code/scripts/raweb-component-lookup.sh show dialog-modal  # Contract: criteria, keyboard, ARIA (markdown tables)
./raweb-code/scripts/raweb-component-lookup.sh show dialog-modal --plain   # Same, as terminal bullets
./raweb-code/scripts/raweb-component-lookup.sh code dialog-modal          # Code examples, all frameworks
./raweb-code/scripts/raweb-component-lookup.sh code dialog-modal react    # Just the React section
./raweb-code/scripts/raweb-component-lookup.sh roles "dialog"     # Find patterns by ARIA role

# Consistency check — fails if a skill cites a criterion or level that
# contradicts the official RAWeb data, or if a "Do" code example does not parse.
# Exit 1 on drift, so it can gate CI. Ships in every RAWeb skill.
./raweb-code/scripts/validate-references.sh
./raweb-audit/scripts/validate-references.sh

# Keep the -code and -audit skills' shared files identical. Each skill ships its
# own references/ and scripts/ so single-skill installs work; this is what stops
# those copies drifting apart.
./scripts/sync-skills.sh            # copy raweb-code → raweb-audit, raam-code → raam-audit
./scripts/sync-skills.sh --check    # exit 1 if they have diverged (CI gate)

# RAAM criteria (mobile) — script lives in raam-code/scripts/ and raam-audit/scripts/
./raam-code/scripts/raam-lookup.sh topics                         # List all 15 topics
./raam-code/scripts/raam-lookup.sh stats                          # Summary statistics
./raam-code/scripts/raam-lookup.sh criterion 9.1                  # Specific criterion
./raam-code/scripts/raam-lookup.sh topic 9                        # All criteria in a topic
./raam-code/scripts/raam-lookup.sh methodology 9.1                # Test procedure (iOS & Android)
./raam-code/scripts/raam-lookup.sh level AA                       # All Level AA criteria
./raam-code/scripts/raam-lookup.sh search "gesture"               # Search by keyword
./raam-code/scripts/raam-lookup.sh glossary "assistive"           # Glossary lookup
```

Requires `jq` (`brew install jq` on macOS, `apt install jq` on Linux).

---
## Reference data

| Framework | Source | Criteria | Themes | Standards |
|-----------|--------|----------|--------|-----------|
| **RAWeb 1.1** | [ReferentielAccessibiliteWeb](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb) | 136 | 17 | EN 301 549, WCAG 2.1 |
| **RAAM 1.1** | [ReferentielAccessibiliteMobile](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteMobile) | 108 | 15 | EN 301 549 v3.2.1, WCAG 2.1 |

All reference data published under **CC-BY 3.0 LU** by Luxembourg's Service information et presse.

Default conformance target: **Level AA**.

---
## Repository structure

Each skill folder is fully self-contained — its scripts and reference JSON ship inside, so installing a single skill (or copying one folder) gives you everything that skill needs.

That means the `-code` and `-audit` skills of a pair hold **identical copies** of `references/` and `scripts/`. The duplication is deliberate; the danger is silent drift. The `-code` skill is the source of truth — **edit `raweb-code/`, then run `scripts/sync-skills.sh`**. Never hand-edit `raweb-audit/references/` or `raweb-audit/scripts/`; `sync-skills.sh --check` will fail CI if they diverge.

```
luxembourg-accessibility-skillset/
├── raweb-code/                         # Web accessible code guidance
│   ├── SKILL.md
│   ├── scripts/
│   │   ├── raweb-lookup.sh             # RAWeb criteria CLI lookup
│   │   ├── raweb-component-lookup.sh   # APG pattern contract + code example lookup
│   │   └── validate-references.sh      # Fails on criterion/level drift (CI gate)
│   └── references/
│       ├── criteres.json               # RAWeb criteria + tests + WCAG mappings
│       ├── glossaire.json              # RAWeb glossary
│       ├── methodologies.json          # RAWeb test procedures
│       ├── themes.json                 # RAWeb topic names
│       ├── niveaux.json                # RAWeb WCAG levels per criterion
│       ├── components/                 # 30 WAI-ARIA APG component patterns
│       │   ├── index.json              # Pattern index with keyword mappings
│       │   └── *.json                  # SOURCE OF TRUTH: ARIA roles/attributes/
│       │                               # values, keyboard interaction, and the
│       │                               # RAWeb criteria each pattern must satisfy.
│       │                               # accordion, alert, alertdialog, breadcrumb,
│       │                               # button, carousel, checkbox, combobox,
│       │                               # dialog-modal, disclosure, feed, grid,
│       │                               # landmarks, link, listbox, menu-button,
│       │                               # menubar, meter, radio, slider,
│       │                               # slider-multithumb, spinbutton, switch,
│       │                               # table, tabs, toolbar, tooltip, treeview,
│       │                               # treegrid, windowsplitter
│       └── patterns/                   # Code examples — all 30 patterns
│           ├── _TEMPLATE.md            # Authoring contract for new patterns
│           └── *.md                    # Dos AND don'ts. Prose + code only —
│                                       # tables are rendered from components/*.json
│                                       #
│                                       # 25 interactive patterns → vanilla + React
│                                       # + Angular + Web Component
│                                       #
│                                       # 5 static patterns → vanilla only (no JS
│                                       # required, so no framework sections):
│                                       # landmarks, link, breadcrumb, table, meter
├── raweb-audit/                        # Web accessibility audit skill
│   ├── SKILL.md                        # Its own — never synced
│   ├── scripts/                        # ⇜ synced from raweb-code/
│   └── references/                     # ⇜ synced from raweb-code/ (incl. patterns/:
│                                       #   the Don't blocks are a defect catalogue and
│                                       #   the Verify sections are test procedures)
├── raam-code/                          # Mobile accessible code guidance
│   ├── SKILL.md
│   ├── scripts/
│   │   └── raam-lookup.sh              # RAAM criteria CLI lookup
│   └── references/
│       ├── criteres.json               # RAAM criteria + tests + EN 301 549 mappings
│       ├── glossaire.json              # RAAM glossary
│       └── methodologies.json          # RAAM test procedures (iOS & Android)
├── raam-audit/                         # Mobile accessibility audit skill
│   ├── SKILL.md                        # Its own — never synced
│   ├── scripts/                        # ⇜ synced from raam-code/
│   └── references/                     # ⇜ synced from raam-code/
├── scripts/
│   └── sync-skills.sh                  # Keeps -code and -audit copies identical
│                                       # (--check exits 1 on drift, for CI)
├── CHANGELOG.md
├── LICENSE
└── README.md
```

---

## Reflections

One thing I've been thinking about lately: **a standardised, shareable JSON format for accessibility audits**.

Right now, every audit tool, every consultancy, every automated checker produces results in its own format, making it nearly impossible to compare, merge, or exchange audit data across tools and teams. A common open standard for audit results (criteria ID, verdict, impact level, remediation, evidence, WCAG/EN 301 549 mapping…) would unlock real cross-compatibility between audit interfaces, APIs, CI pipelines, and reporting dashboards.

If you know of an existing initiative or format working toward this goal (EARL, ACT Rules, something newer?), I'd love to hear about it. And if you have ideas on what such a format should look like, feel free to open an issue or a discussion. This feels like something worth collaborating on.

By the way, I'm building [CheckFox, an accessibility audit manager](https://checkfox.eu/link/github-md) that brings together multiple standards (RAWeb, RGAA, RAAM, RAPDF, WCAG) in a single tool. No more juggling XLS files or manually updating report and statement templates. Everything lives in one place, and generating a polished report or statement takes just one click. Among many others benefits and features like live-collaboration, optional AI helpers, etc.

---

## Contributing

Contributions are welcome! Whether it's improving existing skill instructions, adding code examples for a new framework, fixing criteria references, or helping build the RAPDF skills, all help is appreciated.

**How to contribute:**
1. Fork the repository
2. Create a branch: `git checkout -b feat/your-improvement`
3. Make your changes and test the lookup scripts
4. Open a Pull Request with a clear description

Please keep the skills focused, accurate, and grounded in the official reference JSON data. When in doubt, the source of truth is the official Luxembourg accessibility repositories.

---

## Contributors

| Name | Role | Links |
|------|------|-------|
| [Geoffrey Crofte](https://github.com/geoffreycrofte) | Author of the skillset • UX Lead Designer & Accessibility Officer • Creator of the [Accessibility Audit Tool CheckFox](https://checkfox.eu/link/github-md) | [geoffreycrofte.com](https://geoffreycrofte.com) • [LinkedIn](https://linkedin.com/in/geoffreycrofte) |
| [Alain Vagner](https://github.com/alainvagner) | Publisher of RAWeb & RAAM • [@accessibility-luxembourg](https://github.com/accessibility-luxembourg) | [accessibilite.public.lu](https://accessibilite.public.lu) • [LinkedIn](https://linkedin.com/in/avagner) |

---

## License

- **Skills and scripts**: [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/) • Geoffrey Crofte — see [LICENSE](LICENSE)
- **RAWeb reference data**: [CC-BY 3.0 LU](https://creativecommons.org/licenses/by/3.0/lu/) • Service information et presse, Luxembourg
- **RAAM reference data**: [CC-BY 3.0 LU](https://creativecommons.org/licenses/by/3.0/lu/) • Service information et presse, Luxembourg

The skills are a derivative work of the RAWeb and RAAM referentials. CC-BY 3.0 §4(b)
permits licensing a derivative under a later version of the licence, which is what CC-BY
4.0 here does; attribution to *Service information et presse, Luxembourg* is retained for
the reference data regardless.
