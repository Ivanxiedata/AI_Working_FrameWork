#!/bin/sh
# One-time rename after copying the framework: the Go module path (go.mod and every import) and the CODEOWNERS owner.
set -eu
cd "$(git rev-parse --show-toplevel)"
mod=${1:-}
owner=${2:-}
case $mod in '' | *[!A-Za-z0-9._~/-]*) echo 'usage: make init MODULE=github.com/you/project OWNER=@you'; exit 1 ;; esac
case $owner in '' | @*) ;; *) echo "OWNER must start with @ (a GitHub user or @org/team)"; exit 1 ;; esac
old=$(go list -m)
[ "$old" != "$mod" ] || { echo "init: module is already $mod"; exit 0; }
go mod edit -module "$mod"
for f in $(git ls-files -co --exclude-standard '*.go'); do
	grep -qF "\"$old" "$f" || continue
	sed "s|\"$old|\"$mod|g" "$f" >"$f.tmp"
	cat "$f.tmp" >"$f" # keeps the file mode
	rm -f -- "$f.tmp"
done
[ -z "$owner" ] || printf '/shared/ %s\n' "$owner" >.github/CODEOWNERS
echo "init: module $old -> $mod${owner:+, CODEOWNERS -> $owner}. Next: write docs/product.md, then make check."
