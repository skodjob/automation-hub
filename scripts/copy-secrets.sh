#!/usr/bin/env bash

KUBECONFIG=/tmp/kubeconfig oc login -u $OC_USERNAME -p $OC_PASSWORD $OC_API_URL --insecure-skip-tls-verify=true
KUBECONFIG=/tmp/kubeconfig oc get secret -n strimzi-kafka her-ur -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences,.metadata.annotations,.metadata.managedFields,.metadata.resourceVersion,.metadata.uid)' - | oc apply -n strimzi-twitter-connector -f -
KUBECONFIG=/tmp/kubeconfig oc get secret -n strimzi-kafka anubis-cluster-ca-cert -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences,.metadata.annotations,.metadata.managedFields,.metadata.resourceVersion,.metadata.uid)' - | oc apply -n strimzi-twitter-connector -f -
KUBECONFIG=/tmp/kubeconfig oc get secret -n strimzi-kafka hathor -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences,.metadata.annotations,.metadata.managedFields,.metadata.resourceVersion,.metadata.uid)' - | oc apply -n strimzi-twitter-connector -f -