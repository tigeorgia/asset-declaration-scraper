#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
SCRIPTS_FOLDER=$BASEDIR/scripts

# Once we have the PDF, we need to convert them into XML files
cd $BASEDIR
if [ ! -d "$XML_OUTPUT" ]; then
    mkdir $XML_OUTPUT
    mkdir "$XML_OUTPUT"/en
    mkdir "$XML_OUTPUT"/ka
fi
$SCRIPTS_FOLDER/toxml.sh $PDF_OUTPUT $XML_OUTPUT
