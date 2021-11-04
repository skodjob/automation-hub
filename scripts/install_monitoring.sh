#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

SED=sed
GREP=grep
DATE=date

UNAME_S=$(uname -s)
if [ $UNAME_S = "Darwin" ];
then
    # MacOS GNU versions which can be installed through Homebrew
    SED=gsed
    GREP=ggrep
    DATE=gdate
fi

function wait_pod_exists() {
    NAMESPACE=$1
    CHECK_STRING=$2

    for i in {1..60}; do
        if [[ "$(kubectl get po -n ${NAMESPACE})" == *"${CHECK_STRING}"* ]]; then
            echo "[INFO] There are some pods in namespace ${NAMESPACE}"
            return
        else
            echo "[WARN] There are no pods in namespace ${NAMESPACE}"
            sleep 5
        fi
    done
    exit 1
}

CLUSTER_URL=$1
CLUSTER_USER=$2
CLUSTER_PASS=$3

NAMESPACE="tealc-monitoring"

echo "[INFO] Login to remote cluster"
oc login -u "$CLUSTER_USER" -p "$CLUSTER_PASS" --insecure-skip-tls-verify=true "$CLUSTER_URL"

echo "[INFO] Enable user-workload"
oc apply -f "${DIR}/../argo/install/metrics/user-workload-cm.yaml"

echo "[INFO] Create namespace ${NAMESPACE}"
oc create namespace "${NAMESPACE}" || true

echo "[INFO] Create service-account in ${NAMESPACE} namespace for data-source access"
oc apply -f "${DIR}/../argo/install/metrics/grafana-setup.yaml"

echo "[INFO] Install Grafana Operator"
oc apply -f "${DIR}/../argo/install/metrics/grafana-operator.yaml"

wait_pod_exists "tealc-monitoring" "Running"

echo "[INFO] Create Grafana instance"
oc apply -f "${DIR}/../argo/install/metrics/grafana.yaml"

wait_pod_exists "tealc-monitoring" "1/1"

export ACCESS_TOKEN=$(oc serviceaccounts get-token grafana-serviceaccount -n "${NAMESPACE}")
echo "${ACCESS_TOKEN}"

echo "[INFO] Change values in the data-source and apply"
$SED "s/Bearer.*\"/Bearer ${ACCESS_TOKEN}\"/g" "${DIR}/../argo/install/metrics/grafana-data-source.yaml" | oc apply -f -
oc apply -f "${DIR}/../argo/install/metrics/argo-dashboard-cm.yaml"
oc apply -f "${DIR}/../argo/install/metrics/grafana-argo-dashboards.yaml"
oc apply -f "${DIR}/../argo/install/alerts/"

echo "[INFO] Apply configuration for Alertmanager to manage properly tealc alerts"
$SED "s/AUTH_USERNAME/${SMTP_AUTH_USERNAME}/g" "${DIR}/../argo/install/alert-manager-configuration.yaml" > /tmp/alert-manager-configuration.yaml
$SED "s/AUTH_PASSWORD/${SMTP_AUTH_PASSWORD}/g" "/tmp/alert-manager-configuration.yaml" | oc apply -f -
rm -rf /tmp/alert-manager-configuration.yaml

