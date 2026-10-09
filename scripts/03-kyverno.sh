#!/usr/bin/env bash
# Installs Kyverno (policy engine) with minimal replicas
# and applies the policies in policies/kyverno.
set -euo pipefail

cd "$(dirname "$0")/.."

helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null
helm repo update >/dev/null

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set admissionController.replicas=1 \
  --set backgroundController.replicas=1 \
  --set cleanupController.replicas=1 \
  --set reportsController.replicas=1 \
  --wait \
  --timeout 5m

kubectl apply -f policies/kyverno/

echo
kubectl get clusterpolicy

echo
echo "Try to break a policy (should be denied):"
echo "kubectl -n devsecops run bad --image=nginx:latest"
