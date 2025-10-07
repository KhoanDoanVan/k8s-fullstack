#!/bin/bash
set -e

echo "Creating kind cluster..."
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
  - containerPort: 443
    hostPort: 443
EOF

echo "Installing nginx-ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Installing Linkerd..."
curl -sL https://run.linkerd.io/install | sh
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check

echo "Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo "Generating TLS certificates with mkcert..."
mkcert -install
mkcert -cert-file tls.crt -key-file tls.key "*.local"
kubectl create secret tls tls-secret -n services --cert=tls.crt --key=tls.key

echo "Adding hosts to /etc/hosts..."
echo "127.0.0.1 api.local grafana.local keycloak.local" | sudo tee -a /etc/hosts

echo "Cluster ready! Run 'tilt up' to start development"
