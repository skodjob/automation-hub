#!/usr/bin/env bash

oc login -u $OC_USERNAME -p $OC_PASSWORD $OC_API_URL --insecure-skip-tls-verify=true
oc get secret -n strimzi-kafka her-ur -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences, .metadata.annotations)' - | oc apply -n strimzi-twitter-connector -f -
oc get secret -n strimzi-kafka anubis-cluster-ca-cert -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences, .metadata.annotations)' - | oc apply -n strimzi-twitter-connector -f -
oc get secret -n strimzi-kafka hathor -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences, .metadata.annotations)' - | oc apply -n strimzi-twitter-connector -f -