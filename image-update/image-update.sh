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

if [[ -z "${YAML_BUNDLE_PATH}" ]]; then
    echo "Missing yaml bundle path"
    exit 1
elif [[ -z "${CURRENT_DEPLOYMENT_REPO}" ]]; then
    echo "Missing deployment repo"
    exit 2
elif [[ -z "${TARGET_ORG_REPO}" ]]; then
    echo "Missing target organization link"
    exit 3
elif [[ -z ${SYNC_CRD_REPO} ]]; then 
    echo "Missing target CRD sync repo"
    exit 4
elif [[ -z ${SYNC_CRD_PATH} ]]; then 
    echo "Missing target CRD path"
    exit 5
fi


TARGET_DIR="${PWD}/../current_deployment"
echo $TARGET_DIR

git config --global user.email "$GITHUB_USERNAME@redhat.com"
git config --global user.name "$GITHUB_USERNAME"

echo "Cloning repository"
echo "================================================"
git clone $CURRENT_DEPLOYMENT_REPO $TARGET_DIR

echo "================================================"
echo "Cloning target CRD repo for sync"

SYNC_CRD_DIR="${PWD}/../sync_repo"
git clone $SYNC_CRD_REPO $SYNC_CRD_DIR
cp -r $SYNC_CRD_DIR/$SYNC_CRD_PATH/* $TARGET_DIR/$YAML_BUNDLE_PATH/

echo "================================================"
echo "Moving into synced deployment repository"
echo "================================================"

pushd $TARGET_DIR
CURRENT_DEPLOYMENT_REPO=$(echo $CURRENT_DEPLOYMENT_REPO | cut -d '/' -f3-)

git remote set-url origin "https://$GITHUB_USERNAME:$GITHUB_TOKEN@$CURRENT_DEPLOYMENT_REPO"
git checkout -b $BRANCH

FILE_NAME=$(ls $YAML_BUNDLE_PATH | $GREP Deployment)

# Change floating tags to random digest
IMAGES_TAGS=$(cat $YAML_BUNDLE_PATH/$FILE_NAME | grep $TARGET_ORG_REPO/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2- | cut -d '/' -f3- | sort -u | tr '\n' ';')
echo $IMAGES_TAGS
IFS=';' read -r -a IMGS <<< $IMAGES_TAGS
T=11111
for ELEMENT_O in "${IMGS[@]}"
do
    CURRENT_TAG=$(echo $ELEMENT_O | cut -d ':' -f2)
    CURRENT_TAG=$(echo ":$CURRENT_TAG")
    IMAGE_NAME=$(echo $ELEMENT_O | cut -d ':' -f1)
    NEW_DIGEST="$IMAGE_NAME@sha:$T"
    T=$((T+1))
    $SED -i 's#'"$IMAGE_NAME$CURRENT_TAG"'#'"$NEW_DIGEST"'#g' $YAML_BUNDLE_PATH/$FILE_NAME
done

IMAGES_PLAIN=$(cat $YAML_BUNDLE_PATH/$FILE_NAME | $GREP $TARGET_ORG_REPO/ | sort -u | awk '{$1=$1};1' | cut -d ' ' -f2-| tr '\n' ';')
IFS=';' read -r -a IMAGES <<< $IMAGES_PLAIN

echo "================================================"
echo "Replacing image digests"
for ELEMENT in "${IMAGES[@]}"
do
    CURRENT_DIGEST=$(echo $ELEMENT | cut -d '@' -f2)
    IMAGE=$(echo $ELEMENT | rev | cut -d '@' -f2 | cut -d '/' -f1 | rev)

    #Parse image with prefix = kafka
    if [[ $ELEMENT == *"="* ]]; then
        PREFIX=$(echo $ELEMENT | cut -d '=' -f1)
        LATEST_DIGEST=$(skopeo inspect docker://$TARGET_ORG_REPO/$IMAGE:latest-kafka-$PREFIX  --format "{{ .Digest }}")
    elif [[ $ELEMENT == *"kafka@"* ]]; then

        continue
    else
        LATEST_DIGEST=$(skopeo inspect docker://$TARGET_ORG_REPO/$IMAGE --format "{{ .Digest }}")
    fi
    
    if [[ $CURRENT_DIGEST != $LATEST_DIGEST ]]; then
        echo "Found outdated digest for image $IMAGE"
        $SED -i 's#'"$CURRENT_DIGEST"'#'"$LATEST_DIGEST"'#g' $YAML_BUNDLE_PATH/$FILE_NAME
    fi
done

echo "================================================"
echo "Adding changes to repository"
git add $YAML_BUNDLE_PATH/*
git commit -m "Image update: $($DATE "+%Y-%m-%d %T")"
git push origin $BRANCH
popd
echo "================================================"
echo "Cleaning"
rm -rf $TARGET_DIR
rm -rf $SYNC_CRD_DIR
echo "================================================"
exit 0
