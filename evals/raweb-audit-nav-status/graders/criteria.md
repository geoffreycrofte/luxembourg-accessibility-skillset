---
type: llm
---

PASS if the audit: flags role="menu"/"menuitem" on site navigation as the wrong pattern (a plain list of links should be used); flags the status message as non-compliant because RAWeb's status-message criterion (7.5) requires aria-atomic="true" alongside aria-live (or role="status"); gives verdicts using RAWeb criterion numbers (not only WCAG numbers) with C / NC / NA or equivalent; and recommends a human review.
FAIL if it accepts role="menu" for site navigation, accepts bare aria-live="polite" as compliant, or cites status messages under a criterion other than 7.5.
