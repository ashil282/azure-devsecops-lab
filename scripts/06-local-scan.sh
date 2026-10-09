#!/usr/bin/env bash
# Runs the whole shift-left security suite locally,
# the same checks the pipelines run.
#
# Output goes to reports/.
# Prints a PASS/FAIL table at the end.

set -uo pipefail

cd "$(dirname "$0")/.."

mkdir -p reports

RESULTS=()

run() {
  local name="$1"
  shift

  echo
  echo "==> ${name}"

  if "$@"; then
    RESULTS+=("PASS ${name}")
  else
    RESULTS+=("FAIL ${name}")
  fi
}

run "Gitleaks (secrets)" \
  gitleaks detect \
  --source . \
  --redact \
  --report-path reports/gitleaks.json

run "Hadolint (Dockerfile)" \
  hadolint \
  --config .hadolint.yaml \
  Dockerfile

run "yamllint" \
  yamllint \
  -c .yamllint.yml \
  k8s policies argocd .github

run "Ruff (lint)" \
  bash -c '
    python3 -m venv .venv &&
    . .venv/bin/activate &&
    pip install -q -r app/requirements-dev.txt &&
    ruff check app
  '

run "Pytest + coverage" \
  bash -c '
    . .venv/bin/activate &&
    pytest app/tests --cov=app --cov-fail-under=80 -q
  '

run "Semgrep (SAST)" \
  semgrep scan \
  --config p/ci \
  --config p/python \
  --config p/dockerfile \
  --error \
  --sarif \
  --output reports/semgrep.sarif \
  app

run "Docker build" \
  docker build \
  -t devsecops-lab:scan \
  .

run "Trivy image" \
  trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  --format table \
  --output reports/trivy-image.txt \
  devsecops-lab:scan

run "Syft SBOM" \
  syft devsecops-lab:scan \
  -o spdx-json=reports/sbom.spdx.json

run "Grype (SBOM)" \
  grype sbom:reports/sbom.spdx.json \
  --fail-on high

run "Trivy IaC/config" \
  trivy config \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  --format table \
  --output reports/trivy-config.txt \
  .

run "Checkov" \
  checkov \
  --config-file .checkov.yaml \
  --output-file-path reports

run "Bicep build" \
  az bicep build \
  --file infra/bicep/main.bicep \
  --stdout >/dev/null

run "Terraform validate" \
  bash -c '
    cd infra/terraform &&
    terraform init -backend=false -input=false >/dev/null &&
    terraform fmt -check -recursive &&
    terraform validate
  '

run "TFLint" \
  bash -c '
    cd infra/terraform &&
    tflint --init >/dev/null &&
    tflint
  '

run "Kustomize render" \
  bash -c '
    kubectl kustomize k8s > reports/rendered.yaml
  '

run "Kubeconform" \
  kubeconform \
  -strict \
  -summary \
  reports/rendered.yaml

run "Conftest (OPA)" \
  conftest test \
  reports/rendered.yaml \
  -p policies/conftest

run "Kyverno CLI" \
  kyverno apply \
  policies/kyverno/disallow-latest-tag.yaml \
  policies/kyverno/require-run-as-nonroot.yaml \
  policies/kyverno/requireresource-limits.yaml \
  policies/kyverno/disallow-privileged.yaml \
  --resource reports/rendered.yaml

echo
echo "==================== SUMMARY ===================="

printf '%s\n' "${RESULTS[@]}"

if printf '%s\n' "${RESULTS[@]}" | grep -q '^FAIL'; then
  exit 1
fi
