#! /bin/sh -lvx

set -e

if [ -z "$ACCESS_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]
then
    echo "You must provide the action with either a Personal Access Token or the GitHub Token secret in order to deploy."
    exit 1
fi

if [ -z "$BRANCH" ]
then
    echo "You must provide the action with a branch name it should deploy to, for example gh-pages or docs."
    exit 1
fi

if [ -z "$FOLDER"]
then
    echo "You must provide the action with the folder name in the repository where you compiled page lives."
    exit 1
fi

case "$FOLDER" in /*|./*)
    echo "The deployment folder cannot be prefixed with '/' or './'. Instead refrence the folder name directly."
    exit 1
esac

# Installs Git and jq.
apt-get update && \
apt-get install -y git && \
apt-get install -y jq && \

# Gets the commit email/name if it exists in the push event payload
COMMIT_EMAIL=`jq '.pusher.email' ${GITHUB_EVENT_PATH}`
COMMIT_NAME=`jq '.pusher.name' ${GITHUB_EVENT_PATH}`

if [ -z "$COMMIT_EMAIL"]
then
    COMMIT_EMAIL="${GITHUB_ACTOR:-github-pages-deploy-action}@user.no-reply.github.com"
fi

if [ -z "$COMMIT_NAME"]
then
    COMMIT_NAME="${GITHUB_ACTOR:-GitHub Pages Deploy Action}"
fi

# Directs the action to the GitHub workspace

cd $GITHUB_WORKSPACE && \

# Configure Git

git init && \
git config --global user.email "${COMMIT_EMAIL}" && \
git config --global user.name "${COMMIT_NAME}" && \

## Initializes the repository path using the access token
REPOSITORY_PATH="https://${ACCESS_TOKEN:-"x-access-token:$GITHUB_TOKEN"}@github.com/${GITHUB_REPOSITORY}.git" && \

# Checks to see if the remote exists prior to deploying
# If the branch doesn't exist it gets created here as an orphan
REMOTE_BRANCH_EXISTS="$(git ls-remote --heads "$REPOSITORY_PATH" "$BRANCH" | wc -l)"
if [ $REMOTE_BRANCH_EXISTS -eq 0 ];
then
    echo "Creating remote branch ${BRANCH} as it doesn't exist..."
    git checkout "${BASE_BRANCH:-master}" && \
    git checkout --orphan $BRANCH && \
    git rm -rf . && \
    touch README.md && \
    git add README.md && \
    git commit -m "Initial ${BRANCH} commit" && \
    git push $REPOSITORY_PATH $BRANCH
else 
    git checkout --orphan $BRANCH && \
    git rm -rf . && \
    git pull $REPOSITORY_PATH $BRANCH
fi

# Checks out the base branch to begin the deploy process
git checkout "${BASE_BRANCH:-master}" && \

# Builds the project if a build script is provided
echo "Running build scripts... $BUILD_SCRIPT" && \
eval "$BUILD_SCRIPT" && \

if [ -d "$FOLDER" ]
then
    if [ -z "$(ls -A ${FOLDER})"]
    then
        echo "Build folder is empty. Nothing to do here." && \
        exit 0
    fi
else
    echo "Build folder does not exist. Nothing to do here." && \
    exit 0
fi

if [ "$CNAME" ];
then
    echo "Generating a CNAME file in the $FOLDER directory..."
    echo $CNAME > $FOLDER/CNAME
fi

# moving deployment $FOLDER out of git folder
echo "Moving build directory to tmp" && \
mv -v $FOLDER $HOME && \

echo "Deploying to GitHub..." && \
git checkout $BRANCH && \

# Checking the content of moved dist
echo "Moving back the build artifacts in ${BRANCH}" && \
mv "${HOME}/${FOLDER}"/* . && \
git add . && \

git commit -m "Deploying to ${BRANCH} from ${BASE_BRANCH:-master} ${GITHUB_SHA}" --quiet && \
git push $REPOSITORY_PATH $BRANCH --force && \

echo "Deployment successful!"
exit 0
