# AI Working Framework

A Go repo skeleton built so humans and any coding agent (Claude Code, Codex, Cursor, ...) can work on it in parallel
without stepping on each other. It keeps the structure and rules, not a product. Extracted from
[youtube-skill](https://github.com/Ivanxiedata/youtube-skill).

Three ideas carry it:
1. **One folder per feature.** Each has its own spec, notes for agents, and `progress.md`. Ten agents can work on ten features without touching the same files.
2. **`progress.md` is the hand-off.** Status, Next, Blockers, Decisions and Log, written for an agent that has never seen the conversation. The next session continues from "Next".
3. **`make check` is the definition of done.** It runs on every commit (git hook) and in CI, and it fails when a rule is broken, not just when tests fail.

## Start a new project (5 minutes)

```sh
gh repo create my-app --private --clone --template Ivanxiedata/AI_Working_FrameWork
cd my-app
make init MODULE=github.com/you/my-app OWNER=@you   # renames the Go module and the CODEOWNERS owner
make setup                                          # git hook + go deps (run in every clone and worktree)
make check                                          # should pass
git switch -c develop && git commit -am "init" && git push -u origin develop
gh repo edit --default-branch develop
```

Then write `docs/product.md` (what you're building, for whom, non-goals). Agents read it before anything else.

**Existing Go repo instead?** Copy in `AGENTS.md`, `CLAUDE.md`, `Makefile`, `scripts/`, `docs/`, `.githooks/`, `.github/`,
`.gitattributes` and `skills.lock`, then run `make init` and `make setup`. `make check` then shows which existing folders
need a spec, `AGENTS.md`, `progress.md` or a row in `docs/features.md`. A folder that is not a feature goes in `reserved` in `scripts/lib.sh`.

## Daily use

**You (the owner)** talk to agents in plain words: "build the billing feature", "review PR 12". You merge PRs into `develop`;
agents never merge. When `develop` is ready, fast-forward `main` to it.

**An agent** reads `AGENTS.md` (Claude Code loads it through `CLAUDE.md`), which tells it to:

```sh
make status                                   # what every feature is doing, what's in flight
make worktree NAME=billing-refunds            # one task = one branch = one worktree
make new-feature NAME=billing DESC="Charges customers"   # only if the task fits no feature
# claim: prefix Status in billing/progress.md with "in progress (billing-refunds): ", commit, push
# write docs/specs/billing.md first, then code and tests
make check                                    # done = this passes
gh pr create --base develop
```

## What `make check` enforces

| Rule | Script |
|---|---|
| Every top-level folder is a feature with a spec, `AGENTS.md`, `progress.md` (Status, Next) and a row in `docs/features.md` | `check-structure.sh` |
| A ticked spec line `- [x] ... -> TestName` names a test that exists in that feature | `check-spec.sh` |
| A feature imports only itself and `shared/`; only `cmd/` wires features together | `check-imports.sh` |
| A branch that changes a feature also updates its `progress.md` (repo-level changes update `docs/progress.md`) | `check-progress.sh` |
| gofmt, go vet, go test -race | `Makefile` |

## What's in the box

| Path | What |
|---|---|
| `AGENTS.md` | The agent's map: session start, claiming, branches, workflow, rules, model routing |
| `CLAUDE.md` | `@AGENTS.md`: one source of truth for every agent |
| `docs/product.md` | What and why (you write this) |
| `docs/architecture.md` | Layout, import rules, how features connect |
| `docs/features.md` | One row per feature; union-merged so parallel branches don't conflict |
| `docs/specs/<feature>.md` | Goal, acceptance criteria (ticked with test names), non-goals, interfaces, later |
| `docs/progress.md` | Repo-level progress (harness, `shared/`, `cmd/`, `scripts/`) |
| `docs/lessons.md` | Feedback turned into rules; a repeated lesson gets a harder rule |
| `docs/roles/` | `reviewer.md`, `judge.md`: how an agent reviews or judges work it didn't write |
| `cmd/app/` | The CLI: a command registry; each feature registers in its own `cmd/app/<feature>.go` |
| `skills.lock` | Third-party agent skills pinned to reviewed commits; `make skills` installs them repo-locally |
| `.githooks/pre-commit` | Runs `make check` (short tests) before every commit |
| `.github/` | CI (`make check` + `make selftest`), PR template, CODEOWNERS for `shared/` |

## Extending it

| You want | Do |
|---|---|
| A new rule | Add `scripts/check-<name>.sh` (exit non-zero on failure). `make check` picks it up. |
| A top-level folder that isn't a feature (`web/`, `data/`) | Add it to `reserved` in `scripts/lib.sh` |
| Another binary | Add `cmd/<name>/`. Feature files in it (`cmd/<name>/<feature>.go`) still count as the feature's. |
| A role (security reviewer, evaluator) | Add `docs/roles/<role>.md` and one line in `AGENTS.md` Workflow 7 |
| A third-party skill | Read its code, pin it in `skills.lock` (instructions in the header), `make skills` |
| A repeatable non-code process (releases, content) | Write it as `docs/workflow.md` (steps, output file per step, pass gate) and link it from `AGENTS.md` |
| A rule the owner keeps repeating | A row in `docs/lessons.md`. If it comes back, turn it into a check. |

After changing anything in `scripts/`, run `make selftest`. It runs 11 pass/fail cases against a throwaway copy of the repo.

## Commands

| Command | What |
|---|---|
| `make setup` | git hook + go deps |
| `make status` | where every feature stands + in-flight branches + stale branches |
| `make check` | the definition of done |
| `make check-<feature>` | vet + test one feature (fast loop) |
| `make new-feature NAME=x DESC="..."` | scaffold a feature |
| `make worktree NAME=x` | new branch from `develop` in its own worktree |
| `make skills` | install pinned third-party skills |
| `make init MODULE=... OWNER=@...` | one-time rename after copying |
| `make selftest` | test the framework's own scripts |
