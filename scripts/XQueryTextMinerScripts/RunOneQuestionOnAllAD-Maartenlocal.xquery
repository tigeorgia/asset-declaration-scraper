(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
          tiADQ:ExtractTextToFile($col,$QuestionID,$OutputFormat,$Outputfile) 
          with $QuestionID between 0-11 and $Outputformat = /xml|csv/
          
          :)

import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at " FunctionsForEachCSVFile.xquery";

 (: 
declare variable $QuestionID external; (: between 0 and 11 :)
declare variable $Language external; (: eng OR geo :)
declare variable $outputtype external; (: xml OR csv :)
declare variable $XMLstore external; (: := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/'; :)
declare variable $Filename external;
:) 

declare variable $GEOXMLstore   := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/GEOXML/ka'; 
declare variable $XMLstore   :='/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/'; 
let $col := subsequence(collection($GEOXMLstore),1,100)

return tiADQ:ExtractTextToFile($col,7,'geo','xml','test')
 
  
 
