#!/usr/bin/env bash
# RAAM 1.1 Criteria Lookup Script (Mobile Accessibility)
# Usage: raam-lookup.sh <command> [args]
#
# Commands:
#   criterion <topic.criterion>     Show a specific criterion (e.g., 1.1, 9.3)
#   topic <number>                  Show all criteria for a topic (e.g., 1, 9)
#   methodology <topic.criterion>   Show test methodology (e.g., 1.1, 9.3)
#   level <A|AA>                    List all criteria at a given WCAG level
#   search <keyword>                Search criteria by keyword
#   glossary <term>                 Search glossary by term
#   topics                          List all 15 topics
#   stats                           Show criteria count summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_DIR="${SCRIPT_DIR}/../references"

CRITERES="${REF_DIR}/criteres.json"
METHODOLOGIES="${REF_DIR}/methodologies.json"
GLOSSAIRE="${REF_DIR}/glossaire.json"

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
        exit 1
    fi
}

cmd_topics() {
    echo "=== RAAM 1.1 Topics ==="
    jq -r '.topics[] | "  \(.number). \(.topic)"' "$CRITERES"
}

cmd_stats() {
    echo "=== RAAM 1.1 Statistics ==="
    local total
    total=$(jq '[.topics[].criteria | length] | add' "$CRITERES")
    local level_a
    level_a=$(jq '[.topics[].criteria[].criterium | select(.level == "A")] | length' "$CRITERES")
    local level_aa
    level_aa=$(jq '[.topics[].criteria[].criterium | select(.level == "AA")] | length' "$CRITERES")
    echo "  Total criteria: ${total}"
    echo "  Level A:  ${level_a}"
    echo "  Level AA: ${level_aa}"
    echo "  Topics:   15"
    echo "  Platform: iOS & Android"
    echo "  Standards: EN 301 549 v3.2.1, WCAG 2.1"
}

cmd_criterion() {
    local ref="$1"
    local topic_num="${ref%%.*}"
    local crit_num="${ref#*.}"

    echo "=== RAAM 1.1 — Criterion ${ref} ==="
    echo ""

    jq -r --argjson tn "$topic_num" --argjson cn "$crit_num" '
        .topics[] | select(.number == $tn) |
        "Topic \(.number): \(.topic)\n" as $header |
        .criteria[] | select(.criterium.number == $cn) |
        .criterium |
        $header +
        "Level: \(.level)\n\n" +
        "Title: \(.title)\n" +
        (if (.tests | length) > 0 then
            "\nTests:\n" +
            (.tests | to_entries | map("  \(.key): \(.value | join("\n      "))") | join("\n"))
        else "" end) +
        "\n\nReferences:" +
        (.references | to_entries | map("\n  \(.key): \(.value | if type == "array" then join(", ") else tostring end)") | join(""))
    ' "$CRITERES"
}

cmd_topic() {
    local topic_num="$1"

    jq -r --argjson tn "$topic_num" '
        .topics[] | select(.number == $tn) |
        "=== RAAM 1.1 — Topic \(.number): \(.topic) ===\n",
        (.criteria[] | .criterium |
            "  \($tn).\(.number) [Level \(.level)] \(.title)")
    ' "$CRITERES"
}

cmd_methodology() {
    local ref="$1"
    echo "=== RAAM 1.1 — Test Methodology ${ref} ==="
    echo ""
    jq -r --arg r "$ref" '.[$r] // "No methodology found for \($r)"' "$METHODOLOGIES"
}

cmd_level() {
    local target_level="${1^^}"
    echo "=== RAAM 1.1 — Level ${target_level} Criteria ==="
    echo ""
    jq -r --arg l "$target_level" '
        .topics[] |
        .number as $tn | .topic as $tt |
        .criteria[] | .criterium |
        select(.level == $l) |
        "  \($tn).\(.number): \(.title)"
    ' "$CRITERES"
}

cmd_search() {
    local keyword="$1"
    echo "=== RAAM 1.1 — Search: \"${keyword}\" ==="
    echo ""
    jq -r --arg k "$keyword" '
        .topics[] |
        .number as $tn |
        .criteria[] | .criterium |
        select(.title | test($k; "i")) |
        "  \($tn).\(.number) [Level \(.level)]: \(.title)"
    ' "$CRITERES"
}

cmd_glossary() {
    local term="$1"
    echo "=== RAAM 1.1 — Glossary: \"${term}\" ==="
    echo ""
    jq -r --arg t "$term" '
        .glossary[] |
        select(.title | test($t; "i")) |
        "--- \(.title) ---\n\(.body | gsub("<[^>]+>"; "") | gsub("&quot;"; "\"") | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&#39;"; "'"'"'"))\n"
    ' "$GLOSSAIRE"
}

check_deps

case "${1:-help}" in
    criterion|crit|c)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 criterion <topic.criterion> (e.g., 1.1, 9.3)"; exit 1; }
        cmd_criterion "$2"
        ;;
    topic|t)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 topic <number> (e.g., 1, 9)"; exit 1; }
        cmd_topic "$2"
        ;;
    methodology|method|m)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 methodology <topic.criterion> (e.g., 1.1, 9.3)"; exit 1; }
        cmd_methodology "$2"
        ;;
    level|l)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 level <A|AA>"; exit 1; }
        cmd_level "$2"
        ;;
    search|s)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 search <keyword>"; exit 1; }
        cmd_search "$2"
        ;;
    glossary|g)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 glossary <term>"; exit 1; }
        cmd_glossary "$2"
        ;;
    topics)
        cmd_topics
        ;;
    stats)
        cmd_stats
        ;;
    help|--help|-h)
        echo "RAAM 1.1 Criteria Lookup (Mobile Accessibility)"
        echo ""
        echo "Commands:"
        echo "  topics                          List all 15 topics"
        echo "  stats                           Show criteria count summary"
        echo "  criterion <topic.criterion>     Show a specific criterion (e.g., 1.1)"
        echo "  topic <number>                  Show all criteria for a topic (e.g., 9)"
        echo "  methodology <topic.criterion>   Show test methodology (e.g., 1.1)"
        echo "  level <A|AA>                    List criteria at a given WCAG level"
        echo "  search <keyword>                Search criteria by keyword"
        echo "  glossary <term>                 Search glossary by term"
        ;;
    *)
        echo "Unknown command: $1. Run '$0 help' for usage." >&2
        exit 1
        ;;
esac
