#!/usr/bin/env bash

oc get secret -n strimzi-kafka her-ur -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences)' - | oc apply -n strimzi-twitter-connector -f -
oc get secret -n strimzi-kafka anubis-cluster-ca-cert -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences)' - | oc apply -n strimzi-twitter-connector -f -
oc get secret -n strimzi-kafka hathor -o yaml | yq eval 'del(.metadata.namespace,.metadata.ownerReferences)' - | oc apply -n strimzi-twitter-connector -f -