# Architecture

Routing, workflow and gates: `AGENTS.md`.

## Layout
| Path | What | May import |
|---|---|---|
| `<feature>/` | One product feature. Root package = its public API; the rest in `<feature>/internal/` | itself, `shared/` |
| `shared/<concept>/` | One package per concept used by 2+ features. No code directly in `shared/` | `shared/` only |
| `cmd/<app>/` | Binaries; the only place features are wired together | features' root packages, `shared/` |
| `docs/` | Product, architecture, specs, repo-level progress, roles, lessons | — |
| `scripts/` | The checks and scaffolds behind `make` | — |

Boundaries are enforced by `scripts/check-imports.sh` (via `make check`) and by Go's own `internal/` rule, not by convention.
Any other top-level dir is a feature and must have a spec, `AGENTS.md`, `progress.md` and a row in `docs/features.md`
(`scripts/check-structure.sh`). A top-level dir that is not a feature (e.g. `web/`, `data/`) is added to `reserved` in `scripts/lib.sh`.

## How features connect
Features never call each other directly. If two features need the same thing, it moves to `shared/`.
If one feature needs another's output, `cmd/` passes it in (constructor arguments, or interfaces defined by the consuming feature).

- **Shared types:** a value type used by 2+ features lives in `shared/<domain>/`.
  Features define behavior interfaces themselves; they don't copy each other's structs.
- **Wiring:** `cmd/app/main.go` holds only a command registry. Each feature registers its subcommands in
  `cmd/app/<feature>.go` via `init()`, so adding a command never edits `main.go`. That file and its `_test.go` belong to the
  feature: `make check` asks for `<feature>/progress.md` (not `docs/progress.md`), so parallel feature PRs don't conflict.
- **Connections:** record what a feature consumes and exposes in its spec's `Interfaces` section.
- **Changing `shared/`:** land it as its own small PR first; feature branches then rebase onto it.

## Why it scales
- Each feature is a folder with its own spec, progress and notes, so N agents work on N features without touching the same files.
- `docs/features.md` is union-merged (`.gitattributes`), so parallel `make new-feature` branches don't conflict.
- `make check` runs every `scripts/check-*.sh`: a new rule is a new file.
- One task = one branch = one worktree, claimed in its progress.md, visible to everyone through `make status`.
