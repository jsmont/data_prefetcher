#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
PREFETCHER_FOLDER=$REPOROOT/models
TARGET_FOLDER=$REPOROOT/bin
INCLUDE=$REPOROOT/lib/dpc2sim.a

if [ ! -d $TARGET_FOLDER ]; then
    mkdir -p $TARGET_FOLDER
fi

for pre in $PREFETCHER_FOLDER/*_prefetcher.c; do
    target=$(basename -- "$pre")
    target=${target%.*}
    echo "Compiling $target"
    gcc -Wall -o $TARGET_FOLDER/$target $pre $INCLUDE
done

