
(:  
 
 Compute the total income for an MP based on paid work and based on entrepeuneurial activities
  
  Contains a lot of not used code based on FamilyIncome.xquery

GEORGIAN VERSION
:)



declare namespace ti = "http://transparency.ge";
declare namespace xsd="http://www.w3.org/2001/XMLSchema";

(: import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "/home/etienne/asset-declaration-scraper/scripts/XQueryTextMinerScripts/XMLUtilities.xquery"; :)
import module namespace tiUtil= "http://transparency.ge/XML-Utilities" at "/mnt/drvScrapper/asset-declaration-scraper/scripts/XQueryTextMinerScripts/XMLUtilities.xquery";


declare option saxon:output "method=text";  (: output as text without xml header :)
declare option saxon:output    "omit-xml-declaration=yes";


declare variable $USD_GELexchange_rate  := number(1.65); (: see http://www.xe.com/currencycharts/?from=USD&to=GEL&view=5Y , we guessed the average in the period 2010-2013 :)
declare variable $language := "geo"; (: eng|geo :) 
declare variable $public_official := if ($language = 'eng') then 'Public Official' else 'საჯარო თანამდებობის პირის';
declare variable $ADbaseurl := "https://declaration.gov.ge/declaration?id=";
declare variable $ADbaseurlENG := "https://declaration.gov.ge/eng/declaration?id=";
(: declare variable  $English_Ent_Activity := doc('/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/en/ADentrepreneurial_activity_en.xml'); :)


declare variable $colpath external; (:  '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/ka' ;  :)
declare variable $colpath_english external;  (: '/Users/admin/Documents/TIGeorgia/DeclarationsScraper/Spreadsheets/xml/en' :)
declare variable $outputtype external;
declare variable $col := collection($colpath);
declare variable $eng_col := collection($colpath_english) ;
  
  
declare variable $SQLcreatetable := string("
-- Table: incomedeclaration_declarationtotalincome
 
--CREATE TABLE incomedeclaration_declarationtotalincome 
--(
--  id serial NOT NULL,
--  representative_id integer,
--  ad_id integer NOT NULL,
--  ad_submission_date date NOT NULL,
--  ad_entrepeuneurial_income integer,
--  ad_paid_work_income integer,
--  CONSTRAINT representative_total_income_pkey PRIMARY KEY (id),
--  CONSTRAINT representative_id_refs_person_ptr_id FOREIGN KEY (representative_id)
--      REFERENCES representative_representative (person_ptr_id) MATCH SIMPLE
--      ON UPDATE NO ACTION ON DELETE NO ACTION DEFERRABLE INITIALLY DEFERRED
--)
--WITH (
--  OIDS=FALSE
--);
--ALTER TABLE incomedeclaration_declarationtotalincome 
--  OWNER TO shenmartav;
 

DELETE FROM incomedeclaration_declarationtotalincome;
 
");


declare function ti:WriteAsSQLInsert($mprow){

(: Our goal 
INSERT INTO incomedeclaration_declarationtotalincome (representative_id,ad_id,ad_submission_date,ad_entrepreneurial_income,ad_paid_work_income)
 VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='აზერ სულეიმანოვი'),45799,TO_DATE('2013-05-13','YYYY-MM-DD'),0,53776.03);
:) 
 

 concat("&#10;INSERT INTO incomedeclaration_declarationtotalincome (representative_id,ad_id,ad_submission_date,ad_entrepreneurial_income,ad_paid_work_income) 
 VALUES ((SELECT person_id FROM popit_personname WHERE name_ka='",normalize-space($mprow[1]),"'),", replace($mprow[2],"#",''),",TO_DATE('",$mprow[3],"','YYYY-MM-DD')",",",$mprow[4],",",$mprow[5],");" 
 )
};



(: remove members which have exactly the same name from the family, we always only keep the oldest :)
declare function  ti:RemoveDoubles($members){ 
 let $fnlns := distinct-values( for $m in $members return <tr>{subsequence($m//td,1,2)}</tr>)
 return 
 if (count($fnlns)=count($members) )
 then $members
 else 
      for $name in $fnlns 
          let $eldest := (for $dob in $members[$name eq concat(td[1],td[2])]/td[4] order by $dob return $dob)[1]
          return ($members[td[4] eq $eldest])[1]  (: YES there are people who list themselves twice, so we remove them like this :)
};

declare function ti:EntrepeneurialIncome($row,$id,$col){


         let $row := tiUtil:GeorgianName2EnglishName($row/td[1],$row/td[2],$id,$col,$eng_col)  (: English version of the name :)
         
         (: this is a copy of the calculation for paid work, except the amount and dimension are in other fields :)
         let $incomedata:= $eng_col[.//@name='ADentrepreneurial_activity']//tr[td[last()] = $id]
            return sum((
                            for $gel in $incomedata[td[1]=$row/td[1] and td[2]=$row/td[2]  and td[8]= 'GEL'] //td[7]
                                return number($gel)
                            ,
                            for $usd in $incomedata[td[1]=$row/td[1] and td[2]=$row/td[2]  and td[8]= 'USD'] //td[7]
                                return number($usd) * $USD_GELexchange_rate 
                               
                            ))
};


declare function ti:PaidWorkIncome($row,$id,$col){
let $incomedata:= $col[.//@name='ADpaid_work']//tr[td[last()] = $id]
         
            let $inGEL := sum((
                            for $gel in $incomedata[td[1]=$row/td[1] and td[2]=$row/td[2]  and td[6]= 'GEL'] //td[5]
                                return number($gel)
                            ,
                            for $usd in $incomedata[td[1]=$row/td[1] and td[2]=$row/td[2]  and td[6]= 'USD'] //td[5]
                                return number($usd) * $USD_GELexchange_rate 
                               
                            ))
            return
             
             if ( $inGEL) then $inGEL else 0 
};
 
(: write output either as csv, or as sql insert statements :)
declare function ti:MPincome($outputtype){ 
 
let  $ADheader :=  $col[.//@name="ADheader"]//tr
    [contains(td[5],"საქართველოს პარლამენტი")] (: Just parliamnet [contains(td[5],"საქართველოს პარლამენტი")]  :)  
    [td[last()-1] ge '2012-10-01']  (: only from after 2012 election :)
    
return

 (if ($outputtype='csv') then () else $SQLcreatetable
 ,
    distinct-values(
    for $row   in $ADheader
        let $ADid := $row//td[last()]
        let $name := concat($row//td[1]," ",$row//td[2])
        let $date := $row//td[last()-1]
        let $out := ($name, $ADid,$date,string(ti:EntrepeneurialIncome($row,$ADid,$col)), string(ti:PaidWorkIncome($row,$ADid,$col)))
        where not( $ADheader[td[1] = $row/td[1] and td[2]=$row/td[2] and td[last()-1] gt $date])  (: so only take the last submitted AD :)
              and (: not(matches(normalize-space($name),'^$')) :) matches(normalize-space($name),' ') (: should contain at least a space :)
        order by $name
        return
        if ($outputtype='csv') then
        concat('&#10;',string-join($out, '&#09;'))
        else
        ti:WriteAsSQLInsert($out)  
    )    
)
        };
 
 
 
ti:MPincome($outputtype) 

  
