#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
BIN_FOLDER=$REPOROOT/bin
TRACE_FOLDER=$REPOROOT/traces
LOG_FOLDER=$REPOROOT/logs


for simulator in $BIN_FOLDER/*; do
    for trace in $TRACE_FOLDER/*; do
        sim=$(basename -- "$simulator")
        tr=$(basename -- "$trace")
        tr=${tr%.*}
        echo "Running $sim <- $tr"
        zcat $trace | $simulator > "$LOG_FOLDER/$sim-$tr.log"

    done
done
