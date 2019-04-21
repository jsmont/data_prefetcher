#!/usr/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
DATAFILE=datafile.csv


grep "Instructions Retired" $1 > $DATAFILE
sed -i "s/.*Retired: \([0-9]\+\) .*IPC: \([0-9.]\+\) .*IPC: \([0-9.]\+\).*/\1\t\2\t\3/g" $DATAFILE
gnuplot -p $REPOROOT/scripts/temporal.pt
