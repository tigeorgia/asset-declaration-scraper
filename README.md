Asset Declaration Scrapper
==========================

This project is used to get the information available on [http://declaration.gov.ge](http://declaration.gov.ge), regarding Georgian public officials' asset declarations. Once the program (which consists in running a bunch of scripts) is done running, CSV files of both Georgian and English declarations are created. This is a 4-step process, please have a look at each of these steps below for more information.

Prerequisites
-------------

Before running any scripts, you need to configure the environment you're running the scripts from: either from 'dev' (usually you development machine/environment) or 'prod' (the server you plan to run your script periodically).

1) After cloning the project onto the chosen machine, open the configuration file:

`.scripts/config.properties` 

2) Update the <b>full</b> paths of the following files and folder:

- FunctionsForEachCSVFile.xquery
- AssetDeclarationsQuestionsInformation.xml
- the 'xmloutput' folder

Update the values to the properties tied to the environment you're aiming (ie update either the '.dev' or the '.prod' properties)

3) Save and close `config.properties`.

4) Open `.scripts/complete.sh` and update the variable `ENVIRONMENT`. Save and close this file then.

Running the scripts
-------------------

To run the entire process (all the 4 steps), run the following script, from the root of the project:

`./scripts/complete.sh <list of declaration ids>`

where `<list of declaration ids>` is a file that contains all the declaration ids crawled from a previous run. 

If you want to run each steps individually. Please follow the following:

1) The first step consists of grabbing all the declaration ids from [http://declaration.gov.ge](http://declaration.gov.ge). Once this is done, this list will be compared with another list you must provide as an argument. A diff will be made between the 2 lists, and the new declaration ids will be determined. They will define the newly uploaded declarations to download.

`./scripts/defineNewIds.sh <list of declaration ids>`

where `<list of declaration ids>` is a file that contains all the declaration ids crawled from a previous run. 

2) This step downloads all the PDF files, matching the new list of ids, defined in the step above.

`./scripts/downloadpdf.sh`

3) This third step converts PDF files, into XML files, using the version 0.16.7 of [Poppler's PDFTOHTML](http://www.linuxfromscratch.org/blfs/view/svn/general/poppler.html) tool.

`./scripts/toxml.sh <pdf folder> <xml folder>`

where:

- `<pdf folder>` is the full path where the PDF files that will be read are.
- `<xml folder>` is the full path where the generated XML files will be written in.

4) This last step will run a Java program that uses the Saxon library, in order to convert XML files into CSV files, based on XQuery manipulation.

`./scripts/xmltocsv.sh <xml folder> <csv folder>`

where:

- `<xml folder>` is the full path where the XML files that will be read are.
- `<csv folder>` is the full path where the generated CSV files will be written in.
 
