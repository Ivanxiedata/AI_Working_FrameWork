# AGENTS.md

Map for any coding agent (Claude Code, Codex, Copilot, Cursor, ...). Short on purpose; details live in the linked files.
Product: `docs/product.md`.

## Start of every session
1. `make status`: each feature's status and next step, plus work in flight on other branches.
2. `make check` as a baseline. If it fails on a clean checkout, fixing that comes first.
3. Route your task. Continue from the "Next" of the progress file you land on; don't ask the owner what the previous agent did.
   - **Feature work** (a row in `docs/features.md`): read `<feature>/AGENTS.md`, `docs/specs/<feature>.md`, `<feature>/progress.md`.
   - **Fits no feature:** it's a new feature. `make new-feature NAME=<name> DESC="<one line>"`, then write the spec.
   - **Repo-level** (harness, `shared/`, `cmd/` except `cmd/<app>/<feature>.go`, `scripts/`): `docs/progress.md`. One repo-level task at a time.
4. **Claim before you start.** If "In flight" in `make status` shows someone on your feature, pick other work.
   Right after `make worktree`, prefix the existing Status line of the progress.md you'll own with `in progress (<branch>): `,
   keeping the old text; commit, `git push -u origin HEAD`. Other agents only see claims that are pushed.
   Drop the prefix in your last commit, when the work is done.
5. Background when needed: `docs/product.md` (what and why), `docs/architecture.md` (how features connect), `docs/lessons.md` (rules learned from feedback).

## Before you stop (every session, even mid-task)
Update the progress.md you own: Status (one line: `make status` shows only that), Next (numbered, concrete), Blockers, Decisions (with the why),
and one Log line appended at the bottom (oldest first). Write it for an agent that has never seen your conversation.
`make check` fails a branch that changes `<feature>/`, its spec or `cmd/<app>/<feature>.go` (and `_test.go`) without `<feature>/progress.md`,
or `shared/`, the rest of `cmd/`, `scripts/`, `Makefile`, `.githooks/`, `.github/` without `docs/progress.md`.
In CI it also fails a feature whose newest code/spec commit is newer than its progress.md's: update progress.md after your last code change.

## Branches
- `develop` is the integration branch. Every task branches from `develop`, and every PR targets `develop`.
- `main` only moves by fast-forward to `develop`, and only when the owner says develop is done:
  `git fetch origin && git push origin origin/develop:refs/heads/main` (git rejects it if it isn't a fast-forward).
- Never commit or open a PR directly against `main`.
- **Agents never merge PRs.** The owner merges into develop when CI is green.

## Workflow
1. New task: `make worktree NAME=<slug>`, then `cd` there, `make setup`, `make status`, scaffold if needed (`make new-feature`), and claim (above). Work only in that worktree.
2. Spec before code: change `docs/specs/<feature>.md` before changing behavior.
   Spec ticks: `[ ]` not built; `- [x] ... -> TestName` built. One line per criterion, `->` only;
   the name must be a Test/Example/Fuzz that exists in the feature (`make check` verifies).
   New ideas beyond this version go in the spec's `## Later`.
3. Done means `make check` passes. Never commit with `--no-verify`.
4. Before the PR: `git fetch origin && git rebase origin/develop`, then `make check` again.
5. PR: `git push --force-with-lease -u origin HEAD`, then `gh pr create --base develop`, using the template.
   The claim already pushed this branch and the rebase rewrote it, so a plain push is rejected; forcing is safe because the branch is yours alone.
   Never force-push `develop`, `main` or anyone else's branch.
6. After the owner merges your PR, from another checkout: `git worktree remove <dir>`, then `git branch -D <slug>` (`-D`: git can't tell a squash-merged branch is merged).
   `make status` lists local branches whose upstream is gone under "Stale local branches".
7. Roles: when asked to review or judge, follow `docs/roles/reviewer.md` or `docs/roles/judge.md`; never review or judge your own work.
   The owner's feedback is a lesson: add a row to `docs/lessons.md` in the same session.
8. Third-party skills: `make skills` installs the pinned ones (`skills.lock`) into this worktree (`.claude/skills`, `.agents/skills`);
   each worktree runs it itself. Never install skills globally. Bumping a pin: read the upstream diff first (`skills.lock` header).
9. Cheap model for easy work: hand an easy task to a subagent on a cheaper model, keep the expensive model for the hard parts.
   Claude Code: the Agent tool with `model: "sonnet"`. Other agents: their smaller model. Never launch a subagent without choosing its model.
   - Easy: the inputs and the expected result are written down, and a command checks it. Edits from a spec or progress Next,
     fixing a failing `make check`, lookups, moving or renaming files.
   - Hard: research where sources disagree, design, reviewing or judging work, debugging with no known cause, decisions the owner hasn't made.
   - When a cheap subagent fails the same step twice, the expensive model takes it over; say so in the progress file.
10. Parallel agents: each works only in its own worktree and its own scratch folder; never write into, or delete, a folder another agent may use.

## Rules
- Go. Tests sit next to code as `*_test.go`.
- Slow tests (network, DB, >1s) start with `if testing.Short() { t.Skip("slow") }`. The commit hook skips them; CI runs them.
- A feature imports only itself and `shared/`. `shared/` imports no feature. `cmd/` wires features together.
  Enforced by `scripts/check-imports.sh`. Details: `docs/architecture.md`.
- A feature's root package is its only public API; everything else goes in `<feature>/internal/`.
- Changing `shared/` needs owner review and `make check` passing for every feature; land it as its own small PR.

## Commands
| Command | What |
|---|---|
| `make status` | where every feature stands + in-flight branches |
| `make check` | gofmt, vet, test, structure, import boundaries, progress updated, spec ticks have tests |
| `make check-<feature>` | vet + test one feature |
| `make new-feature NAME=x DESC="..."` | scaffold dir, spec, AGENTS.md, progress.md, map row (write a literal `$` as `$$`) |
| `make worktree NAME=x` | branch from develop + worktree |
| `make skills` | install the pinned third-party skills repo-locally |
| `make selftest` | test the framework's own scripts (after changing `scripts/`) |
