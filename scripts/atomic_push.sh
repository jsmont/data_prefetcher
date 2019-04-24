#!/bin/sh
REPOROOT=$(git rev-parse --show-toplevel)


# Credit: https://gist.github.com/willprice/e07efd73fb7f13f917ea

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

    until git push origin master --quiet
    do
        git pull --rebase origin master
        $REPOROOT/scripts/plot_valid.sh
        commit_files
    done
}

save_state() {
    git checkout last_state
    git pull --rebase origin last_state
    git merge master
    until git push -u origin last_state
    do
        git pull --rebase origin last_state
    done
    git checkout master
}

echo "Commiting files"
commit_files

echo "Pushing results"
upload_files

echo "Saving state"
save_state

echo "Done."
