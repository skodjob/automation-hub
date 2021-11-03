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
elif [[ -z ${SYNC_DEPLOYMENT_REPO} ]]; then
    echo "Missing target Deployment sync repo: SYNC_DEPLOYMENT_REPO"
    exit 4
elif [[ -z ${SYNC_DEPLOYMENT_PATH} ]]; then
    echo "Missing target Deployment path: SYNC_DEPLOYMENT_PATH"
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

FILE_NAME=$(ls "$TARGET_DIR/$YAML_BUNDLE_PATH" | $GREP -i Deployment)
echo "[INFO] Deployment filename: ${FILE_NAME}"
echo "================================================"
echo "Cloning target Deployment repo for sync: ${SYNC_DEPLOYMENT_REPO}"

SYNC_DEPLOYMENT_DIR="${WORKING_DIR}/sync_repo"
git clone "$SYNC_DEPLOYMENT_REPO" $SYNC_DEPLOYMENT_DIR

# Cyklus pres vsechny a postupny ulozeni - copy - restore

FILE_NAMES=$(ls $SYNC_DEPLOYMENT_DIR/$SYNC_DEPLOYMENT_PATH | tr '\n' ';')
IFS=';' read -r -a FILES <<< $FILE_NAMES
for C_FILE in "${FILES[@]}"
do
    echo $C_FILE
    export METADATA=$(yq e '.metadata' "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE") 

    cp -r $SYNC_DEPLOYMENT_DIR/$SYNC_DEPLOYMENT_PATH/$C_FILE $TARGET_DIR/$YAML_BUNDLE_PATH/

    yq e -i '.metadata = env(METADATA)' "$TARGET_DIR/$YAML_BUNDLE_PATH/$C_FILE"
done

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
IMAGES_TAGS=$(cat "$YAML_BUNDLE_PATH"/"$FILE_NAME" | grep "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2- | cut -d '/' -f3- | sort -u | tr '\n' ';')
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
    $SED -i 's#'"$IMAGE_NAME$CURRENT_TAG"'#'"$NEW_DIGEST"'#g' "$YAML_BUNDLE_PATH"/"$FILE_NAME"
done

IMAGES_PLAIN=$(cat "$YAML_BUNDLE_PATH"/"$FILE_NAME" | $GREP "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2-| tr '\n' ';')
IFS=';' read -r -a IMAGES <<< "$IMAGES_PLAIN"

echo "================================================"
echo "Replacing image digests"
for ELEMENT in "${IMAGES[@]}"
do
    CURRENT_DIGEST=$(echo $ELEMENT | cut -d '@' -f2)
    IMAGE=$(echo $ELEMENT | rev | cut -d '@' -f2 | cut -d '/' -f1 | rev)

    LATEST_DIGEST=$(skopeo inspect docker://"$TARGET_ORG_REPO"/"$IMAGE" --format "{{ .Digest }}")

    if [[ $CURRENT_DIGEST != $LATEST_DIGEST ]]; then
        echo "[INFO] Found outdated digest for image $IMAGE: $CURRENT_DIGEST vs $LATEST_DIGEST"
        $SED -i 's#'"$CURRENT_DIGEST"'#'"$LATEST_DIGEST"'#g' "$YAML_BUNDLE_PATH"/"$FILE_NAME"
    fi
done

echo "================================================"
echo "Adding changes to repository"
git add "$YAML_BUNDLE_PATH"/*
git diff --staged --quiet || git commit -m "Canary images update: $($DATE "+%Y-%m-%d %T")"
git push origin "$BRANCH"
popd
echo "================================================"
echo "Cleaning ${WORKING_DIR}"
rm -rf ${WORKING_DIR}
echo "================================================"
exit 0
