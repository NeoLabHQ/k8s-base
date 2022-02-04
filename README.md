# Kubernetes Infrustructure Bootstrap

Base services collection for production ready Kubernetes cluster.

This collection based on know enterprise wide services, already used by many companies.
Bootstrap contain base GitOps setup and examples for add new applications.

## Target

Goal of this bootstrap define vendor free bootstrap, which can be started in any type of cluster, not depend on cloud provider.

But if it not problem for you, you can use [Bitnami Kubernetes Production Runtime](https://github.com/bitnami/kube-prod-runtime). BKPR alredy accessable for GKE, AKS, and Amazon EKS.

You can fork this project for define your own infrsutructure bootstrap. Any PRs are allways welcome.

**Advice:** Don't mix infrustructure and business services, this setup only define infrsutructure,
for define business services better use GitOps soltuions, like [ArgoCD](https://argoproj.github.io/argo-cd/),
which already build it in this bootstrap.

## Services

Current setup contains:

* [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) - General-purpose web UI for Kubernetes clusters
* [Cert-Manager](https://github.com/jetstack/cert-manager) - Automatically provision and manage TLS certificates in Kubernetes
* [kube-prometheus-stack](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack) - kube-prometheus-stack collects Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.
* [loki-stack](https://artifacthub.io/packages/helm/grafana/loki-stack) - Loki: like Prometheus, but for logs
* [tempo-distributed](https://artifacthub.io/packages/helm/grafana/tempo-distributed) - Grafana Tempo in MicroService mode
* [argo-cd](https://artifacthub.io/packages/helm/argo/argo-cd) - Declarative continuous deployment for Kubernetes, GitOps implementation.
* Strimzi - Kafka cluster operator
* [ProvectusLab Kafka UI](https://github.com/provectus/kafka-ui) - Kafka WEB UI
* [Mongo Express](https://github.com/mongo-express/mongo-express) - MongoDB WEB UI
* [RedisInsight](https://docs.redis.com/latest/ri/) - Redis WEB UI

## Requirements

Create kubernetes cluster version and configure [kubectl](https://kubernetes.io/docs/tasks/tools/) for connect to it.

Install CLIs:

* [Helm](https://helm.sh/) - The package manager for Kubernetes.
* [Helm Diff](https://github.com/databus23/helm-diff) - A helm plugin that shows a diff explaining what a helm upgrade would change
* [Hemlile](https://github.com/roboll/helmfile) - One file for manage multiple heml charts.
* [GNU Make](https://www.gnu.org/software/make/manual/make.html) - install by `sudo apt-get install build-essential`

## First Start Guide

`helmfile` uses enviroment variables for set parametors of charts.
`Makefile` automatically setup values from `.env` file.

1) Copy `.env.example` and name it as `.env`
2) Change variables in `.env` as you want.
3) Run `make setup` - will upload all services without check on changes.

## Usage

For setup basic infrustructure run

```bash
# Will deploy new or changed charts first time
make setup
```

For update only changed charts run

```bash
make sync
```

### Setup certificates

For use https you need setup sertificates, you can do it by next commands

```bash
# Will be used by lets encrypt for send emails about certificate updates
export CERTIFICATE_EMAIL=user@email.com
# Will create issuers (certificate providers)
make certificate-issuers
```

if `make sync`  were made first time in cluster wait some time before setup certificates,
k8s need time for load certificate manager operator

More about [ceertificate configuration](https://cert-manager.io/docs/configuration/acme/)
and [tutorial](https://cert-manager.io/docs/tutorials/acme/ingress/) for lets encrypt

**IMPORTANT:** If you not setup sertificates or setup them incorrectly, Ingresses will fallback to self-signed sertificates.

### Minikube

For start local cluster and synchronise, just run

```bash
make local
```

It will run next commands, but you can run them by self:

```bash
# Start minikube server
minikube start

# Enable minikkube ingress before sync
make minikube-ingress # or minikube addons enable ingress

# for synchromise cluster
make setup # or helmfile sync
```

---

Get external ip, for access your cluster outside

```bash
make minikube-ip
```

And add to `/etc/hosts` file next line

```hosts
# For access local cubernetes cluster
<your-external-ip> argo.k8s.local dashboard.k8s.local prometheus.k8s.local thanos-gateway.k8s.local grafana.k8s.local alertmanager.k8s.local k8s.local
```

## Access Kubernetes Dashboard

For access kubernets dashboard you need firstly get token:

```bash
# list existing secrets
kubectl -n kubernetes-dashboard get secrets
# pass correct name of secret
kubectl -n kubernetes-dashboard describe secret kubernetes-dashboard-token-<some-id>
# copy token
```

Then you can open page and pass token:

### Through proxy

create local proxy

```bash
# find full name of kubernetes dashboard pod
kubectl get pod -n kubernetes-dashboard

# use this id for port forward
kubectl port-forward -n kubernetes-dashboard kubernetes-dashboard-<some-id> 8443:8443
```

open <http://localhost:8443/>
and pass copied token

### Though Ingress

open <https://dashboard.k8s.local> and pass copied token

## Metrics, Logs, Tracing

**In general this is self containing solution, which must just work out of the box.**

For metrics collection used [Prometheus](https://prometheus.io/).
For togs collection [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/) and [Loki](https://grafana.com/oss/loki/).
For traing collection used [Tempo](https://grafana.com/oss/tempo/).
For dashboard used [Grafana](https://grafana.com/grafana/).

In future release I would like to migrate all what possible to cloud IaaS solutions.

### Why not ELK stack?

You can find comparisions from Grafana guys [there](https://grafana.com/docs/loki/latest/overview/comparisons/). In simple words, Loki + Prometheus + Tempo + Grafana is simpler to setup then ELK, but it have some limitations.
I actually love Kibana, and have plans to add it.

### Why not OpenTelemetry?

I love [OpenTelemetry](https://opentelemetry.io/) idea of vendor agnostic fully containing stack, but it not ready for most of languages (in alpha or beta stages) right now. I would like to swith to OpenTelemetry when it will be ready for production.

Acording to their [roadmap](https://opentelemetry.io/status/) I've expecting to add OpenTelemetry in 2022, when they will add logs component support.

## Acesss Grafana

create local proxy

```bash
# find full name of kube-prometheus-stack-grafana pod
kubectl get pod -n monitoring-logs-trace-stack

# use this id for port forward
kubectl port-forward -n monitoring-logs-trace-stack  kube-prometheus-stack-grafana-<some-id> 8081:3000
```

open <http://localhost:8443/>
for login as admin use username `admin` and password `prom-operator`

You can change password in `helfile.yaml` in `kube-prometheus-stack` grafana section.

### Access Logs

Open explore tab in Grafana, abd swith Prometheus to Loki. On log browser you can see posible valuues to search.

### Access Traces

Open explore tab in Grafana, abd swith Prometheus to Tempo.

If Tempo not connected probably you need enable Tempo.

#### Enable Tempo

Open Configuration.DataSourses page in Grafana -> click Add data sourses -> click Tempo ->
fill URL with `http://tempo-tempo-distributed-query-frontend:3100` and set Trace to Logs section with Data Source `Loki`

## Access kafka UI

To connect to Kafka-UI web application need to execute:

```bash
kubectl port-forward svc/kafka-ui 8080:80
```

Open the <http://127.0.0.1:8080> on the browser to access Kafka-UI.

## Access ArgoCD

Get password to admin account

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
# copy password

# Find full pod name
kubectl get pod -n argocd
# copy name starting with argocd-server-*

# Run proxy to pod
kubectl port-forward -n argocd argocd-server-<real-id> 8080:8080
```

open <localhost:8080> and use `admin` as username

### Create Application

You can easily [create application through:

* [UI application](https://argo-cd.readthedocs.io/en/stable/getting_started/#creating-apps-via-ui)
* [CLI](https://argo-cd.readthedocs.io/en/stable/getting_started/#creating-apps-via-cli).
* [Declarative setup](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/), which used in this repo.

### Declarative application setup

For deploy [applications](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#applications) from `applications` folder just run.

```bash
make apps # Will deploy application configurations
```

For add new applications just add new `yaml` in `applications` folder, like example application.
You also can use this foler for setup [Project](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#projects), or [repository](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#repositories), or [app of apps](https://argoproj.github.io/argo-cd/operator-manual/declarative-setup/#app-of-apps).

### Access deployed application

You can access already deployed application thourgh port-forwarding, just run:

```bash
kubectl port-forward service/frontend :80
# will choose local port and proxy it to service with name frontend (example application)
```

and you can open page localy as `http://localhost:<allocated-port>`

## Acesss Mongo Express

Create local proxy to express service

```bash
# find full name of mongodb-ui-mongo-express pod
kubectl get pod

# use this id for port forward
kubectl port-forward  mongodb-ui-mongo-express-<some-id> 8081:8081
```

open <http://localhost:8081/>

## Acesss RedisInsight

Create local proxy to service

```bash
# find full name of redisinsight pod
kubectl get pod

# use this id for port forward
kubectl port-forward  redisinsight-<some-id> 8001:8001
```

open <http://localhost:8001/>
