#!/usr/bin/env bash
# Keep the -code and -audit skills' shared files identical.
#
# WHY THIS EXISTS
#   Each skill folder ships its own references/ and scripts/ so that installing a
#   single skill works out of the box (see CHANGELOG 1.3.0). That duplication is
#   deliberate. The risk is drift: nothing stops the copies diverging, and they
#   already did once — a change to raweb-code/scripts/ left raweb-audit running
#   an older, buggier lookup.
#
#   Duplication is fine. UNCHECKED duplication is the bug. This script is the
#   check.
#
# SOURCE OF TRUTH
#   The -code skill of each pair. Arbitrary but pinned: edit raweb-code/, then
#   run this. Never hand-edit raweb-audit/references/ or raweb-audit/scripts/ —
#   your change will be overwritten.
#
# NOT COPIED
#   SKILL.md — each skill's instructions are its own.
#
# Usage:
#   scripts/sync-skills.sh            copy source → target
#   scripts/sync-skills.sh --check    exit 1 if anything differs (CI gate)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

# source_skill:target_skill
PAIRS=(
    "raweb-code:raweb-audit"
    "raam-code:raam-audit"
)

drift=0
copied=0

sync_path() {
    local src="$1" dst="$2" label="$3"

    [[ -e "$src" ]] || return 0

    if $CHECK_ONLY; then
        if ! diff -rq "$src" "$dst" &>/dev/null; then
            echo "  ✗ ${label} differs"
            drift=$((drift + 1))
        fi
        return 0
    fi

    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -R "$src" "$dst"
    copied=$((copied + 1))
    echo "  → ${label}"
}

for pair in "${PAIRS[@]}"; do
    source_skill="${pair%%:*}"
    target_skill="${pair##*:}"

    [[ -d "${ROOT}/${source_skill}" && -d "${ROOT}/${target_skill}" ]] || continue

    echo "=== ${source_skill} → ${target_skill} ==="

    sync_path "${ROOT}/${source_skill}/references" \
              "${ROOT}/${target_skill}/references" \
              "${target_skill}/references/"

    # Scripts are copied file by file: a skill may legitimately have its own.
    for script in "${ROOT}/${source_skill}/scripts/"*.sh; do
        [[ -e "$script" ]] || continue
        name="$(basename "$script")"
        sync_path "$script" "${ROOT}/${target_skill}/scripts/${name}" \
                  "${target_skill}/scripts/${name}"
    done
done

echo ""
if $CHECK_ONLY; then
    if [[ $drift -eq 0 ]]; then
        echo "PASS — skills are in sync."
        exit 0
    fi
    echo "FAIL — ${drift} path(s) out of sync. Run: scripts/sync-skills.sh"
    exit 1
fi

echo "Synced ${copied} path(s)."
echo "Review with 'git diff', then commit."
