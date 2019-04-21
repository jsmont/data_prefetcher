#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
LOG_FOLDER=$REPOROOT/logs
STATS_FOLDER=$REPOROOT/logs/stats
BIN_FOLDER=$REPOROOT/bin

for simulator in $BIN_FOLDER/*; do
    sim=$(basename -- "$simulator")
    for log_file in $LOG_FOLDER/$sim-*; do
        log=$(basename -- "$log_file")
        log=${log#*-}
        log=${log%.*}
        if [ ! -d $STATS_FOLDER/${log} ]; then
            mkdir $STATS_FOLDER/${log}
        fi

        ipc=$(cat $LOG_FOLDER/${sim}-${log}.log | grep "Simulation complete" | sed "s/.*IPC:\ \([0-9.]\+\)/\1/")
        echo -e "$(date -R)\t$ipc" >> $STATS_FOLDER/$log/${sim}.txt
    done
done
