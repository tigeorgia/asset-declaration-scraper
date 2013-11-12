#!/bin/bash

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

# Get the new list of id, from the website
cat $1 | sort -g | sed '/^$/d' > sortedidlist

# Read the old list of id, make a diff with the new list, and see what ids are really new.
echo "Crawling new list of id from declaration.gov.ge now..."
./scripts/defineDeclarationIds.sh

cat $OUTPUT/idlist | sort -g | sed '/^$/d' > sortednewidlist

cp sortednewidlist newids

comm -13 sortedidlist sortednewidlist > newids
cp ./newids "$PATH_TO_SCRAPPER"/idlist


# Download the new PDFs, based on the really new ids.
cd $PATH_TO_SCRAPPER
if [ ! -d "$PDF_OUTPUT" ]; then
    mkdir $PDF_OUTPUT
    mkdir "$PDF_OUTPUT"/en
    mkdir "$PDF_OUTPUT"/ka
fi
scrapy crawl declaration

echo "PDF files available in: "$PATH_TO_SCRAPPER"/output"

rm newids
rm sortedidlist
mv $1 "$1"backup
mv sortednewidlist idlist
rm "$1"backup

# Once we have the PDF, we need to convert them into XML files
cd $BASEDIR
if [ ! -d "$XML_OUTPUT" ]; then
    mkdir $XML_OUTPUT
    mkdir "$XML_OUTPUT"/en
    mkdir "$XML_OUTPUT"/ka
fi
$SCRIPTS_FOLDER/toxml.sh $PDF_OUTPUT $XML_OUTPUT

# The XML files have been generated, we can now turn them into CSV files
if [ ! -d "$CSV_OUTPUT" ]; then
    mkdir $CSV_OUTPUT
fi
java -jar ./scripts/declarationXmlParsing.jar $SCRIPTS_FOLDER/CollectRealEstateTest.xquery $XML_OUTPUT $CSV_OUTPUT


