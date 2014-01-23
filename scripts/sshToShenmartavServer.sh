#!/bin/bash

pathToScripts=$PWD/scripts
uost=178.77.73.48
user=tigeorgia
pathToScriptsOnRemoteServer=/home/tigeorgia/shenmartav/sqlscripts

scp $pathToScripts/MPincome.sql $user@$host:$pathToScriptsOnRemoteServer/MPincome.sql

ssh tigeorgia@178.77.73.48 'bash -s' < $pathToScripts/runSqlFile.sh
