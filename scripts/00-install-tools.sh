#!/usr/bin/env bash
# Installs the free DevSecOps toolchain on Ubuntu 22.04/24.04 (amd64).
# Safe to re-run. A failed optional tool is reported at the end instead of aborting everything.
set -euo pipefail

if [ "$(dpkg --print-architecture)" != "amd64" ]; then
  echo "This script targets amd64 Ubuntu." >&2
  exit 1
fi

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

FAILED=()
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

step() {
  local name="$1"
  shift
  echo
  echo "==> ${name}"
  if ! "$@"; then
    echo "!! ${name} failed (continuing)"
    FAILED+=("${name}")
  fi
}

have() {
  command -v "$1" >/dev/null 2>&1
}

gh_latest_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name
}

install_bin() {
  $SUDO install -m 0755 "$1" "/usr/local/bin/$2"
}

base_packages() {
  $SUDO apt-get update -y
  $SUDO apt-get install -y ca-certificates curl gnupg jq git unzip make shellcheck \
    python3 python3-pip python3-venv pipx lsb-release apt-transport-https software-properties-common
  pipx ensurepath || true
}

install_docker() {
  if have docker; then
    echo "docker already installed"
    return 0
  fi

  curl -fsSL https://get.docker.com | $SUDO sh
  $SUDO usermod -aG docker "${SUDO_USER:-$USER}" || true
  echo "NOTE: log out and back in (or run 'newgrp docker') so docker works without sudo."
}

install_kubectl() {
  have kubectl && {
    echo "kubectl already installed"
    return 0
  }

  local v
  v="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$TMP/kubectl" \
    "https://dl.k8s.io/release/${v}/bin/linux/amd64/kubectl"
  install_bin "$TMP/kubectl" kubectl
}

install_kind() {
  have kind && {
    echo "kind already installed"
    return 0
  }

  local v
  v="$(gh_latest_tag kubernetes-sigs/kind)"
  curl -fsSL -o "$TMP/kind" \
    "https://kind.sigs.k8s.io/dl/${v}/kind-linux-amd64"
  install_bin "$TMP/kind" kind
}

install_helm() {
  have helm && {
    echo "helm already installed"
    return 0
  }

  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 |
    $SUDO bash
}

install_trivy() {
  have trivy && {
    echo "trivy already installed"
    return 0
  }

  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key |
    $SUDO gpg --dearmor -o /usr/share/keyrings/trivy.gpg

  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" |
    $SUDO tee /etc/apt/sources.list.d/trivy.list >/dev/null

  $SUDO apt-get update -y
  $SUDO apt-get install -y trivy
}

install_gitleaks() {
  have gitleaks && {
    echo "gitleaks already installed"
    return 0
  }

  local v
  v="$(gh_latest_tag gitleaks/gitleaks)"

  curl -fsSL \
    "https://github.com/gitleaks/gitleaks/releases/download/${v}/gitleaks_${v#v}_linux_x64.tar.gz" |
    tar -xz -C "$TMP" gitleaks

  install_bin "$TMP/gitleaks" gitleaks
}

install_hadolint() {
  have hadolint && {
    echo "hadolint already installed"
    return 0
  }

  local base="https://github.com/hadolint/hadolint/releases/latest/download"

  curl -fsSL -o "$TMP/hadolint" "${base}/hadolint-linux-x86_64" ||
    curl -fsSL -o "$TMP/hadolint" "${base}/hadolint-Linux-x86_64"

  install_bin "$TMP/hadolint" hadolint
}

install_cosign() {
  have cosign && {
    echo "cosign already installed"
    return 0
  }

  curl -fsSL -o "$TMP/cosign" \
    "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"

  install_bin "$TMP/cosign" cosign
}

install_syft() {
  have syft && {
    echo "syft already installed"
    return 0
  }

  curl -fsSL https://raw.githubusercontent.com/anchore/syft/main/install.sh |
    $SUDO sh -s -- -b /usr/local/bin
}

install_grype() {
  have grype && {
    echo "grype already installed"
    return 0
  }

  curl -fsSL https://raw.githubusercontent.com/anchore/grype/main/install.sh |
    $SUDO sh -s -- -b /usr/local/bin
}

install_conftest() {
  have conftest && {
    echo "conftest already installed"
    return 0
  }

  local v
  v="$(gh_latest_tag open-policy-agent/conftest)"

  curl -fsSL \
    "https://github.com/open-policy-agent/conftest/releases/download/${v}/conftest_${v#v}_Linux_x86_64.tar.gz" |
    tar -xz -C "$TMP"

  install_bin "$TMP/conftest" conftest
}

install_kubeconform() {
  have kubeconform && {
    echo "kubeconform already installed"
    return 0
  }

  curl -fsSL \
    "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz" |
    tar -xz -C "$TMP" kubeconform

  install_bin "$TMP/kubeconform" kubeconform
}

install_kyverno_cli() {
  have kyverno && {
    echo "kyverno CLI already installed"
    return 0
  }

  local v
  v="$(gh_latest_tag kyverno/kyverno)"

  curl -fsSL \
    "https://github.com/kyverno/kyverno/releases/download/${v}/kyverno-cli_${v}_linux_x86_64.tar.gz" |
    tar -xz -C "$TMP" kyverno

  install_bin "$TMP/kyverno" kyverno
}

install_argocd_cli() {
  have argocd && {
    echo "argocd CLI already installed"
    return 0
  }

  curl -fsSL -o "$TMP/argocd" \
    "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"

  install_bin "$TMP/argocd" argocd
}

install_act() {
  have act && {
    echo "act already installed"
    return 0
  }

  curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh |
    $SUDO bash -s -- -b /usr/local/bin
}

install_terraform() {
  have terraform && {
    echo "terraform already installed"
    return 0
  }

  curl -fsSL https://apt.releases.hashicorp.com/gpg |
    $SUDO gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg

  echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
    $SUDO tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  $SUDO apt-get update -y
  $SUDO apt-get install -y terraform
}

install_tflint() {
  have tflint && {
    echo "tflint already installed"
    return 0
  }

  curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh |
    $SUDO bash
}

install_azcli() {
  have az && {
    echo "azure cli already installed"
    return 0
  }

  curl -fsSL https://aka.ms/InstallAzureCLIDeb |
    $SUDO bash
}

install_bicep() {
  have az || return 1
  az bicep install
}

install_pipx_tools() {
  for t in checkov semgrep pre-commit yamllint ruff; do
    if have "$t"; then
      echo "$t already installed"
    else
      pipx install "$t"
    fi
  done
}

pull_zap() {
  docker pull ghcr.io/zaproxy/zaproxy:stable
}

step "Base packages" base_packages
step "Docker" install_docker
step "kubectl" install_kubectl
step "kind" install_kind
step "Helm" install_helm
step "Trivy" install_trivy
step "Gitleaks" install_gitleaks
step "Hadolint" install_hadolint
step "Cosign" install_cosign
step "Syft (SBOM)" install_syft
step "Grype" install_grype
step "Conftest (OPA)" install_conftest
step "Kubeconform" install_kubeconform
step "Kyverno CLI" install_kyverno_cli
step "Argo CD CLI" install_argocd_cli
step "act (run GitHub Actions locally)" install_act
step "Terraform" install_terraform
step "TFLint" install_tflint
step "Azure CLI" install_azcli
step "Bicep" install_bicep
step "pipx tools (checkov, semgrep, pre-commit, yamllint, ruff)" install_pipx_tools

if have docker && docker info >/dev/null 2>&1; then
  step "OWASP ZAP image" pull_zap
else
  echo "Skipping ZAP image pull: docker is not usable yet."
  echo "After re-login, run: docker pull ghcr.io/zaproxy/zaproxy:stable"
fi

echo
echo "==================== Installed versions ===================="

for c in docker kubectl kind helm trivy gitleaks hadolint cosign syft grype \
  conftest kubeconform kyverno argocd act terraform tflint az checkov \
  semgrep pre-commit; do

  if have "$c"; then
    printf '%-12s OK\n' "$c"
  else
    printf '%-12s MISSING\n' "$c"
  fi
done

if [ "${#FAILED[@]}" -gt 0 ]; then
  echo
  echo "These steps failed and can be re-run by executing this script again:"
  echo "${FAILED[*]}"
  exit 1
fi

echo "All tools installed."
