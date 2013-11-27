declare namespace ti = "http://transparency.ge";

import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "../XMLUtilities.xquery";

declare variable $startdate := '2012-10-01';

declare function ti:GiveUniqueID($firstName,$lastName,$BirthDate)
{   string-join(for $n in string-to-codepoints(string-join(($firstName,$lastName,$BirthDate),';')) return string($n),'.')};

declare function ti:PersonID2Name($PersonID){
codepoints-to-string(for $i in tokenize($PersonID,'\.') return xs:integer($i))};


let $colGEO := collection('/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/ka')
let $colENG := collection('/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/en')

let $header := $colENG/table[@name='ADheader']
let $GEOheader :=  $colGEO/table[@name='ADheader']

let $JoinTable := 
<table name='ADpersonID_filed_DocID' lan='eng'>
{
comment {'Unique ID for each person is generated using  string-to-codepoints(string-join(($firstName,$lastName,$BirthDate),";")).
You can generate the Name, birthday string back by tiUtil:PersonID2Name($PersonID)'},

for $row in $header//tr
let $DocID:= $row/td[last()]
let $georow := $GEOheader//tr[td[last()] =$DocID]
order by $DocID
return  
<tr>
{<td lan='eng'>{ tiUtil:GiveUniqueID($row/td[1],$row/td[2],$row/td[4])}</td>,
<td lan='geo'>{ tiUtil:GiveUniqueID($georow/td[1],$row/td[2],$row/td[4])} </td>,
$DocID}
</tr>
 }
</table> 
 
return
 $JoinTable
 