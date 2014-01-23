#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts

# Exports the MP incomes into an SQL file
$SCRIPTS_FOLDER/MPincome.sh

# Establish a connection with the remote server, where shenmartav is deployed, then runs the SQL file on it.
$SCRIPTS_FOLDER/sshToShenmartavServer.sh

