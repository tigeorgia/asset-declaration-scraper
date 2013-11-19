(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
    needs 4 external variables set        
         
         The names of the ouput file for each question is 
         doc('AssetDeclarationsQuestionsInformation.xml')//q[@n=$QuestionID]/@t
         like in this example : <q n='0' t='ADheader'>
         
          :)


import module namespace tiAD= "http://transparency.ge/AssetDeclaration" at "scraper.ad.assetdeclaration.toreplace";

declare variable $QuestionID external; (: between 0 and 11 :)
declare variable $Language external; (: eng OR geo :)
declare variable $outputtype external; (: xml OR csv :)
declare variable $XMLstore  external ; (: := '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources/'; :)
declare variable $Filename external;

let $col := collection($XMLstore)

return  tiAD:WriteHeader($col,$QuestionID,$Language,$outputtype,$Filename)
