#!/usr/bin/env bash

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="${DIR}/../"

function wait_pod_exists() {
    LABEL=$1
    NAMESPACE=$2

    for i in {1..60}; do
        if [[ "$(kubectl get po -l ${LABEL} -n ${NAMESPACE})" != "" ]]; then
            echo "[INFO] Pod with label ${LABEL} in namespace ${NAMESPACE} exists"
            return
        else
            echo "[WARN] Pod with label ${LABEL} in namespace ${NAMESPACE} does not exist"
            sleep 5
        fi
    done
    exit 1
}

function install_tekton_kube() {
    echo "[INFO] installing tekton operator on kubernetes cluster"
    kubectl apply -f https://storage.googleapis.com/tekton-releases/operator/latest/release.yaml

    wait_pod_exists "app=tekton-operator" "tekton-operator"
    kubectl wait pod -l app=tekton-operator -n tekton-operator --for condition=ready --timeout 120s

    kubectl apply -f https://raw.githubusercontent.com/tektoncd/operator/main/config/crs/kubernetes/config/all/operator_v1alpha1_config_cr.yaml

    wait_pod_exists "app=tekton-pipelines-controller" "tekton-pipelines"
    kubectl wait pod -l app=tekton-pipelines-controller -n tekton-pipelines --for condition=ready --timeout 120s

    echo "[INFO] tekton is installed on kubernetes cluster"

    kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
    wait_pod_exists "app=tekton-dashboard" "tekton-pipelines"
    kubectl wait pod -l app=tekton-dashboard -n tekton-pipelines --for condition=ready --timeout 120s

    echo "[INFO] tekton dashboard is installed on kubernetes cluster"
}

function install_tekton_ocp() {
    echo "[INFO] installing tekton operator on openshift cluster using OLM"
    cat << EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
    name: openshift-pipelines-operator
    namespace: openshift-operators
spec:
    channel: stable
    name: openshift-pipelines-operator-rh
    source: redhat-operators
    sourceNamespace: openshift-marketplace
EOF

    wait_pod_exists "name=openshift-pipelines-operator" "openshift-operators"
    kubectl wait pod -l name=openshift-pipelines-operator -n openshift-operators --for condition=ready --timeout 120s

    kubectl apply -f https://raw.githubusercontent.com/tektoncd/operator/main/config/crs/openshift/config/all/operator_v1alpha1_config_cr.yaml

    wait_pod_exists "app=tekton-pipelines-controller" "openshift-pipelines"
    kubectl wait pod -l app=tekton-pipelines-controller -n openshift-pipelines --for condition=ready --timeout 120s

    echo "[INFO] tekton is installed on openshift cluster"

    kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/openshift-tekton-dashboard-release.yaml --validate=false
    wait_pod_exists "app=tekton-dashboard" "openshift-pipelines"
    kubectl wait pod -l app=tekton-dashboard -n openshift-pipelines --for condition=ready --timeout 120s

    echo "[INFO] tekton dashboard is installed on openshift cluster"
    echo "[INFO] expose tekton dahsboard service on openshift cluster"
    oc expose service tekton-dashboard -n openshift-pipelines
}

function install_argo_ocp() {
    echo "[INFO] installing argocd operator on openshift cluster using OLM"
    cat << EOF | kubectl apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
    name: argocd-operator
    namespace: openshift-operators
spec:
    channel: alpha
    name: argocd-operator
    source: community-operators
    sourceNamespace: openshift-marketplace
EOF

    wait_pod_exists "name=argocd-operator" "openshift-operators"
    kubectl wait pod -l name=argocd-operator -n openshift-operators --for condition=ready --timeout 120s

    kubectl create namespace argocd
    cat << EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: argocd
  namespace: argocd
  labels:
    example: oauth
spec:
  dex:
    openShiftOAuth: true
  rbac:
    defaultPolicy: 'role:readonly'
    policy: |
      g, system:cluster-admins, role:admin
    scopes: '[groups]'
  server:
    route:
      enabled: true
EOF

    wait_pod_exists "app.kubernetes.io/name=argocd-server" "argocd"
    kubectl wait pod -l app.kubernetes.io/name=argocd-server -n argocd --for condition=ready --timeout 120s
}

function install_argo_kube() {
    echo "[INFO] installing argocd operator on kubernetes cluster"
    kubectl create namespace argocd
    kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    kubectl apply -n argocd -f "${REPO_ROOT}/secrets/argo-secret.yaml"

    wait_pod_exists "app.kubernetes.io/name=argocd-server" "argocd"
    kubectl wait pod -l app.kubernetes.io/name=argocd-server -n argocd --for condition=ready --timeout 120s
}

#Test requirements
TEST=$(which kubectl)
if [ $? -gt 0 ]; then
    echo "[ERROR] kubectl command not found"
    exit 1
fi

#Test if cluster is openshift or kubernetes
if [[ "$(kubectl api-versions)" == *"openshift.io"* ]]; then
    install_tekton_ocp
    install_argo_ocp
else
    install_tekton_kube
    install_argo_kube
fi
echo "[INFO] waiting 120s for tekton warmup"
sleep 120
