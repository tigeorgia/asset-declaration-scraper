module namespace tiUtil= "http://transparency.ge/XML-Utilities";

declare namespace xsd="http://www.w3.org/2001/XMLSchema";



declare variable  $tiUtil:genderdb := doc('https://raw2.github.com/tigeorgia/asset-declaration-scraper/master/scripts/XQueryTextMinerScripts/GenderData.xml');
(: helper functions :)

declare function tiUtil:NotEmpty($s){ if ($s) then $s else ' '};
declare function tiUtil:tostring($list){normalize-space(string-join( for $t in $list return normalize-space(string($t)),' '))};
declare function tiUtil:NoDoubleQuotes($text){replace($text,'"',"'")};
declare function tiUtil:QuotesAround($text){concat('"',tiUtil:NoDoubleQuotes($text),'"')};


(: date functions :)
declare function tiUtil:toISOdate($date){ let $cleandate:= replace($date,'[^0-9/.\-]','')   (: remove junk including space :)
                                          let $cleandate := replace($cleandate,'(\d*)[/.\-](\d*)[/.\-](\d*)','$3-$2-$1')  (: reorder :) 
                                          let $cleandate := replace($cleandate,'-(\d)-','-0$1-')  (: pad the month :)
                                          let $cleandate := replace($cleandate,'-(\d)$','-0$1')   (: pad the day :)
                                          return $cleandate};
 
 (: compute the number of days (as a positive integer) between $Earlier and $Later which are both iso-dates :)
declare function tiUtil:SubstractDates($Earlier,$Later){days-from-duration(xsd:date($Later) - xsd:date($Earlier))};
          
          
 (: compute the age in years TODAY given a date of birth:)
 declare function tiUtil:AgeTODAYInYears($dob) {tiUtil:AgeInYears($dob,current-date())};
(: compute the age in years given two dates. from Michael Kay http://www.stylusstudio.com/xsllist/200601/post60440.html 
returns 666 when one of the dates is not an ISO date
:)
declare function tiUtil:AgeInYears($Earlier,$Later){
if ( $Earlier castable as  xs:date  and $Later castable as  xs:date)
then
years-from-duration(
((xsd:date($Later) - xsd:date($Earlier)) div xsd:dayTimeDuration('P1D'))
   idiv 365.242199 
   * xsd:yearMonthDuration('P1Y')
   )
 else
 666
 };


declare function tiUtil:toAmountWithMoneyUnit($money){
    let $amount :=  replace($money,'[^0-9.]','') (: tiUtil:NotEmpty(replace($money,'[^0-9.]','')) :)
    let $Unit := replace($money,'[0-9 .\-]','')   (: tiUtil:NotEmpty(replace($money,'[0-9.]','')) :)
        return (tiUtil:pad($amount),tiUtil:pad($Unit))};


(: Functions about names :) 

(: create 2 columns first-name;last-name out of a string :)
declare function tiUtil:ParseStringToFirstNameLastName($name){
let $name := replace($name,'\(.*\)',' ')  (: get rid of the "extra names between brackets" :)
let $fnln := tokenize(normalize-space($name),' +')  
return 
if (count($fnln)=2)  (: just a first name and a last name :)
    then $fnln 
    else (tiUtil:pad(tiUtil:tostring($fnln[not(last())])),tiUtil:pad($fnln[last()]))  (: otherwise we use the last item as the last name, and all the rest as the first name :)
    };                           


(: returns True if $Firstname1 and 2 are the same, or if one of them ends in an "i" and the other not, and they are the same without the "i" :)
declare function tiUtil:EqualFirstnames($Firstname1,$Firstname2){
$Firstname1 eq $Firstname2
or
replace($Firstname1,'ი$','') eq $Firstname2
or
replace($Firstname2,'ი$','') eq $Firstname1
};

(: determine the Gender based on a Georgian first name :)

declare function tiUtil:Gender($name as xs:string){
    
    
        ($tiUtil:genderdb//tr[.//td[3] eq $name]//td[2])[1] };  

(: the same as the previous, but now for Latin alphabet version of the name :)
declare function tiUtil:GenderForLatinName($name as xs:string){
    
    
        ($tiUtil:genderdb//tr[.//td[4] eq $name]//td[2])[1] };  

(: Give the English variant of a Georgian name used in the same asset declaration :)
declare function tiUtil:GeorgianName2EnglishName($fn,$ln,$id,$geo_col,$eng_col){
let $ADheadername := $geo_col[.//@name="ADheader"]//tr[./td[1] = $fn and ./td[2] = $ln and ./td[last()]=$id]
let $ADfamilyname := for $name at $pos in $geo_col[.//@name="ADfamily_relations"]//tr[./td[last()]=$id]
                     where $name/td[1] = $fn and $name/td[2] = $ln
                     return   $eng_col[  .//@name="ADfamily_relations"]//tr[./td[last()]=$id][$pos]
return
    if ($ADheadername) (: there is oonly one line for each asset declaration :)
    then $eng_col[.//@name="ADheader"]//tr[  ./td[last()]=$id]  
    else $ADfamilyname  (: here we have to use the position of the family members. We assume they are ordered in the same way in English and in Georgian :)
 
    };



(: find the relatives in a collection given an Asset declaration ID :)

declare function tiUtil:relatives($ADid,$col){
let $ADrelatives := $col[.//@name="ADfamily_relations"]//tr
return 
$ADrelatives[td[last()]=$ADid]
};

(: Creating CSV file functions :)

declare function tiUtil:pad($td){if ($td) then $td else ' '};   

declare function tiUtil:RemoveDoubleQuotes($s){replace($s,'"',' ')};

(: text writing functions :)

(: write a list to a <tr> element with <td>'s in it :)
declare function  tiUtil:WriteSequenceAsTR($seq){
let $seq := for $i in $seq return normalize-space($i)
return
<tr>
{
(for $i in $seq     return <td>{$i}</td>)
}
</tr>
};
(: similar as previous , but now we have two lists as input, the first contains the attribute names, the second the values.
attribute names will come out as $attributename attributes of the td-elements.
:)
declare function  tiUtil:WriteSequenceAsTR($attseq,$valueseq,$attributename){
let $valueseq := for $i in $valueseq return normalize-space($i)
let $attseq := for $i in $attseq return normalize-space($i)
return
<tr>
{
(for $i at $pos in $attseq     return <td>{ (attribute {$attributename} {$i}, $valueseq[$pos])}</td>)
}
</tr>
};


(: write a  sequence of attribute value pairs of the form A1:V1 A2:V2 .... as 
  <tr><td A1='V1' A2='V2' ..../></tr>
  :)
declare function  tiUtil:WriteAttributeValueAsTRwithAttributes($seq)
{
  <tr><td>{
                     
                    for $av in $seq
                    let $pair := tokenize($av,':')
                    return
                    attribute {normalize-space(string($pair[1]))} {normalize-space(string($pair[2]))}
                    
                    }
                    </td></tr>
};


(: write a table to CSV format :)
declare function tiUtil:trTOcsv($table){for $tr in $table//tr return 
                            concat('&#10;',
                                   string-join(for $i in $tr//td  return 
                                                                   if ($i eq '') (: value is in an attribute :)
                                                                   then $i/@*
                                                                   else $i
                                              ,
                                              '&#09;'
                                              )
                                   )
                                        };


(: write a table in which each td has an id element with a name to JSON format

[ { 
    "Naam": "JSON",
    "Type": "Gegevensuitwisselingsformaat",
    "isProgrammeertaal": false,
    "Zie ook": [ "XML", "ASN.1" ] 
  },
  { 
    "Naam": "JavaScript",
    "Type": "Programmeertaal",
    "isProgrammeertaal": true,
    "Jaar": 1995 
  } 
]

:)
declare function tiUtil:trTOjson($table){
(string('&#10;[')
,
for $tr in $table//tr[position() ne last()] return (string('{&#10;'),
                              concat(string-join(for $av in $tr//td return concat('&#10;&#09;"',$av/@id,'": "',$av,'"'), ','),
                                     string('&#10;},&#10;'))
                              ),
                              for $tr in $table//tr[last()] return (string('{&#10;'),
                              concat(string-join(for $av in $tr//td return concat('&#10;&#09;"',$av/@id,'": "',$av,'"'), ','),
                                     string('&#10;}&#10;'))
                              
                              )
,
 
string(']')
)
};


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



(: functions about Asset Declarations  
$ADheaderRows should be bound to a sequnece of tr elements from the ADheader file :)

declare function tiUtil:AssetDeclarations($FirstName,$LastName,$ADheaderRows){
for $tr in $ADheaderRows[ .//td[2]  eq $LastName and   tiUtil:EqualFirstnames(.//td[1],$FirstName) ]
    order by $tr//td[last()-1]  descending  (: date of submission :) 
    return $tr
};
