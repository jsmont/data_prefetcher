#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
VALID_FILE=$REPOROOT/valid_prefetchers

NUM_BUILDS=1;
BUILD_ID=0;

if [ ! -z "$1" ]; then
    NUM_BUILDS=$1;
fi

if [ ! -z "$2" ]; then
    BUILD_ID=$2;
fi

echo "Compiling prefetchers for build $BUILD_ID/$NUM_BUILDS"

cd $REPOROOT

counter=0
while read PREF
do
    module=$((counter % NUM_BUILDS))
    if [ "$module" == "$BUILD_ID" ]; then
        make $PREF
    fi
    counter=$((counter+1))
done < $VALID_FILE
