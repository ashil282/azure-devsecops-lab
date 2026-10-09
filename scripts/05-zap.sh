#!/usr/bin/env bash
# OWASP ZAP baseline (passive DAST) against the running app.
# Run ONE heavy tool at a time.
#
# Usage:
# ./scripts/05-zap.sh [target-url]
#
# Default:
# http://localhost:8080

set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-http://localhost:8080}"

mkdir -p reports
cp .zap/rules.tsv reports/rules.tsv
chmod 777 reports

docker run --rm \
  --network host \
  -v "$PWD/reports:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
    -t "$TARGET" \
    -c rules.tsv \
    -r zap-report.html \
    -J zap-report.json \
    -I

echo "Report: reports/zap-report.html"
