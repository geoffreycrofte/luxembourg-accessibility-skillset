# Accessibility Skillset <small><small>• v1.3.0</small></small>

Agent skills for [RAWeb](https://accessibilite.public.lu/en/raweb1.1/index.html), [RAAM](https://accessibilite.public.lu/en/raam1.1/index.html), and RAPDF, Luxembourg's official accessibility frameworks based on EN 301 549 and WCAG 2.1.

Compatible with [skills.sh](https://skills.sh) and the [Agent Skills open standard](https://agentskills.io). Works with Claude Code, Cursor, Gemini CLI, GitHub Copilot, and 30+ other AI coding agents.

## Available Skills

| Skill | Framework | Description | Status |
|-------|-----------|-------------|--------|
| **raweb-code** | RAWeb 1.1 | Write accessible web code (HTML/CSS/JS) | ✅ Ready |
| **raweb-audit** | RAWeb 1.1 | Audit web code against RAWeb criteria | ✅ Ready |
| **raam-code** | RAAM 1.1 | Write accessible mobile apps (iOS/Android/RN/Flutter) | ✅ Ready |
| **raam-audit** | RAAM 1.1 | Audit mobile apps against RAAM criteria | ✅ Ready |
| **rapdf-code** | RAPDF | Generate accessible PDFs | 🔜 Planned |
| **rapdf-audit** | RAPDF | Audit PDFs against RAPDF criteria | 🔜 Planned |

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

### Web development • RAWeb

The `raweb-code` skill activates automatically when you write front-end web code. It provides:
- Inline accessible code patterns for all 17 RAWeb themes
- Code examples for common components (forms, tables, navigation, modals, etc.)
- Pre-commit accessibility checklist
- Lookup commands for specific RAWeb criteria and test methodologies

Invoke explicitly with `/raweb-code`. Audit with `/raweb-audit`.

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
./raweb-code/scripts/raweb-component-lookup.sh show dialog-modal  # Full pattern details
./raweb-code/scripts/raweb-component-lookup.sh roles "dialog"     # Find patterns by ARIA role

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

## Reference data

| Framework | Source | Criteria | Themes | Standards |
|-----------|--------|----------|--------|-----------|
| **RAWeb 1.1** | [ReferentielAccessibiliteWeb](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb) | 136 | 17 | EN 301 549, WCAG 2.1 |
| **RAAM 1.1** | [ReferentielAccessibiliteMobile](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteMobile) | 108 | 15 | EN 301 549 v3.2.1, WCAG 2.1 |

All reference data published under **CC-BY 3.0 LU** by Luxembourg's Service information et presse.

Default conformance target: **Level AA**.

## Repository structure

Each skill folder is fully self-contained — its scripts and reference JSON ship inside, so installing a single skill (or copying one folder) gives you everything that skill needs.

```
luxembourg-accessibility-skillset/
├── raweb-code/                         # Web accessible code guidance
│   ├── SKILL.md
│   ├── scripts/
│   │   ├── raweb-lookup.sh             # RAWeb criteria CLI lookup
│   │   └── raweb-component-lookup.sh   # WAI-ARIA APG component pattern lookup
│   └── references/
│       ├── criteres.json               # RAWeb criteria + tests + WCAG mappings
│       ├── glossaire.json              # RAWeb glossary
│       ├── methodologies.json          # RAWeb test procedures
│       ├── themes.json                 # RAWeb topic names
│       ├── niveaux.json                # RAWeb WCAG levels per criterion
│       └── components/                 # 30 WAI-ARIA APG component patterns
│           ├── index.json              # Pattern index with keyword mappings
│           └── *.json                  # accordion, alert, alertdialog, breadcrumb,
│                                       # button, carousel, checkbox, combobox,
│                                       # dialog-modal, disclosure, feed, grid,
│                                       # landmarks, link, listbox, menu-button,
│                                       # menubar, meter, radio, slider,
│                                       # slider-multithumb, spinbutton, switch,
│                                       # table, tabs, toolbar, tooltip, treeview,
│                                       # treegrid, windowsplitter
├── raweb-audit/                        # Web accessibility audit skill
│   ├── SKILL.md
│   ├── scripts/                        # Same scripts as raweb-code/
│   └── references/                     # Same JSON as raweb-code/
├── raam-code/                          # Mobile accessible code guidance
│   ├── SKILL.md
│   ├── scripts/
│   │   └── raam-lookup.sh              # RAAM criteria CLI lookup
│   └── references/
│       ├── criteres.json               # RAAM criteria + tests + EN 301 549 mappings
│       ├── glossaire.json              # RAAM glossary
│       └── methodologies.json          # RAAM test procedures (iOS & Android)
├── raam-audit/                         # Mobile accessibility audit skill
│   ├── SKILL.md
│   ├── scripts/                        # Same script as raam-code/
│   └── references/                     # Same JSON as raam-code/
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Reflections

One thing I've been thinking about lately: **a standardised, shareable JSON format for accessibility audits**.

Right now, every audit tool, every consultancy, every automated checker produces results in its own format, making it nearly impossible to compare, merge, or exchange audit data across tools and teams. A common open standard for audit results (criteria ID, verdict, impact level, remediation, evidence, WCAG/EN 301 549 mapping…) would unlock real cross-compatibility between audit interfaces, APIs, CI pipelines, and reporting dashboards.

If you know of an existing initiative or format working toward this goal (EARL, ACT Rules, something newer?), I'd love to hear about it. And if you have ideas on what such a format should look like, feel free to open an issue or a discussion. This feels like something worth collaborating on.

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
| [Geoffrey Crofte](https://github.com/geoffreycrofte) | Author of the skillset • UX Lead Designer & Accessibility Officer | [geoffreycrofte.com](https://geoffreycrofte.com) • [LinkedIn](https://linkedin.com/in/geoffreycrofte) |
| [Alain Vagner](https://github.com/alainvagner) | Publisher of RAWeb & RAAM • [@accessibility-luxembourg](https://github.com/accessibility-luxembourg) | [accessibilite.public.lu](https://accessibilite.public.lu) • [LinkedIn](https://linkedin.com/in/avagner) |

---

## License

- **Skills and scripts**: See [LICENSE](LICENSE) file
- **RAWeb reference data**: [CC-BY 3.0 LU](https://creativecommons.org/licenses/by/3.0/lu/) • Service information et presse, Luxembourg
- **RAAM reference data**: [CC-BY 3.0 LU](https://creativecommons.org/licenses/by/3.0/lu/) • Service information et presse, Luxembourg
