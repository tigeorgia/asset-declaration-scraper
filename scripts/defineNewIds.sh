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
        echo "usage: defineNewIds.sh <most available id list>"
        exit 1
fi

# Get the new list of id, from the website
cat $1 | sort -g | sed '/^$/d' > sortedidlist

# Read the old list of id, make a diff with the new list, and see what ids are really new.
echo "Crawling new list of id from declaration.gov.ge now..."
./scripts/defineDeclarationIds.sh

cat $OUTPUT/idlist | sort -g | sed '/^$/d' > sortednewidlist

cp sortednewidlist newids

# We make the new list of ids ready for the scrapper.
comm -13 sortedidlist sortednewidlist > newids
cp ./newids "$PATH_TO_SCRAPPER"/idlist

# Timestamp is added to the name of new list of ids file.
now=$(date +'%Y-%m-%d')
cp $BASEDIR/sortednewidlist $BASEDIR/"declarationids-"$now
