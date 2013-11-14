#!/bin/bash

# Update the following line with one of these 2 values: 'dev' or 'prod'
# - Choose 'prod' if you are running the scripts from a remote server
# - Choose 'dev' if you are running the scripts in a development environment (ie your work machine).
ENVIRONMENT=prod


OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
CSV_OUTPUT=$BASEDIR/csvoutput
SCRIPTS_FOLDER=$BASEDIR/scripts

if [ $# -lt 1 ]
    then
        echo "usage: complete.sh <most available id list>"
        exit 1
fi

# Get all the ids from declaration.gov.ge, and make a diff with the most available id list ($1), 
# in order to define what are the new documents that have been posted, since the last time 
# this script had run
$SCRIPTS_FOLDER/defineNewIds.sh $1

# Download the new PDFs, based on the really new ids.
$SCRIPTS_FOLDER/downloadpdf.sh

# Once we have the PDF, we need to convert them into XML files
$SCRIPTS_FOLDER/toxml.sh $PDF_OUTPUT $XML_OUTPUT

# The XML files have been generated, we can now turn them into CSV files
$SCRIPTS_FOLDER/xmltocsv.sh $XML_OUTPUT $CSV_OUTPUT $ENVIRONMENT


