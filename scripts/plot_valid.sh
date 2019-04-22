#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
LOG_FOLDER=$REPOROOT/logs
GH_FILE=$REPOROOT/docs/index.html

cd $LOG_FOLDER

if [ ! -z "$GEN_GH" ]; then
    echo "<html>
<head>
<title>Data prefetcher stats</title>
</head>
<body>" > $GH_FILE
fi

for trace in $LOG_FOLDER/*; do
    cd $trace
    for simulator in $trace/*.log; do
        sim=$(basename -- "$simulator")
        sim="$(sed "s/sim_\(.*\).log/\1/g" <<<$sim)"
        tr=$(basename -- "$trace")
        tr=${tr%.*}

        echo -e "Instructions\t$(basename $sim)" > $sim.csv
        grep "Instructions Retired" $simulator >> $sim.csv
        sed -i "s/.*Retired: \([0-9]\+\) .*IPC: \([0-9.]\+\) .*IPC: \([0-9.]\+\).*/\1\t\2/g" $sim.csv
    done
    if [ -z "$GEN_GH" ]; then
    echo "
        set title \"$tr IPC evolution\"
        set xlabel \"\# of instructions\"
        set ylabel \"IPC\"
        set key autotitle columnhead
        FILES = system(\"ls -1 *.csv\")
        plot for [data in FILES] data using 1:2 with lines lw 2
    " | gnuplot --persist
    else
        echo "
            set term png
            set output \"$REPOROOT/docs/img/$tr.png\"
            set title \"$tr IPC evolution\"
            set xlabel \"\# of instructions\"
            set ylabel \"IPC\"
            set key autotitle columnhead
            FILES = system(\"ls -1 *.csv\")
            plot for [data in FILES] data using 1:2 with lines lw 2
            set term x11
        " | gnuplot
        echo "<img src=\"img/$tr.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
    fi
    rm *.csv
    cd $LOG_FOLDER
done


if [ ! -z "$GEN_GH" ]; then
    echo "</body>
</html>" >> $GH_FILE
fi
