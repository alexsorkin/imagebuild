
#K8S_VERSION = v1.11.6

#DEFAULT_OIDC_SERVER := https://dex-minikube.machine.com:32000

MINIKUBE_OPTIONS = -p vanila
MINIKUBE_OPTIONS += --apiserver-name api.minikube.machine.com
#MINIKUBE_OPTIONS += --host-only-cidr 172.21.0.1/24
MINIKUBE_OPTIONS += --docker-opt dns=8.8.8.8
#MINIKUBE_OPTIONS += --docker-opt insecure-registry=$(REGISTRY_MIRROR)
#MINIKUBE_OPTIONS += --network-plugin=calico
#MINIKUBE_OPTIONS += --kubernetes-version $(K8S_VERSION)
MINIKUBE_OPTIONS += --memory 6144 --cpus 3 --disk-size 60g
MINIKUBE_OPTIONS += --bootstrapper kubeadm
#MINIKUBE_OPTIONS += --service-cluster-ip-range 172.22.0.1/24
#MINIKUBE_OPTIONS += --registry-mirror http://$(REGISTRY_MIRROR)
ifneq ($(strip $(OIDC_SERVER)),)
  MINIKUBE_OPTIONS += --extra-config=apiserver.authorization-mode=RBAC
  MINIKUBE_OPTIONS += --extra-config=apiserver.oidc-issuer-url=$(OIDC_SERVER)
  MINIKUBE_OPTIONS += --extra-config=apiserver.oidc-client-id=minikube-app
  MINIKUBE_OPTIONS += --extra-config=apiserver.oidc-ca-file=/var/lib/minikube/certs/ca.crt
  MINIKUBE_OPTIONS += --extra-config=apiserver.oidc-username-claim=email
  MINIKUBE_OPTIONS += --extra-config=apiserver.oidc-groups-claim=groups
endif

kube: minikube jetstack

minikube:
	minikube start $(MINIKUBE_OPTIONS)
	minikube profile vanila
	helm init

#	eval $(minikube docker-env -p vanila)
#	docker load -i ../ansible-operator-working.tar.gz

registry:
	docker run -d --net=host --restart=on-failure:5 --memory=256M --name=registry registry

