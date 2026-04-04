#!/usr/bin/env bash
# check-manifest-parity.sh — Automated manifest parity check
#
# Validates that sync-manifest.yaml and the variant files on disk are consistent.
# Detects: orphan variants, stale entries, cross-target parity gaps.
#
# Exit codes:
#   0 — Clean (no issues found)
#   1 — Issues found (see report)
#   2 — Script error (missing manifest, bad parse, etc.)
#
# Usage:
#   ./scripts/check-manifest-parity.sh              # Run from loom/
#   ./scripts/check-manifest-parity.sh /path/to/loom # Explicit root

set -euo pipefail

# ─────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────

LOOM_ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
MANIFEST="${LOOM_ROOT}/.claude/sync-manifest.yaml"
VARIANTS_DIR="${LOOM_ROOT}/.claude/variants"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: Manifest not found at $MANIFEST" >&2
  exit 2
fi

if [[ ! -d "$VARIANTS_DIR" ]]; then
  echo "ERROR: Variants directory not found at $VARIANTS_DIR" >&2
  exit 2
fi

# Declared targets (extracted from repos: section)
TARGETS=()

# ─────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────

# Temporary files for working sets
MANIFEST_PATHS=$(mktemp)
DISK_PATHS=$(mktemp)
VARIANT_REPLACEMENTS=$(mktemp)  # global-path -> target mappings from variants: section
PARITY_GAPS_FILE=$(mktemp)
trap 'rm -f "$MANIFEST_PATHS" "$DISK_PATHS" "$VARIANT_REPLACEMENTS" "$PARITY_GAPS_FILE"' EXIT

# ─────────────────────────────────────────────────────────────────
# STEP 1: Extract declared targets from repos: section
# ─────────────────────────────────────────────────────────────────

extract_targets() {
  local in_repos=false
  local indent=""
  while IFS= read -r line; do
    # Detect repos: section start
    if [[ "$line" =~ ^repos: ]]; then
      in_repos=true
      continue
    fi
    # Exit repos section when we hit a non-indented line (or another top-level key)
    if $in_repos; then
      if [[ "$line" =~ ^[a-z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
        break
      fi
      # Target keys are at 2-space indent: "  py:", "  rs:", "  rb:"
      if [[ "$line" =~ ^[[:space:]]{2}([a-z]+):$ ]]; then
        TARGETS+=("${BASH_REMATCH[1]}")
      fi
    fi
  done < "$MANIFEST"
}

extract_targets

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "ERROR: No targets found in repos: section of manifest" >&2
  exit 2
fi

# ─────────────────────────────────────────────────────────────────
# STEP 2: Extract ALL variant paths declared in manifest
# ─────────────────────────────────────────────────────────────────
# We parse two sections:
#   variants:   → replacement mappings (global-path: {target: variant-path})
#   variant_only: → addition lists ({target: [variant-path, ...]})

extract_manifest_paths() {
  local section=""       # "variants" | "variant_only" | ""
  local current_global="" # For variants: section, the current global path key
  local current_target="" # For variant_only: section, the current target key

  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    # Detect top-level section changes
    if [[ "$line" =~ ^variants: ]]; then
      section="variants"
      current_global=""
      continue
    elif [[ "$line" =~ ^variant_only: ]]; then
      section="variant_only"
      current_target=""
      continue
    elif [[ "$line" =~ ^[a-z_]+: ]] && [[ "$section" != "" ]]; then
      # Hit another top-level key — end of our sections
      section=""
      continue
    fi

    case "$section" in
      variants)
        # Global path key (2-space indent, ends with colon):
        #   "  rules/patterns.md:"
        if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_/.-]+):$ ]]; then
          current_global="${BASH_REMATCH[1]}"
          continue
        fi
        # Target mapping (4-space indent):
        #   "    py: variants/py/rules/patterns.md"
        if [[ "$line" =~ ^[[:space:]]{4}([a-z]+):[[:space:]]+(variants/[a-zA-Z0-9_./-]+) ]]; then
          local target="${BASH_REMATCH[1]}"
          local vpath="${BASH_REMATCH[2]}"
          echo "$vpath" >> "$MANIFEST_PATHS"
          # Record replacement mapping for parity gap analysis
          echo "${current_global}|${target}" >> "$VARIANT_REPLACEMENTS"
        fi
        ;;
      variant_only)
        # Target key (2-space indent): "  py:"
        if [[ "$line" =~ ^[[:space:]]{2}([a-z]+):$ ]]; then
          current_target="${BASH_REMATCH[1]}"
          continue
        fi
        # Empty array marker: "    []"
        [[ "$line" =~ ^[[:space:]]+\[\]$ ]] && continue
        # List item (4-space indent):
        #   "    - variants/py/agents/frameworks/infrastructure-specialist.md"
        if [[ "$line" =~ ^[[:space:]]{4}-[[:space:]]+(variants/[a-zA-Z0-9_./-]+) ]]; then
          echo "${BASH_REMATCH[1]}" >> "$MANIFEST_PATHS"
        fi
        ;;
    esac
  done < "$MANIFEST"
}

extract_manifest_paths

# Sort and deduplicate manifest paths
sort -u "$MANIFEST_PATHS" -o "$MANIFEST_PATHS"

# ─────────────────────────────────────────────────────────────────
# STEP 3: Find ALL variant files on disk
# ─────────────────────────────────────────────────────────────────

find_disk_paths() {
  for target in "${TARGETS[@]}"; do
    local target_dir="${VARIANTS_DIR}/${target}"
    if [[ -d "$target_dir" ]]; then
      find "$target_dir" -type f \( -name '*.md' -o -name '*.js' -o -name '*.json' -o -name '*.sh' -o -name '*.yaml' -o -name '*.yml' \) | while read -r filepath; do
        # Convert absolute path to relative (from .claude/)
        echo "${filepath#${LOOM_ROOT}/.claude/}"
      done
    fi
  done | sort -u > "$DISK_PATHS"
}

find_disk_paths

# Exclude the variants/README.md from disk paths (it's a documentation file, not a variant)
grep -v '^variants/README\.md$' "$DISK_PATHS" > "${DISK_PATHS}.tmp" && mv "${DISK_PATHS}.tmp" "$DISK_PATHS"

# ─────────────────────────────────────────────────────────────────
# STEP 4: Compute orphans and stale entries
# ─────────────────────────────────────────────────────────────────

# Orphans: on disk but NOT in manifest
ORPHANS=$(comm -23 "$DISK_PATHS" "$MANIFEST_PATHS")

# Stale: in manifest but NOT on disk
STALE=$(comm -13 "$DISK_PATHS" "$MANIFEST_PATHS")

# ─────────────────────────────────────────────────────────────────
# STEP 5: Compute parity gaps
# ─────────────────────────────────────────────────────────────────
# For each global path in the variants: section, check which targets
# have variants. If some targets have a variant but others don't,
# that's a parity gap.
#
# Note: We only check entries in the `variants:` section (replacements),
# not `variant_only:` (those are intentionally single-target).

if [[ -s "$VARIANT_REPLACEMENTS" ]]; then
  # Build target list as a string for comparison
  ALL_TARGETS_STR=""
  for t in "${TARGETS[@]}"; do
    ALL_TARGETS_STR="${ALL_TARGETS_STR} ${t}"
  done

  # Group targets by global path using sort + awk
  # Input: global|target lines, sorted by global
  sort "$VARIANT_REPLACEMENTS" | awk -F'|' '
  {
    if ($1 != prev) {
      if (prev != "") print prev "|" targets
      prev = $1
      targets = $2
    } else {
      targets = targets " " $2
    }
  }
  END { if (prev != "") print prev "|" targets }
  ' | while IFS='|' read -r global declared; do
    missing=""
    for target in "${TARGETS[@]}"; do
      if ! echo " $declared " | grep -q " $target "; then
        missing="${missing} ${target}"
      fi
    done
    if [[ -n "$missing" ]]; then
      has_targets=$(echo "$declared" | sed 's/^ *//;s/ *$//' | tr ' ' ', ')
      missing_targets=$(echo "$missing" | sed 's/^ *//;s/ *$//' | tr ' ' ', ')
      echo "  ${global}"
      echo "    has: ${has_targets}"
      echo "    missing: ${missing_targets}"
    fi
  done > "$PARITY_GAPS_FILE"
fi

# ─────────────────────────────────────────────────────────────────
# STEP 6: Output report
# ─────────────────────────────────────────────────────────────────

orphan_count=0
stale_count=0
parity_count=0
issues_found=false

echo "================================================================"
echo "  MANIFEST PARITY CHECK"
echo "  Manifest: ${MANIFEST}"
echo "  Targets:  ${TARGETS[*]}"
echo "  Date:     $(date +%Y-%m-%d\ %H:%M:%S)"
echo "================================================================"
echo ""

# --- ORPHAN VARIANTS ---
echo "--- ORPHAN VARIANTS (files on disk without manifest entries) ---"
if [[ -n "$ORPHANS" ]]; then
  while IFS= read -r orphan; do
    echo "  $orphan"
    orphan_count=$((orphan_count + 1))
  done <<< "$ORPHANS"
  issues_found=true
else
  echo "  (none)"
fi
echo ""

# --- STALE ENTRIES ---
echo "--- STALE ENTRIES (manifest entries without files on disk) ---"
if [[ -n "$STALE" ]]; then
  while IFS= read -r stale_entry; do
    echo "  $stale_entry"
    stale_count=$((stale_count + 1))
  done <<< "$STALE"
  issues_found=true
else
  echo "  (none)"
fi
echo ""

# --- PARITY GAPS ---
echo "--- PARITY GAPS (variants missing for some targets) ---"
if [[ -s "$PARITY_GAPS_FILE" ]]; then
  cat "$PARITY_GAPS_FILE"
  issues_found=true
else
  echo "  (none)"
fi
echo ""

# --- SUMMARY ---
echo "--- SUMMARY ---"

# Recount for summary since subshell vars don't propagate
orphan_count=0
if [[ -n "$ORPHANS" ]]; then
  orphan_count=$(echo "$ORPHANS" | wc -l | tr -d ' ')
fi

stale_count=0
if [[ -n "$STALE" ]]; then
  stale_count=$(echo "$STALE" | wc -l | tr -d ' ')
fi

parity_count=0
if [[ -s "$PARITY_GAPS_FILE" ]]; then
  parity_count=$(grep -c '^  [a-z]' "$PARITY_GAPS_FILE" || true)
fi

total_manifest=$(wc -l < "$MANIFEST_PATHS" | tr -d ' ')
total_disk=$(wc -l < "$DISK_PATHS" | tr -d ' ')
total_issues=$((orphan_count + stale_count + parity_count))

echo "  Variant files on disk:     $total_disk"
echo "  Variant entries in manifest: $total_manifest"
echo "  Orphan variants:           $orphan_count"
echo "  Stale entries:             $stale_count"
echo "  Parity gaps:               $parity_count"
echo "  Total issues:              $total_issues"
echo ""

if [[ "$total_issues" -eq 0 ]]; then
  echo "RESULT: CLEAN — manifest and disk are in sync."
  exit 0
else
  echo "RESULT: $total_issues issue(s) found — review above and update sync-manifest.yaml or disk."
  exit 1
fi
