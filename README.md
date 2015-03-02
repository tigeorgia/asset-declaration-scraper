Asset Declaration Scrapper
==========================

This project is used to get the information available on [http://declaration.gov.ge](http://declaration.gov.ge), regarding Georgian public officials' asset declarations. Once the program (which consists in running a bunch of scripts) is done running, CSV files of both Georgian and English declarations are created. This is a 4-step process, please have a look at each of these steps below for more information.

Prerequisites
-------------

Before running any scripts, you need to configure the environment you're running the scripts from.

1) Open `./scripts/complete.sh` and update the following variables:

- `BRANCH` - choose the Github branch you want your project to be updated from.

2) Create a MySQL database, and indicate its inforamtion details into `./scripts/database.yml`. Once the declarations have been downloaded and converted into XML files, they will be imported into this MySQL database.

Save and close this file once you are done.

Running the scripts
-------------------

To run the entire process (all the 4 steps), run the following script, from the root of the project:

`./scripts/complete.sh`

If you want to run each steps individually. Please follow the following:

1) This first step update the project with the latest changes from the Github repository.
Once the update is done, this step will package the Java project into a JAR file, and copy it to the 'scripts' folder. This JAR file will be called later in xmltocsv.sh

`./scripts/checkoutAndPackageApp.sh <list of declaration ids>`


2) This step consists of grabbing all the declaration ids from [http://declaration.gov.ge](http://declaration.gov.ge). Once this is done, this list will be compared with another list, 'currentDeclarationsIds' which you'll find in the main folder. A diff will be made between the 2 lists, and the new declaration ids will be determined. They will define the newly uploaded declarations to download.

`./scripts/defineNewIds.sh`


3) This step downloads all the PDF files, matching the new list of ids, defined in the step above.

`./scripts/downloadpdf.sh`

4) This step converts PDF files, into XML files, using the version 0.16.7 of [Poppler's PDFTOHTML](http://www.linuxfromscratch.org/blfs/view/svn/general/poppler.html) tool.

`./scripts/toxml.sh <pdf folder> <xml folder>`

where:

- `<pdf folder>` is the full path where the PDF files that will be read are.
- `<xml folder>` is the full path where the generated XML files will be written in.


5) This step archive all the XML and PDF files in the 'archive' folder, along with the older declarations that were downloaded and processed before.

`./scripts/archive.sh`


6) This step runs a Ruby program, that will create several MySQL tables, and scrapes all the information available in the XML files, in order to inport them into a MySQL database.

`ruby ./scripts/export_assets-declarations.rb`


7) Based on the imported data in the MySQL database, this step will generate an SQL file, 'RepresentativeTableUpdate.sql', to be run on myparliament.ge database, in order to update each MP's profile.

`ruby ./scripts/create-sql-script.rb`

8) If 'RepresentativeTableUpdate.sql' has been created successfully, this last step will scp this file to myparliament.ge server, and remotely run it against the website's database.

`./scripts/sshToShenmartavServer.sh`


Other scripts
-------------

There are other scripts that have been written to respond to the need of various TIG staff members.

1) 'export_to_csv.rb' has been written to export all the information about several declarations, into CSV files. Before running this script, make sure you provide a list of "Position", among those you can find in the drop down list, in the search section of declaration.gov.ge, into 'scripts/input.csv' (rename the provided sample file)

`ruby ./scripts/export_to_csv.rb`


License
-------

Asset Declaration scraper is released under the terms of [GNU General Public License (V2)](http://www.gnu.org/licenses/gpl-2.0.html).
