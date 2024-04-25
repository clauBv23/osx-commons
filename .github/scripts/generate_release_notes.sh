#!/bin/bash

printf "Hello world\n"

PACKAGE=$1

echo "RELEASE_NOTES<<EOF" >> $GITHUB_ENV
echo "## All changes in $PACKAGE" >> $GITHUB_ENV
echo "" >> $GITHUB_ENV
echo $PACKAGE
echo "====================<>"

PULL_REQUESTS=$(gh pr list --label $PACKAGE --state merged --json title,mergeCommit,number)

echo $PULL_REQUESTS

# convert to base64 so we only have one line per pull request that we iterate over
echo $PULL_REQUESTS | jq -r '.[] | @base64' | while read pull_request ; do
    echo "--------------------------------------------------------------------------------"
    COMMIT=$(echo $pull_request | base64 -d | jq -r '.mergeCommit.oid')
    NUMBER=$(echo $pull_request | base64 -d | jq -r '.number')
    TITLE=$(echo $pull_request | base64 -d | jq -r '.title')

    echo $COMMIT
    echo $NUMBER
    echo $TITLE

    # if there is more than 1 tag, the pull request is already included in another release
    echo $(git tag --contain $COMMIT)
    if [ $(git tag --contain $COMMIT | grep -i $PACKAGE | wc -l) -le 1 ]; then
        echo "Adding $TITLE to release notes"
        echo "- $TITLE in #$NUMBER" >> $GITHUB_ENV
    fi
done
echo $GITHUB_ENV

echo "================END==================>"
echo "" >> $GITHUB_ENV
echo "EOF" >> $GITHUB_ENV
echo $GITHUB_ENV
cat $GITHUB_ENV
