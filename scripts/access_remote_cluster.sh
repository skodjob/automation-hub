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

CLUSTER_URL=$1
CLUSTER_USER=$2
CLUSTER_PASS=$3

echo "[INFO] Login to remote cluster"
oc login -u "$CLUSTER_USER" -p "$CLUSTER_PASS" --insecure-skip-tls-verify=true "$CLUSTER_URL"

echo "[INFO] Create service-account in default namespace for remote access"
oc apply -f "${DIR}/../scripts/remote_access_sa.yaml"

export ACCESS_TOKEN=$(oc serviceaccounts get-token access-serviceaccount -n default)
echo "$ACCESS_TOKEN"

echo "[INFO] Change values in the cluster secret"
$SED -i "s#server: .*#server: ${CLUSTER_URL} #g" "${DIR}/../secrets/cluster-secret.yaml"
$SED -i "s/bearerToken\": \".*\"/bearerToken\": \"${ACCESS_TOKEN}\"/g" "${DIR}/../secrets/cluster-secret.yaml"

echo "[INFO] Change values in the tekton-secret"
$SED -i "s#server: .*#server: ${CLUSTER_URL} #g" "${DIR}/../secrets/tekton-secret.yaml"
$SED -i "s#username: .*#username: ${CLUSTER_USER} #g" "${DIR}/../secrets/tekton-secret.yaml"
$SED -i "s#password: .*#password: ${CLUSTER_PASS} #g" "${DIR}/../secrets/tekton-secret.yaml"

echo "[INFO] Applying secrets"
oc create namespace tealc-ci
oc apply -f "${DIR}/../secrets/tekton-secret.yaml"
oc apply -f "${DIR}/../secrets/github-secret.yaml"
oc apply -f "${DIR}/../secrets/cluster-secret.yaml"