#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
CSV_OUTPUT=$BASEDIR/csvoutput
SCRIPTS_FOLDER=$BASEDIR/scripts

# Download the new PDFs, based on the really new ids.
cd $PATH_TO_SCRAPPER
if [ ! -d "$PDF_OUTPUT" ]; then
    mkdir $PDF_OUTPUT
    mkdir "$PDF_OUTPUT"/en
    mkdir "$PDF_OUTPUT"/ka
fi
scrapy crawl declaration

echo "PDF files available in: "$PATH_TO_SCRAPPER"/output"

rm $BASEDIR/newids
rm $BASEDIR/sortedidlist

