#!/usr/bin/env bash
# RAWeb 1.1 Criteria Lookup Script
# Usage: raweb-lookup.sh <command> [args]
#
# Commands:
#   criterion <topic.criterion>     Show a specific criterion (e.g., 1.1, 11.3)
#   topic <number>                  Show all criteria for a topic (e.g., 1, 11)
#   methodology <topic.crit.test>   Show test methodology (e.g., 1.1.1, 11.3.1)
#   level <A|AA>                    List all criteria at a given WCAG level
#   search <keyword>                Search criteria by keyword
#   glossary <term>                 Search glossary by term
#   topics                          List all 17 topics
#   stats                           Show criteria count summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_DIR="${SCRIPT_DIR}/../references"

CRITERES="${REF_DIR}/criteres.json"
METHODOLOGIES="${REF_DIR}/methodologies.json"
GLOSSAIRE="${REF_DIR}/glossaire.json"
THEMES="${REF_DIR}/themes.json"
NIVEAUX="${REF_DIR}/niveaux.json"

check_deps() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required. Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
        exit 1
    fi
}

cmd_topics() {
    echo "=== RAWeb 1.1 Topics ==="
    jq -r 'to_entries[] | "  \(.key). \(.value.title)"' "$THEMES"
}

cmd_stats() {
    echo "=== RAWeb 1.1 Statistics ==="
    local total
    total=$(jq '[.topics[].criteria | length] | add' "$CRITERES")
    local level_a
    level_a=$(jq -r '[to_entries[] | select(.value == "A")] | length' "$NIVEAUX")
    local level_aa
    level_aa=$(jq -r '[to_entries[] | select(.value == "AA")] | length' "$NIVEAUX")
    echo "  Total criteria: ${total}"
    echo "  Level A:  ${level_a}"
    echo "  Level AA: ${level_aa}"
    echo "  Topics:   17"
}

cmd_criterion() {
    local ref="$1"
    local topic_num="${ref%%.*}"
    local crit_num="${ref#*.}"

    local topic_title
    topic_title=$(jq -r --arg n "$topic_num" '.[$n].title' "$THEMES")

    local level
    level=$(jq -r --arg r "$ref" '.[$r] // "unknown"' "$NIVEAUX")

    echo "=== RAWeb 1.1 — Criterion ${ref} (Level ${level}) ==="
    echo "Topic ${topic_num}: ${topic_title}"
    echo ""

    jq -r --argjson tn "$topic_num" --argjson cn "$crit_num" '
        .topics[] | select(.number == $tn) |
        .criteria[] | select(.criterium.number == $cn) |
        .criterium |
        "Title: \(.title)\n\nTests:",
        (.tests | to_entries[] | "  \(.key): \(.value | join("\n      "))"),
        "\nReferences:",
        (.references[] | to_entries[] | "  \(.key): \(.value | join(", "))")
    ' "$CRITERES"
}

cmd_topic() {
    local topic_num="$1"
    local topic_title
    topic_title=$(jq -r --arg n "$topic_num" '.[$n].title' "$THEMES")

    echo "=== RAWeb 1.1 — Topic ${topic_num}: ${topic_title} ==="
    echo ""

    jq -r --argjson tn "$topic_num" '
        .topics[] | select(.number == $tn) |
        .criteria[] | .criterium |
        "  \($tn).\(.number) [\(
            if .references then
                (.references[] | to_entries[] | select(.key == "wcag") | .value[0] // "") // ""
            else "" end
        )] \(.title)"
    ' "$CRITERES"
}

cmd_methodology() {
    local ref="$1"
    echo "=== RAWeb 1.1 — Test Methodology ${ref} ==="
    echo ""
    jq -r --arg r "$ref" '.[$r] // "No methodology found for \($r)"' "$METHODOLOGIES"
}

cmd_level() {
    local target_level="${1^^}"
    echo "=== RAWeb 1.1 — Level ${target_level} Criteria ==="
    echo ""
    jq -r --arg l "$target_level" '
        to_entries[] | select(.value == $l) | .key
    ' "$NIVEAUX" | sort -t. -k1,1n -k2,2n | while read -r ref; do
        local topic_num="${ref%%.*}"
        local crit_num="${ref#*.}"
        local title
        title=$(jq -r --argjson tn "$topic_num" --argjson cn "$crit_num" '
            .topics[] | select(.number == $tn) |
            .criteria[] | select(.criterium.number == $cn) |
            .criterium.title
        ' "$CRITERES")
        echo "  ${ref}: ${title}"
    done
}

cmd_search() {
    local keyword="$1"
    echo "=== RAWeb 1.1 — Search: \"${keyword}\" ==="
    echo ""
    jq -r --arg k "$keyword" '
        .topics[] as $t |
        $t.criteria[] | .criterium |
        select(.title | test($k; "i")) |
        "  \($t.number).\(.number): \(.title)"
    ' "$CRITERES"
}

cmd_glossary() {
    local term="$1"
    echo "=== RAWeb 1.1 — Glossary: \"${term}\" ==="
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
        [[ -z "${2:-}" ]] && { echo "Usage: $0 criterion <topic.criterion> (e.g., 1.1, 11.3)"; exit 1; }
        cmd_criterion "$2"
        ;;
    topic|t)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 topic <number> (e.g., 1, 11)"; exit 1; }
        cmd_topic "$2"
        ;;
    methodology|method|m)
        [[ -z "${2:-}" ]] && { echo "Usage: $0 methodology <topic.crit.test> (e.g., 1.1.1)"; exit 1; }
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
        echo "RAWeb 1.1 Criteria Lookup"
        echo ""
        echo "Commands:"
        echo "  topics                          List all 17 topics"
        echo "  stats                           Show criteria count summary"
        echo "  criterion <topic.criterion>     Show a specific criterion (e.g., 1.1)"
        echo "  topic <number>                  Show all criteria for a topic (e.g., 11)"
        echo "  methodology <topic.crit.test>   Show test methodology (e.g., 1.1.1)"
        echo "  level <A|AA>                    List criteria at a given WCAG level"
        echo "  search <keyword>                Search criteria by keyword"
        echo "  glossary <term>                 Search glossary by term"
        ;;
    *)
        echo "Unknown command: $1. Run '$0 help' for usage." >&2
        exit 1
        ;;
esac
