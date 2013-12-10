let $doc := doc('AssetDeclarationsQuestionsInformation.xml')
let $DBname := name($doc//AssetDeclarations)
let $CreateDB := concat("&#10;CREATE DATABASE ",$DBname,';&#10;')
let $varcharlength := 200
let $VARCHAR := concat("VARCHAR(",$varcharlength,")")

(: Example

CREATE TABLE pet (name VARCHAR(20), owner VARCHAR(20), species VARCHAR(20), sex CHAR(1), birth DATE, death DATE)
    
    :)
return    

(: TODO
    1) language and equivalent attributes to each row
    2) correct datatype for "amounts"
    3) Create statements for loading the data from the csv files (see http://dev.mysql.com/doc/refman/5.0/en/loading-tables.html)
:)    

(
$CreateDB
,
for $question in $doc//q 
    let $createtable := concat("CREATE TABLE ",$question/@t," ")
    let $attributes := tokenize($question//outschema,',')
    let $att_decl := string-join(
                            for $a in $attributes return concat($a,
                                                                ' ',
                                                                if (matches($a,'date','i')) then "DATE" else $VARCHAR
                                                               )
                            ,
                            ', '
                            )
    return concat($createtable,
                  "(",
                  $att_decl,
                  ");&#10;"
                 )
)