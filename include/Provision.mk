
operator:
	kubectl -n $(OPERATOR_NAMESPACE) apply -f deploy/service_account.yaml
	kubectl apply -f deploy/role.yaml
	kubectl apply -f deploy/role_binding.yaml
	kubectl -n $(OPERATOR_NAMESPACE) apply -f deploy/operator.yaml
	kubectl -n $(OPERATOR_NAMESPACE) apply -f deploy/crds/blueocean_v1alpha1_devops_tools_crd.yaml

clean:
	kubectl -n $(PROVISION_NAMESPACE) delete blueoceans,ingresses,deployments,services -l app=blueocean-server --include-uninitialized
	kubectl -n $(PROVISION_NAMESPACE) delete roles,rolebindings,certificates,secrets -l app=blueocean-server --include-uninitialized
	kubectl delete clusterroles,clusterrolebindings -l app=blueocean-server --include-uninitialized
#	kubectl -n $(PROVISION_NAMESPACE) delete secrets -l certmanager.k8s.io/certificate-name=menora-corp-ad-ldapproxy-tls-cert --include-uninitialized

purge: clean
	kubectl -n $(OPERATOR_NAMESPACE) delete -f deploy/crds/blueocean_v1alpha1_devops_tools_crd.yaml
	kubectl -n $(OPERATOR_NAMESPACE) delete -f deploy/operator.yaml
	kubectl -n $(OPERATOR_NAMESPACE) delete -f deploy/service_account.yaml
	kubectl delete -f deploy/role.yaml
	kubectl delete -f deploy/role_binding.yaml

provision:
	kubectl -n $(PROVISION_NAMESPACE) apply -f deploy/crds/blueocean_v1alpha1_devops-tools_cr.yaml
