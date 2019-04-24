#!/bin/sh

echo "Setting up git"

git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"
if [ ! -z "$GIT_TOKEN" ]; then
    # Remove existing "origin"
    git remote rm origin
    # Add new "origin" with access token in the git URL for authentication
    git remote add origin https://jsmont:${GIT_TOKEN}@github.com/jsmont/data_prefetcher.git > /dev/null 2>&1
fi
