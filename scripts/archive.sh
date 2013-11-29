#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
OUTPUT=$BASEDIR/output

if ([ ! -d "$BASEDIR/archive" ]); then
    mkdir $BASEDIR/archive
    mkdir $BASEDIR/archive/declarationids
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

# Archiving the new declaration ids
now=$(date +'%Y-%m-%d')
cp $BASEDIR/"declarationids-"$now $BASEDIR/archive/declarationids/

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
cp -f $OUTPUT/csv/JoinResults.csv $BASEDIR/archive/output/csv/
cp -f $OUTPUT/xml/JoinResults.xml $BASEDIR/archive/output/xml/

echo "Done. The files have been archived in "$BASEDIR"/archive"
echo "Sending report e-mail"

numberOfDownloadedDeclarations=$(ls -l $PATH_TO_SCRAPPER/output/en | wc -l)

cat > emailToSend <<endmsg
--- Asset Declaration Scraper - $now - report ---

Number of downloaded declarations: $numberOfDownloadedDeclarations, in each language.

Declaration ids can be found in $BASEDIR/archive/declarationids/declarationids-$now

Information added in CSV files:
endmsg

while read p; do
    countBefore=$(grep "$p" $BASEDIR/countBeforeUpdate | cut -d ' ' -f1)
    countAfter=$(grep "$p" $BASEDIR/countAfterUpdate | cut -d ' ' -f1)
    numLines=`expr $countAfter - $countBefore`
    echo "$p: $numLines line(s) added" >> emailToSend
done < $SCRIPTS_FOLDER/listOfCsvNames.csv

# Sending e-mail report
SUBJECT="Asset Declaration Scraper report - $now"
EMAIL="etiennebaque@gmail.com"

/usr/bin/mail -s "$SUBJECT" "$EMAIL" < emailToSend

rm $BASEDIR/countBeforeUpdate
rm $BASEDIR/countAfterUpdate
rm emailToSend

echo "e-mail sent"

