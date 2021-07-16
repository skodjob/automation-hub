#!/usr/bin/env bash

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="${DIR}/../../.."

kubectl create ns test
kubectl create -f "${REPO_ROOT}/pipelines/test/" -n test
kubectl wait pipelinerun pipeline-run-test -n test --for condition=Succeeded --timeout 120s
kubectl delete ns test
