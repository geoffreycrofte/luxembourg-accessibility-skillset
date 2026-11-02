---
name: raam-code
description: >
  Develop accessible mobile applications (iOS and Android) conforming to RAAM 1.1
  (Luxembourg Mobile Accessibility Assessment Framework, based on EN 301 549 v3.2.1
  / WCAG 2.1). Use when building native mobile apps, React Native, Flutter, or any
  mobile UI that must meet Luxembourg accessibility law. Covers all 15 RAAM themes
  with platform-specific code guidance. Default conformance target: Level AA.
license: CC-BY-4.0
metadata:
  author: Geoffrey Crofte
  version: "1.6.0"
  raam-version: "1.1"
  wcag-version: "2.1"
  en301549-version: "3.2.1"
  repository: https://github.com/geoffreycrofte/luxembourg-accessibility-skillset
  reference: https://github.com/accessibility-luxembourg/ReferentielAccessibiliteMobile
  reference-license: CC-BY-3.0-LU
allowed-tools: Bash Read Grep
---

# RAAM 1.1 — Accessible Mobile Development Guide

You are an accessibility-aware mobile developer. Every piece of iOS, Android,
React Native, or Flutter code you write MUST conform to **RAAM 1.1** (Level AA
by default). RAAM is Luxembourg's official mobile accessibility assessment
framework implementing EN 301 549 v3.2.1 and WCAG 2.1.

## How to use the reference data

The full RAAM 1.1 criteria, test methodologies, and glossary are available as
JSON files. Use the lookup script to query specific criteria on demand:

```bash
# List all topics
!`${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topics`

# Look up a specific criterion
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh criterion 9.1

# Look up test methodology
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh methodology 9.1

# Search criteria by keyword
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh search "form"

# Check glossary definition
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh glossary "assistive technologies"
```

The raw JSON reference files are located at:
- `${CLAUDE_SKILL_DIR}/references/criteres.json` — All 108 criteria with tests, levels, and EN 301 549 mappings
- `${CLAUDE_SKILL_DIR}/references/methodologies.json` — Step-by-step test procedures (iOS & Android)
- `${CLAUDE_SKILL_DIR}/references/glossaire.json` — Glossary of mobile accessibility terms

When writing code for a specific component, ALWAYS look up the relevant RAAM
criteria first. For example, before writing a form, run `search "form"` and `topic 9`.

---

## Core rules (apply to ALL mobile code you write)

**Code examples** for each topic below are in one file per platform, under the same
topic heading. Read the file for the platform you are writing before you write code:

| Platform | File |
|----------|------|
| iOS (SwiftUI, UIKit) | `${CLAUDE_SKILL_DIR}/references/examples/ios.md` |
| Android (Compose, XML Views) | `${CLAUDE_SKILL_DIR}/references/examples/android.md` |
| React Native | `${CLAUDE_SKILL_DIR}/references/examples/react-native.md` |
| Flutter | `${CLAUDE_SKILL_DIR}/references/examples/flutter.md` |

Not every topic has an example for every platform: when one is missing, apply the rule
with the platform's equivalent API (see the quick reference below).

### 1. Graphic Elements (Topic 1)

**ALWAYS:**
- Every decorative graphic element MUST be ignored by assistive technologies (1.1)
- Every informative graphic element MUST have an accessible alternative (1.2)
- Text alternatives must be relevant — describe what the element conveys (1.3)
- CAPTCHA graphic elements must describe their nature/function, not the answer (1.4)
- Complex graphics (charts, maps) need a detailed description (1.6, 1.7)
- Avoid text in graphic elements unless the effect cannot be reproduced with styled text (1.8 — Level AA)

### 2. Colours (Topic 2)

- Information MUST NOT be conveyed by colour alone — always add shape, text, or icon (2.1)
- Text contrast: at least **4.5:1** (normal text) or **3:1** (large text ≥24px / bold ≥18.5px) (2.2 — Level AA)
- Non-text element contrast (icons, borders, UI controls): at least **3:1** (2.3 — Level AA)
- If contrast is insufficient by default, a replacement mechanism must exist and itself be accessible (2.4 — Level AA)

### 3. Multimedia (Topic 3)

- Audio-only media MUST have a text transcript (3.1, 3.2)
- Video-only media MUST have a text transcript, audio description, or audio-only alternative (3.3, 3.4)
- Synchronised media MUST have captions (3.7, 3.8)
- Synchronised media MUST have audio description (3.9, 3.10 — Level AA)
- Media MUST be identified by an adjacent text label outside the player (3.11)
- Auto-playing audio must last ≤3 seconds or provide a stop/mute control (3.12)
- Media player MUST provide: play, pause/stop, mute, and caption/AD toggles (3.13)
- Caption and AD controls must be at the same level as play/pause (3.14 — Level AA)

### 4. Tables (Topic 4)

- Data tables MUST have headers correctly associated with data cells (4.1, 4.2, 4.3)
- Complex tables MUST have a title and summary to explain structure (4.4, 4.5)

### 5. Interactive Components (Topic 5)

**This is critical for mobile. Always look up: `bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 5`**

- Every interactive component MUST be keyboard/switch accessible (5.1)
- Every interactive component MUST have a relevant accessible name (5.2)
- Accessible names MUST include any visible text (5.3)
- Screen reader users must receive context changes (5.4 — Level AA)
- Interactive component states (selected, expanded, disabled) MUST be rendered by assistive technologies (5.5)

### 6. Mandatory Elements (Topic 6)

- Every screen MUST have a title announced by assistive technologies (6.1)
- Default human language of the app MUST be identifiable by assistive technologies (6.2)

### 7. Information Structure (Topic 7)

- Content must use semantic headings exposed to assistive technologies (7.1)
- Significant elements must use appropriate semantics (lists, headings, etc.) (7.2)

### 8. Presentation of Information (Topic 8)

- Content must remain visible and functional when text is enlarged to 200% via system settings (8.1)
- No loss of information or functionality at 200% enlargement (8.2 — Level AA)
- On screens ≥ 320px CSS equivalent, content must not require both horizontal and vertical scrolling (8.2)
- Landscape AND portrait orientations MUST be supported unless a specific orientation is essential (8.3)
- Focus indicator must be visible on all interactive elements (8.4)
- Content revealed on hover/focus must be dismissable, hoverable, and persistent (8.5)
- Content hidden from screen but exposed to AT must still be accessible (8.6)
- Content that appears on focus/hover must not obstruct other content without a dismiss mechanism (8.7 — Level AA)

### 9. Forms (Topic 9)

**Critical topic for mobile apps. Always look up: `bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 9`**

- Every form field MUST have an accessible label (9.1)
- Labels must be relevant (9.2)
- Accessible name must include visible label text (9.3)
- Related fields must be grouped with a group label (9.4)
- Same-purpose fields must be identifiable programmatically across the app (9.5)
- Required fields must be indicated (9.7)
- Required fields' indication must be accessible (9.8)
- Error messages must be linked to the field and describe expected format (9.9)
- Input suggestions on error must be relevant (9.10 — Level AA)
- User must be able to review/modify/confirm data before final submission (9.11 — Level AA)
- Autocomplete for personal data fields (9.12 — Level AA)

### 10. Navigation (Topic 10)

- Every interactive component must be accessible and operable by keyboard and any pointing device (10.1)
- The application must not contain any keyboard or focus traps (10.2)
- Tab/swipe order must be consistent with visual reading order (10.3)
- Keyboard shortcuts using a single key must be controllable (disable, remap, or only active on focus) (10.4)

### 11. Consultation (Topic 11)

- No automatic refresh without user control (11.1)
- User must be able to control each time limit (extend, remove, or ≥20h) (11.2)
- Moving/blinking content must have a pause/stop mechanism (11.3, 11.4)
- No flashing content > 3 flashes per second (11.5)
- Abrupt context changes must be triggered by user action only, or user must be able to disable them (11.6, 11.7)
- Content viewable regardless of screen orientation (portrait/landscape) unless essential (11.8)
- Gestures: complex gestures (multi-pointer, path-based) must have single-pointer alternatives (11.9 — Level AA)
- Touch actions must use up-event (release), not down-event (press); or provide undo mechanism (11.10)
- Pointer target size must be at least 24×24 CSS px (11.14 — Level AA)
- Dragging actions must have a single-pointer alternative (11.15)
- Motion-triggered actions (shake, tilt) must have UI alternatives and be disableable (11.16)

**Minimum touch target sizes:**
```swift
// iOS: Apple recommends 44×44 pt minimum
.frame(minWidth: 44, minHeight: 44)

// RAAM 1.1 criterion 11.14: 24×24 CSS px minimum (AA)
// Using 44pt is safer and exceeds the requirement
```

```kotlin
// Android: minimum 48dp (exceeds RAAM's 24px requirement)
Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)
```

### 12–15. Extended Topics (EN 301 549)

These topics cover documentation, editing tools, support services, and real-time
communication. Query them individually when relevant:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 12  # Documentation & accessibility features
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 13  # Editing tools
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 14  # Support services
bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh topic 15  # Real-time communication
```

Key rules for these topics:
- Documentation must describe accessibility features and how to use them (12.1 — Level AA)
- Accessibility features must not be removed or deactivated (12.3)
- Editing tools must support creation of accessible content (13.1–13.6)
- Support services must communicate accessibility info (14.1–14.3)
- Real-time text communication must meet EN 301 549 requirements (15.1–15.11)

---

## Platform-specific accessibility APIs — Quick reference

| Feature | iOS (SwiftUI) | iOS (UIKit) | Android (Compose) | Android (XML) | React Native | Flutter |
|---------|---------------|-------------|-------------------|---------------|--------------|---------|
| Label | `.accessibilityLabel()` | `.accessibilityLabel` | `Modifier.semantics { contentDescription }` | `contentDescription` | `accessibilityLabel` | `Semantics(label:)` |
| Hint | `.accessibilityHint()` | `.accessibilityHint` | `Modifier.semantics { stateDescription }` | — | `accessibilityHint` | `Semantics(hint:)` |
| Hidden | `.accessibilityHidden(true)` | `.isAccessibilityElement = false` | `Modifier.semantics { invisibleToUser() }` | `importantForAccessibility="no"` | `accessible={false}` | `ExcludeSemantics()` |
| Heading | `.accessibilityAddTraits(.isHeader)` | `.accessibilityTraits = .header` | `Modifier.semantics { heading() }` | `accessibilityHeading` | `accessibilityRole="header"` | `Semantics(header: true)` |
| Button | `.accessibilityAddTraits(.isButton)` | `.accessibilityTraits = .button` | `Modifier.semantics { role = Role.Button }` | `role="button"` | `accessibilityRole="button"` | `Semantics(button: true)` |
| Live region | `.accessibilityAddTraits(.updatesFrequently)` | `.accessibilityTraits = .updatesFrequently` | `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` | `accessibilityLiveRegion="polite"` | `accessibilityLiveRegion="polite"` | `Semantics(liveRegion:)` |

---

## Pre-commit checklist (apply before finalizing any code)

- [ ] All informative graphic elements have accessible alternatives
- [ ] All decorative graphic elements are hidden from assistive technologies
- [ ] Colour is never the sole means of conveying information
- [ ] Text contrast ≥ 4.5:1 (normal) / 3:1 (large)
- [ ] All interactive elements are reachable via screen reader swipe navigation
- [ ] All interactive elements are operable by keyboard/switch access
- [ ] Component states (expanded, selected, disabled) are exposed to AT
- [ ] Every screen has a title announced by AT
- [ ] App language is declared for AT pronunciation
- [ ] Headings use proper accessibility traits/semantics
- [ ] All form fields have associated labels
- [ ] Required fields are indicated accessibly
- [ ] Error messages are linked to their fields and describe expected input
- [ ] Autocomplete is set for personal data fields
- [ ] Both portrait and landscape orientations work
- [ ] Content scales correctly with system font size (200%)
- [ ] Complex gestures have single-pointer alternatives
- [ ] Touch targets are at least 44×44pt (iOS) / 48×48dp (Android)
- [ ] No keyboard/focus traps exist
- [ ] No auto-playing media without controls

---

## When in doubt

1. Look up the specific RAAM criterion: `bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh criterion <topic.criterion>`
2. Check the test methodology (includes iOS AND Android steps): `bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh methodology <topic.criterion>`
3. Consult the glossary: `bash ${CLAUDE_SKILL_DIR}/scripts/raam-lookup.sh glossary "<term>"`
4. Use native platform components over custom ones — they have built-in accessibility
5. Test with VoiceOver (iOS) and TalkBack (Android) mentally: would every element be announced correctly?
