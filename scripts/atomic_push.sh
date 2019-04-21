REPOROOT=$(git rev-parse --show-toplevel)

git add $REPOROOT/logs

until git push origin HEAD:master
do
    git pull
done
