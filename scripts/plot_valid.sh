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
<style>img{ width: 32%;} </style>
</head>
<body>" > $GH_FILE
fi

for config_folder in $LOG_FOLDER/*; do
    cd $config_folder
    for trace in $config_folder/*; do
    cd $trace
    for simulator in $trace/*.log; do
        sim=$(basename -- "$simulator")
        sim="$(sed "s/\(.*\).log/\1/g" <<<$sim)"
        tr=$(basename -- "$trace")
        tr=${tr%.*}
        config=$(basename -- "$config_folder")

        echo -e "Instructions\t$(basename $sim)\t$(basename $sim)" > ${sim}_temporal.csv
        grep "Instructions Retired" $simulator >> ${sim}_temporal.csv
        sed -i "s/.*Retired: \([0-9]\+\) .*IPC: \([0-9.]\+\) .*IPC: \([0-9.]\+\).*/\1\t\2\t\3/g" ${sim}_temporal.csv
        
        grep "Simulation complete." $simulator | sed "s/.*Cycles elapsed: \([0-9.]\+\).*/$sim\t\1/g" >> ${tr}_aggregated.csv
    done
    if [ -z "$GEN_GH" ]; then
    echo "
        set title \"[$config] $tr IPC evolution\"
        set xlabel \"\# of instructions\"
        set format x \"%.0f\"
        set ylabel \"IPC\"
        set key autotitle columnhead
        FILES = system(\"ls -1 *_temporal.csv\")
        plot for [data in FILES] data using 1:2 with lines lw 2
    " | gnuplot --persist
    echo "
        set title \"[$config] $tr accumulative IPC\"
        set xlabel \"\# of instructions\"
        set format x \"%.0f\"
        set ylabel \"IPC\"
        set key autotitle columnhead
        FILES = system(\"ls -1 *_temporal.csv\")
        plot for [data in FILES] data using 1:3 with lines lw 2
    " | gnuplot --persist
    echo "
    set title \"[$config] $tr execution cycles\"
    set style data histograms
    set ylabel \"Cycles\"
    set style fill solid 1.00 border lt -1
    set xtics border in scale 1,0.5 nomirror rotate by -90 offset character 0, 0, 0
    unset key
    plot '${tr}_aggregated.csv' using 2:xticlabels(1) with histogram,\
         \"\"  using 0:(\$2):(\$2) with labels notitle offset 2,1
    " | gnuplot --persist
    else
        echo "
            set term png
            set output \"$REPOROOT/docs/img/${config}_${tr}_temporal.png\"
            set title \"[$config] $tr IPC evolution\"
            set xlabel \"\# of instructions\"
            set ylabel \"IPC\"
            set format x \"%.0f\"
            set key autotitle columnhead
            FILES = system(\"ls -1 *_temporal.csv\")
            plot for [data in FILES] data using 1:2 with lines lw 2
        " | gnuplot
        echo "<img src=\"img/${config}_${tr}_temporal.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
        echo "
            set term png
            set output \"$REPOROOT/docs/img/${config}_${tr}_accumulative.png\"
            set title \"[$config] $tr accumulative IPC\"
            set xlabel \"\# of instructions\"
            set ylabel \"IPC\"
            set format x \"%.0f\"
            set key autotitle columnhead
            FILES = system(\"ls -1 *_temporal.csv\")
            plot for [data in FILES] data using 1:3 with lines lw 2
        " | gnuplot
        echo "<img src=\"img/${config}_${tr}_accumulative.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
        echo "
            set term png
            set output \"$REPOROOT/docs/img/${config}_${tr}_histogram.png\"
            set title \"[$config] $tr execution cycles\"
            set style data histograms
            set ylabel \"Cycles\"
            set style fill solid 1.00 border lt -1
            set xtics border in scale 1,0.5 nomirror rotate by -90 offset character 0, 0, 0
            unset key
            plot '${tr}_aggregated.csv' using 2:xticlabels(1) with histogram,\
                 \"\"  using 0:(\$2):(\$2) with labels notitle offset 2,1
        " | gnuplot --persist
        echo "<img src=\"img/${config}_${tr}_histogram.png\" alt=\"Temporal IPC evolution for all prefetchers on $tr code.\">" >> $GH_FILE
    fi
    rm *.csv
    cd $config_folder
done

    cd $LOG_FOLDER
done


if [ ! -z "$GEN_GH" ]; then
    echo "</body>
</html>" >> $GH_FILE
fi
