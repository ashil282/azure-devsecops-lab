#!/usr/bin/env bash
# Build -> scan -> load into kind -> deploy.
# Works without GitHub or a registry.
set -euo pipefail

cd "$(dirname "$0")/.."

IMAGE="devsecops-lab:local"

docker build -t "$IMAGE" .

trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  "$IMAGE"

kind load docker-image "$IMAGE" --name devsecops

kubectl kustomize k8s |
  sed -E "s#^( *image: ).*#\1${IMAGE}#" |
  kubectl apply -f -

kubectl -n devsecops rollout status \
  deployment/devsecops-app \
  --timeout=120s

echo
echo "App is up: http://localhost:8080"

curl -fsS http://localhost:8080/api/info && echo
