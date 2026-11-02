# RAAM 1.1 — Flutter code examples

Companion to the *Core rules* in `SKILL.md`: the rules and their criterion numbers
live there; this file only shows them applied. Headings match the SKILL.md topics;
a topic missing here has no Flutter-specific example yet.

## 1. Graphic Elements (Topic 1)

#### Flutter

```dart
// Informative image
Image.asset(
  'assets/chart.png',
  semanticsLabel: 'Sales increased 40% in Q3 2024',
)

// Decorative image
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/decoration.png'),
)
```
