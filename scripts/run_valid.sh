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
            sim=$(basename -- "$simulator")
            tr=$(basename -- "$trace")
            tr=${tr%.*}

            if [ ! -d $LOG_FOLDER/$tr ] || [ ! -z "$(git diff origin/last_state --name-only -- $REPOROOT/src | grep "${sim}_prefetcher.c")" ] || [ ! -f "$LOG_FOLDER/$tr/$sim.log" ]; then
                if [ ! -d $LOG_FOLDER/$tr ]; then
                    mkdir $LOG_FOLDER/$tr
                fi

                echo "Running $sim <- $tr"
                zcat $trace | $simulator > "$LOG_FOLDER/$tr/$sim.log"
            else
                echo "Discarted $sim <- $tr"
            fi
        fi
        counter=$((counter+1))
    done
done
