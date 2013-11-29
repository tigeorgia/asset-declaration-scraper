#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts
OUTPUT_CSV_FOLDER=$BASEDIR/output/csv/en

if [ -z "$1" ]; then
    echo "Need before|after argument."
    exit 1;
fi

WHEN=$1

if [ "$WHEN" == 'before' ]; then
    if ([ -f "$BASEDIR/countBeforeUpdate" ]); then
        rm $BASEDIR/countBeforeUpdate
    fi

    while read p; do
	wc -l $OUTPUT_CSV_FOLDER/$p >> $BASEDIR/countBeforeUpdate
    done < $SCRIPTS_FOLDER/listOfCsvNames.csv
fi

if [ "$WHEN" == 'after' ]; then
    if ([ -f "$BASEDIR/countAfterUpdate" ]); then
        rm $BASEDIR/countAfterUpdate
    fi

    while read p; do
	wc -l $OUTPUT_CSV_FOLDER/$p >> $BASEDIR/countAfterUpdate
    done < $SCRIPTS_FOLDER/listOfCsvNames.csv
fi










