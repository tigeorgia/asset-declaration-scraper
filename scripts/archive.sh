#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
OUTPUT=$BASEDIR/output

if ([ ! -d "$BASEDIR/archive" ]); then
    mkdir $BASEDIR/archive
    mkdir $BASEDIR/archive/pdf
    mkdir $BASEDIR/archive/pdf/en
    mkdir $BASEDIR/archive/pdf/ka
    mkdir $BASEDIR/archive/xml
    mkdir $BASEDIR/archive/xml/en
    mkdir $BASEDIR/archive/xml/ka
    mkdir $BASEDIR/archive/output
    mkdir $BASEDIR/archive/output/xml
    mkdir $BASEDIR/archive/output/xml/en
    mkdir $BASEDIR/archive/output/xml/ka
    mkdir $BASEDIR/archive/output/csv
    mkdir $BASEDIR/archive/output/csv/en
    mkdir $BASEDIR/archive/output/csv/ka
fi

# Archiving downloaded PDF files
echo "Archiving PDF files..."
mv $PDF_OUTPUT/en/* $BASEDIR/archive/pdf/en/
mv $PDF_OUTPUT/ka/* $BASEDIR/archive/pdf/ka/

# Archiving XMl files, created from the PDF files
echo "Archiving XML files created from PDF files..."
mv $XML_OUTPUT/en/* $BASEDIR/archive/xml/en/
mv $XML_OUTPUT/ka/* $BASEDIR/archive/xml/ka/

# Archiving/replacing CSV and XML output files
echo "Archiving output files..."
cp -f $OUTPUT/csv/en/* $BASEDIR/archive/output/csv/en/
cp -f $OUTPUT/csv/ka/* $BASEDIR/archive/output/csv/ka/
cp -f $OUTPUT/xml/en/* $BASEDIR/archive/output/xml/en/
cp -f $OUTPUT/xml/ka/* $BASEDIR/archive/output/xml/ka/

echo "Done. The files have been archived in "$BASEDIR"/archive"
