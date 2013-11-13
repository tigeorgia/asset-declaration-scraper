module namespace tiUtil= "http://transparency.ge/XML-Utilities";


(: helper functions :)

declare function tiUtil:NotEmpty($s){ if ($s) then $s else ' '};
declare function tiUtil:tostring($list){normalize-space(string-join( for $t in $list return normalize-space($t),' '))};
declare function tiUtil:toISOdate($date){replace($date,'(..)/(..)/(....)','$3-$2-$1')};
declare function tiUtil:toAmountWithMoneyUnit($money){
    let $amount := tiUtil:NotEmpty(replace($money,'[^0-9.]',''))
    let $Unit := tiUtil:NotEmpty(replace($money,'[0-9.]',''))
        return ($amount,$Unit)};

(: create 2 columns first-name;last-name out of a string :)
declare function tiUtil:ParseStringToFirstNameLastName($name){
let $fnln := tokenize(normalize-space($name),' +')  
return 
if (count($fnln)=2)  (: just a first name and a last name :)
    then $fnln 
    else (tiUtil:tostring($fnln[not(last())]),$fnln[last()])  (: otherwise we use the last item as the last name, and all the rest as the first name :)
    };                           
                            
(:Write an error message :)
declare function tiUtil:WriteError($string){
    concat('&#10; ######################## ERROR ####################### &#10;',$string,'&#10;')};