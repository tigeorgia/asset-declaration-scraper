module namespace tiAD= "http://transparency.ge/AssetDeclaration";

declare namespace ti = "http://transparency.ge";

import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "XMLUtilities.xquery";

declare variable $tiAD:QI := doc(' AssetDeclarationsQuestionsInformation.xml');  
 


declare variable $tiAD:attribution := "Created by Maarten Marx for TI Georgia. 2013-11-07";



(: get the Document ID from a document :)
declare function tiAD:GetDocID($doc){normalize-space($doc//page[1]//text[matches(normalize-space(.),'^#\d+')])};


(: Functions implementing the steps taken by tiAD:WriteRawXML($doc,$questionNumber) :)

(: step 1 get the pages with the answers to   question   $PageQuestionString 
WE DO NOT USE PAGE NUMBERS, INSTEAD WE USE THE QUESTION, IT IS REPEATED ON EACH PAGE WHEN A QUESTION IS LONGER THAN ONE PAGE:)
declare function tiAD:GetOurPages($doc,$PageQuestionString){
$doc//page[.//text[tiAD:MatchColumnName(.,$PageQuestionString)]]};


(: step 2 Given a $page and question $PageQuestionString get all  lines with CSV information from that $page :)
declare function tiAD:GetLines($page,$PageQuestionString){
                        $page//text[not(b)]
                              [not(matches(.,'^www.declaration.gov.ge$'))]
                              [not(matches(.,'^[0-9# ]*$'))]
                              [preceding::text[tiAD:MatchColumnName(.,$PageQuestionString)]]
                              };
                              
(: step 3 get the line numbers corresponding to one row in the csv output 
    Idea: We only take line numbers with information in the first column.
          Lines with "empty first column"   contain information of a column which is printed on several lines 
    Implementation: Get the most right coordinate $C of the header of the first column.
                    Then check if there is information which starts BEFORE $C.
:)

declare function tiAD:csvlinenrs($page,$firstcolummheaderString,$PageQuestionString){
let $firstcolummheader := ($page//text[tiAD:MatchColumnName(.,$firstcolummheaderString)])[1]  (: Question specific :)
let $Xleft := xs:integer($firstcolummheader/@left)+ xs:integer($firstcolummheader/@width)  (: the right coordinate of the header of the first column :)
return
distinct-values(tiAD:GetLines($page,$PageQuestionString)[xs:integer(@left) lt $Xleft]/@top)  (: the line numbers we want :) 
              };        
              
  (: step 4  return all lines of text which together will form one line of CSV output :)             
declare function tiAD:CreateCSVrow($line,$pos,$page,$csvlinenrs,$PageQuestionString){
let $next := $csvlinenrs[$pos+1]
    return tiAD:GetLines($page,$PageQuestionString)
                         [xs:integer(@top) ge xs:integer($line)]
                         [xs:integer(@top) lt xs:integer($next) 
                            or $pos=count($csvlinenrs)]   (: for the last row :)
};
             
              
(: Step 5 : Create the Columns of a csvline  
Output is a list of strings with each string having all information in the cell of one csvline
:)

(: two important  helper functions for tiAD:CreateDataCells 

In both we use the fact that column headers are in a b-element.
If we do not use the b-element we get an error on question 1 where "First Name" occurs twice on the page.

:)
declare function tiAD:startCol($QuestionNumber,$Language, $ColumnNumber,$page){
    let $q := $tiAD:QI//q[@n=$QuestionNumber]
    let $column := if ($Language='geo') then $q//hg else $q//h
    let $headerText := $column[@n=$ColumnNumber]/s
    let $matchingtext := $page//text[./b[tiAD:MatchColumnName(.,$headerText)]]
    return
 xs:integer($matchingtext/@left)};
 
 declare function tiAD:endCol($QuestionNumber,$Language, $ColumnNumber,$page){
    let $q := $tiAD:QI//q[@n=$QuestionNumber]
    let $column := if ($Language='geo') then $q//hg else $q//h
    let $headerText := $column[@n=$ColumnNumber]/s
    let $matchingtext := $page//text[./b[tiAD:MatchColumnName(.,$headerText)]]
    return
 xs:integer($matchingtext/@left) + xs:integer($matchingtext/@width)};
 

declare function tiAD:CreateDataCells($questionNumber,$Language,$lines,$page){
let $q := $tiAD:QI//q[@n=$questionNumber]
let $NrofColumns := count($q//h)
let $ColumnNames := if ($Language='geo') then $q//hg else $q//h
for $n in $ColumnNames (: for each header create the data cell:)
return
(: the first column: end of tekst is before the start of the second column :)
if ($n/@n =1) then tiUtil:tostring($lines[xs:integer(@left)+xs:integer(@width) lt tiAD:startCol($questionNumber,$Language,xs:integer($n/@n)+1,$page)] )
else
(: the last column: start of tekst is before the end of preceding column :)
if ($n/@n=$NrofColumns) then tiUtil:tostring($lines[xs:integer(@left) gt tiAD:endCol($questionNumber,$Language,xs:integer($n/@n)-1,$page) ])
else
(: end of tekst is before the start of the following column AND start of tekst is before the end of preceding column :)
tiUtil:tostring($lines[xs:integer(@left) +xs:integer(@width) lt tiAD:startCol($questionNumber,$Language,xs:integer($n/@n)+1,$page)]
      [xs:integer(@left) gt tiAD:endCol($questionNumber,$Language,xs:integer($n/@n)-1,$page) ] )

 
};


(: Function which runs all steps and writes RAW XML of one document $doc for one specific query $questionNumber.
 The output is exactly the same as in the PDF plus the DocumentID attached as a last column (but then in XML)
 
 The output may stil be worked on. Eg, you might want to split "100 USD" into "100" "USD", etc.

That is specific for each question :)
 
declare function tiAD:WriteRawXML($doc,$questionNumber,$Language)
{

let $q := $tiAD:QI//q[@n=$questionNumber] 
    let $PageQuestionString := if ($Language='eng') then  $q//w/s
                                else 
                                if ($Language='geo') then   $q//wg/s
                                                     else 'ERROR: wrong language specification'
    let $firstcolummheaderString := if ($Language='eng') then  $q//h[@n=1]/s
                                    else 
                                    if ($Language='geo') then   $q//hg[@n=1]/s
                                                     else 'ERROR: wrong language specification'
                                                     
 

for $page in tiAD:GetOurPages($doc,$PageQuestionString)
    let $csvlinenrs := tiAD:csvlinenrs($page,$firstcolummheaderString,$PageQuestionString)
    return
    
        <table>
        {
        for $line at $pos in $csvlinenrs 
            let $csvrow := tiAD:CreateCSVrow($line,$pos,$page,$csvlinenrs,$PageQuestionString)   
            let $output :=    tiAD:CreateDataCells($questionNumber,$Language,$csvrow,$page) 
        return  
        
         <tr>
            {
            tiAD:WriteCSVrowasXML($output)
            }
          </tr>
        }
        </table>
    
};

(::::::::::::::::: HELPER FUNCTIONS :::::::::::::::::::::::::::)

(: get the table name, given a QuestionID :)
declare function tiAD:TableName($QuestionID){$tiAD:QI//q[@n=$QuestionID]/@t};

(: Test if $headerText  is a prefix of $string  :) 
declare function tiAD:MatchColumnName($string,$headerText){
let $s := normalize-space($string)
let $head := normalize-space($headerText)
return
 starts-with($s,$head)  };
 
 (: Only output a row for a $QuestionID if it is of the correct arity :)
declare function tiAD:WriteAritySaferow($output,$doc,$Outputformat,$QuestionID){
    let $arity := $tiAD:QI//q[@n=$QuestionID]/@a 
    return
    if (count($output)=$arity) then tiAD:Writerow($output,$doc,$Outputformat) else '' (: for $i in 1 to 8 return ' ':)  
};

declare function tiAD:Writerow($output,$doc,$Outputformat){
    let $output := for $i in $output return normalize-space(string($i))
    return
    if ($Outputformat='xml')
    then
        tiAD:WriteXMLrow($output,$doc)
    else
    if ($Outputformat='csv')
    then
        tiAD:WriteCSVrow($output,$doc)
    else
        tiUtil:WriteError(concat('Unrecognized output format: ',$Outputformat,'. You can only use "csv" or "xml".'))
        };

declare function tiAD:WriteCSVrowasXML($output){
    for $i in $output return <td>{normalize-space($i)}</td> };
    
(: write one CSV row :)
declare function tiAD:WriteCSVrow($output,$doc){
    concat('&#10;',  (: newline :)
          string-join(($output,tiAD:GetDocID($doc))  
                      ,
                     '&#09;')  (: tab :) 
           ) };
    
  (: write one CSV row  in XML table/tr/td format:)

declare function  tiAD:WriteXMLrow($output,$doc){
<tr>
{
(for $i in $output return <td>{$i}</td>,<td>{tiAD:GetDocID($doc)}</td>)
}
</tr>
};
           
           
         
        
        
 (: just write out the header of the csv or XML  file as comments :)    
 
declare function tiAD:WriteHeader($col,$QuestionID,$Language,$OutputFormat,$Outputfile){
let $header := 
concat('&#10;#File: ',$Outputfile,
'&#10;#',$tiAD:attribution,'&#10;',
'#',"Information mined from AssetDeclarations", '&#10;&#10;',
'# LANGUAGE: ', $Language,'&#10;',
'# QUESTION: ', string($tiAD:QI//q[@n=$QuestionID]//w),'&#10;',
'# TABLE NAME: ',string(tiAD:TableName($QuestionID)),'&#10;',
'# SCHEMA IN PDF: ', '&#10;#&#09;', string-join($tiAD:QI//q[@n=$QuestionID]//h,'&#10;#&#09;'),
'&#10;# SCHEMA HERE (eng): &#10; #',string-join(
(tokenize(normalize-space($tiAD:QI//q[@n=$QuestionID]//outschema),','),"DocumentId"),
'&#09;'),
'&#10;# SCHEMA HERE (geo): &#10; #',string-join(
(tokenize(normalize-space($tiAD:QI//q[@n=$QuestionID]//outschemag),','),"DocumentId"),
'&#09;'),
'&#10;'
)
return
if ($OutputFormat='xml')  then  comment { $header} 
else 
if ($OutputFormat='csv') then $header
else ''
};


