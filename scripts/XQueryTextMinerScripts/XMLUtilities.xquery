module namespace tiUtil= "http://transparency.ge/XML-Utilities";


(: helper functions :)

declare function tiUtil:NotEmpty($s){ if ($s) then $s else ' '};
declare function tiUtil:tostring($list){normalize-space(string-join( for $t in $list return normalize-space(string($t)),' '))};
declare function tiUtil:NoDoubleQuotes($text){replace($text,'"',"'")};
declare function tiUtil:toISOdate($date){ let $cleandate:= replace($date,'[^0-9/.\-]','')   (: remove junk including space :)
                                          let $cleandate := replace($cleandate,'(\d*)[/.\-](\d*)[/.\-](\d*)','$3-$2-$1')  (: reorder :) 
                                          let $cleandate := replace($cleandate,'-(\d)-','-0$1-')  (: pad the month :)
                                          let $cleandate := replace($cleandate,'-(\d)$','-0$1')   (: pad the day :)
                                          return $cleandate};
declare function tiUtil:toAmountWithMoneyUnit($money){
    let $amount :=  replace($money,'[^0-9.]','') (: tiUtil:NotEmpty(replace($money,'[^0-9.]','')) :)
    let $Unit := replace($money,'[0-9 .\-]','')   (: tiUtil:NotEmpty(replace($money,'[0-9.]','')) :)
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
declare function tiUtil:trTOcsv($table){for $tr in $table//tr return concat('&#10;',string-join($tr//td/(.|@*)[not(empty(.))],'&#09;'))};


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
