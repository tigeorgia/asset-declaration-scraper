#!/bin/bash

export PGPASSWORD=shenmartav
psql -U shenmartav shenmartav -f /home/tigeorgia/shenmartav/sqlscripts/MPincome.sh
