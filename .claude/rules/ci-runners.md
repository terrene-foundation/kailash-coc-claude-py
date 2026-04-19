---
paths:
  - ".github/workflows/**"
  - "**/ci/**"
  - "**/.github/**"
---

# CI Runner Rules

Self-hosted CI runner hygiene. Language-agnostic — applies to every project using GitHub Actions self-hosted runners regardless of SDK language.

For recovery protocols, service-management commands, and step-by-step troubleshooting, see `skills/10-deployment-git/ci-runner-troubleshooting.md`.

## MUST Rules

### 1. Every Toolchain-Consuming Job Includes A Toolchain Setup Step

Every job that invokes a language toolchain (`cargo`, `maturin`, `rustc`, `npm`, `pnpm`, `bundle`, etc.) MUST include a dedicated toolchain setup step (e.g. `dtolnay/rust-toolchain@stable`, `actions/setup-node`, `ruby/setup-ruby`) as one of its earliest steps — even if a previous job in the same workflow already installed the toolchain.

```yaml
# DO — every job re-establishes its own toolchain
steps:
  - uses: actions/checkout@v4
  - uses: dtolnay/rust-toolchain@stable
  - name: Build
    run: cargo build --release

# DO NOT — relying on a sibling job's toolchain install
steps:
  - uses: actions/checkout@v4
  - name: Build
    run: cargo build --release   # fails if PATH was re-written by an earlier job
```

**Why:** Self-hosted runners do not reset `PATH` between jobs cleanly. A sibling job that reinstalled `rustup` or ran `nvm use` leaves the runner in a state where the proxy binary (`~/.cargo/bin/rustup`, `~/.nvm/...`) may be missing or points to the wrong version. Each job re-establishing its own toolchain is the only structural defense.

### 2. Restart The Runner After Changing Its Environment File

After editing the runner's `.env` file (e.g. `~/actions-runner-*/.env`), the runner MUST be restarted via `launchctl unload && launchctl load` (macOS) or `systemctl restart` (Linux). Running jobs MUST be allowed to complete under the old environment before the restart.

```bash
# DO — explicit unload, wait for in-flight jobs, reload
launchctl unload ~/Library/LaunchAgents/com.github.actions.runner.<name>.plist
# wait for any in-flight job to drain
launchctl load ~/Library/LaunchAgents/com.github.actions.runner.<name>.plist

# DO NOT — edit .env and expect new jobs to pick up changes
vim ~/actions-runner-<name>/.env  # save
# next queued job still reads the old env because the runner process cached it at startup
```

**Why:** The runner daemon reads its `.env` once at process startup. Silent drift between "what operators edited" and "what jobs actually ran with" is invisible until a job fails with a missing variable that the operator can see in the file.

### 3. Post-fmt Cascade Discovery Protocol

When `Format` (or any early short-circuiting gate) transitions from red to green for the first time in a long while, the session MUST expect multiple subsequent failures and budget for multi-wave triage. A red fmt gate short-circuits the pipeline — Clippy, Docs, Deny, Test, MSRV, and Integration Tests are SKIPPED, not failed. Pre-existing failures in those gates accumulate invisibly and surface one-wave-at-a-time once fmt is green.

```yaml
# DO — tight triage loop until all gates green
# push → inspect failing gate → fix root cause → push → repeat
# accept that wave N+1 may reveal a failure wave N masked

# DO NOT — declare victory after fmt goes green
# gh pr checks <N>  # fmt: pass, 6 others: skipped (NOT green)
# git push origin feat/cleanup  # "CI is fixed" — it isn't
```

**BLOCKED rationalizations:**

- "Fmt is green, CI is fixed"
- "The other gates were skipped, so they're passing"
- "We can triage the rest in parallel branches"
- "These failures are pre-existing, not our problem"

**Why:** Short-circuit semantics hide months of accumulated failures behind a single red fmt. Declaring "fixed" after fmt green leaves the downstream backlog to surface on the next unrelated PR, where the failures look like new regressions. Parallel triage branches also break because each wave's fix depends on the previous wave's state.

### 4. Runner Auto-Update Disconnect Recovery

If `gh api repos/<org>/<repo>/actions/runners` returns 0 runners while the runner's stdout log tails show `Connected to GitHub` and `Listening for Jobs`, the runner auto-updated mid-session and its in-flight job is orphaned — the old worker process holds the job in GitHub's state machine but cannot report completion. The session MUST restart the runner service AND trigger a fresh run via an empty commit.

```bash
# DO — re-register the runner and trigger a fresh run
launchctl unload ~/Library/LaunchAgents/com.github.actions.runner.<name>.plist
launchctl load ~/Library/LaunchAgents/com.github.actions.runner.<name>.plist
git commit --allow-empty -m "chore(ci): trigger fresh run post-runner-update"
git push

# DO NOT — rerun the orphaned run; the dead worker still owns the job
gh run rerun <run-id> --failed  # the new worker can't claim the old worker's jobs
```

**BLOCKED rationalizations:**

- "The runner log says Connected, it must be fine"
- "Wait for the hung job to time out on its own"
- "Re-run the failed job, it'll get picked up"

**Why:** The GitHub Actions runner auto-update path renames and replaces the worker binary. Jobs assigned to the dead worker cannot be claimed by the new worker; GitHub's dispatcher needs a new trigger to assign the job. Without the service restart, the "Connected" log is from a fresh worker that never knew about the orphaned job, and the hung run blocks the PR for hours.

### 5. Binding-CI Paths Filter Matches The Core-Lang Pattern

Every binding-channel CI workflow (`python.yml`, `nodejs.yml`, `ruby.yml`, `wasm.yml`, etc.) MUST have a `paths:` filter that covers the transitive dependency graph of the core language, not just the binding directory. Narrow enumerations of specific packages or crates silently stop matching whenever a new transitive dependency is added.

```yaml
# DO — broad filter matches the core-language CI's pattern
on:
  pull_request:
    paths:
      - "bindings/python/**"
      - "crates/**"
      - "Cargo.toml"
      - "Cargo.lock"
      - ".github/workflows/python.yml"

# DO NOT — enumerate specific packages
on:
  pull_request:
    paths:
      - "bindings/python/**"
      - "crates/kailash-capi/**"
      - "crates/kailash-ml*/**"  # misses kailash-core, kailash-nexus, etc.
```

**BLOCKED rationalizations:**

- "The binding only depends on these packages today"
- "Broad filter triggers too many unnecessary builds"
- "We'll update the filter when we add new deps"

**Why:** Bindings transitively link most of a workspace. A narrow filter means a fix to a shared dependency triggers the core CI but skips the binding CI, letting the binding ship broken into the next release. When a shared crate change lands and the binding CI reports "no changes", that is the exact failure mode this rule prevents.

## MUST NOT Rules

### 1. Never Commit Registration Tokens

Runner registration tokens expire after 1 hour and become credentials once committed. MUST NOT commit hardcoded tokens to version control. Always use placeholder `RUNNER_TOKEN="REPLACE_WITH_FRESH_TOKEN"` in setup scripts.

**Why:** A token committed to a public branch is harvested by token scanners within minutes and used to register unauthorized runners into the repository's job queue.

### 2. Every `upload-artifact` Step MUST Use `continue-on-error: true`

GitHub Actions artifact storage has a per-account quota that recalculates every 6-12 hours. When exhausted, `upload-artifact` returns `Failed to CreateArtifact: Artifact storage quota has been hit` and fails the job even though the underlying build succeeded. This masks real build success with an infrastructure billing problem.

Every `actions/upload-artifact@v*` step across ALL workflows MUST include `continue-on-error: true`:

```yaml
# DO
- uses: actions/upload-artifact@v7
  continue-on-error: true
  with:
    name: wheel-${{ matrix.python-version.label }}
    path: target/wheels/*.whl

# DO NOT
- uses: actions/upload-artifact@v7
  with:
    name: wheel-${{ matrix.python-version.label }}
    path: target/wheels/*.whl
```

**BLOCKED rationalizations:**

- "The upload failure is a legitimate build failure"
- "Adding continue-on-error hides real problems"
- "We'll fix it when the quota resets"
- "This only affects release.yml"

**Why:** The failure mode re-surfaces every ~12h on PR CI until someone re-discovers the fix. Codify once, apply everywhere.

Origin: kailash-rs CI cascade waves 6-18 (commits `ecc50c4e..5429928c`, 2026-04-16/17). 12 consecutive waves fixed pre-existing failures hidden by fmt short-circuit. Wave 17 fixup to a shared crate didn't trigger Python/Node/Ruby binding CI because their paths filters excluded the shared-crates tree. Runner auto-update at a trivial commit orphaned one run and required a service restart. Recovery protocols for each MUST rule live in `skills/10-deployment-git/ci-runner-troubleshooting.md`.
