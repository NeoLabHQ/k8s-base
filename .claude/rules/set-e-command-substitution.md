---
title: Neutralise Command Substitution You Intend to Diagnose
impact: MEDIUM
paths:
  - "justfile"
  - "**/*.sh"
  - "**/*.bash"
---

# Neutralise Command Substitution You Intend to Diagnose

Under `set -e`, `x=$(cmd)` aborts the script the moment `cmd` exits non-zero — before
any `case`, `if`, or error message written to handle the result can run. The exit code
is still correct, but the diagnostic branch is dead code and the operator sees the raw
tool error instead of the message you wrote. Whenever a substitution's failure is
something you handle rather than something you want to abort on, capture it with
`|| true` and branch on the value.

## Incorrect

The `case` below is written to explain an empty status, but a `kubectl` that errors
never reaches it: `set -e` fires on the assignment and the `FAILED:` line never prints.

```bash
set -euo pipefail
sync=$(kubectl get application root -n argocd -o jsonpath='{.status.sync.status}')
case "$sync" in
    Synced) echo "OK" ;;
    "")     echo "FAILED: Argo CD has not reported on the root Application." >&2; exit 1 ;;
esac
```

## Correct

`|| true` keeps the assignment from aborting, so a failed command and an empty result
both land in the branch that explains them. `cmd` still prints its own reason to stderr.

```bash
set -euo pipefail
sync=$(kubectl get application root -n argocd -o jsonpath='{.status.sync.status}' || true)
case "$sync" in
    Synced) echo "OK" ;;
    "")     echo "FAILED: Argo CD has not reported on the root Application." >&2; exit 1 ;;
esac
```

## Reference

- Related: `.claude/rules/verification-commands-must-assert.md` (exit codes); this rule
  governs which diagnostic actually runs.
