#!/bin/sh
REPOROOT=$(git rev-parse --show-toplevel)

step="1"
target_branch="last_state"

if [ "$TRAVIS_BRANCH" = "last_state" ]; then
    step="2"
    target_branch="master"
fi


commit_files() {
    echo "$(git status)"
    git checkout $target_branch
    # Current month and year, e.g: Apr 2018
    dateAndMonth=`date "+%b %Y"`
    # Stage the modified files in dist/output
    if [ "$step" = "1" ]; then git add --all $REPOROOT/logs; fi
    if [ "$step" = "2" ]; then git add --all $REPOROOT/docs; fi
    # Create a new commit with a custom build message
    # with "[skip ci]" to avoid a build loop
    # and Travis build number for reference
    if [ "$step" = "1" ]; then 
        git commit -am "$TRAVIS_COMMIT_MESSAGE: step 1 (Build $TRAVIS_JOB_NUMBER)"; 
    fi
    if [ "$step" = "2" ]; then 
        git commit -am "$TRAVIS_COMMIT_MESSAGE: step 2 (Build $TRAVIS_BUILD_NUMBER)" -m "[skip ci]"; 
    fi
    echo "$(git status)"
}

upload_files() {

    until git push origin master --quiet
    do
        git pull --rebase origin master
        if [ "$step" = "2" ]; then 
            scripts/plot_valid.sh; 
        fi
        commit_files
    done
}

save_state() {
    until git push -u origin last_state
    do
        git pull --rebase origin last_state
    done
}

echo "Commiting files"
commit_files 

if [ "$step" = "2" ]; then
    echo "Pushing results"
    upload_files
fi

if [ "$step" = "1" ]; then
    echo "Saving state"
    save_state
fi

echo "Done."
