#!/bin/sh
# A branch that changes part of the repo must also update that part's progress file,
# so the next agent can continue without being told what happened:
#   <feature>/... or docs/specs/<feature>.md             -> <feature>/progress.md
#   cmd/<app>/<feature>.go and <feature>_test.go         -> <feature>/progress.md (so parallel feature PRs don't all edit docs/progress.md)
#   shared/ cmd/ scripts/ Makefile .githooks/ .github/   -> docs/progress.md
# In CI ($CI set) it must also be updated after the last change to a feature's code (see the end).
set -eu
cd "$(git rev-parse --show-toplevel)"
. scripts/lib.sh
git rev-parse -q --verify origin/develop >/dev/null || { echo "progress: no origin/develop yet, skipped"; exit 0; }
base=$(git merge-base HEAD origin/develop)
# Index vs base = this branch's commits plus what is staged for the commit in progress.
# --no-renames: a moved file counts as a change to both its old and new place.
changed=$(git diff --cached --no-renames --name-only "$base")
# A feature's progress file, if it has one.
feature() { reserved "$1" || [ ! -f "$1/progress.md" ] || echo "$1/progress.md"; }
# cmd/<app>/<f>.go or <f>_test.go: feature <f>'s progress file when <f> is a feature, else the repo-level one (main.go, ...).
cmdfile() {
	f=${1#cmd/*/}; f=${f%.go}; f=${f%_test}
	case $f in '' | */*) f= ;; esac
	n=$([ -z "$f" ] || feature "$f")
	echo "${n:-docs/progress.md}"
}
need=$(printf '%s\n' "$changed" |
	while IFS= read -r p; do
		case $p in
		(cmd/*/*.go) cmdfile "$p" ;;
		(shared/* | cmd/* | scripts/* | Makefile | .githooks/* | .github/*) echo docs/progress.md ;;
		(docs/specs/*.md) s=${p#docs/specs/}; feature "${s%.md}" ;;
		(*/*) feature "${p%%/*}" ;;
		esac
	done | sort -u)
fail=0
for n in $need; do
	printf '%s\n' "$changed" | grep -Fxq "$n" ||
		{ echo "progress: this branch changes what $n covers, but not $n. Update Status/Next/Log."; fail=1; }
done

# CI only: no change to a feature's code/spec may come after (be missing from) the latest update of its progress.md.
# Ancestry, not dates, so parallel branches merged together are judged correctly.
# Locally (the hook) "touched at least once" above stays the rule: the commit in progress isn't in the log yet.
# ponytail: feature progress files only; the repo-level docs/progress.md keeps the touched-once rule.
if [ -n "${CI:-}" ]; then
	for n in $need; do
		[ "$n" != docs/progress.md ] || continue
		f=${n%/progress.md}
		prog=$(git log -1 --format=%H "$base"..HEAD -- "$n")
		[ -z "$(git rev-list -1 "${prog:-$base}"..HEAD -- "$f/" "docs/specs/$f.md" "cmd/*/$f.go" "cmd/*/${f}_test.go" ":(exclude)$n")" ] ||
			{ echo "progress: $n is older than the last change to what it covers. Update it after your last code change."; fail=1; }
	done
fi
exit $fail
