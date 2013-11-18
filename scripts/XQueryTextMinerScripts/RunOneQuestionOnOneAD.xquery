(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
    needs 4 external variables set        
         
         The names of the ouput file for each question is 
         doc('AssetDeclarationsQuestionsInformation.xml')//q[@n=$QuestionID]/@t
         like in this example : <q n='0' t='ADheader'>
         
          :)


import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at "scraper.ad.functionxquery.toreplace";

declare variable $QuestionID external; (: between 0 and 11 :)
declare variable $Language external; (: eng OR geo :)
declare variable $outputtype external; (: xml OR csv :)
declare variable $DocID external; (: just the ID :)
declare variable $XMLstore  external ; (: := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/'; :)

let $doc := doc(concat($XMLstore,'/',$DocID,'.xml'))
return  tiADQ:ExtractText($doc,$QuestionID,$Language,$outputtype)  
  
