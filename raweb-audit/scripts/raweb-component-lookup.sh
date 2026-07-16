#!/usr/bin/env bash
# RAWeb Component Pattern Lookup Script
# Usage: raweb-component-lookup.sh <command> [args]
#
# Commands:
#   find <keyword>            Find component patterns matching a keyword (e.g., "modal", "tab", "menu")
#   show <slug> [--plain]     Show full pattern details as markdown tables (--plain for terminal bullets)
#   code <slug> [framework]   Show code examples (framework: vanilla|react|angular|web-component)
#   list                      List all available component patterns
#   roles <role>              Find patterns using a specific ARIA role (e.g., "dialog", "tablist")
#
# The JSON files under references/components/ are the single source of truth for
# keyboard interactions, ARIA attributes and RAWeb criteria mappings. Criterion
# levels and official titles are resolved at render time from niveaux.json and
# criteres.json, so they can never drift.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_DIR="${SCRIPT_DIR}/../references"
COMP_DIR="${REF_DIR}/components"
PATTERNS_DIR="${REF_DIR}/patterns"
INDEX="${COMP_DIR}/index.json"
CRITERES="${REF_DIR}/criteres.json"
NIVEAUX="${REF_DIR}/niveaux.json"

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
        exit 1
    fi
}

# Resolve a component slug to its JSON file, or exit with guidance.
resolve_slug() {
    local slug="$1"
    local file="${COMP_DIR}/${slug}.json"
    if [[ ! -f "$file" ]]; then
        echo "Error: No component pattern found for '${slug}'." >&2
        echo "Run '$0 list' to see available patterns, or '$0 find <keyword>' to search." >&2
        exit 1
    fi
    echo "$file"
}

cmd_list() {
    echo "=== Available WAI-ARIA APG Component Patterns ==="
    echo ""
    jq -r '.patterns[] | "  \(.slug) — \(.name)"' "$INDEX"
}

cmd_find() {
    local keyword
    keyword=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    echo "=== Component Patterns matching: \"${keyword}\" ==="
    echo ""
    local matches
    matches=$(jq -r --arg k "$keyword" '
        .patterns[] |
        select(
            (.slug | test($k; "i")) or
            (.name | test($k; "i")) or
            (.keywords[] | test($k; "i"))
        ) | "  \(.slug) — \(.name) [\(.keywords | join(", "))]"
    ' "$INDEX")

    if [[ -z "$matches" ]]; then
        echo "  No patterns found for \"${keyword}\"."
        echo "  Try: list, or search with a broader term."
    else
        echo "$matches"
    fi
}

# Render the RAWeb criteria table, joining the component's criteria mapping with
# the official level (niveaux.json) and title (criteres.json).
render_criteria() {
    local file="$1"
    local has
    has=$(jq -r 'if (.raweb_criteria // []) | length > 0 then "yes" else "no" end' "$file")
    [[ "$has" == "no" ]] && return 0

    echo "### RAWeb criteria"
    echo ""
    echo "| Criterion | Level | Requirement | Why it applies to this pattern |"
    echo "|---|---|---|---|"

    jq -r '.raweb_criteria[] | "\(.id)\t\(.reason)"' "$file" | while IFS=$'\t' read -r id reason; do
        local topic_num="${id%%.*}"
        local crit_num="${id#*.}"
        local level title
        level=$(jq -r --arg r "$id" '.[$r] // "?"' "$NIVEAUX")
        # Strip the glossary markdown links from the official title for table use.
        title=$(jq -r --argjson tn "$topic_num" --argjson cn "$crit_num" '
            .topics[] | select(.number == $tn) |
            .criteria[] | select(.criterium.number == $cn) |
            .criterium.title
            | gsub("\\[(?<t>[^\\]]+)\\]\\([^)]*\\)"; .t)
            | gsub("\\|"; "\\|")
        ' "$CRITERES")
        echo "| ${id} | ${level} | ${title} | ${reason} |"
    done
    echo ""
}

render_markdown() {
    local file="$1"
    local slug
    slug=$(jq -r '.slug' "$file")

    jq -r '
        "## \(.name)",
        "",
        .description,
        ""
    ' "$file"

    local native
    native=$(jq -r '.native_element // empty' "$file")
    [[ -n "$native" ]] && { echo "**Prefer the native element:** \`${native}\`"; echo ""; }

    local code_ref
    code_ref=$(jq -r '.code_examples // empty' "$file")
    if [[ -n "$code_ref" && -f "${REF_DIR}/${code_ref}" ]]; then
        echo "**Code examples:** \`references/${code_ref}\`"
        echo "Run \`$(basename "$0") code ${slug} [vanilla|react|angular|web-component]\` for a single framework."
        echo ""
    fi

    render_criteria "$file"

    echo "### Keyboard interaction"
    echo ""
    echo "| Key | Action |"
    echo "|---|---|"
    jq -r '.keyboard_interactions[] | "| `\(.key)` | \(.action | gsub("\\|"; "\\|")) |"' "$file"
    echo ""

    echo "### ARIA roles"
    echo ""
    echo "| Role | On element | Notes |"
    echo "|---|---|---|"
    jq -r '.aria.roles[] | "| `\(.role)` | \(.element // "container") | \(.description // "—" | gsub("\\|"; "\\|")) |"' "$file"
    echo ""

    echo "### Required ARIA attributes"
    echo ""
    echo "| Attribute | On element | Values / states | Purpose |"
    echo "|---|---|---|---|"
    jq -r '
        .aria.required_attributes[] |
        "| `\(.attribute)` | \(.element) | \(
            if .values then (.values | map("`" + . + "`") | join(" / ")) else "—" end
        ) | \(.description | gsub("\\|"; "\\|")) |"
    ' "$file"
    echo ""

    local opt_count
    opt_count=$(jq -r '(.aria.optional_attributes // []) | length' "$file")
    if [[ "$opt_count" -gt 0 ]]; then
        echo "### Optional ARIA attributes"
        echo ""
        echo "| Attribute | On element | Values / states | Purpose |"
        echo "|---|---|---|---|"
        jq -r '
            .aria.optional_attributes[] |
            "| `\(.attribute)` | \(.element) | \(
                if .values then (.values | map("`" + . + "`") | join(" / ")) else "—" end
            ) | \(.description | gsub("\\|"; "\\|")) |"
        ' "$file"
        echo ""
    fi

    local notes_count
    notes_count=$(jq -r '(.notes // []) | length' "$file")
    if [[ "$notes_count" -gt 0 ]]; then
        echo "### Implementation notes"
        echo ""
        jq -r '.notes[] | "- \(.)"' "$file"
        echo ""
    fi
}

render_plain() {
    local file="$1"
    jq -r '
        "=== \(.name) Pattern ===",
        "",
        "Description: \(.description)",
        "",
        "--- Keyboard Interactions ---",
        (.keyboard_interactions[] | "  \(.key): \(.action)"),
        "",
        "--- ARIA Roles ---",
        (.aria.roles[] | "  \(.role) — on: \(.element // "container") — \(.description // "")"),
        "",
        "--- Required ARIA Attributes ---",
        (.aria.required_attributes[] | "  \(.attribute) — on: \(.element) — \(.description)"),
        "",
        if ((.aria.optional_attributes // []) | length) > 0 then
            "--- Optional ARIA Attributes ---",
            (.aria.optional_attributes[] | "  \(.attribute) — on: \(.element) — \(.description)")
        else empty end,
        "",
        if .notes then
            "--- Notes ---",
            (.notes[] | "  • \(.)")
        else empty end
    ' "$file"
}

cmd_show() {
    local slug="$1"
    local format="${2:---md}"
    local file
    file=$(resolve_slug "$slug")

    case "$format" in
        --plain) render_plain "$file" ;;
        --md|"")  render_markdown "$file" ;;
        *) echo "Unknown format: ${format}. Use --md (default) or --plain." >&2; exit 1 ;;
    esac
}

cmd_code() {
    local slug="$1"
    local framework="${2:-}"
    local file="${PATTERNS_DIR}/${slug}.md"

    if [[ ! -f "$file" ]]; then
        echo "No code examples yet for '${slug}'." >&2
        echo "Available patterns with code examples:" >&2
        if compgen -G "${PATTERNS_DIR}/*.md" >/dev/null; then
            for f in "${PATTERNS_DIR}"/*.md; do
                local base
                base="$(basename "$f" .md)"
                [[ "$base" == _* ]] && continue
                echo "  ${base}" >&2
            done
        fi
        echo "Fall back to '$0 show ${slug}' for the ARIA and keyboard contract." >&2
        exit 1
    fi

    if [[ -z "$framework" ]]; then
        cat "$file"
        return 0
    fi

    # Extract the "## <Framework>" section up to the next "## " heading.
    local section
    section=$(awk -v want="$framework" '
        BEGIN { want = tolower(want); gsub(/[^a-z0-9]+/, "", want); found = 0 }
        /^## / {
            heading = tolower(substr($0, 4))
            gsub(/[^a-z0-9]+/, "", heading)
            found = (heading == want)
            if (found) { print; next }
        }
        found { print }
    ' "$file")

    if [[ -z "$section" ]]; then
        echo "No '${framework}' section in ${slug}.md. Sections available:" >&2
        grep -E '^## ' "$file" | sed 's/^## /  /' >&2
        exit 1
    fi
    echo "$section"
}

cmd_roles() {
    local role
    role=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    echo "=== Patterns using role: \"${role}\" ==="
    echo ""
    for file in "${COMP_DIR}"/*.json; do
        [[ "$(basename "$file")" == "index.json" ]] && continue
        local match
        match=$(jq -r --arg r "$role" '
            select(.aria.roles[]? | .role | test($r; "i")) |
            "  \(.slug) — \(.name)"
        ' "$file" 2>/dev/null)
        [[ -n "$match" ]] && echo "$match"
    done
}

check_deps

case "${1:-help}" in
    find|f)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 find <keyword> (e.g., modal, tab, menu)"; exit 1; }
        cmd_find "$2"
        ;;
    show|s)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 show <slug> [--plain] (e.g., dialog-modal, tabs)"; exit 1; }
        cmd_show "$2" "${3:---md}"
        ;;
    code|c)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 code <slug> [vanilla|react|angular|web-component]"; exit 1; }
        cmd_code "$2" "${3:-}"
        ;;
    list|l)
        cmd_list
        ;;
    roles|r)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 roles <role> (e.g., dialog, tablist)"; exit 1; }
        cmd_roles "$2"
        ;;
    help|--help|-h)
        echo "RAWeb Component Pattern Lookup"
        echo ""
        echo "Commands:"
        echo "  list                       List all available component patterns"
        echo "  find <keyword>             Find patterns matching a keyword (e.g., modal, tab)"
        echo "  show <slug> [--plain]      Show the ARIA/keyboard/RAWeb contract as markdown tables"
        echo "  code <slug> [framework]    Show code examples (vanilla|react|angular|web-component)"
        echo "  roles <role>               Find patterns using an ARIA role (e.g., dialog, tablist)"
        ;;
    *)
        echo "Unknown command: $1. Run '$0 help' for usage." >&2
        exit 1
        ;;
esac
