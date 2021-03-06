
KUBE_NAMESPACE ?= default
HELM_RELEASE = test
INGRESS_HOST = sticky.test.minikube.local

# define overides for above variables in here
-include PrivateRules.mak

.PHONY: vars k8s apply show deploy delete ls podlogs namespace help
.DEFAULT_GOAL := help

vars: ## Display variables - pass in DISPLAY and XAUTHORITY
	@echo "DISPLAY: $(DISPLAY)"
	@echo "Namespace: $(KUBE_NAMESPACE)"

k8s: ## Which kubernetes are we connected to
	@echo "Kubernetes cluster-info:"
	@kubectl cluster-info
	@echo ""
	@echo "kubectl version:"
	@kubectl version
	@echo ""
	@echo "Helm client version:"
	@helm version --client

namespace: ## create the kubernetes namespace
	kubectl describe namespace $(KUBE_NAMESPACE) || kubectl create namespace $(KUBE_NAMESPACE)

deploy: namespace  ## deploy the helm chart
	@helm template chart/sticky-test/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
	             --tiller-namespace $(KUBE_NAMESPACE) \
	             --set sticky.hostName="$(INGRESS_HOST)" | kubectl -n $(KUBE_NAMESPACE) apply -f -

show: ## show the helm chart
	@helm template chart/sticky-test/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
	             --tiller-namespace $(KUBE_NAMESPACE) \
	             --set sticky.hostName="$(INGRESS_HOST)"

lint:  ## lint the helm chart release
	@helm lint --namespace $(KUBE_NAMESPACE) \
		         --tiller-namespace $(KUBE_NAMESPACE) \
		         --set sticky.hostName="$(INGRESS_HOST)" \
	             chart/sticky-test/ --debug

delete: ## delete the helm chart release
	@helm template chart/sticky-test/ --name $(HELM_RELEASE) \
				 --namespace $(KUBE_NAMESPACE) \
         --tiller-namespace $(KUBE_NAMESPACE) \
         --set sticky.hostName="$(INGRESS_HOST)" | kubectl -n $(KUBE_NAMESPACE) delete -f -


poddescribe: ## describe Pods executed from Helm chart
	@for i in `kubectl -n $(KUBE_NAMESPACE) get pods -l release=$(HELM_RELEASE) -o=name`; \
	do echo "---------------------------------------------------"; \
	echo "Describe for $${i}"; \
	echo kubectl -n $(KUBE_NAMESPACE) describe $${i}; \
	echo "---------------------------------------------------"; \
	kubectl -n $(KUBE_NAMESPACE) describe $${i}; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

podlogs: ## show Helm chart POD logs
	@for i in `kubectl -n $(KUBE_NAMESPACE) get pods -l release=$(HELM_RELEASE) -o=name`; \
	do \
	echo "---------------------------------------------------"; \
	echo "Logs for $${i}"; \
	echo kubectl -n $(KUBE_NAMESPACE) logs $${i}; \
	echo kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.initContainers[*].name}"`; do \
	RES=`kubectl -n $(KUBE_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "initContainer: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "Main Pod logs for $${i}"; \
	echo "---------------------------------------------------"; \
	for j in `kubectl -n $(KUBE_NAMESPACE) get $${i} -o jsonpath="{.spec.containers[*].name}"`; do \
	RES=`kubectl -n $(KUBE_NAMESPACE) logs $${i} -c $${j} 2>/dev/null`; \
	echo "Container: $${j}"; echo "$${RES}"; \
	echo "---------------------------------------------------";\
	done; \
	echo "---------------------------------------------------"; \
	echo ""; echo ""; echo ""; \
	done

localip:  ## set local Minikube IP in /etc/hosts file for apigateway
	@new_ip=`minikube ip` && \
	existing_ip=`grep $(INGRESS_HOST) /etc/hosts || true` && \
	echo "New IP is: $${new_ip}" && \
	echo "Existing IP: $${existing_ip}" && \
	if [ -z "$${existing_ip}" ]; then echo "$${new_ip} $(INGRESS_HOST)" | sudo tee -a /etc/hosts; \
	else sudo perl -i -ne "s/\d+\.\d+.\d+\.\d+/$${new_ip}/ if /$(INGRESS_HOST)/; print" /etc/hosts; fi && \
	echo "/etc/hosts is now: " `grep $(INGRESS_HOST) /etc/hosts`

mkcerts:  ## Make dummy certificates for sticky.test.minikube.local and Ingress
	openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
	   -keyout chart/sticky-test/data/tls.key \
		 -out chart/sticky-test/data/tls.crt \
		 -subj "/CN=$(INGRESS_HOST)/O=Integration"

help:   ## show this help.
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
