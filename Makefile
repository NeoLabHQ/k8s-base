#!/usr/bin/env make

.PHONY: setup sync apps proxy contexts current-context dashboard-proxy local minikube minikube-ingress minikube-ip certificate-issuers

default: sync

# Apply .env if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# ---------------------------------------------------------------------------------------------------------------------
# SETUP
# ---------------------------------------------------------------------------------------------------------------------

# run on first setup
setup:
	helmfile sync
	make apply-base

dev-setup:
	helmfile -f helmfile.dev.yaml sync
	make apply-dev-base

sync: 
	helmfile apply
	make apply-base

apply-base:
	make create-dashboard-role
	make save-docker-hub-creds
	make save-stackgres-profiles
	make save-wasabi-creds
	make save-amocrm-creds
	make save-mongodb-creds
	make save-chatapi-creds
	make save-redis-creds
	make apply-cors
	make apply-redisinsight
	make apply-eventrouter
	make apps

apply-dev-base:
	make create-dashboard-role
	make save-docker-hub-creds
	make apply-kong-operator-for-minikube
	make save-amocrm-creds
	make save-mongodb-creds
	make save-chatapi-creds
	make save-redis-creds
	make apply-dev-cors
	make apply-redisinsight
	make apply-eventrouter

# if kubernetes dashboard cannot list something
update-admin-role:
	kubectl apply -f ./rbac/cluster-admin.yaml

create-dashboard-role:
	kubectl delete --ignore-not-found=true clusterrolebinding kubernetes-dashboard
	kubectl create clusterrolebinding kubernetes-dashboard \
		--clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard

apps:
	kubectl apply -n argocd -f ./applications/

save-stackgres-profiles:
	kubectl apply -f ./manifests/stackgres-instance-profiles.yaml

apply-kong-operator-for-minikube:
	kubectl create -f https://bit.ly/k4k8s
	kubectl apply -f ./manifests/kong-operator.dev-patch.yaml
	
apply-cors:
	kubectl apply -f ./manifests/cors.yaml

apply-dev-cors:
	kubectl apply -f ./manifests/cors.dev.yaml

apply-redisinsight:
	kubectl apply -f ./manifests/redisinsight.yaml

apply-eventrouter:
	kubectl apply -f ./manifests/eventrouter.yaml

# ---------------------------------------------------------------------------------------------------------------------
# MINIKUBE
# ---------------------------------------------------------------------------------------------------------------------

# Setup local cluster
local: minikube dev-setup

minikube:
	minikube start --memory='max' --cpus='max'
#	minikube start --addons=ingress --memory='max' --cpus='max'
#	make minikube-ingress

# Allow access without proxy
minikube-ingress:
	minikube addons enable ingress

# get the external IP of cluster
minikube-ip:
	minikube ip

# ---------------------------------------------------------------------------------------------------------------------
# REGISTRY
# ---------------------------------------------------------------------------------------------------------------------

save-wasabi-creds:
	kubectl delete --ignore-not-found=true secret wasabi-creds
	kubectl create secret generic wasabi-creds \
		--from-literal='AWS_ACCESS_KEY_ID=${WASABI_ACCESS_KEY_ID}' \
		--from-literal='AWS_SECRET_ACCESS_KEY=${WASABI_SECRET_ACCESS_KEY}' \
		--from-literal='AWS_REGION=${WASABI_REGION}' \
		--from-literal='AWS_DEFAULT_REGION=${WASABI_DEFAULT_REGION}'


save-docker-hub-creds:
	kubectl delete --ignore-not-found=true secret docker-hub-creds
	kubectl create secret generic docker-hub-creds \
		--from-file=.dockerconfigjson=./.docker/config.json \
		--type=kubernetes.io/dockerconfigjson

save-amocrm-creds:
	kubectl delete --ignore-not-found=true secret amocrm-creds
	kubectl create secret generic amocrm-creds \
		--from-literal='AMOCRM_INTEGRATION_ID=${AMOCRM_INTEGRATION_ID}' \
		--from-literal='AMOCRM_SECRET_KEY=${AMOCRM_SECRET_KEY}' \
		--from-literal='AMOCRM_AUTH_REDIRECT_URI=${AMOCRM_AUTH_REDIRECT_URI}' \
		--from-literal='AMOCRM_CHANNEL_SECRET_KEY=${AMOCRM_CHANNEL_SECRET_KEY}' \
		--from-literal='AMOCRM_CHANNEL_ID=${AMOCRM_CHANNEL_ID}' 

save-mongodb-creds:
	kubectl delete --ignore-not-found=true secret mongodb-creds
	kubectl create secret generic mongodb-creds \
		--from-literal='MONGOOSE_URI=mongodb://root:mongodb-omnigram-password@mongodb-0.mongodb-headless.default.svc.cluster.local:27017,mongodb-1.mongodb-headless.default.svc.cluster.local:27017/'
	kubectl delete --ignore-not-found=true secret mongodb-config
	kubectl create secret generic mongodb-config \
		--from-literal='mongodb-password=${MONGODB_PASSWORD}' \
		--from-literal='mongodb-root-password=${MONGODB_ROOT_PASSWORD}' \
		--from-literal='mongodb-replica-set-key=${MONGODB_REPLICASET_KEY}' 

save-chatapi-creds:
	kubectl delete --ignore-not-found=true secret chatapi-creds
	kubectl create secret generic chatapi-creds \
		--from-literal='CHATAPI_API_URL=${CHATAPI_API_URL}' \
		--from-literal='CHATAPI_API_KEY=${CHATAPI_API_KEY}' 

save-redis-creds:
	kubectl delete --ignore-not-found=true secret redis-creds
	kubectl create secret generic redis-creds \
		--from-literal='REDIS_PASSWORD=${REDIS_PASSWORD}'

# ---------------------------------------------------------------------------------------------------------------------
# CERTIFICATE MANAGER
# ---------------------------------------------------------------------------------------------------------------------

certificate-issuers: certificate-issuer-staging certificate-issuer-prod

certificate-issuer-staging:
	envsubst < ./certificate/staging-issuer.yaml | kubectl apply -f -

certificate-issuer-prod:
	envsubst < ./certificate/production-issuer.yaml | kubectl apply -f -

# ---------------------------------------------------------------------------------------------------------------------
# USAGE
# ---------------------------------------------------------------------------------------------------------------------

contexts:
	kubectl config get-contexts

current-context:
	kubectl config current-context

secrets:
	kubectl get secrets

# ---------------------------------------------------------------------------------------------------------------------
# ACCESSS
# ---------------------------------------------------------------------------------------------------------------------

proxy:
	kubectl proxy

proxy-dashboard:
	kubectl port-forward -n kubernetes-dashboard kubernetes-dashboard-75bfbd4977-t58j8 8443:8443
	echo "Open at https://localhost:8443"
# If chrome not allow open localhost use chrome://flags/#allow-insecure-localhost

proxy-argo:
	echo "Open at http://localhost:8080"
	kubectl port-forward -n argocd argocd-server-7cc6fc47d7-bs8rg 8080:8080

proxy-grafana: 
	kubectl port-forward -n monitoring-logs-trace-stack  kube-prometheus-stack-grafana-7df49b8657-wfrdn 8081:3000