#!/bin/bash

OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy

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
