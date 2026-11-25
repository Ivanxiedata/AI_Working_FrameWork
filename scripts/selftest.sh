#!/bin/sh
# Tests the framework's own scripts in a throwaway copy of this checkout (with a local bare "origin"):
# each case changes the copy and expects `make check` to pass, or to fail with a given message.
set -eu
src=$(git rev-parse --show-toplevel)
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir "$tmp/repo"
git init -q --bare "$tmp/origin.git"
(cd "$src" && git ls-files -co --exclude-standard -z | xargs -0 tar cf - 2>/dev/null) | tar xf - -C "$tmp/repo"
cd "$tmp/repo"
unset CI # the CI-only rule in check-progress is not what these cases test
export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@example.com GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@example.com
git init -q -b develop
git add -A && git commit -qm base
git remote add origin "$tmp/origin.git" && git push -q origin develop
git switch -qc task
mod=$(go list -m)

fails=0
check() { make check TESTFLAGS=-short 2>&1; }
pass() {
	if out=$(check); then echo "ok   $1"; else echo "FAIL $1: want pass, got:"; echo "$out" | tail -5; fails=$((fails + 1)); fi
}
fail() { # <case> <message make check must print>
	if out=$(check); then
		echo "FAIL $1: want a failure saying '$2', got pass"; fails=$((fails + 1))
	elif printf '%s\n' "$out" | grep -qF -- "$2"; then
		echo "ok   $1"
	else
		echo "FAIL $1: want '$2', got:"; echo "$out" | tail -5; fails=$((fails + 1))
	fi
}
undo() { git reset -q --hard && git clean -qfd; }

pass "clean framework passes"

make -s new-feature NAME=billing DESC="Charges customers" >/dev/null
git add -A
pass "new-feature scaffold passes"

mkdir orphan && echo 'package orphan' >orphan/orphan.go && git add -A
fail "a dir with no spec fails" "orphan/ has no docs/specs/orphan.md"
git rm -rqf orphan

sed 's/^- \[ \] Given .*/- [x] Charges once -> TestChargesOnce/' docs/specs/billing.md >spec.tmp
mv spec.tmp docs/specs/billing.md
git add -A
fail "a ticked criterion without its test fails" "names TestChargesOnce, which doesn't exist in billing/"
printf 'package billing\n\nimport "testing"\n\nfunc TestChargesOnce(t *testing.T) {}\n' >billing/billing_test.go && git add -A
pass "a ticked criterion with its test passes"

git commit -qm billing && git push -q origin task:develop && git fetch -q origin

make -s new-feature NAME=invoice DESC="Sends invoices" >/dev/null
printf 'package invoice\n\nimport _ "%s/billing"\n' "$mod" >invoice/invoice.go && git add -A
fail "a feature importing another feature fails" "imports: invoice/invoice.go -> $mod/billing"
undo

printf '\n// Changed.\n' >>billing/doc.go && git add -A
fail "feature code changed without its progress.md fails" "changes what billing/progress.md covers"
echo '- today task: changed doc.go' >>billing/progress.md && git add -A
pass "feature code changed with its progress.md passes"
undo

printf 'package main\n' >cmd/app/billing.go && git add -A
fail "cmd/<app>/<feature>.go counts as the feature's" "changes what billing/progress.md covers"
undo

echo '# changed' >>scripts/lib.sh && git add -A
fail "a scripts/ change without docs/progress.md fails" "changes what docs/progress.md covers"
undo

make -s init MODULE=example.com/renamed OWNER=@someone >/dev/null
git add -A
[ "$(go list -m)" = example.com/renamed ] && grep -qx '/shared/ @someone' .github/CODEOWNERS ||
	{ echo "FAIL init: module or CODEOWNERS not rewritten"; fails=$((fails + 1)); }
echo '- today task: renamed' >>docs/progress.md && git add -A
pass "init renames the module and the check still passes"
undo

make -s status >/dev/null 2>&1 || { echo "FAIL make status exits non-zero"; fails=$((fails + 1)); }

[ $fails = 0 ] || { echo "selftest: $fails failed"; exit 1; }
echo "selftest: all passed"
