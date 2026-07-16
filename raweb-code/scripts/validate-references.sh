#!/usr/bin/env bash
# Validate that this skill never lies about RAWeb.
#
# Guards the failure mode that matters most for an accessibility skill: an agent
# confidently citing a criterion number or conformance level that is wrong. A
# wrong number in an audit report is worse than no number at all.
#
# Checks:
#   1. Every criterion cited in SKILL.md exists in the official reference data
#   2. Every "(x.y — Level Z)" annotation in SKILL.md matches niveaux.json
#   3. Every raweb_criteria id in components/*.json resolves
#   4. Every code_examples pointer resolves to a file that exists
#   5. Every patterns/<slug>.md has a matching components/<slug>.json
#
# Usage: bash scripts/validate-references.sh   (exit 0 = clean, 1 = drift)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="${SCRIPT_DIR}/.."
REF_DIR="${SKILL_DIR}/references"
COMP_DIR="${REF_DIR}/components"
PATTERNS_DIR="${REF_DIR}/patterns"
CRITERES="${REF_DIR}/criteres.json"
NIVEAUX="${REF_DIR}/niveaux.json"
SKILL_MD="${SKILL_DIR}/SKILL.md"

command -v jq &>/dev/null || { echo "Error: jq is required." >&2; exit 1; }

errors=0
checks=0

fail() { echo "  ✗ $1"; errors=$((errors + 1)); }
pass() { checks=$((checks + 1)); }

level_of() { jq -r --arg r "$1" '.[$r] // "MISSING"' "$NIVEAUX"; }

# Topic numbers are 1-17. Anchored so that version strings ("RAWeb 1.1",
# "WCAG 2.1") and stray decimals ("0.12em", a "4.5:1" contrast ratio) are not
# mistaken for citations.
ID='([1-9]|1[0-7])\.[0-9]{1,2}'

# The two skills cite criteria in DIFFERENT shapes. Miss one and the check
# silently passes on a file it never really read:
#   raweb-code  → "(7.3)" / "(10.4 — Level AA)" / "(1.8, 1.9)"
#   raweb-audit → markdown table rows: "| Frame titles are relevant | 2.2 |"
#                 and prose: "(RAWeb criteria 7.1, 7.3, 12.8)"
extract_citations() {
    local file="$1"
    {
        # "(7.3)" / "(10.4 — Level AA)" — must OPEN with the id
        grep -oE "\\(${ID}[^)]*\\)" "$file" | grep -oE "^\\(${ID}" | tr -d '('
        # "criterion 7.3" / "criteria 7.1, 7.3, 12.8"
        grep -oiE "criteri(on|a) ${ID}(, *${ID})*" "$file" | grep -oE "${ID}"
        # A markdown cell holding ONLY criterion ids: "| 2.2 |" or "| 4.1, 4.3 |"
        grep -oE "\\| *${ID}(, *${ID})* *\\|" "$file" | grep -oE "${ID}"
    } | sort -u -t. -k1,1n -k2,2n
}

echo "=== 1. Criteria cited in SKILL.md exist ==="
for id in $(extract_citations "$SKILL_MD"); do
    if [[ "$(level_of "$id")" == "MISSING" ]]; then
        fail "SKILL.md cites ${id} — not a RAWeb criterion"
    else
        pass
    fi
done
if [[ $checks -eq 0 ]]; then
    # A vacuous pass is worse than a failure: it looks like the file was checked.
    fail "SKILL.md: no criterion citations found at all — the extractor probably does not understand this file's citation style"
else
    echo "  ${checks} citations resolve"
fi

echo "=== 2. Level annotations in SKILL.md match niveaux.json ==="
before=$errors

compare_level() {
    local id="$1" claimed="$2"
    local actual
    actual=$(level_of "$id")
    [[ "$claimed" == "$actual" ]] && return 0
    fail "SKILL.md says ${id} is Level ${claimed}, official data says Level ${actual}"
}

# Shape A — prose: "10.4 — Level AA"
while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    compare_level "$(echo "$match" | grep -oE "^${ID}")" \
                  "$(echo "$match" | grep -oE 'Level (A+)' | awk '{print $2}')"
done < <(grep -oE "${ID} — Level A+" "$SKILL_MD")

# Shape B — table row: "| Non-text contrast ≥ 3:1 — AA | 3.3 |"
# The level lives in the description cell, the id in the last cell. Only rows
# with exactly one id are compared, so "| … (AA) | 4.5, 4.6 |" is skipped rather
# than guessed at.
while IFS= read -r row; do
    [[ -z "$row" ]] && continue
    local_ids=$(echo "$row" | grep -oE "\\| *${ID} *\\|$" | grep -oE "${ID}")
    [[ -z "$local_ids" ]] && continue
    [[ $(echo "$local_ids" | wc -l) -ne 1 ]] && continue
    # Level claimed as "— AA" or "(AA)" in the description cell.
    claimed=$(echo "${row% | *}" | grep -oE '(— |\()A{1,3}\b' | grep -oE 'A{1,3}' | head -1)
    [[ -z "$claimed" ]] && continue
    compare_level "$local_ids" "$claimed"
done < <(grep -E "\\| *${ID} *\\|$" "$SKILL_MD")

[[ $errors -eq $before ]] && echo "  all level annotations correct"

echo "=== 3. components/*.json → raweb_criteria resolve ==="
before=$errors
for f in "${COMP_DIR}"/*.json; do
    [[ "$(basename "$f")" == "index.json" ]] && continue
    slug=$(basename "$f" .json)
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        if [[ "$(level_of "$id")" == "MISSING" ]]; then
            fail "${slug}.json maps to criterion ${id} — does not exist"
            continue
        fi
        topic="${id%%.*}"; crit="${id#*.}"
        title=$(jq -r --argjson tn "$topic" --argjson cn "$crit" \
            '.topics[]|select(.number==$tn)|.criteria[]|select(.criterium.number==$cn)|.criterium.title' "$CRITERES")
        [[ -z "$title" ]] && fail "${slug}.json maps to ${id} — absent from criteres.json"
    done < <(jq -r '.raweb_criteria[]?.id' "$f")
done
[[ $errors -eq $before ]] && echo "  all component criteria mappings resolve"

echo "=== 4. code_examples pointers resolve ==="
before=$errors
for f in "${COMP_DIR}"/*.json; do
    [[ "$(basename "$f")" == "index.json" ]] && continue
    ref=$(jq -r '.code_examples // empty' "$f")
    [[ -z "$ref" ]] && continue
    [[ -f "${REF_DIR}/${ref}" ]] || fail "$(basename "$f") points at references/${ref} — file missing"
done
[[ $errors -eq $before ]] && echo "  all code_examples pointers resolve"

echo "=== 5. patterns/*.md have a matching component JSON ==="
before=$errors
if compgen -G "${PATTERNS_DIR}/*.md" >/dev/null; then
    for f in "${PATTERNS_DIR}"/*.md; do
        slug=$(basename "$f" .md)
        [[ "$slug" == _* ]] && continue
        [[ -f "${COMP_DIR}/${slug}.json" ]] \
            || fail "patterns/${slug}.md has no components/${slug}.json — 'code ${slug}' will work but 'show ${slug}' will not"
    done
fi
[[ $errors -eq $before ]] && echo "  all pattern files are paired"

echo "=== 6. JavaScript in 'Do' examples parses ==="
# Only "### Do" blocks are checked. "### Don't" blocks are deliberately
# fragments (a bare `case:`, a method outside a class) that show the offending
# line in context — they are not meant to parse standalone.
if ! command -v node &>/dev/null; then
    echo "  skipped (node not installed)"
else
    before=$errors
    checked=0
    workdir=$(mktemp -d)
    trap 'rm -rf "$workdir"' EXIT

    if compgen -G "${PATTERNS_DIR}/*.md" >/dev/null; then
        for f in "${PATTERNS_DIR}"/*.md; do
            slug=$(basename "$f" .md)
            [[ "$slug" == _* ]] && continue
            awk -v out="${workdir}/${slug}" '
                /^### Don/ { indo=0; next }   # must precede the "### Do" rule
                /^### Do/  { indo=1; next }
                /^## /     { indo=0 }
                /^```js$/  { if (indo) { n++; f=1; fn=sprintf("%s-%d.js", out, n); next } }
                /^```$/    { f=0; next }
                f          { print > fn }
            ' "$f"
        done
    fi

    for js in "${workdir}"/*.js; do
        [[ -e "$js" && -s "$js" ]] || continue
        checked=$((checked + 1))
        node --check "$js" 2>/dev/null || fail "$(basename "$js" .js): Do-block JS does not parse"
    done
    [[ $errors -eq $before ]] && echo "  ${checked} Do-block JS examples parse"
fi

echo ""
if [[ $errors -eq 0 ]]; then
    echo "PASS — no drift found."
    exit 0
fi
echo "FAIL — ${errors} problem(s) found."
exit 1
