#!/bin/sh
#
# This script downloads the satelitte image files from ESA-Sentinel 1
# for several pre-defined targets. These targets are defined in the 
# main script s1_downloader.sh
#
# Dependencies: 
# - /opt/local/bin/xmlstarlet and curl (install with macports)
# - the main script: /YourPath/S1-Copernicus/s1_downloader.sh
#
# This script was made for Mac computer. 
# It is provided as an example and must be tuned to your needs:
# - the path to s1_downloader.sh script on your computer
# - your targets (footprints/orbits) as defined in s1_downloader.sh
# - your options (which type of data, how far backward would you like to check data availability...) 
#
# Written by G. Celli for AMSTer software at ECGS

#############
## Domyuo
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --domuyoA18 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --domuyoD83 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60


## RD of Congo
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --congoA174 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --congoD21 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

## Hawaii
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh  --hawaiiA124 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh  --hawaiiD87 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

## Luxembourg
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --luxembourgA88 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --luxembourgD139 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

# PF
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFascSM --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFdescSM --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFascIW --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFdescIW --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60
