#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts

# The XML files have been generated, we can now turn them into CSV files
#if [ ! -d "$CSV_OUTPUT" ]; then
#    mkdir $CSV_OUTPUT
#fi

if [ -z "$1" ]; then
    echo "Need directory to read the XML files from!"
    exit 1;
fi
if [ -z "$2" ]; then
    echo "Need directory to write CSV files to!"
    exit 2;
fi

XML_OUTPUT=$1
CSV_OUTPUT=$2

if [ ! -d "$CSV_OUTPUT" ]; then
    mkdir $CSV_OUTPUT
    mkdir "$CSV_OUTPUT"/en
    mkdir "$CSV_OUTPUT"/ka
fi

if [ ! -d "$CSV_OUTPUT"/en ]; then
    mkdir "$CSV_OUTPUT"/en
fi

if [ ! -d "$CSV_OUTPUT"/ka ]; then
    mkdir "$CSV_OUTPUT"/ka
fi

java -jar ./scripts/declarationXmlParsing.jar $SCRIPTS_FOLDER/CollectRealEstateTest.xquery $XML_OUTPUT $CSV_OUTPUT

