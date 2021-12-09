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

if [[ -z "${FILE_NAME}" ]]; then
    echo "Missing clients file name: FILE_NAME"
    exit 1
elif [[ -z "${CURRENT_DEPLOYMENT_REPO}" ]]; then
    echo "Missing deployment repo: CURRENT_DEPLOYMENT_REPO"
    exit 2
elif [[ -z "${TARGET_ORG_REPO}" ]]; then
    echo "Missing target organization link: TARGET_ORG_REPO"
    exit 3
elif [[ -z ${BRANCH} ]]; then
    echo "Missing branch name: BRANCH"
    exit 4
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

echo "[INFO] Deployment filename: ${FILE_NAME}"
echo "================================================"

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
IMAGES_TAGS=$(cat "$FILE_NAME" | grep "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2- | cut -d '/' -f3- | sort -u | tr '\n' ';')
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
    $SED -i 's#'"$IMAGE_NAME$CURRENT_TAG"'#'"$NEW_DIGEST"'#g' "$FILE_NAME"
done

IMAGES_PLAIN=$(cat "$FILE_NAME" | $GREP "$TARGET_ORG_REPO"/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2-| tr '\n' ';')
echo ${IMAGES_PLAIN}
IFS=';' read -r -a IMAGES <<< "$IMAGES_PLAIN"

echo "================================================"
echo "Replacing image digests"
for ELEMENT in "${IMAGES[@]}"
do
    CURRENT_DIGEST=$(echo $ELEMENT | cut -d '@' -f2-)
    IMAGE=$(echo $ELEMENT | cut -d '@' -f1 | cut -d '/' -f3)

    LATEST_DIGEST=$(skopeo inspect docker://"$TARGET_ORG_REPO"/"$IMAGE" --format "{{ .Digest }}")

    if [[ $CURRENT_DIGEST != $LATEST_DIGEST ]]; then
        echo "[INFO] Found outdated digest for image $IMAGE: $CURRENT_DIGEST vs $LATEST_DIGEST"
        $SED -i 's#'"$CURRENT_DIGEST"'#'"$LATEST_DIGEST"'#g' "$FILE_NAME"
    fi
done

echo "================================================"
echo "Adding changes to repository"
git add .
git diff --staged --quiet || git commit -m "Clients images update: $($DATE "+%Y-%m-%d %T")"
git push origin "$BRANCH"
popd
echo "================================================"
echo "Cleaning ${WORKING_DIR}"
rm -rf ${WORKING_DIR}
echo "================================================"
exit 0
