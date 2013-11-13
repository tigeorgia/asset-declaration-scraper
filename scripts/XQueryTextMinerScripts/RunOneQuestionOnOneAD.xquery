(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
    needs three external variables set       and a hardcoded path to the XML store.
          
          :)

import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at "FunctionsForEachCSVFile.xquery";
 
declare variable $outputtype external; (: xml OR csv :)
declare variable $QuestionID external; (: between 0 and 11 :)
declare variable $DocID external; (: just the ID :)

declare variable $XMLstore := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/';
let $doc := concat($XMLstore,$DocID,'.xml')
return  tiADQ:ExtractText(doc($doc),$QuestionID,$outputtype)  
  
    
 