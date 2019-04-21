REPOROOT=$(git rev-parse --show-toplevel)

git add $REPOROOT/logs

until git push
do
    git pull
done
