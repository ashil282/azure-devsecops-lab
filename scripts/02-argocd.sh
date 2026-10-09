#!/usr/bin/env bash
# Installs Argo CD (GitOps) and trims it to save RAM.
set -euo pipefail

cd "$(dirname "$0")/.."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Server-side apply is required: the ApplicationSet CRD exceeds
# the client-side annotation size limit.
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# RAM savers for a small lab machine:
# SSO (dex) and notifications are not needed here.
kubectl -n argocd scale deployment argocd-dex-server --replicas=0 || true
kubectl -n argocd scale deployment argocd-notifications-controller --replicas=0 || true

kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d

echo
echo
echo "Open the UI:"
echo "kubectl -n argocd port-forward svc/argocd-server 8081:443"

echo "Then browse:"
echo "https://localhost:8081"

echo "User: admin"
echo
echo "Deploy the app from Git after scripts/set-owner.sh and pushing to GitHub:"
echo "kubectl apply -f argocd/application.yaml"
