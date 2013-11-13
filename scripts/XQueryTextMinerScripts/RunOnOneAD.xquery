(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine the asset declarations , 
          
          QUESTION: Do you or your family members have bank accounts in Georgian or foreign banks?
          
          :)

 
declare namespace ti = "http://transparency.ge";

import module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile" at "FunctionsForEachCSVFile.xquery";
import module namespace tiAD= "http://transparency.ge/AssetDeclaration" at "AssetDeclaration.xquery"; 
import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "XMLUtilities.xquery";

(:
let $doc := doc('48303.xml')
    for $i in 0 to 11 
   return  tiADQ:ExtractText($doc,$i,'xml')  
   (:  tiAD:GetOurPages($doc,$tiAD:QI//q[@n=9] /w/s)  tiADQ:ExtractText($doc,11,'xml') :)
   
 :)  
   
  let $col := collection($tiAD:collectiondir)  union collection($tiAD:collectiondir2) 
return
 
 tiADQ:ExtractTextToFile($col,8,'xml','ADpaid_work')
 