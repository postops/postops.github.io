#!/bin/bash
set -e

echo "Pushing up crosspost cache"

git config user.name "$CIRCLE_USERNAME"
git config user.email "$USER_EMAIL"

git add -fA
git commit --allow-empty -m "$(git log -1 --pretty=%B) - crosspost cache [ci skip]"
git push -f $CIRCLE_REPOSITORY_URL master
