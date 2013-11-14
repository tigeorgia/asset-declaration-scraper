(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
          tiADQ:ExtractTextToFile($col,$QuestionID,$OutputFormat,$Outputfile) 
          with $QuestionID between 0-11 and $Outputformat = /xml|csv/
          
          :)

  

import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at "FunctionsForEachCSVFile.xquery";
 
 
   declare variable $XMLstore := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/';

  let $col :=  collection($XMLstore)  (: subsequence(collection($XMLstore) ,1,100)  :)
return
  
   tiADQ:ExtractTextToFile($col,3,'xml','ADheader')   
  
 