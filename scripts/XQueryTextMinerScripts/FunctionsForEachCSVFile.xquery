module namespace tiADQ = "http://transparency.ge/AssetDeclaration/FunctionsForEachCSVFile";

declare namespace ti = "http://transparency.ge";
 
import module namespace tiAD= "http://transparency.ge/AssetDeclaration" at "AssetDeclaration.xquery"; 
import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "XMLUtilities.xquery";



(: general wrapper around the text extraction for each $doc function :)
  
declare function       tiADQ:ExtractTextToFile($col,$QuestionID,$OutputFormat,$Outputfile){
(tiAD:WriteHeader($col,$QuestionID,$OutputFormat,$Outputfile),
'&#10;'
,
if ($OutputFormat='xml') 
then
<table name='{tiAD:TableName($QuestionID)}'>
{
for $doc in  $col 
return
tiADQ:ExtractText($doc,$QuestionID,$OutputFormat)
}
</table>
 
else 
if ($OutputFormat='csv')
then
for $doc in  $col 
return
tiADQ:ExtractText($doc,$QuestionID,$OutputFormat)

else
tiUtil:WriteError(concat('Unrecognized output format: ',$OutputFormat,'. You can only use "csv" or "xml".'))
)
        };
        


(: the real work is done by this function :) 

declare function tiADQ:ExtractText($doc,$QuestionIdentifier,$Outputformat){
(: special part for "question 0" (the header information :)
if ($QuestionIdentifier=0)
then
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
(: end of special part for question 0 :)
return tiAD:Writerow($output,$doc,$Outputformat)

else 

(: generic part for all other questions :)
(:step 1: Get the Raw data (that is, formatted as in the PDF :)
let $table := tiAD:WriteRawXML($doc,$QuestionIdentifier)
for $tr in $table//tr 
return
(:step 2, reformat each line in the Raw output into $output. This is specific for each question :)


if ($QuestionIdentifier=1)
then

    let $output := (subsequence($tr/td,1,3),tiUtil:toISOdate($tr/td[4]),$tr/td[5])
    return tiAD:Writerow($output,$doc,$Outputformat)
else    
if ($QuestionIdentifier=2)
then
 let $fnlnline := tokenize($tr/td[1],' +')  
    let $fnln := subsequence($fnlnline,1,2)
    let $percentage:= if ($fnlnline[3]) then subsequence($fnlnline,3,count($fnlnline)) else ' '
(: type :)
    let $type := $tr/td[2]   
(: The property description :)
 (: let $prop := $tr/td[xs:integer(@left) gt $SecondColEnd]
                        [xs:integer(@left)+xs:integer(@width)  lt $FourthColStart]
 let $niceprop := string-join( for $t in $prop return normalize-space($t),' ')
 :)
 let $niceprop := $tr/td[3]
 let $propdescription := if (contains($niceprop,'Area -')) then substring-before($niceprop,'Area -') else $niceprop
 let $area := if (contains($niceprop,'Area -')) then 
                    let $a := normalize-space(substring-after($niceprop,'Area -'))
                    return 
                    (substring-before($a,' '),replace(substring-after($a,' '),' ',''))
                    else ' '
 (: the last question :)
 let $poss := $tr/td[4]
(: specify output order :)  
let $output :=   ($fnln,$percentage,$type,$propdescription,$area,$poss) 
    return tiAD:Writerow($output,$doc,$Outputformat)
else    

if ($QuestionIdentifier=4)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,2),tiUtil:toAmountWithMoneyUnit($tr/td[4]) ) 
    return tiAD:Writerow($output,$doc,$Outputformat)
else

if ($QuestionIdentifier=5)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,2),tiUtil:toAmountWithMoneyUnit($tr/td[4]) ) 
    return tiAD:Writerow($output,$doc,$Outputformat)
else

if ($QuestionIdentifier=6)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]), tiUtil:toAmountWithMoneyUnit($tr/td[2]) ) 
    return tiAD:Writerow($output,$doc,$Outputformat)
else

if ($QuestionIdentifier=7)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,4),tiUtil:toAmountWithMoneyUnit($tr/td[6]) ) 
    return tiAD:Writerow($output,$doc,$Outputformat)
else
if ($QuestionIdentifier=8)
then

        let $fnln := tokenize($tr/td[1],' +')  
        let $org:= $tr/td[2] 
    let $jobtitle := $tr/td[3]
    let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
    let $output :=    ($fnln,$org,$jobtitle,$amount)  
return tiAD:Writerow($output,$doc,$Outputformat)

else
if ($QuestionIdentifier=9)
then
  
        let $fnln := tokenize($tr/td[1],' +')  
        let $col2:= $tr/td[2]
        let $col3 := $tr/td[3]
        let $amount := tiUtil:toAmountWithMoneyUnit($tr/td[4])
         (: we could try to separate "GEL (Expenditure)" into 2 columns :)
    let $output :=    ($fnln,$col2,$col3,$amount )  
    
return tiAD:Writerow($output,$doc,$Outputformat)
else

if ($QuestionIdentifier=11)
then
let $output :=   (tiUtil:ParseStringToFirstNameLastName($tr/td[1]),subsequence($tr/td,2,1),tiUtil:toAmountWithMoneyUnit($tr/td[last()]) ) 
    return tiAD:Writerow($output,$doc,$Outputformat)





else (: the default is just to output the raw output :)
  
  let $output := $tr//td//text()
  return tiAD:Writerow($output,$doc,$Outputformat)
  
  
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
