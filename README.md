# Azure DevSecOps Lab

[![CI](https://github.com/OWNER/azure-devsecops-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/azure-devsecopslab/actions/workflows/ci.yml)
[![CodeQL](https://github.com/OWNER/azure-devsecops-lab/actions/workflows/codeql.yml/badge.svg)](https://github.com/OWNER/azure-devsecopslab/actions/workflows/codeql.yml)
[![Build, sign, deploy](https://github.com/OWNER/azure-devsecops-lab/actions/workflows/build-sign-deploy.yml/badge.svg)](https://github.com/OWNER/azure-devsecops-lab/actions/workflows/build-sign-deploy.yml)
[![IaC security](https://github.com/OWNER/azure-devsecops-lab/actions/workflows/iac-security.yml/badge.svg)](https://github.com/OWNER/azuredevsecops-lab/actions/workflows/iac-security.yml)

A practical, zero-cost DevSecOps platform built specifically for Azure engineers. Run a fully secured Flask microservice through a strict security-gated pipeline that ends in a cryptographically signed container image. Deployed using GitOps to a local Kubernetes cluster wrapped with admission controllers and security policies. Infrastructure code is included via Bicep and Terraform, fully scanned, requiring **no paid Azure subscription**.

---

## Architecture Flow

```text
developer ──► pre-commit hooks (gitleaks, ruff, hadolint, checkov)
    │
    ▼ git push
GitHub ──► 1-ci: Gitleaks │ ruff/yamllint/hadolint │ pytest+coverage │ Semgrep
       ├─► 2-codeql: CodeQL (security-extended analysis)
       ├─► 3-build-sign: Docker build ──► Trivy gate ──► GHCR push ──► Syft SBOM ──► Cosign keyless signing
       │     └─► automatic bot commit updating image tag in k8s/ (GitOps workflow)
       ├─► 4-iac-security: Bicep build │ terraform validate │ TFLint │ Checkov │ Trivy config │ Conftest OPA │ Kyverno CLI │ Kubeconform
       └─► 5-dast: OWASP ZAP baseline scan against running container
    │
    ▼ all unified findings piped to GitHub Security tab (SARIF format)
Argo CD (kind cluster) ◄── watches k8s/ ──► Kyverno admission policies + Pod Security "restricted" profile
                         + verified Cosign signatures + NetworkPolicy default-deny
