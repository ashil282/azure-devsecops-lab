#!/usr/bin/env bash

# Creates a single-node kind cluster (about 1-1.5 GB RAM).

set -euo pipefail

cd "$(dirname "$0")/.."

if ! docker info >/dev/null 2>&1; then
  echo "Docker is not usable. Run 'newgrp docker' or log out/in after installing." >&2
  exit 1
fi

if kind get clusters 2>/dev/null | grep -qx devsecops; then
  echo "Cluster 'devsecops' already exists."
else
  kind create cluster --config scripts/kind-config.yaml
fi

kubectl cluster-info --context kind-devsecops

kubectl wait \
  --for=condition=Ready \
  node --all \
  --timeout=120s

echo "Cluster ready. Free RAM check:"
free -h | head -2
