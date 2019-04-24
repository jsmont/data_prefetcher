#!/usr/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
DATAFILE=datafile.csv
OFFSET_DATAFILE=off_datafile.csv

#grep "Instructions Retired" $1 > $DATAFILE

grep "Instructions Retired" $1 > $DATAFILE
grep "Best offset" $1 > $OFFSET_DATAFILE
sed -i "s/.*Cycle: \([0-9]\+\) .*IPC: \([0-9.]\+\) .*IPC: \([0-9.]\+\).*/\1\t\2\t\3/g" $DATAFILE
sed -i "s/.*Cycle: \([0-9]\+\).*Best offset: \([0-9.]\+\).*Score: \([0-9.]\+\).*/\1\t\2\t\3/g" $OFFSET_DATAFILE
if [ -z "$(cat $OFFSET_DATAFILE)" ]; then
    gnuplot -p $REPOROOT/scripts/temporal.pt
else
    gnuplot -p $REPOROOT/scripts/offset_temporal.pt
fi

