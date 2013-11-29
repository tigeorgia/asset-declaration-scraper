Asset Declaration Scrapper
==========================

This project is used to get the information available on [http://declaration.gov.ge](http://declaration.gov.ge), regarding Georgian public officials' asset declarations. Once the program (which consists in running a bunch of scripts) is done running, CSV files of both Georgian and English declarations are created. This is a 4-step process, please have a look at each of these steps below for more information.

Prerequisites
-------------

Before running any scripts, you need to configure the environment you're running the scripts from: either from 'dev' (usually you development machine/environment) or 'prod' (the server you plan to run your script periodically).

1) After cloning the project onto the chosen machine, open the configuration file:

`.scripts/config.properties` 

2) Update the <b>full path</b> in the environment of your choice (ie update either the 'scraper.ad.xqueryscripts.dev' or the 'scraper.ad.xqueryscripts.prod' property).
The full path should point to the folder where all the XQuery files sites, in the project (by default, they are in /scripts/XQueryTextMinerScripts).

3) Save and close `config.properties`.

4) Open `.scripts/complete.sh` and update the following variables:

- `ENVIRONMENT` - choose the environment you want your scripts to run from.
- `BRANCH` - choose the Github branch you want your project to be updated from.

Save and close this file once you are done.

Running the scripts
-------------------

To run the entire process (all the 4 steps), run the following script, from the root of the project:

`./scripts/complete.sh <list of declaration ids> (-noupdate)`

where `<list of declaration ids>` is a file that contains all the declaration ids crawled from a previous run. 

If you want to run each steps individually. Please follow the following:

1) This first step update the project with the latest changes from the Github repository. If you don't want the project to be updated from GitHub, add the optional parameter `(-noupdate)`.
Once the update is done, this step will package the Java project into a JAR file, and copy it to the 'scripts' folder.

2) This step consists of grabbing all the declaration ids from [http://declaration.gov.ge](http://declaration.gov.ge). Once this is done, this list will be compared with another list you must provide as an argument. A diff will be made between the 2 lists, and the new declaration ids will be determined. They will define the newly uploaded declarations to download.

`./scripts/defineNewIds.sh <list of declaration ids>`

where `<list of declaration ids>` is a file that contains all the declaration ids crawled from a previous run. 

3) This step downloads all the PDF files, matching the new list of ids, defined in the step above.

`./scripts/downloadpdf.sh`

4) This step converts PDF files, into XML files, using the version 0.16.7 of [Poppler's PDFTOHTML](http://www.linuxfromscratch.org/blfs/view/svn/general/poppler.html) tool.

`./scripts/toxml.sh <pdf folder> <xml folder>`

where:

- `<pdf folder>` is the full path where the PDF files that will be read are.
- `<xml folder>` is the full path where the generated XML files will be written in.

5) This step will run a Java program that uses the Saxon library, in order to convert XML files into CSV files, based on XQuery manipulation.

`./scripts/xmltocsv.sh <xml folder> <output folder> <environment> "main"`

where:

- `<xml folder>` is the full path where the XML files that will be read are.
- `<output folder>` is the full path where the generated CSV and XML files will be written in.
- `<environment>` can either be 'dev' or 'prod', and defines the environment your scripts are running on.

6) This step will run this Java program again, but this time it will create CSV and XML documents related to joined information between people's name and declaration ids.

`./scripts/createJoinTables.sh <xml folder> <output folder> <environment> "join"`

where:

- `<xml folder>` is the full path where the XML files that will be read are.
- `<output folder>` is the full path where the generated CSV and XML files will be written in.
- `<environment>` can either be 'dev' or 'prod', and defines the environment your scripts are running on.
