(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
          tiADQ:ExtractTextToFile($col,$QuestionID,$OutputFormat,$Outputfile) 
          with $QuestionID between 0-11 and $Outputformat = /xml|csv/
          
          :)

import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at "/home/etienne/asset-declaration-scraper/scripts/XQueryTextMinerScripts/FunctionsForEachCSVFile.xquery";

 
declare variable $QuestionID external; (: between 0 and 11 :)
declare variable $Language external; (: eng OR geo :)
declare variable $outputtype external; (: xml OR csv :)
declare variable $XMLstore external; (: := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/'; :)
declare variable $Filename external;

let $col := collection($XMLstore)

return tiADQ:ExtractTextToFile($col,$QuestionID,$Language,$outputtype,$Filename)
 
  
 
