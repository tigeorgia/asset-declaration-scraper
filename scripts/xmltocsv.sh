#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts
XQUERY_SCRIPTS_FOLDER=$SCRIPTS_FOLDER/XQueryTextMinerScripts

# The XML files have been generated, we can now turn them into CSV files
#if [ ! -d "$CSV_OUTPUT" ]; then
#    mkdir $CSV_OUTPUT
#fi

if [ -z "$1" ]; then
    echo "Need directory to read the XML files from!"
    exit 1;
fi
if [ -z "$2" ]; then
    echo "Need directory to write the output CSV and XML files to!"
    exit 2;
fi
if [ -z "$3" ]; then
    echo "Please specify the environment you are running this script from ('dev' or 'prod')!"
    exit 1;
fi
if [ -z "$4" ]; then
    echo "Please specify the action you wish to carry out ('main' to create main csv and xml files, or 'join' to create the files that gather names and declaration ids)!"
    exit 1;
fi

XML_OUTPUT=$1
OUTPUT=$2
ENVIRONMENT=$3
ACTION=$4

if [ ! -d "$OUTPUT" ]; then
    mkdir $OUTPUT
    mkdir "$OUTPUT"/csv
    mkdir "$OUTPUT"/csv/en
    mkdir "$OUTPUT"/csv/ka
    mkdir "$OUTPUT"/xml
    mkdir "$OUTPUT"/xml/en
    mkdir "$OUTPUT"/xml/ka
fi

if [ ! -d "$OUTPUT"/csv ]; then
    mkdir "$OUTPUT"/csv
    mkdir "$OUTPUT"/csv/en
    mkdir "$OUTPUT"/csv/ka
fi

if [ ! -d "$OUTPUT"/xml ]; then
    mkdir "$OUTPUT"/xml
    mkdir "$OUTPUT"/xml/en
    mkdir "$OUTPUT"/xml/ka
fi

# Counting the number of lines in each CSV before update.
$SCRIPTS_FOLDER/countLinesInOutput.sh "before"

java -jar ./scripts/declarationXmlParsing.jar $XQUERY_SCRIPTS_FOLDER $XML_OUTPUT $OUTPUT $ENVIRONMENT $SCRIPTS_FOLDER/config.properties $ACTION

$SCRIPTS_FOLDER/countLinesInOutput.sh "after"

echo "Running xmllint --noout on the output XML files, to validate them."
for f in `ls $OUTPUT/xml/en`; do
    name=$OUTPUT/xml/en/$f

    if xmllint --noout $name; then
        continue
    else
	rm $name
        echo "WARNING: "+$name+".xml (English version) was not formed properly! It was removed automatically, to avoid any further processing problems."
    fi
done 

