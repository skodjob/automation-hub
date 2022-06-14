#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${DIR}/common.sh"

if [ -z "$SOURCE_USER" ] ; then
        err 'Missing SOURCE_USER env var' >&2
        exit 1
fi
if [ -z "$SOURCE_PASS" ] ; then
        err 'Missing SOURCE_PASS env var' >&2
        exit 1
fi
if [ -z "$SOURCE_URL" ] ; then
        err 'Missing SOURCE_URL env var' >&2
        exit 1
fi

if [ -z "$TARGET_USER" ] ; then
        err 'Missing TARGET_USER env var' >&2
        exit 1
fi
if [ -z "$TARGET_PASS" ] ; then
        err 'Missing TARGET_PASS env var' >&2
        exit 1
fi
if [ -z "$TARGET_URL" ] ; then
        err 'Missing TARGET_URL env var' >&2
        exit 1
fi
if [ -z "$SOURCE_NAMESPACE" ] ; then
        err 'Missing SOURCE_NAMESPACE env var' >&2
        exit 1
fi
if [ -z "$TARGET_NAMESPACE" ] ; then
        err 'Missing TARGET_NAMESPACE env var' >&2
        exit 1
fi
if [ -z "$LABEL_SELECTOR" ] ; then
        err 'Missing LABEL_SELECTOR env var' >&2
        exit 1
fi

OUTPUT_NAME=/tmp/secrets.yaml

info "Logging to source cluster and getting secret"
oc login -u "${SOURCE_USER}" -p "${SOURCE_PASS}" "--insecure-skip-tls-verify=true" "${SOURCE_URL}"
oc get secret -l "${LABEL_SELECTOR}" -o yaml -n "${SOURCE_NAMESPACE}" | yq eval 'del(.items[].metadata.namespace,.items[].metadata.ownerReferences,.items[].metadata.annotations,.items[].metadata.managedFields,.items[].metadata.resourceVersion,.items[].metadata.uid)' > $OUTPUT_NAME

cat "${OUTPUT_NAME}"

info "Logging to target cluster and applying secret"
oc login -u "${TARGET_USER}" -p "${TARGET_PASS}" "--insecure-skip-tls-verify=true" "${TARGET_URL}"
oc apply -f "${OUTPUT_NAME}" -n "${TARGET_NAMESPACE}"