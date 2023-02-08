# kind
K8S_VERSION ?= v1.24.7
KIND_KUBECONFIG=tmp/kind-kubeconfig
K8S_CLUSTER_NAME := m8-dev-cluster

# values
CERT_MANAGER_HELM_VALUES_FILE		?= setup/cert-manager.yaml
CERT_MANAGER_ISSUER_RESOURCE_FILE		?= setup/cert-manager-issuer.yaml
EMISSARY_INGRESS_HELM_VALUES_FILE		?= setup/emissary-ingress.yaml
DEX_HELM_VALUES_FILE		?= setup/dex.yaml
MONOSKOPE_HELM_VALUES_FILE		?= setup/m8.yaml
EMISSARY_INGRESS_LISTENER_RESOURCE_FILE		?= setup/emissary-ingress-listener.yaml

# versions
CERT_MANAGER_VERSION ?= v1.11.0
EMISSARY_VERSION ?= 3.4.0
EMISSARY_INGRESS_CHART_VERSION ?= 8.4.0
DEX_VERSION ?= 0.8.2
MONOSKOPE_VERSION ?= v0.5.2


KUBECTL ?= kubectl --kubeconfig ${KIND_KUBECONFIG}
HELM ?= helm --kubeconfig ${KIND_KUBECONFIG}

##@ Deploy

.PHONY: deploy
deploy: deploy-cleanup kind-create-cluster helm-repo deploy-m8-trust-anchor deploy-cert-manager deploy-emissary-ingress deploy-dex deploy-monoskope ## deploy monoskope

.PHONY: kind-watch
kind-watch: ## watch monoskope beain deployed
	KUBECONFIG=${KIND_KUBECONFIG} watch "kubectl get no -owide; echo; kubectl get po -A"

.PHONY: port-forward
port-forward: ## create a port-forward to the m8Api and dex
	KUBECONFIG=$(KIND_KUBECONFIG) sh ./port-forward.sh

.PHONY: kind-create-cluster
kind-create-cluster: ## create kind cluster
	@kind create cluster --name ${K8S_CLUSTER_NAME} --image kindest/node:${K8S_VERSION} --kubeconfig ${KIND_KUBECONFIG}
	@kind get kubeconfig --name ${K8S_CLUSTER_NAME} > ${KIND_KUBECONFIG}

.PHONY: helm-repo
helm-repo: ## add necessary chart repos
	@helm repo add jetstack https://charts.jetstack.io
	@helm repo add datawire https://getambassador.io
	@helm repo add dex https://charts.dexidp.io
	@helm repo add finleap-connect https://finleap-connect.github.io/charts/

.PHONY: deploy-m8-trust-anchor
deploy-m8-trust-anchor: ## create trust-anchor in kind cluster
	@echo "Generating trust-anchor for m8 PKI..."
	@step certificate create root.monoskope.cluster.local tmp/ca.crt tmp/ca.key --profile root-ca --no-password --insecure --not-after=87600h
	@echo "Creating secret containing trust-anchor in kind cluster..."
	@$(KUBECTL) create namespace monoskope --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) -n monoskope create secret tls m8-trust-anchor --cert=tmp/ca.crt --key=tmp/ca.key --dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: deploy
deploy-cert-manager: helm-repo ## deploy dex
	@$(HELM) upgrade -i cert-manager -n cert-manager --create-namespace jetstack/cert-manager --version $(CERT_MANAGER_VERSION) --values $(CERT_MANAGER_HELM_VALUES_FILE)
	@$(KUBECTL) apply -f $(CERT_MANAGER_ISSUER_RESOURCE_FILE)

.PHONY: deploy
deploy-emissary-ingress: helm-repo ## deploy emissary-ingress
	@$(KUBECTL) apply -f https://app.getambassador.io/yaml/emissary/$(EMISSARY_VERSION)/emissary-crds.yaml
	@$(KUBECTL) -n emissary-system patch deploy emissary-apiext -p '{"spec":{"replicas": 1}}'
	@$(KUBECTL) wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
	@$(HELM) upgrade -i ei -n emissary --create-namespace datawire/emissary-ingress --version $(EMISSARY_INGRESS_CHART_VERSION) --values $(EMISSARY_INGRESS_HELM_VALUES_FILE) \
		--set=image.tag=$(EMISSARY_VERSION)

.PHONY: deploy
deploy-dex: helm-repo ## deploy dex
	@$(HELM) upgrade -i dex -n monoskope --create-namespace dex/dex --version $(DEX_VERSION) --values $(DEX_HELM_VALUES_FILE)
	@$(KUBECTL) -n monoskope create secret generic m8-gateway-oidc --from-literal=oidc-clientid=gateway --from-literal=oidc-clientsecret=verysecretclientsecret --from-literal=oidc-nonce=somerandomstring --dry-run=client -o yaml | $(KUBECTL) apply -f -

.PHONY: deploy
deploy-monoskope: helm-repo ## deploy monoskope
	@$(HELM) upgrade -i m8 -n monoskope --create-namespace finleap-connect/monoskope --version $(MONOSKOPE_VERSION) --values $(MONOSKOPE_HELM_VALUES_FILE)
	@$(KUBECTL) apply -f $(EMISSARY_INGRESS_LISTENER_RESOURCE_FILE)
	@$(KUBECTL) wait --timeout=90s --for=condition=ready certificate m8-monoskope-tls-cert -n monoskope
	@$(KUBECTL) -n monoskope get secret m8-monoskope-tls-cert -o jsonpath='{.data.ca\.crt}' | base64 -D > tmp/domain-ca.crt
	@echo "server: api.monoskope.dev:8443" > tmp/monoctl-devconfig

deploy-cleanup: ## uninstall everything again
	@echo "cleaning up..."
	@rm -R ./tmp || true
	@kind delete cluster --name ${K8S_CLUSTER_NAME}

template: helm-repo ## template chart
	helm template finleap-connect/monoskope --version $(MONOSKOPE_VERSION) --values $(MONOSKOPE_HELM_VALUES_FILE) > tmp/m8.yaml
