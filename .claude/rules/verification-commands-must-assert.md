---
title: Verification Commands Must Assert, Not Print
impact: HIGH
---

# Verification Commands Must Assert, Not Print

A recipe or script named `verify`, `check`, `health`, or `smoke` must exit non-zero
when the thing it checks is unhealthy. A command that only prints status always
exits 0, so it silently passes broken state to whatever runs it next — a bootstrap
chain, a CI gate, or an operator who skimmed the output. If it cannot fail, it is a
status command; name it `status` and write a separate assertion.

## Incorrect

`verify` prints two tables and exits 0 whether or not the workloads are available
and whether or not the application actually synced.

```just
verify:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "== Argo CD workloads =="
    kubectl get deployment,statefulset --namespace argocd
    echo "== Root Application =="
    kubectl get application root --namespace argocd \
        -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status'
```

## Correct

The same information is shown, but each condition is asserted, so the recipe fails
with a message naming what is wrong.

```just
verify:
    #!/usr/bin/env bash
    set -euo pipefail
    kubectl get deployment,statefulset --namespace argocd
    kubectl wait --namespace argocd --for=condition=available \
        --timeout=60s deployment --all

    sync=$(kubectl get application root --namespace argocd \
        -o jsonpath='{.status.sync.status}')
    echo "root sync status: ${sync:-<none>}"
    case "$sync" in
        Synced|Unknown) ;;   # Unknown is expected on an empty gitops repo
        *) echo "root Application is '$sync'" >&2; exit 1 ;;
    esac
```
