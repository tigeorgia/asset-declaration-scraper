#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output

# Download the new PDFs, based on the really new ids.
cd "$PATH_TO_SCRAPPER"
if [ ! -d "$PDF_OUTPUT" ]; then
    mkdir $PDF_OUTPUT
    mkdir "$PDF_OUTPUT"/en
    mkdir "$PDF_OUTPUT"/ka
fi

if [ ! -d "$PDF_OUTPUT"/en ]; then
    mkdir "$PDF_OUTPUT"/en
fi

if [ ! -d "$PDF_OUTPUT"/ka ]; then
    mkdir "$PDF_OUTPUT"/ka
fi

scrapy crawl declaration

echo "PDF files available in: "$PATH_TO_SCRAPPER"/output"

rm "$BASEDIR"/newids
rm "$BASEDIR"/sortedidlist

