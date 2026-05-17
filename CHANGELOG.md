# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
