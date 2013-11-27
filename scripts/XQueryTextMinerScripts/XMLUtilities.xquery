module namespace tiUtil= "http://transparency.ge/XML-Utilities";


(: helper functions :)

declare function tiUtil:NotEmpty($s){ if ($s) then $s else ' '};
declare function tiUtil:tostring($list){normalize-space(string-join( for $t in $list return normalize-space(string($t)),' '))};
declare function tiUtil:toISOdate($date){ let $cleandate:= replace($date,'[^0-9/-]','') return replace($cleandate,'(..)/(..)/(....)','$3-$2-$1')};
declare function tiUtil:toAmountWithMoneyUnit($money){
    let $amount :=  replace($money,'[^0-9.]','') (: tiUtil:NotEmpty(replace($money,'[^0-9.]','')) :)
    let $Unit := replace($money,'[0-9- .]','')   (: tiUtil:NotEmpty(replace($money,'[0-9.]','')) :)
        return (tiUtil:pad($amount),tiUtil:pad($Unit))};

(: create 2 columns first-name;last-name out of a string :)
declare function tiUtil:ParseStringToFirstNameLastName($name){
let $fnln := tokenize(normalize-space($name),' +')  
return 
if (count($fnln)=2)  (: just a first name and a last name :)
    then $fnln 
    else (tiUtil:pad(tiUtil:tostring($fnln[not(last())])),tiUtil:pad($fnln[last()]))  (: otherwise we use the last item as the last name, and all the rest as the first name :)
    };                           

(: Creating CSV file functions :)

declare function tiUtil:pad($td){if ($td) then $td else ' '};   

declare function tiUtil:RemoveDoubleQuotes($s){replace($s,'"',' ')};

(: text writing functions :)

(: write a table to CSV format :)
declare function tiUtil:trTOcsv($table){for $tr in $table//tr return concat('&#10;',string-join($tr//td,'&#09;'))};

(:Write an error message :)
declare function tiUtil:WriteError($string){
    concat('&#10; ######################## ERROR ####################### &#10;',$string,'&#10;')};
    
    
(: functions to Create Unique ID's given a first name, last name and date of birth.
We can also turn the ID's back into the original information 
:)
declare function tiUtil:GiveUniqueID($firstName,$lastName,$BirthDate)
{   string-join(for $n in string-to-codepoints(string-join(($firstName,$lastName,$BirthDate),';')) return string($n),'.')};

declare function tiUtil:PersonID2Name($PersonID){
codepoints-to-string(for $i in tokenize($PersonID,'\.') return xs:integer($i))};
