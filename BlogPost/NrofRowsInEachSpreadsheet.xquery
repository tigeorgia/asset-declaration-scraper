
(: count number of rows in each spreadsheet :)

declare namespace ti = "http://transparency.ge";
 

let $col := collection('/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/en')

let $header := $col/table[@name='ADheader']
 
return
<table>
<tr><th>Table</th><th>Nr of rows</th></tr>
{
for $tab in $col//table
return
<tr><td>{string($tab/@name)}</td><td>{count($tab//tr)}</td></tr>
}
</table>

(:  other things i counted 
(count($JoinTable//tr), count($persons), 
subsequence(for $p in $persons 
let $c := count($JoinTable//tr[td[1]=$p])
order by $c descending
return concat(ti:PersonID2Name($p),':',$c)
,1,20)
)

:)