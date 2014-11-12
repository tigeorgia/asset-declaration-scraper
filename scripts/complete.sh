#!/bin/bash

BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
SCRIPTS_FOLDER=$BASEDIR/scripts

# Get all the ids from declaration.gov.ge, and make a diff with the most available id list ($1), 
# in order to define what are the new documents that have been posted, since the last time 
# this script had run
$SCRIPTS_FOLDER/defineNewIds.sh

# Download the new PDFs, based on the really new ids.
$SCRIPTS_FOLDER/downloadpdf.sh

# Once we have the PDF, we need to convert them into XML files
$SCRIPTS_FOLDER/toxml.sh $PDF_OUTPUT $XML_OUTPUT

# Importing data into MySQL database
ruby $SCRIPTS_FOLDER/export-assets-declarations.rb

# Creating the SQL file to update MP's profile on myparliament.ge
ruby $SCRIPTS_FOLDER/create-sql-script.rb

if [ -f "RepresentativeTableUpdate.sql" ]; then
    # uploads the sql file to shenmartav server, and runs it once uploaded.
    $SCRIPTS_FOLDER/sshToShenmartavServer.sh
fi


echo "All done."
