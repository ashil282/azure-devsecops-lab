#!/usr/bin/env bash
# Usage:
# ./scripts/set-owner.sh <your-github-username>
#
# Replaces the OWNER placeholder in manifests/policies
# with your GitHub username.

set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -ne 1 ]; then
  echo "Usage: $0 <github-username>" >&2
  exit 1
fi

OWNER="$1"
OWNER_LOWER="$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')"

# Image names must be lowercase.
# GitHub URLs keep the original username casing.
sed -i \
  "s#ghcr.io/OWNER/#ghcr.io/${OWNER_LOWER}/#g" \
  k8s/deployment.yaml \
  k8s/kustomization.yaml \
  policies/kyverno/verify-image-signature.yaml

sed -i \
  "s#github.com/OWNER/#github.com/${OWNER}/#g" \
  argocd/application.yaml \
  policies/kyverno/verify-image-signature.yaml

echo "Owner set to ${OWNER}."
echo "Remaining placeholders (should be none):"

grep -rn "OWNER" k8s argocd policies || echo "none"
