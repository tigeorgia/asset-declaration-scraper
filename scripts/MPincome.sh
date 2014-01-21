#!/bin/sh

# 

#  paths   needs to be configured
 
# The import module statement in  MPincome.xquery
saxon="/home/etienne/asset-declaration-scraper/DeclarationXmlParsing/lib/saxon9he.jar"
collectionpath="/home/etienne/asset-declaration-scraper/archive/output/xml/ka";  # path to Georgian Asset DEclaration collection
colpath_english='/home/etienne/asset-declaration-scraper/archive/output/xml/en'; # path to English Asset DEclaration collection
path_to_xquery='/home/etienne/asset-declaration-scraper/scripts/XQueryTextMinerScripts';

 
# don't touch what is below this line


outputtype='sql'  # sql|csv depending on the type of output you want
out="MPincome" ;  #"Parliament_familyincome";  #

 
java -Xmx1G -cp  "$saxon" net.sf.saxon.Query  "$path_to_xquery"/MPincome.xquery  colpath="$collectionpath" colpath_english="$colpath_english" outputtype="$outputtype"   > "$out.$outputtype"   
 
