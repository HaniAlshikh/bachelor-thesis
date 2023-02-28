# kind
K8S_VERSION=1.24.7
KIND_KUBECONFIG = $(LOCALTMP)/kind-kubeconfig
KIND_M8_CLUSTER_NAME ?= m8-dev-cluster

# values
CERT_MANAGER_HELM_VALUES_FILE		?= setup/cert-manager.yaml
CERT_MANAGER_ISSUER_RESOURCE_FILE		?= setup/cert-manager-issuer.yaml
EMISSARY_INGRESS_HELM_VALUES_FILE		?= setup/emissary-ingress.yaml
DEX_HELM_VALUES_FILE		?= setup/dex.yaml
MONOSKOPE_HELM_VALUES_FILE		?= setup/m8.yaml
EMISSARY_INGRESS_LISTENER_RESOURCE_FILE		?= setup/emissary-ingress-listener.yaml
MONOGUI_HELM_VALUES_FILE		?= setup/monogui.yaml

MOCK_DATA_RESOURCE_FILE		?= setup/m8-eventstore-mock-data.yaml

# versions
CERT_MANAGER_VERSION ?= v1.11.0
EMISSARY_VERSION ?= 3.4.0
EMISSARY_INGRESS_CHART_VERSION ?= 8.4.0
DEX_VERSION ?= 0.8.2
MONOSKOPE_VERSION ?= v0.5.2
MONOGUI_VERSION ?= v0.1.0

MONOSKOPECONFIG ?= $(LOCALTMP)/monoctl-devconfig
KIND_KUBECTL ?= $(KUBECTL) --kubeconfig ${KIND_KUBECONFIG}
KIND_HELM ?= $(HELM) --kubeconfig ${KIND_KUBECONFIG}

##@ Manage

.PHONY: kind-watch
kind-watch: kubectl ## watch monoskope beain deployed
	@watch "$(KIND_KUBECTL) get no -owide; echo; $(KIND_KUBECTL) get po -A"

.PHONY: port-forward
port-forward: kubectl ## create a port-forward to the m8Api, dex and monogui
	@KUBECTL=$(KUBECTL) KUBECONFIG=$(KIND_KUBECONFIG) sh ./port-forward.sh

.PHONY: mock-data
mock-data: monoctl ## create some aggregates in monoskope to enrich UX
	@echo $(MONOCTL)
	@MONOCTL=$(MONOCTL) MONOSKOPECONFIG=$(MONOSKOPECONFIG) $(BASH) ./mock-data.sh

.PHONY: trust-m8-ca
trust-m8-ca: ## trust monoskope certificate authority (OSX only)
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" $(LOCALTMP)/ca.crt

##@ Deploy

.PHONY: deploy
deploy: deploy-cleanup kind-create-cluster deploy-m8-trust-anchor deploy-cert-manager deploy-emissary-ingress deploy-dex deploy-monoskope deploy-monogui ## deploy monoskope and monogui


.PHONY: kind-create-cluster
kind-create-cluster: kind ## create kind cluster
	@$(KIND) create cluster --name ${KIND_M8_CLUSTER_NAME} --image kindest/node:v${K8S_VERSION} --kubeconfig ${KIND_KUBECONFIG}
	@$(KIND) get kubeconfig --name ${KIND_M8_CLUSTER_NAME} > ${KIND_KUBECONFIG}

.PHONY: deploy-m8-trust-anchor
deploy-m8-trust-anchor: kubectl step ## create trust-anchor in kind cluster
	@$(ECHO) "Generating trust-anchor for m8 PKI..."
	@$(STEP) certificate create root.monoskope.cluster.local $(LOCALTMP)/ca.crt $(LOCALTMP)/ca.key --profile root-ca --no-password --insecure --not-after=87600h
	@$(ECHO) "Creating secret containing trust-anchor in kind cluster..."
	@$(KIND_KUBECTL) create namespace monoskope --dry-run=client -o yaml | $(KIND_KUBECTL) apply -f -
	@$(KIND_KUBECTL) -n monoskope create secret tls m8-trust-anchor --cert=$(LOCALTMP)/ca.crt --key=$(LOCALTMP)/ca.key --dry-run=client -o yaml | $(KIND_KUBECTL) apply -f -

.PHONY: deploy-cert-manager
deploy-cert-manager: helm kubectl helm-repo ## deploy dex
	@$(KIND_HELM) upgrade -i cert-manager -n cert-manager --create-namespace jetstack/cert-manager --version $(CERT_MANAGER_VERSION) --values $(CERT_MANAGER_HELM_VALUES_FILE)
	@$(KIND_KUBECTL) -n cert-manager create secret tls m8-trust-anchor --cert=$(LOCALTMP)/ca.crt --key=$(LOCALTMP)/ca.key --dry-run=client -o yaml | $(KIND_KUBECTL) apply -f -
	@$(KIND_KUBECTL) apply -f $(CERT_MANAGER_ISSUER_RESOURCE_FILE)

.PHONY: deploy-emissary-ingress
deploy-emissary-ingress: kubectl #helm helm-repo ## deploy emissary-ingress
	@$(KIND_KUBECTL) apply -f https://app.getambassador.io/yaml/emissary/$(EMISSARY_VERSION)/emissary-crds.yaml
	@$(KIND_KUBECTL) -n emissary-system patch deploy emissary-apiext -p '{"spec":{"replicas": 1}}'
	@$(KIND_KUBECTL) wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
	@$(KIND_HELM) upgrade -i ei -n emissary --create-namespace datawire/emissary-ingress --version $(EMISSARY_INGRESS_CHART_VERSION) --values $(EMISSARY_INGRESS_HELM_VALUES_FILE) \
		--set=image.tag=$(EMISSARY_VERSION)

.PHONY: deploy-dex
deploy-dex: kubectl helm helm-repo ## deploy dex
	@$(KIND_HELM) upgrade -i dex -n monoskope --create-namespace dex/dex --version $(DEX_VERSION) --values $(DEX_HELM_VALUES_FILE)
	@$(KIND_KUBECTL) -n monoskope create secret generic m8-gateway-oidc --from-literal=oidc-clientid=gateway --from-literal=oidc-clientsecret=verysecretclientsecret --from-literal=oidc-nonce=somerandomstring --dry-run=client -o yaml | $(KIND_KUBECTL) apply -f -

.PHONY: deploy-monoskope
deploy-monoskope: helm kubectl helm-repo ## deploy monoskope
	@$(KIND_HELM) upgrade -i m8 -n monoskope --create-namespace finleap-connect/monoskope --version $(MONOSKOPE_VERSION) --values $(MONOSKOPE_HELM_VALUES_FILE)
	@$(KIND_KUBECTL) apply -f $(EMISSARY_INGRESS_LISTENER_RESOURCE_FILE)
	@$(KIND_KUBECTL) wait --timeout=90s --for=condition=ready certificate m8-monoskope-tls-cert -n monoskope
	@$(ECHO) "server: api.monoskope.dev:8443" > $(MONOSKOPECONFIG)

.PHONY: deploy-monogui
deploy-monogui: helm kubectl helm-repo ## deploy monoskope
	@$(KIND_HELM) upgrade -i monogui -n monoskope --create-namespace H-S/monogui --version $(MONOGUI_VERSION) --values $(MONOGUI_HELM_VALUES_FILE)

.PHONY: deploy-cleanup
deploy-cleanup: kind ## uninstall everything again
	@$(ECHO) "cleaning up..."
	@$(KIND) delete cluster --name ${KIND_M8_CLUSTER_NAME}
	@$(RM) -R $(LOCALTMP) || true


##@ Build Dependencies
ARCH := $(shell sh -c 'uname -m 2>/dev/null || echo not')
OS := $(shell sh -c 'uname -s 2>/dev/null | tr A-Z a-z || echo not')

# kubectl
KUBECTL ?= $(LOCALBIN)/kubectl
KUBECTL_VERSION ?= $(K8S_VERSION)
KUBECTL_OS = $(OS)
KUBECTL_ARCH = $(ARCH)
ifeq ($(ARCH),x86_64)
	KUBECTL_ARCH = amd64
endif

kubectl: $(KUBECTL) ## Download kubectl locally if necessary.
$(KUBECTL): $(LOCALBIN)
	@$(CURL) -L -o $(KUBECTL) "https://dl.k8s.io/release/v$(KUBECTL_VERSION)/bin/$(KUBECTL_OS)/$(KUBECTL_ARCH)/kubectl"
	@chmod +x $(KUBECTL)

# kind
KIND ?= $(LOCALBIN)/kind
KIND_VERSION ?= 0.17.0
KIND_OS = $(KUBECTL_OS)
KIND_ARCH = $(KUBECTL_ARCH)

kind: $(KIND) ## Download kind locally if necessary.
$(KIND): $(LOCALBIN)
	@$(CURL) -L -o $(KIND) "https://kind.sigs.k8s.io/dl/v$(KIND_VERSION)/kind-$(KIND_OS)-$(KIND_ARCH)"
	@chmod +x $(KIND)

# step
STEP ?= $(LOCALBIN)/step
STEP_VERSION ?= 0.23.2
STEP_OS = $(KUBECTL_OS)
STEP_ARCH = $(KUBECTL_ARCH)

step: $(STEP) ## Download step locally if necessary.
$(STEP): $(LOCALBIN)
	@$(CURL) -L -o step.tar.gz "https://dl.step.sm/gh-release/cli/gh-release-header/v$(STEP_VERSION)/step_$(STEP_OS)_$(STEP_VERSION)_$(STEP_ARCH).tar.gz"
	@mkdir -p $(LOCALBIN)/step-tmp
	@$(TAR) zxvf step.tar.gz -C $(LOCALBIN)/step-tmp --strip-components=2
	@mv $(LOCALBIN)/step-tmp/step $(LOCALBIN)/step
	@$(RM) -r step.tar.gz $(LOCALBIN)/step-tmp
	@chmod +x $(STEP)

# monoctl
MONOCTL ?= $(LOCALBIN)/monoctl
MONOCTL_VERSION ?= 0.5.4
MONOCTL_OS = $(OS)
MONOCTL_ARCH = $(KUBECTL_ARCH)
ifeq ($(OS),darwin)
	MONOCTL_OS = osx
endif

monoctl: $(MONOCTL) ## Download monoctl locally if necessary.
$(MONOCTL): $(LOCALBIN)
	@$(CURL) -L -o monoctl.tar.gz "https://github.com/finleap-connect/monoctl/releases/download/v$(MONOCTL_VERSION)/monoctl-$(MONOCTL_OS)-$(MONOCTL_ARCH).tar.gz"
	@$(TAR) -zxvf monoctl.tar.gz -C $(LOCALBIN) "monoctl"
	@$(RM) monoctl.tar.gz
	@chmod +x $(MONOCTL)

# helm
HELM ?= $(LOCALBIN)/helm
HELM_VERSION ?= 3.11.1
HELM_HOME ?= $(LOCALBIN)/helm-home
$(HELM_HOME): $(LOCALBIN)
	@mkdir -p $(HELM_HOME)
export HELM_REGISTRY_CONFIG = $(HELM_HOME)/config.json
export HELM_REPOSITORY_CACHE = $(HELM_HOME)
export HELM_REPOSITORY_CONFIG = $(HELM_HOME)/repositories.yaml
export HELM_PLUGINS = $(HELM_HOME)
export HELM_DATA_HOME = $(HELM_HOME)
export HELM_CONFIG_HOME = $(HELM_HOME)
export HELM_CACHE_HOME = $(HELM_HOME)

helm: $(HELM) ## Download helm locally if necessary.
$(HELM): $(LOCALBIN) $(HELM_HOME)
	@$(CURL) https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | PATH=$(LOCALBIN):$(PATH) HELM_INSTALL_DIR=$(LOCALBIN) DESIRED_VERSION=v$(HELM_VERSION) USE_SUDO="false" $(BASH)
	@touch $(HELM_REPOSITORY_CONFIG)

helm-repo: helm $(HELM_REGISTRY_CONFIG) ## add necessary chart repos
$(HELM_REGISTRY_CONFIG): $(HELM_HOME)
	@$(HELM) repo add jetstack https://charts.jetstack.io
	@$(HELM) repo add datawire https://getambassador.io
	@$(HELM) repo add dex https://charts.dexidp.io
	@$(HELM) repo add finleap-connect https://finleap-connect.github.io/charts/
	@$(HELM) repo add H-S https://charts.alshikh.de
	@$(HELM) repo update