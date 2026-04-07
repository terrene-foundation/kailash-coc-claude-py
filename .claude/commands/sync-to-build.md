---
description: "Merge artifacts with variant overlays from loom/ into BUILD repos (kailash-py, kailash-rs)"
---

Merge CC+CO+COC artifacts from loom/ (source of truth) into BUILD repos, applying variant overlays. This is a **merge**, not a copy — BUILD repos have legitimate local content that must be preserved and understood.

**Usage**: `/sync-to-build [target]`

- `target`: `py`, `rs`, or `all`. If omitted, ask.

## Critical: This Is Not rsync

BUILD repos contain three kinds of content:

| Kind                 | Examples                                                 | Action                                          |
| -------------------- | -------------------------------------------------------- | ----------------------------------------------- |
| **Shared**           | Global agents, rules, commands, guides, hooks            | Update from source (with variant overlay)       |
| **BUILD-specific**   | Internal crate docs, binding agents, BUILD-only commands | **Preserve** — never overwrite, never delete    |
| **Stale duplicates** | Old-numbered skills superseded by globals                | Flag for human review (may need manual cleanup) |

Before writing ANY file, you MUST read the target's existing content to understand what's there.

## Process

### 1. Resolve BUILD repo

Read `sync-manifest.yaml` → `repos.{target}.build` to get the BUILD repo name. Resolve to absolute path.

### 2. Inventory the BUILD repo (READ FIRST)

Before computing what to push, read what the BUILD repo already has:

1. List ALL directories under BUILD `.claude/skills/` — note any that use different numbering than loom/ source
2. List ALL agents, commands, rules — note BUILD-specific files
3. If skill numbering diverges from source, **STOP and report** — do not blindly push canonical-numbered skills on top of a differently-numbered tree

### 3. Compute expected state

For each file in loom/.claude/ that's in a tier (cc/co/coc) and not excluded:

- If a variant exists for this target → use variant version
- Otherwise → use global

### 4. Per-file merge decisions

For each file, compare source against BUILD repo and decide:

**UNCHANGED**: source and BUILD have identical content → skip

**NEW (safe)**: file exists in source but not in BUILD → add it. No risk.

**MODIFIED — shared artifact**: file exists in both, content differs, file IS in loom/ source (global or variant):

- Read BOTH versions before deciding
- If BUILD version is the global/variant content with minor drift → safe to update
- If BUILD version has BUILD-specific adaptations (internal paths, crate references, SDK internals) that the source doesn't have → **flag for human review**. The BUILD may have legitimately diverged.

**BUILD-ONLY**: file exists in BUILD but not in source:

- **Never touch**. These are BUILD-repo artifacts (internal agents, crate docs, binding skills, etc.)
- List them for awareness but take no action.

**NUMBERING CONFLICT**: BUILD has a skill at the same number but different name/topic:

- **STOP**. Do not overwrite. Report the conflict. This requires human decision:
  - Rename the BUILD skill to avoid the conflict?
  - Add the global under a different local path?
  - Skip this skill for now?

### 5. Present merge plan

Group by decision type. For MODIFIED files, show what would change:

```
## Merge Plan: loom/ → kailash-rs/

### Safe updates (shared artifacts, no BUILD-specific content)
- rules/agents.md (+3 -1)
- rules/security.md (unchanged — verify, was already current)
- guides/claude-code/07-the-hook-system.md (+28 -1)
... (N files)

### Flagged for review (BUILD may have diverged)
- skills/02-dataflow/dataflow-express.md
  Source: 48 lines (py variant condensed)
  BUILD:  366 lines (rs-specific expanded content)
  → [K]eep BUILD  [U]pdate from source  [D]iff?

### BUILD-only (preserved, no action)
- agents/rust-architect.md
- agents/bindings/python-binding.md
... (N files)

### Numbering conflicts (requires human decision)
- skills/09-: source=workflow-patterns, BUILD=coc-reference
  → [R]ename BUILD  [S]kip source  [D]iff?

### Scripts/hooks (always updated — these are infrastructure)
- session-start.js (+15 -8)
- user-prompt-rules-reminder.js (+3 -1)

→ Proceed with safe updates? [Y/N]
→ Review flagged files individually? [Y/N]
```

### 6. Apply approved changes

Apply ONLY what the human approved. Scripts/hooks are always updated (they're CC infrastructure, not content).

### 7. Update VERSION

If `.claude/VERSION` exists, update `upstream.build_version`. If it doesn't exist, create it per the spec in `guides/co-setup/08-versioning.md`.

## Exclusions (never synced)

- `sync-manifest.yaml`, `variants/` — source-only
- `learning/` — per-repo data
- `.proposals/`, `settings.local.json` — per-repo
- `CLAUDE.md` — repo-specific (never overwritten)

## Delegate

Delegate to **coc-sync** agent for overlay computation. The merge decisions and flagging require reading BUILD content — do NOT delegate file writing without the merge review.
