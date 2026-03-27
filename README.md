# Accessibility Skillset <small><small>• v1.2.0</small></small>

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
# Install the full skillset (recommended)
npx skills add geoffreycrofte/luxembourg-accessibility-skillset

# Install globally (available in all projects)
npx skills add geoffreycrofte/luxembourg-accessibility-skillset -g
```

> **Important:** Always install the full repository, not individual skills with `--skill`.
> Each skill relies on shared `references/` and `scripts/` directories via relative paths (`../references/`, `../scripts/`). Installing a single skill in isolation will result in broken lookups and missing reference data.

### Manual installation (Claude Code)

```bash
# Project-level — copy skills AND shared directories
cp -r raweb-code raweb-audit raam-code raam-audit .claude/skills/
cp -r references scripts .claude/skills/

# User-level (all projects)
cp -r raweb-code raweb-audit raam-code raam-audit ~/.claude/skills/
cp -r references scripts ~/.claude/skills/
```

> **Note:** The `references/` and `scripts/` directories must be siblings of the skill folders for the lookup commands to work.

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

```bash
# RAWeb criteria (web)
./scripts/raweb-lookup.sh topics                       # List all 17 topics
./scripts/raweb-lookup.sh stats                        # Summary statistics
./scripts/raweb-lookup.sh criterion 11.1               # Specific criterion
./scripts/raweb-lookup.sh topic 11                     # All criteria in a topic
./scripts/raweb-lookup.sh methodology 11.1.1           # Test procedure
./scripts/raweb-lookup.sh level AA                     # All Level AA criteria
./scripts/raweb-lookup.sh search "form"                # Search by keyword
./scripts/raweb-lookup.sh glossary "text alternative"  # Glossary lookup

# WAI-ARIA APG component patterns
./scripts/raweb-component-lookup.sh list               # List all 30 patterns
./scripts/raweb-component-lookup.sh find "modal"       # Find pattern by keyword
./scripts/raweb-component-lookup.sh show dialog-modal  # Full pattern details
./scripts/raweb-component-lookup.sh roles "dialog"     # Find patterns by ARIA role

# RAAM criteria (mobile)
./scripts/raam-lookup.sh topics                        # List all 15 topics
./scripts/raam-lookup.sh stats                         # Summary statistics
./scripts/raam-lookup.sh criterion 9.1                 # Specific criterion
./scripts/raam-lookup.sh topic 9                       # All criteria in a topic
./scripts/raam-lookup.sh methodology 9.1               # Test procedure (iOS & Android)
./scripts/raam-lookup.sh level AA                      # All Level AA criteria
./scripts/raam-lookup.sh search "gesture"              # Search by keyword
./scripts/raam-lookup.sh glossary "assistive"           # Glossary lookup
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

```
luxembourg-accessibility-skillset/
├── raweb-code/
│   └── SKILL.md                        # Web accessible code guidance
├── raweb-audit/
│   └── SKILL.md                        # Web accessibility audit skill
├── raam-code/
│   └── SKILL.md                        # Mobile accessible code guidance
├── raam-audit/
│   └── SKILL.md                        # Mobile accessibility audit skill
├── references/
│   ├── raweb/
│   │   ├── criteres.json               # RAWeb criteria + tests + WCAG mappings
│   │   ├── glossaire.json              # RAWeb glossary
│   │   ├── methodologies.json          # RAWeb test procedures
│   │   ├── themes.json                 # RAWeb topic names
│   │   ├── niveaux.json                # RAWeb WCAG levels per criterion
│   │   └── components/                 # WAI-ARIA APG component patterns
│   │       ├── index.json              # Pattern index with keyword mappings
│   │       ├── accordion.json          # Accordion pattern
│   │       ├── alert.json              # Alert pattern
│   │       ├── alertdialog.json        # Alert dialog pattern
│   │       ├── breadcrumb.json         # Breadcrumb pattern
│   │       ├── button.json             # Button pattern
│   │       ├── carousel.json           # Carousel/slideshow pattern
│   │       ├── checkbox.json           # Checkbox pattern
│   │       ├── combobox.json           # Combobox/autocomplete pattern
│   │       ├── dialog-modal.json       # Modal dialog pattern
│   │       ├── disclosure.json         # Show/hide (details) pattern
│   │       ├── feed.json               # Infinite scroll feed pattern
│   │       ├── grid.json               # Interactive data grid pattern
│   │       ├── landmarks.json          # Page landmarks pattern
│   │       ├── link.json               # Link pattern
│   │       ├── listbox.json            # Listbox/select pattern
│   │       ├── menu-button.json        # Menu button pattern
│   │       ├── menubar.json            # Menu and menubar pattern
│   │       ├── meter.json              # Meter/gauge pattern
│   │       ├── radio.json              # Radio group pattern
│   │       ├── slider.json             # Slider/range pattern
│   │       ├── slider-multithumb.json  # Multi-thumb slider pattern
│   │       ├── spinbutton.json         # Spinbutton/stepper pattern
│   │       ├── switch.json             # Toggle switch pattern
│   │       ├── table.json              # Static data table pattern
│   │       ├── tabs.json               # Tabs pattern
│   │       ├── toolbar.json            # Toolbar pattern
│   │       ├── tooltip.json            # Tooltip pattern
│   │       ├── treeview.json           # Tree view pattern
│   │       ├── treegrid.json           # Treegrid pattern
│   │       └── windowsplitter.json     # Window splitter pattern
│   └── raam/
│       ├── criteres.json               # RAAM criteria + tests + EN 301 549 mappings
│       ├── glossaire.json              # RAAM glossary
│       └── methodologies.json          # RAAM test procedures (iOS & Android)
├── scripts/
│   ├── raweb-lookup.sh                 # RAWeb criteria CLI lookup
│   ├── raweb-component-lookup.sh       # WAI-ARIA APG component pattern lookup
│   └── raam-lookup.sh                  # RAAM criteria CLI lookup
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
