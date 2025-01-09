#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${DIR}/common.sh"

# Define variables
SERVICE_ACCOUNT="skodjob-sa"
NAMESPACE="default"
CONFIG_FILE="${DIR}/../install/secrets/clusters.yaml"

info "Going to use ${NAMESPACE}/${SERVICE_ACCOUNT} service account"

# Create a service account in the default namespace
oc create sa $SERVICE_ACCOUNT -n $NAMESPACE
# Create token secret
cat << EOF | oc apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: ${SERVICE_ACCOUNT}
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SERVICE_ACCOUNT}
EOF

# Grant admin rights to the service account
oc adm policy add-cluster-role-to-user cluster-admin -z $SERVICE_ACCOUNT -n $NAMESPACE

# Retrieve the service account token
TOKEN=$(oc get secret $SERVICE_ACCOUNT -n $NAMESPACE -o jsonpath='{.data.token}' | base64 --decode)

# Update the token value in the YAML file using yq
if [ -f "$CONFIG_FILE" ]; then
  yq e -i ".infra_username = \"$SERVICE_ACCOUNT\"" $CONFIG_FILE
  yq e -i ".infra_access_token = \"$TOKEN\"" $CONFIG_FILE
  yq e -i ".infra_user_namespace = \"$NAMESPACE\"" $CONFIG_FILE
  info "Token updated in $CONFIG_FILE"
else
  err_and_exit "Error: $CONFIG_FILE not found."
fi

info "Do not forget to commit the changes!"
