#!/bin/sh
REPOROOT=$(git rev-parse --show-toplevel)


# Credit: https://gist.github.com/willprice/e07efd73fb7f13f917ea

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

commit_files() {
  git checkout master
  # Current month and year, e.g: Apr 2018
  dateAndMonth=`date "+%b %Y"`
  # Stage the modified files in dist/output
  git add $REPOROOT/logs
  git add $REPOROOT/docs
  # Create a new commit with a custom build message
  # with "[skip ci]" to avoid a build loop
  # and Travis build number for reference
  git commit -am "Travis update: $dateAndMonth (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"
}

upload_files() {
  # Remove existing "origin"
  git remote rm origin
  # Add new "origin" with access token in the git URL for authentication
  git remote add origin https://jsmont:${GIT_TOKEN}@github.com/jsmont/data_prefetcher.git > /dev/null 2>&1

  until git push origin master --quiet
  do
    git pull --rebase -s ours origin master
  done
}

echo "Setting up git"
setup_git

echo "Commiting files"
commit_files

echo "Pushing results"
upload_files

echo "Done."
