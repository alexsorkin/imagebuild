PROJECT_VERSION = 1.0.5
REGISTRY_MIRROR = 192.168.99.102:5000
PRODUCT_IMAGE_BASE = devops-tools

DEFAULT_PULL_REGISTRY = docker.io/menoraaf
DEFAULT_PUSH_REGISTRY = docker.io/menoraaf

OPERATOR_NAMESPACE = kube-system
DEFAULT_PROVISION_NAMESPACE = blueocean

DEFAULT_EXTRACT_DIRECTORY=/tmp
EXTRACT_DIRECTORY = $(DEFAULT_EXTRACT_DIRECTORY)

ifneq ($(strip $(PROVISION_NAMESPACE)),)
  PROVISION_NAMESPACE = $(PROVISION_NAMESPACE)
else
  PROVISION_NAMESPACE = $(DEFAULT_PROVISION_NAMESPACE)
endif

ifneq ($(strip $(PULL_REGISTRY)),)
  PULL_REGISTRY = $(PULL_REGISTRY)
else
  PULL_REGISTRY = $(DEFAULT_PULL_REGISTRY)
endif

ifneq ($(strip $(PUSH_REGISTRY)),)
  PUSH_REGISTRY = $(PUSH_REGISTRY)
else
  PUSH_REGISTRY = $(DEFAULT_PUSH_REGISTRY)
endif

#BUILD_IMAGES := bootstraper
BUILD_IMAGES += blueocean-server
BUILD_IMAGES += blueocean-jnlp
#BUILD_IMAGES += blueocean-docker
#BUILD_IMAGES += blueocean-consul-template
#BUILD_IMAGES += blueocean-kubectl
#BUILD_IMAGES += blueocean-ansible
BUILD_IMAGES += blueocean-all
#BUILD_IMAGES += gitea-runtime
#BUILD_IMAGES += operator
#BUILD_IMAGES += ldapproxy-runtime
#BUILD_IMAGES += ldapexporter-runtime
BUILD_LANG_IMAGES = python
BUILD_LANG_IMAGES += python3
#BUILD_LANG_IMAGES += pandas
###BUILD_LANG_IMAGES += opencv
#BUILD_LANG_IMAGES += node10
#BUILD_LANG_IMAGES += node10-sdk
#BUILD_LANG_IMAGES += node10-py
#BUILD_LANG_IMAGES += node10-ora
#BUILD_LANG_IMAGES += node10-etl
#BUILD_LANG_IMAGES += node12
#BUILD_LANG_IMAGES += node12-sdk
#BUILD_LANG_IMAGES += node12-py
#BUILD_LANG_IMAGES += node12-ora
#BUILD_LANG_IMAGES += node12-etl
BUILD_LANG_IMAGES += node14
BUILD_LANG_IMAGES += node14-sdk
BUILD_LANG_IMAGES += node14-py
BUILD_LANG_IMAGES += node14-ora
BUILD_LANG_IMAGES += node14-etl
BUILD_LANG_IMAGES += gotenberg
BUILD_LANG_IMAGES += imagick-sdk
BUILD_LANG_IMAGES += princexml
BUILD_LANG_IMAGES += princexml-sdk
#BUILD_LANG_IMAGES += puppeteer
BUILD_LANG_IMAGES += cypress
BUILD_LANG_IMAGES += dotnet
BUILD_LANG_IMAGES += dotnet-sdk
#BUILD_LANG_IMAGES += node8
#BUILD_LANG_IMAGES += node8-sdk
BUILD_LANG_IMAGES += java8-jre
BUILD_LANG_IMAGES += java8-jdk
BUILD_LANG_IMAGES += java11-jre
BUILD_LANG_IMAGES += java11-jdk
BUILD_LANG_IMAGES += java15-jre
BUILD_LANG_IMAGES += java15-jdk
BUILD_LANG_IMAGES += ballerina-sdk
#BUILD_LANG_IMAGES += golang
#BUILD_LANG_IMAGES += golang-sdk

ifneq (,$(findstring kube,$(MAKECMDGOALS)))
  include $(SELF_DIR)include/Kube.mk
endif
ifneq (,$(findstring build,$(MAKECMDGOALS)))
  include $(SELF_DIR)include/Build.mk
endif
ifneq (,$(findstring pull,$(MAKECMDGOALS)))
  include $(SELF_DIR)include/Pull.mk
endif
ifneq (,$(findstring push,$(MAKECMDGOALS)))
  include $(SELF_DIR)include/Push.mk
endif

.PHONY: build push pull

# push cabundle minikube certmgr operator provision clean purge

all: build pull purge push operator provision

CERT_MANAGER_OPTIONS = --name cert-manager
CERT_MANAGER_OPTIONS += --namespace cert-manager
CERT_MANAGER_OPTIONS += stable/cert-manager
CA_COMMON_NAME = minikue.machine.com

builder:
	@docker-machine create --virtualbox-disk-size 80000 --virtualbox-memory 4096 --virtualbox-cpu-count=4 builder

jetstack:
	@helm install $(CERT_MANAGER_OPTIONS)

cabundle:
	@openssl genrsa -out ca.key 4096
	@openssl req -x509 -new -nodes -key ca.key -subj "/CN=${CA_COMMON_NAME}" -days 3650 -reqexts v3_req -extensions v3_ca -out ca.crt

certmgr:
	@kubectl -n $(OPERATOR_NAMESPACE) create secret tls ca-key-pair --cert=ca.crt --key=ca.key
	@kubectl -n $(OPERATOR_NAMESPACE) create -f deploy/cert-manager-issuer.yaml

#	kubectl -n $(PROVISION_NAMESPACE) create secret generic ca-bundle --from-file=ca_bundle=ca.crt

deploy:
	@helm install deploy/helm/devops-operator

destroy:
	@docker-machine rm builder
