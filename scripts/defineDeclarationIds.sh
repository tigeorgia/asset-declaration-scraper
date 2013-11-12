#!/bin/bash

SRC="https://declaration.gov.ge/eng/declaration.php?id="
SRCPAGE="https://declaration.gov.ge/searchDeclarations.php?page="
CURL=/usr/bin/curl
OUTPUT=idlistoutput

if [ ! -d "$OUTPUT" ]; then
    mkdir $OUTPUT
fi

PAGE=1

# First, define total number of pages
TMPVAR=$($CURL "$SRCPAGE$PAGE" | awk '/<div class=\"last\">/,/<\/div>/' | grep 'page')
TOTALCOUNT=$(echo $TMPVAR | cut -d '=' -f4 | cut -d '"' -f1)
# Loop over the pages, 

if [[ $TOTALCOUNT != *[!0-9]* ]]; then
	# TOTALCOUNT is strictly a number, we proceed then with parsing each page
	PAGECOUNT=1
	# Creation of output file
	
	while [ $PAGECOUNT -le $TOTALCOUNT ]
	do
		echo "Parsing $SRCPAGE$PAGECOUNT" >> logfile
		$CURL $SRCPAGE$PAGECOUNT | grep 'declaration.php?id=' > $OUTPUT/tmpcount.txt
		while read p; do
			ID=$(echo $p | cut -d '=' -f 3 | cut -d "'" -f 1)
			echo "$ID" >> $OUTPUT/idlist
		done < $OUTPUT/tmpcount.txt

		rm $OUTPUT/tmpcount.txt
		PAGECOUNT=`expr $PAGECOUNT + 1`
	done
else
	# Problem occurred while getting the total number of pages
	echo "Problem occurred while defining the total number of pages."
fi

