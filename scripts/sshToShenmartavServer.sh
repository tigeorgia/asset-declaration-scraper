#!/bin/bash

pathToSql=/var/www/shenmartav/asset-declarations/scraper
host=****
user=****
pathToScriptsOnRemoteServer=/home/tigeorgia/shenmartav/sqlscripts

scp $pathToSql/RepresentativeTableUpdate.sql $user@$host:$pathToScriptsOnRemoteServer/RepresentativeTableUpdate.sql

ssh $user@$host 'bash -s' < $pathToSql/scripts/runSqlFile.sh
