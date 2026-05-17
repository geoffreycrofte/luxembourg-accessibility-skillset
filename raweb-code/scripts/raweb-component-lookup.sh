#!/usr/bin/env bash
# RAWeb Component Pattern Lookup Script
# Usage: raweb-component-lookup.sh <command> [args]
#
# Commands:
#   find <keyword>        Find component patterns matching a keyword (e.g., "modal", "tab", "menu")
#   show <slug>           Show full pattern details for a component (e.g., "dialog-modal", "tabs")
#   list                  List all available component patterns
#   roles <role>          Find patterns using a specific ARIA role (e.g., "dialog", "tablist")

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMP_DIR="${SCRIPT_DIR}/../references/components"
INDEX="${COMP_DIR}/index.json"

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
        exit 1
    fi
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
    # Search in index keywords and aliases
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

cmd_show() {
    local slug="$1"
    local file="${COMP_DIR}/${slug}.json"

    if [[ ! -f "$file" ]]; then
        echo "Error: No component pattern found for '${slug}'." >&2
        echo "Run '$0 list' to see available patterns, or '$0 find <keyword>' to search." >&2
        exit 1
    fi

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
        if (.aria.optional_attributes | length) > 0 then
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
        [[ -z "${2:-}" ]] && { echo "Usage: $0 show <slug> (e.g., dialog-modal, tabs)"; exit 1; }
        cmd_show "$2"
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
        echo "  list                  List all available component patterns"
        echo "  find <keyword>        Find patterns matching a keyword (e.g., modal, tab)"
        echo "  show <slug>           Show full pattern details (e.g., dialog-modal, tabs)"
        echo "  roles <role>          Find patterns using an ARIA role (e.g., dialog, tablist)"
        ;;
    *)
        echo "Unknown command: $1. Run '$0 help' for usage." >&2
        exit 1
        ;;
esac
