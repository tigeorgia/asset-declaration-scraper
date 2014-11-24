#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output

# Get the new list of id, from the website
cat $BASEDIR/currentdeclarationids | sort -g | sed '/^$/d' > sortedidlist

# Read the old list of id, make a diff with the new list, and see what ids are really new.
echo "Crawling new list of id from declaration.gov.ge now..."
if [ -f "$OUTPUT/idlist" ]; then
    rm $OUTPUT/idlist
fi

./scripts/defineDeclarationIds.sh

cat $OUTPUT/idlist | sort -g | sed '/^$/d' > sortednewidlist

cp sortednewidlist newids

# We make the new list of ids ready for the scrapper.
comm -13 sortedidlist sortednewidlist > newids
cp ./newids "$PATH_TO_SCRAPPER"/idlist

# Timestamp is added to the name of new list of ids file.
now=$(date +'%Y-%m-%d')
cp $BASEDIR/sortednewidlist $BASEDIR/"declarationids-"$now

rm sortednewidlist

# Get the PDF output folder ready, in case it does not exist, for the next step (download PDFs)
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

