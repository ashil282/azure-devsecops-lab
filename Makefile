.PHONY: all tools cluster argocd kyverno deploy zap scan

all: scan

tools:
	./scripts/00-install-tools.sh

cluster:
	./scripts/01-cluster.sh

argocd:
	./scripts/02-argocd.sh

kyverno:
	./scripts/03-kyverno.sh

deploy:
	./scripts/04-deploy-local.sh

zap:
	./scripts/05-zap.sh

scan:
	./scripts/06-local-scan.sh
