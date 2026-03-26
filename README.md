# Luxembourg Accessibility Skillset

Agent skills for [RAWeb](https://accessibilite.public.lu/en/raweb1.1/index.html), RAM, and RAPDF — Luxembourg's official accessibility frameworks based on EN 301 549 and WCAG 2.1.

Compatible with [skills.sh](https://skills.sh) and the [Agent Skills open standard](https://agentskills.io). Works with Claude Code, Cursor, Gemini CLI, GitHub Copilot, and 30+ other AI coding agents.

## Available Skills

| Skill | Description | Status |
|-------|-------------|--------|
| **raweb-code** | Write accessible code conforming to RAWeb 1.1 | ✅ Ready |
| **raweb-audit** | Audit existing code against RAWeb 1.1 criteria | ✅ Ready |
| **ram-code** | Write accessible mobile apps (RAM) | 🔜 Planned |
| **ram-audit** | Audit mobile apps against RAM | 🔜 Planned |
| **rapdf-code** | Generate accessible PDFs (RAPDF) | 🔜 Planned |
| **rapdf-audit** | Audit PDFs against RAPDF | 🔜 Planned |

## Installation

### Via npx (recommended)

```bash
# Install all skills
npx skills add geoffreycrofte/luxembourg-accessibility-skillset

# Install a specific skill
npx skills add geoffreycrofte/luxembourg-accessibility-skillset --skill raweb-code

# Install globally (available in all projects)
npx skills add geoffreycrofte/luxembourg-accessibility-skillset -g
```

### Manual installation (Claude Code)

```bash
# Project-level
cp -r raweb-code .claude/skills/
cp -r raweb-audit .claude/skills/
cp -r references .claude/skills/raweb-code/
cp -r references .claude/skills/raweb-audit/
cp -r scripts .claude/skills/raweb-code/
cp -r scripts .claude/skills/raweb-audit/

# User-level (all projects)
cp -r raweb-code ~/.claude/skills/
cp -r raweb-audit ~/.claude/skills/
# ... same for references and scripts
```

## Usage

### Development guidance (raweb-code)

The `raweb-code` skill activates automatically when you write front-end code. It provides:
- Inline accessible code patterns for all 17 RAWeb themes
- Code examples for common components (forms, tables, navigation, modals, etc.)
- Pre-commit accessibility checklist
- Lookup commands for specific RAWeb criteria and test methodologies

You can also invoke it explicitly: `/raweb-code`

### Accessibility audit (raweb-audit)

Use `/raweb-audit` followed by a file path or component description to run a structured RAWeb 1.1 audit. It provides:
- Theme-by-theme systematic evaluation
- Structured report with conformance rates
- Severity classification (Critical / Major / Minor)
- Actionable remediation with code examples
- Code scanning patterns for common violations

### Lookup script

A standalone lookup tool is included for querying RAWeb criteria:

```bash
./scripts/raweb-lookup.sh topics                    # List all 17 topics
./scripts/raweb-lookup.sh stats                     # Summary statistics
./scripts/raweb-lookup.sh criterion 11.1            # Specific criterion
./scripts/raweb-lookup.sh topic 11                  # All criteria in a topic
./scripts/raweb-lookup.sh methodology 11.1.1        # Test procedure
./scripts/raweb-lookup.sh level AA                  # All Level AA criteria
./scripts/raweb-lookup.sh search "form"             # Search by keyword
./scripts/raweb-lookup.sh glossary "text alternative" # Glossary lookup
```

Requires `jq` (`brew install jq` on macOS, `apt install jq` on Linux).

## Reference data

All criteria, test methodologies, and glossary come from the official [ReferentielAccessibiliteWeb](https://github.com/accessibility-luxembourg/ReferentielAccessibiliteWeb) repository, published under **CC-BY 3.0 LU** by Luxembourg's Service information et presse.

- **RAWeb version**: 1.1
- **WCAG version**: 2.1
- **EN 301 549**: Harmonised European Standard
- **Criteria**: 136+ across 17 themes
- **Default conformance target**: Level AA

## Repository structure

```
luxembourg-accessibility-skillset/
├── raweb-code/
│   └── SKILL.md              # Development guidance skill
├── raweb-audit/
│   └── SKILL.md              # Audit skill
├── references/
│   └── raweb/
│       ├── criteres.json     # All criteria with tests & WCAG mappings
│       ├── glossaire.json    # Accessibility glossary
│       ├── methodologies.json # Step-by-step test procedures
│       ├── themes.json       # Topic names
│       └── niveaux.json      # WCAG levels per criterion
├── scripts/
│   └── raweb-lookup.sh       # CLI lookup tool
├── LICENSE
└── README.md
```

## License

- **Skills and scripts**: See [LICENSE](LICENSE) file
- **RAWeb reference data**: [CC-BY 3.0 LU](https://creativecommons.org/licenses/by/3.0/lu/) — Service information et presse, Luxembourg
