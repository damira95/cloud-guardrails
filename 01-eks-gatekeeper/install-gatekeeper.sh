#!/usr/bin/env bash
set -euo pipefail

# Install Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

echo "Waiting for Gatekeeper to be ready..."
kubectl -n gatekeeper-system rollout status deploy/gatekeeper-controller-manager

# Check pods
kubectl -n gatekeeper-system get pods

