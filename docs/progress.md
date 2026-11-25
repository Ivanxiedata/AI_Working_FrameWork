# Repo progress

Covers repo-level work: harness, `shared/`, `cmd/` (except `cmd/<app>/<feature>.go`, which is the feature's), `scripts/`.

## Status
Framework only: no features yet. `make check` and `make selftest` pass.

## Next
1. Owner: copy the framework into a project (README "Start a new project"), run `make init`, write `docs/product.md`.
2. `make new-feature` for the first feature, then write its spec before any code.

## Blockers
none

## Decisions
- 2026-11-24: Extracted from github.com/Ivanxiedata/youtube-skill, keeping only what isn't about videos (episodes, pipeline, voice, brand, upload dropped), because this repo is the reusable framework.
- 2026-11-24: Go only, as the owner chose; the checks (gofmt, vet, test, import boundaries, spec ticks) assume Go.
- 2026-11-24: The binary lives in `cmd/app/`, and scripts treat any `cmd/<app>/<feature>.go` as the feature's, so a project can rename it or add binaries without editing scripts.
- 2026-11-24: `make selftest` tests the scripts themselves in a throwaway copy, because the framework's scripts are the product here and nothing else exercises their failure paths.

## Log
- 2026-11-24 main: framework extracted: AGENTS.md, Makefile, scripts (checks, status, scaffolds, worktree, skills, init, selftest), docs templates, roles, CI.
