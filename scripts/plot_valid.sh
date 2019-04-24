#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)
LOG_FOLDER=$REPOROOT/logs
GH_FILE=$REPOROOT/docs/index.html

mkdir $REPOROOT/docs/img 2>/dev/null

cd $LOG_FOLDER

if [ ! -z "$GEN_GH" ]; then
    echo "<html>
<head>
<title>Data prefetcher stats</title>
<style>img{ width: 49%;} </style>
</head>
<body>" > $GH_FILE
fi

for trace in $LOG_FOLDER/*; do
    cd $trace
    for simulator in $trace/*.log; do
        sim=$(basename -- "$simulator")
        sim="$(sed "s/\(.*\).log/\1/g" <<<$sim)"
        tr=$(basename -- "$trace")
        tr=${tr%.*}

        echo -e "Instructions\t$(basename $sim)\t$(basename $sim)" > $sim.csv
        grep "Instructions Retired" $simulator >> $sim.csv
        sed -i "s/.*Retired: \([0-9]\+\) .*IPC: \([0-9.]\+\) .*IPC: \([0-9.]\+\).*/\1\t\2\t\3/g" $sim.csv
    done
    if [ -z "$GEN_GH" ]; then
    echo "
        set title \"$tr IPC evolution\"
        set xlabel \"\# of instructions\"
        set format x \"%.0f\"
        set ylabel \"IPC\"
        set key autotitle columnhead
        FILES = system(\"ls -1 *.csv\")
        plot for [data in FILES] data using 1:2 with lines lw 2
    " | gnuplot --persist
    echo "
        set title \"$tr accumulative IPC\"
        set xlabel \"\# of instructions\"
        set format x \"%.0f\"
        set ylabel \"IPC\"
        set key autotitle columnhead
        FILES = system(\"ls -1 *.csv\")
        plot for [data in FILES] data using 1:3 with lines lw 2
    " | gnuplot --persist
    else
        echo "
            set term png
            set output \"$REPOROOT/docs/img/${tr}_temporal.png\"
            set title \"$tr IPC evolution\"
            set xlabel \"\# of instructions\"
            set ylabel \"IPC\"
            set format x \"%.0f\"
            set key autotitle columnhead
            FILES = system(\"ls -1 *.csv\")
            plot for [data in FILES] data using 1:2 with lines lw 2
        " | gnuplot
        echo "<img src=\"img/${tr}_temporal.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
        echo "
            set term png
            set output \"$REPOROOT/docs/img/${tr}_accumulative.png\"
            set title \"$tr accumulative IPC\"
            set xlabel \"\# of instructions\"
            set ylabel \"IPC\"
            set format x \"%.0f\"
            set key autotitle columnhead
            FILES = system(\"ls -1 *.csv\")
            plot for [data in FILES] data using 1:3 with lines lw 2
        " | gnuplot
        echo "<img src=\"img/${tr}_accumulative.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
    fi
    rm *.csv
    cd $LOG_FOLDER
done


if [ ! -z "$GEN_GH" ]; then
    echo "</body>
</html>" >> $GH_FILE
fi
