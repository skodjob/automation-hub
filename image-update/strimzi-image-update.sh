#!/usr/bin/env bash
# Skopeo needs to be installed as prerequisity

set -e

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

TEST=$(which kubectl)
if [ $? -gt 0 ]; then
    echo "[ERROR] kubectl command not found"
    exit 1
fi

if [[ -z "${YAML_BUNDLE_PATH}" ]]; then
    echo "Missing yaml bundle path: YAML_BUNDLE_PATH"
    exit 1
elif [[ -z "${CURRENT_DEPLOYMENT_REPO}" ]]; then
    echo "Missing deployment repo: CURRENT_DEPLOYMENT_REPO"
    exit 2
elif [[ -z "${TARGET_ORG_REPO}" ]]; then
    echo "Missing target organization link: TARGET_ORG_REPO"
    exit 3
elif [[ -z ${SYNC_CRD_REPO} ]]; then
    echo "Missing target CRD sync repo: SYNC_CRD_REPO"
    exit 4
elif [[ -z ${SYNC_CRD_PATH} ]]; then
    echo "Missing target CRD path: SYNC_CRD_PATH"
    exit 5
elif [[ -z ${BRANCH} ]]; then
    echo "Missing branch name: BRANCH"
    exit 5
fi

WORKING_DIR=/tmp/tealc

echo "[INFO] Clearing ${WORKING_DIR}"
rm -rf ${WORKING_DIR}

echo "[INFO] Creating ${WORKING_DIR}"
mkdir -p ${WORKING_DIR}
pushd ${WORKING_DIR}

TARGET_DIR="${WORKING_DIR}/current_deployment"
echo $TARGET_DIR
echo "Cloning repository: ${CURRENT_DEPLOYMENT_REPO}"
echo "================================================"
git clone "$CURRENT_DEPLOYMENT_REPO" $TARGET_DIR

DEPLOYMENT_FILE_NAME=$(ls "$TARGET_DIR/$YAML_BUNDLE_PATH" | $GREP Deployment)
echo "[INFO] Deployment filename: ${DEPLOYMENT_FILE_NAME}"
echo "================================================"
echo "Cloning target CRD repo for sync: ${SYNC_CRD_REPO}"

SYNC_CRD_DIR="${WORKING_DIR}/sync_repo"
git clone "$SYNC_CRD_REPO" $SYNC_CRD_DIR

# Storing must have values
export ENV_NAMESPACE=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "STRIMZI_NAMESPACE")' "$TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME")
export ENV_FEATURE_GATES=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "STRIMZI_FEATURE_GATES")' "$TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME")
export ENV_LOG_LEVEL=$(yq e '.spec.template.spec.containers[0].env[] | select(.name == "STRIMZI_LOG_LEVEL")' "$TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME")
export RES=$(yq e '.spec.template.spec.containers[0].resources' "$TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME")
export AFFINITY=$(yq e '.spec.template.spec.affinity' "$TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME")

# Cyklus pres vsechny a postupny ulozeni - copy - restore

FILE_NAMES=$(ls $SYNC_CRD_DIR/$SYNC_CRD_PATH | tr '\n' ';')
IFS=';' read -r -a FILES <<< $FILE_NAMES
for C_FILE in "${FILES[@]}"
do
    echo $C_FILE

    if test -f "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE"; then
        export METADATA=$(yq e '.metadata' "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE")
    else
      echo "File $TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE does not exists. Skipping metadata backup."
    fi

    cp -r $SYNC_CRD_DIR/$SYNC_CRD_PATH/$C_FILE $TARGET_DIR/$YAML_BUNDLE_PATH/

    if test -f "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE"; then
        yq e -i '.metadata = env(METADATA)' "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE"
    fi
done

# We need to keep STRIMZI_NAMESPACE configuration which will be (hopefully) always as the first item in the env list
yq e -i '(.spec.template.spec.containers[0].env[] | select(.name == "STRIMZI_NAMESPACE")) = env(ENV_NAMESPACE)' $TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME
## We need to keep STRIMZI_LOG_LEVEL configuration which will be (hopefully) always as the first item in the env list
yq e -i '.spec.template.spec.containers[0].env += env(ENV_LOG_LEVEL)' $TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME
## We need to keep STRIMZI_FEATURE_GATES configuration which will be (hopefully) always as the first item in the env list
yq e -i '(.spec.template.spec.containers[0].env[] | select(.name == "STRIMZI_FEATURE_GATES")) = env(ENV_FEATURE_GATES)' $TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME
#
## We need to keep resources configuration as well
yq e -i '.spec.template.spec.containers[0].resources = env(RES)' $TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME
## We need to keep affinity configuration as well
yq e -i '.spec.template.spec.affinity = env(AFFINITY)' $TARGET_DIR/$YAML_BUNDLE_PATH/$DEPLOYMENT_FILE_NAME

echo "================================================"
echo "Moving into synced deployment repository"
echo "================================================"

pushd $TARGET_DIR
echo "[INFO] Git configuration with username: ${GITHUB_USERNAME}"
git config user.email "$GITHUB_USERNAME@redhat.com"
git config user.name "$GITHUB_USERNAME"

CURRENT_DEPLOYMENT_REPO=$(echo "$CURRENT_DEPLOYMENT_REPO" | cut -d '/' -f3-)

git remote set-url origin "https://$GITHUB_USERNAME:$GITHUB_TOKEN@$CURRENT_DEPLOYMENT_REPO"

if [[ $(git branch) == *${BRANCH}* ]]; then
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

# Change floating tags to random digest
IMAGES_TAGS=$(cat "$YAML_BUNDLE_PATH"/"$DEPLOYMENT_FILE_NAME" | grep "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2- | cut -d '/' -f3- | sort -u | tr '\n' ';')
echo "$IMAGES_TAGS"
IFS=';' read -r -a IMGS <<< "$IMAGES_TAGS"
T=11111
for ELEMENT_O in "${IMGS[@]}"
do
    CURRENT_TAG=$(echo $ELEMENT_O | cut -d ':' -f2)
    CURRENT_TAG=$(echo ":$CURRENT_TAG")
    IMAGE_NAME=$(echo $ELEMENT_O | cut -d ':' -f1)
    NEW_DIGEST="$IMAGE_NAME@sha:$T"
    T=$((T+1))
    $SED -i 's#'"$IMAGE_NAME$CURRENT_TAG"'#'"$NEW_DIGEST"'#g' "$YAML_BUNDLE_PATH"/"$DEPLOYMENT_FILE_NAME"
done

IMAGES_PLAIN=$(cat "$YAML_BUNDLE_PATH"/"$DEPLOYMENT_FILE_NAME" | $GREP "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2-| tr '\n' ';')
IFS=';' read -r -a IMAGES <<< "$IMAGES_PLAIN"

echo "================================================"
echo "Replacing image digests"
for ELEMENT in "${IMAGES[@]}"
do
    CURRENT_DIGEST=$(echo $ELEMENT | cut -d '@' -f2)
    IMAGE=$(echo $ELEMENT | rev | cut -d '@' -f2 | cut -d '/' -f1 | rev)

    #Parse image with prefix = kafka
    if [[ $ELEMENT == *"="* ]]; then
        PREFIX=$(echo $ELEMENT | cut -d '=' -f1)
        LATEST_DIGEST=$(skopeo inspect docker://"$TARGET_ORG_REPO"/"$IMAGE":latest-kafka-"$PREFIX"  --format "{{ .Digest }}")
    elif [[ $ELEMENT == *"kafka@"* ]]; then
        continue
    else
        LATEST_DIGEST=$(skopeo inspect docker://"$TARGET_ORG_REPO"/"$IMAGE" --format "{{ .Digest }}")
    fi
    
    if [[ $CURRENT_DIGEST != $LATEST_DIGEST ]]; then
        echo "[INFO] Found outdated digest for image $IMAGE: $CURRENT_DIGEST vs $LATEST_DIGEST"
        $SED -i 's#'"$CURRENT_DIGEST"'#'"$LATEST_DIGEST"'#g' "$YAML_BUNDLE_PATH"/"$DEPLOYMENT_FILE_NAME"
    fi
done

echo "================================================"
echo "Adding changes to repository"
git add "$YAML_BUNDLE_PATH"/*
git diff --staged --quiet || git commit -m "Strimzi images update: $($DATE "+%Y-%m-%d %T")"
git push origin "$BRANCH"
popd
echo "================================================"
echo "Cleaning ${WORKING_DIR}"
rm -rf ${WORKING_DIR}
echo "================================================"
exit 0
