#!/usr/bin/env bash

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="${DIR}/../../.."

kubectl create namespace argocd
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
kubectl apply -n argocd -f "${REPO_ROOT}/secrets/argo-secret.yaml"
kubectl apply -f "${REPO_ROOT}/argo/projects/tealc-ci.yaml"

sleep 30

kubectl wait pod -l app.kubernetes.io/name=argocd-server -n argocd --for condition=ready --timeout 120s

echo "[INFO] Wait for deployment of tealc ci"
for i in {1..100}; do
    if [[ "$(kubectl get ns tealc-ci)" != "" ]] \
        && [[ "$(kubectl get po -n tealc-ci)" != "" ]]; then
        echo "[INFO] Tealc CI configured"
        break
    else
        echo "[WARN] Tealc CI is not configured"
        sleep 10
    fi
done

kubectl wait pipelinerun pipeline-run-test -n tealc-ci --for condition=Succeeded --timeout 120s
