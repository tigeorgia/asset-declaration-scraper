module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile";

declare namespace ti = "http://transparency.ge";
 
import module namespace tiAD= "http://transparency.ge/AssetDeclaration" at "AssetDeclaration.xquery"; 
import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "XMLUtilities.xquery";



(: general wrapper around the text extraction for each $doc function :)
  
declare function       tiADQ:ExtractTextToFile($col,$QuestionID,$Language, $OutputFormat,$Outputfile){
if ($OutputFormat='xml') 
then
<table name='{tiAD:TableName($QuestionID)}' language='{$Language}'>
{
tiAD:WriteHeader($col,$QuestionID,$Language,$OutputFormat,$Outputfile),
for $doc in  $col 
return

tiADQ:ExtractText($doc,$QuestionID,$Language,$OutputFormat)

}
</table>
 
else 
if ($OutputFormat='csv')
then
(tiAD:WriteHeader($col,$QuestionID,$Language,$OutputFormat,$Outputfile),
'&#10;',
for $doc in  $col  return tiADQ:ExtractText($doc,$QuestionID,$Language,$OutputFormat)
)
else
tiUtil:WriteError(concat('Unrecognized output format: ',$OutputFormat,'. You can only use "csv" or "xml".'))

        };
        
      

(: the real work is done by this function :) 

declare function tiADQ:ExtractText($doc,$QuestionIdentifier,$Language,$Outputformat){
(: special part for "question 0" (the header information :)
if ($QuestionIdentifier=0)
then
let   $PageQuestionString := if ($Language ='eng') then  (: See step 1 :)
                                    "Asset Declaration of Public Official" 
                                    else "თანამდებობის პირის ქონებრივი მდგომარეობის დეკლარაცია"
let $Submitregex :=   if ($Language ='eng') then    '^Asset Declaration was submitted on:' else   '^თანამდებობის პირის დეკლარაცია შევსებულია: '                
let $Nameregex :=   if ($Language ='eng') then    '^First Name, Last Name:$' else   '^სახელი, გვარი:' 
let $Birthregex := if ($Language ='eng') then '^Place of Birth, Date of Birth:$' else '^დაბადების ადგილი, დაბადების თარიღი:'
let $Orgregex := if ($Language ='eng') then '^Organisation, Position:$' else '^სამსახური, დაკავებული'
let $Workregex := if ($Language ='eng') then '^Work address, Phone number:$' else '^სამსახურის მისამართი, ტელეფონი:'


 return
for $page in tiAD:GetOurPages($doc,$PageQuestionString)[1]
  
    let $submitDate := tiUtil:pad(tiUtil:toISOdate(replace($page//text[matches(normalize-space(.),$Submitregex)],'[^0-9/]','')))
    
    (: first name, last name :)
    let $name :=  $page//text[matches(normalize-space(.),$Nameregex)]//following-sibling::text[1]
    let $fnln :=  tiUtil:ParseStringToFirstNameLastName(string-join($name//text(),' '))
     
    (: Place of Birth, Date of Birth: :)
    let $bdtext :=  $page//text[matches(normalize-space(.),$Birthregex)]//following-sibling::text[1]
    let $birthdate := tiUtil:pad(tiUtil:toISOdate(replace($bdtext,'^(.*), ([0-9/]+)$','$2')))
    let $birthplace :=  tiUtil:pad(replace($bdtext,'^([^0-9/]+)([0-9/]+)$','$1'))
(: Organisation, Position: :)
  let $org := tiUtil:pad(string($page//text[matches(normalize-space(.),$Orgregex)]//following-sibling::text[1]))
  
 (: Work address, Phone number:  :)
 let $work := tiUtil:pad($page//text[matches(normalize-space(.),$Workregex)]//following-sibling::text[1]/text())
(: specify output order :)  
let $output := ($fnln, $birthplace,$birthdate, $org, $work, $submitDate )  
(: end of special part for question 0 :)
return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)

else 

(: generic part for all other questions :)
(:step 1: Get the Raw data (that is, formatted as in the PDF :)
let $table := tiAD:WriteRawXML($doc,$QuestionIdentifier,$Language)
for $tr in $table//tr 
return
(:step 2, reformat each line in the Raw output into $output. This is specific for each question :)


if ($QuestionIdentifier=1)
then

    let $output := (subsequence($tr/td,1,3),tiUtil:toISOdate($tr/td[4]),$tr/td[5])
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)  
else    

if ($QuestionIdentifier=2 ) 
then
 let $fnlnline := tokenize($tr/td[1],' +')  
    let $fnln := subsequence($fnlnline,1,2)
    let $percentage:= if ($fnlnline[3]) then subsequence($fnlnline,3,count($fnlnline)) else ' '
(: type :)
    let $type := tiUtil:pad($tr/td[2])   
(: The property description :)
 (: let $prop := $tr/td[xs:integer(@left) gt $SecondColEnd]
                        [xs:integer(@left)+xs:integer(@width)  lt $FourthColStart]
 let $niceprop := string-join( for $t in $prop return normalize-space($t),' ')
 :)
 let $niceprop := $tr/td[3]
 let $propdescription := if (contains($niceprop,'Area -')) then tiUtil:pad(substring-before($niceprop,'Area -')) else tiUtil:pad($niceprop)
 let $area := if (contains($niceprop,'Area -')) then 
                    let $a := normalize-space(substring-after($niceprop,'Area -'))
                    return 
                    (tiUtil:pad(substring-before($a,' ')),tiUtil:pad(replace(substring-after($a,' '),' ','')))
                    else (' ',' ')
 (: the last question :)
 let $poss := tiUtil:pad($tr/td[4])
(: specify output order :)  
let $output :=   ($fnln,$percentage,$type,$propdescription,$area,$poss) 
let $output := if (count($output)=8) then $output else for $i in 1 to 8 return ' '  (: make sure that the output is always 8 long :)
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else    


if ($QuestionIdentifier=3)
then
 let $fnlnline := tokenize($tr/td[1],' +')  
    let $fnln := subsequence($fnlnline,1,2)
    let $percentage:= if ($fnlnline[3]) then subsequence($fnlnline,3,count($fnlnline)) else ' '
    let $output :=   ($fnln,$percentage, subsequence($tr/td,2,3) ) 
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else

if ($QuestionIdentifier=4)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,2),  tiUtil:toAmountWithMoneyUnit($tr/td[4]), string($tr/td[5]) ) 
    return   $tr (: tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier) :)
else

if ($QuestionIdentifier=5)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,2),tiUtil:toAmountWithMoneyUnit($tr/td[4]) ) 
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else

if ($QuestionIdentifier=6)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]), tiUtil:toAmountWithMoneyUnit($tr/td[2]) ) 
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else

if ($QuestionIdentifier=7)
then  (: for Georgian we do something a little different than for English.
         This is because with the Georgian CSV's this question does not work, because there are two columns whose first line of the header is equal.
         And our recogniser breaks with this.
         We did not expect this, and we did not code for it. 
         :)
    if ($Language='eng')
    then
        let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),   subsequence($tr/td,2,4)  ,tiUtil:toAmountWithMoneyUnit($tr/td[6]) ) 
        return    tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
    else 
        let $output := (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),   subsequence($tr/td,2,1),for $i in 1 to 5 return 'missing data (not missing in English version)' )
        return    tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier) 
else
if ($QuestionIdentifier=8)
then

        let $fnln := tiUtil:ParseStringToFirstNameLastName($tr/td[1])  
        let $org:= tiUtil:pad($tr/td[2]) 
    let $jobtitle := tiUtil:pad($tr/td[3])
    let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
    let $output :=    ($fnln,$org,$jobtitle,$amount)  
return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)

else
if ($QuestionIdentifier=9)
then
  
        let $fnln := tiUtil:ParseStringToFirstNameLastName($tr/td[1]) 
        let $col2:= tiUtil:pad($tr/td[2])
        let $col3 := tiUtil:pad($tr/td[3])
        let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
         (: we could try to separate "GEL (Expenditure)" into 2 columns :)
    let $output :=    ($fnln,$col2,$col3,$amount )  
    
return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else


(: 10 First_Name,Last_Name,Type,Amount,Dimension,Family_Relation :)
if ($QuestionIdentifier=10)
then
  
        let $fnln := tiUtil:ParseStringToFirstNameLastName($tr/td[1]) 
        let $col2:= tiUtil:pad($tr/td[2])
        let $type := tiUtil:pad(replace($tr/td[2],'^(.*),(.*)$','$1'))
        let $amount := tiUtil:toAmountWithMoneyUnit(replace($tr/td[2],'^(.*),(.*)$','$2'))
        let $col3 := tiUtil:pad($tr/td[3])
        
    let $output :=    ($fnln,$type,$amount,$col3 )  
    
return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
else

if ($QuestionIdentifier=11)  (: the last question needs extra care, otherwise it outputs a weird empty csvrow :)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,1),tiUtil:toAmountWithMoneyUnit($tr/td[last()]) ) 
    return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)





else (: the default is just to output the raw output :)
  
  let $output := $tr//td//text()
  return tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionIdentifier)
  
  
};



(:   %%%%%%%%% OLD STUFF:  CAN BE DELETED 
(: header :) 





(: special tricks because the question does not start the page! :)
declare function tiADQ:Header($doc) { 
 let   $PageQuestionString := "Asset Declaration of Public Official" (: See step 1 :)
 return
for $page in tiAD:GetOurPages($doc,$PageQuestionString)[1]
  
    let $submitDate := tiUtil:toISOdate(replace($page//text[matches(.,'Asset Declaration was submitted on:')],'[^0-9/]',''))
    
    (: first name, last name :)
    let $name := $page//text[matches(normalize-space(.),'^First Name, Last Name:$')]//following-sibling::text[1]
    let $fnln := tiUtil:ParseStringToFirstNameLastName(string-join($name//text(),' '))
     
    (: Place of Birth, Date of Birth: :)
    let $bdtext := $page//text[matches(normalize-space(.),'^Place of Birth, Date of Birth:$')]//following-sibling::text[1]
    let $birthdate := tiUtil:toISOdate(replace($bdtext,'[^0-9/]',''))
    let $birthplace :=  replace($bdtext,'[0-9/]','')
(: Organisation, Position: :)
  let $org := $page//text[matches(normalize-space(.),'^Organisation, Position:$')]//following-sibling::text[1]/text()
  
 (: Work address, Phone number:  :)
 let $work := $page//text[matches(normalize-space(.),'^Work address, Phone number:$')]//following-sibling::text[1]/text()
(: specify output order :)  
let $output := ($fnln,$birthplace,$birthdate, $org, $work, $submitDate )  


(: END SPECIFIC :)
return
tiAD:WriteCSVrow($output,$doc)
};






(: 1  Family:) 



(: 2 :) 
declare function tiADQ:RealEstate($doc) {
let $csvrow := tiAD:WriteRawCSV($doc,2)
(: now get all fields for our rows :)  
(: first name, last name , percentage:)
    let $fnlnline := tokenize($csvrow[1],' +')  
    let $fnln := subsequence($fnlnline,1,2)
    let $percentage:= if ($fnlnline[3]) then subsequence($fnlnline,3,count($fnlnline)) else ' '
(: type :)
    let $type := $csvrow[2]   
(: The property description :)
 (: let $prop := $csvrow[xs:integer(@left) gt $SecondColEnd]
                        [xs:integer(@left)+xs:integer(@width)  lt $FourthColStart]
 let $niceprop := string-join( for $t in $prop return normalize-space($t),' ')
 :)
 let $niceprop := $csvrow[3]
 let $propdescription := if (contains($niceprop,'Area -')) then substring-before($niceprop,'Area -') else $niceprop
 let $area := if (contains($niceprop,'Area -')) then 
                    let $a := normalize-space(substring-after($niceprop,'Area -'))
                    return 
                    (substring-before($a,' '),replace(substring-after($a,' '),' ',''))
                    else ' '
 (: the last question :)
 let $poss := $csvrow[4]
(: specify output order :)  
let $output := ($fnln,$percentage,$type,$propdescription,$area,$poss)  
(: END SPECIFIC :)
return
tiAD:WriteCSVrow($output,$doc)
};


(:8 :)
declare function tiADQ:PaidWork($doc) {
let $table := tiAD:WriteRawCSV($doc,8)
    for $tr in $table//tr 
        let $fnln := tokenize($tr/td[1],' +')  
        let $org:= $tr/td[2]
    let $jobtitle := $tr/td[3]
    let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
    let $output :=    ($fnln,$org,$jobtitle,$amount)  
(: END SPECIFIC :)
    return
    tiAD:WriteCSVrow($output,$doc)  
};


(:9:)
declare function tiADQ:ActiveContracts($doc) {
let $table := tiAD:WriteRawCSV($doc,9)
    for $tr in $table//tr 
        let $fnln := tokenize($tr/td[1],' +')  
        let $col2:= $tr/td[2]
    let $col3 := $tr/td[3]
    let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
    let $amount2 := 
        let $tmp:= tokenize($amount[2],' +')
        return
        if (count($tmp) ne 2) 
            then   ($amount[2],' ')
            else $tmp
    let $output :=    ($fnln,$col2,$col3,$amount)  
(: END SPECIFIC :)
    return
    tiAD:WriteCSVrow($output,$doc)  
};
:)
