(: 
 Author: Maarten Marx for TI Georgia
 Date: 2013-11-06
 Purpose: text mine a specific part of the asset declartions
          :)

 

declare namespace ti = "http://transparency.ge";
declare variable $collectiondir := "/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Declarations/XML-sources";
declare variable $attribution := "Created by Maarten Marx for TI Georgia. 2013-11-07";

(: parameters to set for each question :)
declare variable $PageQuestionString := "Do you or your family members own real estate?"; (: See step 1 :)
declare variable $firstcolummheaderString := "Name of the owner of the";   (: See step 3 :)

declare variable $outputformat := ("First Name","Last Name","Percentage","Type of Property","Location of Property","Total Area","Owners");

declare function local:tostring($list){string-join( for $t in $list return normalize-space($t),' ')};

declare variable $docname external; 
let $doc := doc($docname)
 
(:step 0 get the ID of the document :)
let $DocID := $doc//page[1]//text[matches(normalize-space(.),'^#\d+')]

(: step 1 get the page   DO NOT USE PAGE NUMBERS, INSTEAD USE THE QUESTION, IT IS REPEATED ON EACH PAGE WHEN A QUESTION IS LONGER THAN ONE PAGE:)
let $ourpages :=   
   $doc//page[.//text[matches(normalize-space(.),normalize-space($PageQuestionString))]]
   
(: loop over all pages  
This is usually not needed but it is for instance on file 48303
:)    
for $page in $ourpages

(: step 2 get the lines with information :)
let $lines := $page
                       (: now get the text lines we want :)
                        //text[not(b)]
                              [not(matches(.,'^www.declaration.gov.ge$'))]
                              [not(matches(.,'^[0-9# ]*$'))]

(: step 3 get the line numbers corresponding to one row in the csv output 
    Idea: We only take line numbers with information in the first column.
          Lines with "empty first column"   contain information of a column which is printed on several lines 
    Implementation: Get the most right coordinate $C of the header of the first column.
                    Then check if there is information which starts BEFORE $C.
:)

let $firstcolummheader := $page//text[matches(normalize-space(.),normalize-space($firstcolummheaderString))]  (: Question specific :)
let $Xleft := xs:integer($firstcolummheader/@left)+ xs:integer($firstcolummheader/@width)  (: the right coordinate of the header of the first column :)
let $csvlinenrs := distinct-values($lines[xs:integer(@left) lt $Xleft]/@top)  (: the line numbers we want :) 


(: SPECIFIC :)
(: step 4 Get coordinates of the columns 
   ONLY needed if this questionhas columns whose values are over several lines of output
   
   :)
 let $SecondColEnd := xs:integer($page//text[matches(normalize-space(.),'Type of property')]/@left)  + xs:integer($page//text[matches(normalize-space(.),'Type of property')]/@width) 

let $ThirdColEndString := "^Location of the property"
let $ThirdColEnd := xs:integer($page//text[matches(normalize-space(.),$ThirdColEndString)]/@left)  + xs:integer($page//text[matches(normalize-space(.),$ThirdColEndString)]/@width)

let $FourthColStart := xs:integer($page//text[matches(normalize-space(.),'^If the property is in ')]/@left) 
(: END SPECIFIC :)

(: step 5 create one line of csv output :)
for $line at $pos in $csvlinenrs
    let $next := $csvlinenrs[$pos+1]
    let $csvrow := $lines[xs:integer(@top) ge xs:integer($line)]
                         [xs:integer(@top) lt xs:integer($next) 
                            or $pos=count($csvlinenrs)]   (: for the last row :)


(: SPECIFIC :)

(: now get all fields for our rows :)  
(: first name, last name , percentage:)
    let $fnlnline := tokenize($csvrow[1],' +')  
    let $fnln := subsequence($fnlnline,1,2)
    let $percentage:= if ($fnlnline[3]) then $fnlnline[3] else ' '
    
    let $csvrow := $csvrow except $csvrow[1]  (: we remove what we have mined from the $csvrow :)
    
(: type :)

    let $type := $csvrow[1]
    let $csvrow := $csvrow except $type
    
(: The property description :)
 let $prop := $csvrow[xs:integer(@left) gt $SecondColEnd]
                        [xs:integer(@left)+xs:integer(@width)  lt $FourthColStart]
 let $niceprop := string-join( for $t in $prop return normalize-space($t),' ')
 let $propdescription := if (contains($niceprop,'Area -')) then substring-before($niceprop,'Area -') else $niceprop
 let $area := if (contains($niceprop,'Area -')) then substring-after($niceprop,'Area -') else ' '
 let $csvrow := $csvrow except $prop
    
 (: the last question :)
 
 let $poss := $csvrow[xs:integer(@left) gt $ThirdColEnd]
 let $niceposs := local:tostring($poss)
 
(: specify output order :)  
let $output := ($fnln,$percentage,$type,$propdescription,$area,$niceposs)  


(: END SPECIFIC :)


return
    (count($ourpages),concat('&#10;',  (: newline :)
          string-join(for $i in ($output,$DocID)  return normalize-space($i)
                      ,
                     '&#09;')  (: tab :) 
                     )
  )
