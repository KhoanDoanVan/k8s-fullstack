.PHONY: help setup-kind setup-k3d deploy-tilt deploy-skaffold clean

help:
	@echo "Available targets:"
	@echo "  setup-kind       - Create kind cluster with all dependencies"
	@echo "  setup-k3d        - Create k3d cluster with all dependencies"
	@echo "  deploy-tilt      - Deploy using Tilt"
	@echo "  deploy-skaffold  - Deploy using Skaffold"
	@echo "  clean            - Delete cluster and cleanup"

setup-kind:
	@echo "Setting up kind cluster..."
	@bash setup.sh


setup-k3d:
	@echo "Creating k3d cluster..."
	k3d cluster create --config k3d-config.yaml
	@echo "Installing nginx-ingress..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
	@echo "Installing Linkerd..."
	curl -sL https://run.linkerd.io/install | sh
	linkerd install --crds | kubectl apply -f -
	linkerd install | kubectl apply -f -
	@echo "Installing metrics-server..."
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
	@echo "Generating TLS certificates..."
	mkcert -install
	mkcert -cert-file tls.crt -key-file tls.key "*.local"
	kubectl create namespace services || true
	kubectl create secret tls tls-secret -n services --cert=tls.crt --key=tls.key || true
	@echo "Setup complete!"

deploy-tilt:
	tilt up

deploy-skaffold:
	skaffold dev

clean:
	@echo "Cleaning up..."
	kind delete cluster --name kind || true
	k3d cluster delete k8s-cluster || true
	rm -f tls.crt tls.key