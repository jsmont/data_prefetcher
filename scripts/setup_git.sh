#!/bin/sh

REPOROOT=$(git rev-parse --show-toplevel)
cd $REPOROOT

step="1"

if [ "$TRAVIS_BRANCH" = "last_state" ]; then
    step="2"
fi

echo "Setting up git"
if [ ! -z "$GIT_TOKEN" ]; then
    git config --global user.email "travis@travis-ci.org"
    git config --global user.name "Travis CI"
    # Remove existing "origin"
    git remote rm origin
    # Add new "origin" with access token in the git URL for authentication
    git remote add origin https://jsmont:${GIT_TOKEN}@github.com/jsmont/data_prefetcher.git > /dev/null 2>&1
fi

git fetch origin last_state
git fetch origin master

if [ "$step" = "1" ]; then 
    git checkout origin/last_state; 
    git checkout origin/master -- docs
    git merge origin/master;
fi
if [ "$step" = "2" ]; then 
    git checkout origin/master; 
    git checkout origin/last_state -- logs
fi
