#!/usr/bin/env bash
# First-pass scan for common RAWeb defects in source files.
#
# Usage: raweb-scan.sh [path]     (default: current directory)
#
# Every hit is a LEAD, not a verdict: confirm each one against the criterion's
# tests (raweb-lookup.sh methodology <x.y.z>) before reporting it. An empty
# section proves nothing — most RAWeb criteria cannot be detected by grep.
#
# Audit-only script: not part of the raweb-code → raweb-audit sync.

set -uo pipefail

TARGET="${1:-.}"
if [[ ! -e "$TARGET" ]]; then
    echo "Error: '$TARGET' does not exist." >&2
    exit 2
fi

MARKUP=(--include="*.html" --include="*.htm" --include="*.jsx" --include="*.tsx" --include="*.vue" --include="*.svelte")
STYLES=(--include="*.css" --include="*.scss")

# Each check prints file:line:tag. Tag-based checks extract each opening tag
# first (grep -o), so two tags on one line are judged separately; a tag split
# across several lines is not seen.
g()    { grep -rnE  "$1" "${@:2}" "$TARGET" 2>/dev/null; }
tags() { grep -rnoE "$1" "${@:2}" "$TARGET" 2>/dev/null; }

img_no_alt()     { tags '<img[^>]*>' "${MARKUP[@]}" | grep -vE '[[:space:]]alt(=|[[:space:]]|/?>)'; }
empty_links()    { tags '<a[^>]*>[[:space:]]*</a>' "${MARKUP[@]}"; }
pos_tabindex()   { tags '<[a-zA-Z][^>]*tabindex="?[1-9][^>]*>' "${MARKUP[@]}"; }
onclick_nonint() { tags '<[a-zA-Z][^>]*onclick[^>]*>' "${MARKUP[@]}" | grep -vE ':<(button|a)[[:space:]>]'; }
unlabelled()     { tags '<(input|select|textarea)[^>]*>' "${MARKUP[@]}" \
                     | grep -vE 'aria-label|aria-labelledby|[[:space:]]id=|type="?(hidden|submit|button|reset|image)'; }
autoplay()       { tags '<[a-zA-Z][^>]*autoplay[^>]*>' "${MARKUP[@]}"; }
iframe_title()   { tags '<iframe[^>]*>' "${MARKUP[@]}" | grep -v 'title='; }
html_lang()      { tags '<html[^>]*>' "${MARKUP[@]}" | grep -v 'lang='; }
colour_only()    { g 'color:.*(red|green)|text-(red|green|danger|success)' "${STYLES[@]}"; }

section() {
    local hits
    hits=$("$2" | head -50)
    echo "## $1"
    if [[ -n "$hits" ]]; then echo "$hits"; else echo "  (no hits)"; fi
    echo ""
}

section "Images without alt (Theme 1)"                        img_no_alt
section "Empty links (Theme 6)"                                empty_links
section "Positive tabindex (Theme 12)"                         pos_tabindex
section "onclick on an element other than <button> or <a> (Theme 7)" onclick_nonint
section "Form fields that may lack a label (Theme 11)"         unlabelled
section "Autoplaying media (Themes 4 and 13)"                  autoplay
section "Iframes without title (Theme 2)"                      iframe_title
section "<html> without lang (Theme 8)"                        html_lang
section "Possible colour-only indicators (Theme 3, manual review)" colour_only
