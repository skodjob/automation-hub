#!/usr/bin/env bash

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="${DIR}/../../.."
TEALC_CONFIG=${REPO_ROOT}/tealc-ci-test.yaml
if [ -z "$GITHUB_HEAD_REF" ]
then
    BRANCH="HEAD"
else
    BRANCH=$GITHUB_HEAD_REF
fi
echo $BRANCH

kubectl create namespace argocd
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
kubectl apply -n argocd -f "${REPO_ROOT}/secrets/argo-secret.yaml"
sed 's@pipelines@pipelines/test@g' argo/projects/tealc-ci.yaml > $TEALC_CONFIG
sed -i "s@HEAD@$BRANCH@g" $TEALC_CONFIG
kubectl apply -f $TEALC_CONFIG

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
kubectl wait pipelinerun pipeline-run-test-2 -n tealc-ci --for condition=Succeeded --timeout 120s
