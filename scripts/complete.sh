#!/bin/bash

# Update the following line with one of these 2 values: 'dev' or 'prod'
# - Choose 'prod' if you are running the scripts from a remote server
# - Choose 'dev' if you are running the scripts in a development environment (ie your work machine).
#ENVIRONMENT=dev

# Update the following variable, to choose which Github branch you want to update your project from.
# Leave the value to 'master' by default.
BRANCH=master


OUTPUT=idlistoutput
BASEDIR=$PWD
PATH_TO_SCRAPPER=$BASEDIR/declarationScrapy
PDF_OUTPUT=$PATH_TO_SCRAPPER/output
XML_OUTPUT=$BASEDIR/xmloutput
#OUTPUT=$BASEDIR/output
SCRIPTS_FOLDER=$BASEDIR/scripts

# Compile and package the Java application.
$SCRIPTS_FOLDER/checkoutAndPackageApp.sh $BRANCH

# Get all the ids from declaration.gov.ge, and make a diff with the most available id list ($1), 
# in order to define what are the new documents that have been posted, since the last time 
# this script had run
$SCRIPTS_FOLDER/defineNewIds.sh

# Download the new PDFs, based on the really new ids.
$SCRIPTS_FOLDER/downloadpdf.sh

# Once we have the PDF, we need to convert them into XML files
$SCRIPTS_FOLDER/toxml.sh $PDF_OUTPUT $XML_OUTPUT

# The XML files have been generated, we can now turn them into CSV files
#$SCRIPTS_FOLDER/xmltocsv.sh $XML_OUTPUT $OUTPUT $ENVIRONMENT "main"

# This script create a CSV and XML files, which are a join of people's information with asset declaration ids.
#$SCRIPTS_FOLDER/createJoinTablesFiles.sh $XML_OUTPUT $OUTPUT $ENVIRONMENT "join"

# Archiving the newly downloaded and created files
$SCRIPTS_FOLDER/archive.sh

# Importing data into MySQL database
ruby $SCRIPTS_FOLDER/export_assets-declarations.rb

# Creating the SQL file to update MP's profile on myparliament.ge
ruby $SCRIPTS_FOLDER/create-sql-script.rb

if [ -f "RepresentativeTableUpdate.sql" ]; then
    # uploads the sql file to shenmartav server, and runs it once uploaded.
    $SCRIPTS_FOLDER/sshToShenmartavServer.sh
fi


echo "All done."
