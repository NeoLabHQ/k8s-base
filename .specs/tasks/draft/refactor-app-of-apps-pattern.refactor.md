---
title: Refactor project to app-of-apps pattern
---

## Initial User Prompt

refactor project to app-of-apps pattern

### Context

This project is for of highly outdated and not maintained project. It's not used in production.

But it provides usefull blueprint for bootstrap of base k8s cluster that we need.

### Goal

Taking inspiration from https://github.com/konstructio/kubefirst project, this project should be refactored to provide app-of-apps pattern.

### Requirements

- Remove kubernetes dashboard, cert-manager, kube-prometheus-stack, loki-stack, tempo-distributed, strimzi, provectuslab-kafka-ui, mongo-express, redisinsight, eventrouter. From this project.
- Keep argo-cd, but update it. 
- Add Argo Rollouts and Kargo for deployment of applications.
- Add Dex for ArgoCD/Github authentication.
- This project will be used to setup base k8s cluster infrustructure, where argocd will be pointed to other `gitops` reposititory. The `gitops` repository will contain other base infrustructure like kubernetes dashboard, cert-manager, external-dns, ingress-ng, kube-prometheus-stack, etc. But it out of scope of this project. But add docs/getting-started.md file to explain how to use this project. And setup it's integration with other `gitops` repository.
- Update readme to explain new architecture, how to use and modify it.
- Migrate makefile to justfile. Copy all existing commands from makefile (adjust if need), and also keep commands that exists in justfile. Then delete makefile.

Special note: while kubefirst project provides much more infrustructure, we have different requirements, that he not will satisfy in future. But this is not attempt to replace him, rather provide minimal base, with minimal in maintance efforts.

## Description

// Will be filled in future stages by business analyst
