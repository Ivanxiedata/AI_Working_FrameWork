# Sourced by scripts. Top-level dirs that are not features. Add a dir here when it is not a feature (e.g. data/, web/).
reserved() { case $1 in .* | docs | scripts | shared | cmd) return 0 ;; *) return 1 ;; esac; }

# progress.md skeleton: progress_md <name> <first Next item>
progress_md() {
	cat <<EOT
# $1 progress

## Status
not started

## Next
1. $2

## Blockers
none

## Decisions
<!-- - YYYY-MM-DD: decision, because why -->

## Log
<!-- append at the bottom, oldest first: - YYYY-MM-DD <branch>: what was done -->
EOT
}
