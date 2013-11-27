(: run this file on doc(' AssetDeclarationsQuestionsInformation.xml') :)


(: create table of questions 
<table border='1'>
<tr><th>Table Name</th><th>Question</th></tr>
{
for $q in //q[@n ne '0'] 
order by xs:integer($q/@n) 
return
    <tr><td>{string($q/@t)}</td><td>{$q//w//text()}</td></tr>
    }
    </table>
    
    :)
    
    
    (: create table of schema :)
   <table border='1'>
<tr><th>Table Name</th><th># Columns in PDF</th>
<th># Columns in our Spreadsheet</th><th>Description of Columns</th></tr>
{
for $q in //q[@n ne '0'] 
order by xs:integer($q/@n) 
return
    <tr>
    <td>{string($q/@t)}</td>
    <td>{count($q/h)}</td>
    <td>{string($q/@a + 1)}</td>
    <td>{$q//outschema//text(),',AssetDeclarationID'}</td></tr>
    }
    </table>
     