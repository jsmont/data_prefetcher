#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
VALID_FILE=$REPOROOT/valid_prefetchers
BIN_FOLDER=$REPOROOT/bin
TRACE_FOLDER=$REPOROOT/traces
LOG_FOLDER=$REPOROOT/logs


NUM_BUILDS=1;
BUILD_ID=0;

if [ ! -z "$1" ]; then
    NUM_BUILDS=$1;
fi

if [ ! -z "$2" ]; then
    BUILD_ID=$2;
fi

echo "Running for build $BUILD_ID/$NUM_BUILDS"

cd $REPOROOT

for simulator in $BIN_FOLDER/*; do
    counter=0
    for trace in $TRACE_FOLDER/*; do
        module=$((counter % NUM_BUILDS))
        if [ "$module" == "$BUILD_ID" ]; then
            mkdir -p $LOG_FOLDER/$tr
            sim=$(basename -- "$simulator")
            tr=$(basename -- "$trace")
            tr=${tr%.*}
            echo "Running $sim <- $tr"
            zcat $trace | $simulator > "$LOG_FOLDER/$tr/$sim.log"
        fi
        counter=$((counter+1))
    done
done
