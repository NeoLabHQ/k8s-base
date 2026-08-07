---
title: Guard Variables Before envsubst Into apply
impact: HIGH
---

# Guard Variables Before envsubst Into apply

`envsubst` substitutes an unset variable with an empty string and exits 0. Piping it
straight into `kubectl apply` therefore ships a structurally valid manifest with a
blank credential, URL, or path to a live cluster. Guard every variable in the recipe
that consumes it, not only in its caller — private recipes get invoked directly.

## Incorrect

The recipe trusts its caller to have checked. Run on its own with the variables
unset, it applies a repository Secret whose url, username and password are `""`.

```just
_apply-repo-secret:
    @envsubst '$GITOPS_REPO_URL $GITOPS_REPO_USERNAME $GITOPS_REPO_PASSWORD' \
        < bootstrap/repo-secret.yaml | kubectl apply -f -
```

## Correct

`${VAR:?message}` fails on unset *and* empty, before anything reaches the cluster,
and names the variable the operator has to set.

```just
_apply-repo-secret:
    #!/usr/bin/env bash
    set -euo pipefail
    : "${GITOPS_REPO_URL:?set GITOPS_REPO_URL in .env}"
    : "${GITOPS_REPO_USERNAME:?set GITOPS_REPO_USERNAME in .env}"
    : "${GITOPS_REPO_PASSWORD:?set GITOPS_REPO_PASSWORD in .env}"
    envsubst '$GITOPS_REPO_URL $GITOPS_REPO_USERNAME $GITOPS_REPO_PASSWORD' \
        < bootstrap/repo-secret.yaml | kubectl apply -f -
```
