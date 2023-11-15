#!/usr/bin/env bash

set -x
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${DIR}/common.sh"

if [ -z "$BRANCH" ] ; then
        err 'Missing BRANCH env var' >&2
        exit 1
fi

DIGEST=$(skopeo inspect --override-arch amd64 --override-os linux docker://quay.io/opendatahub/opendatahub-operator:${BRANCH}  --format "{{ .Digest }}")
OPERATOR_IMAGE="quay.io/opendatahub/opendatahub-operator@${DIGEST}"

WORKING_DIR=/tmp/tealc
SOKAR_REPO="https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/ExcelentProject/sokar.git"
SOKAR_DIR="sokar"
SOKAR_ODH_DIR="open-data-hub"
SOKAR_ODH_OPERATOR_DIR="${WORKING_DIR}/${SOKAR_DIR}/${SOKAR_ODH_DIR}/install"
ODH_REPO="https://github.com/opendatahub-io/opendatahub-operator.git"
ODH_DIR="odh-operator"
CRDS_ODH_REPO="https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/ExcelentProject/opendatahub-crds.git"
CRDS_ODH_DIR="opendatahub-crds"
ODH_E2E_SUITE_REPO="https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/ExcelentProject/odh-e2e.git"
ODH_E2E_SUITE_DIR="odh-e2e"


info "[INFO] Clearing ${WORKING_DIR}"
rm -rf ${WORKING_DIR}

info "[INFO] Creating ${WORKING_DIR}"
mkdir -p ${WORKING_DIR}
pushd ${WORKING_DIR}

pwd
# Checkout Sokar repo
git clone $SOKAR_REPO $SOKAR_DIR
mkdir -p ${SOKAR_ODH_OPERATOR_DIR}

# Checkout ODH repo
git clone --branch $BRANCH $ODH_REPO $ODH_DIR

pushd $ODH_DIR
$SED -i "s@/bin/bash@/usr/bin/env bash@" get_all_manifests.sh
./get_all_manifests.sh

for item in $(find odh-manifests -type d -name "crd")
do
	info "Working with ${item} ..."
	files=$(ls $item)
	if [ -n "$(ls -A ${item}/kustomization.yaml)" ]
	then
		kustomize build ${item} > "${WORKING_DIR}/${SOKAR_DIR}/${SOKAR_ODH_DIR}/client/${item//\//-}.yaml"
	else
		if [ -n "$(ls -A ${item}/external/kustomization.yaml)" ]
		then
			kustomize build ${item}/external > "${WORKING_DIR}/${SOKAR_DIR}/${SOKAR_ODH_DIR}/client/${item//\//-}.yaml"
		else
			echo "Not a kustomization folder. Skipping..."
		fi
	fi
done

# Generate install files
pushd config/manager
kustomize edit set image controller=${OPERATOR_IMAGE}
popd

kustomize build config/default > ${SOKAR_ODH_OPERATOR_DIR}/deploy.yaml
info "Data generated!"

info "Adding changes to repository"
cd "${WORKING_DIR}/${SOKAR_DIR}"
info "[INFO] Git configuration with username: ${GITHUB_USERNAME}"
git config user.email "$GITHUB_USERNAME@redhat.com"
git config user.name "$GITHUB_USERNAME"

git add "."
CLI_CRDS_CHANGED=$(git diff --name-status --staged | { grep "open-data-hub/client" || true; })
ODH_CRDS_CHANGED=$(git diff --staged --unified=0 | grep -Po '(?<=^\+)(?!\+\+).*' | { grep -v image || true; })
git diff --staged --quiet || git commit -m "ODH Install files update: $($DATE '+%Y-%m-%d %T')"
git push origin "main"

if [[ "${CLI_CRDS_CHANGED}" == *"client"* ]] || [[ "${ODH_CRDS_CHANGED}" != "" ]]; then
  echo "CRDS Updated -> releasing a new version of fluent classes"
  cd ${WORKING_DIR}
  git config user.email "$GITHUB_USERNAME@redhat.com"
  git config user.name "$GITHUB_USERNAME"
  git clone "${CRDS_ODH_REPO}" "${CRDS_ODH_DIR}"
  git clone "${ODH_E2E_SUITE_REPO}" "${ODH_E2E_SUITE_DIR}"

  cd ${CRDS_ODH_DIR}
  git config user.email "$GITHUB_USERNAME@redhat.com"
  git config user.name "$GITHUB_USERNAME"
  mvn build-helper:parse-version versions:set -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion}-SNAPSHOT versions:commit
  VERSION_CRDS=$(mvn -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q)
  git add "."
  git diff --staged --quiet || git commit -m "Version bump: $($DATE '+%Y-%m-%d %T')"
  git push origin "main"

  echo "Take some time to build and release package"
  sleep 480

  cd ..
  cd "${ODH_E2E_SUITE_DIR}"
  mvn versions:set-property -Dproperty=opedatahub-crds.version -DnewVersion=$VERSION_CRDS
  git add "."
  git diff --staged --quiet || git commit -m "Bump version of opendatahub-crds dependency: $($DATE '+%Y-%m-%d %T')"
  git push origin "main"
  cd ..
fi

info "Cleaning ${WORKING_DIR}"
rm -rf ${WORKING_DIR}
exit 0
