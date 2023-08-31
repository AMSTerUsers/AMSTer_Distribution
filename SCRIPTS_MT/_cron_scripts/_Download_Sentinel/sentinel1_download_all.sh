#!/bin/sh

# Log:
# 2017.05.23 - Now uses sentinel1_downloader_ingestiondate.sh v2.4.x
# 
# 2015.11.0: Added sleep command, or else esa.int will block downloads
# See: https://scihub.esa.int/news/News00040

# 2015.08.13 -> Only download --slc for all countries, but downlaod also --raw for Congo


# This script downloads the satelitte image files from ESA-Sentinel 1
# requires /opt/local/bin/xmlstarlet and curl (install with macports)
# and the main script: /Users/doris/scripts/sentinel1_downloader_ingestiondate.sh

# Always mount the SMB Disc via Applescript osascript, this avoids writing an empty 'DiscData' Folder to /Volumes/
#echo $mount_value

## RD of Congo
/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --congo --slc --startdate=30-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days
/bin/sleep 180

## Hawaii
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --hawaii --slc --startdate=10-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days
#/bin/sleep 420

## Luxembourg
/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --luxembourg --slc --startdate=10-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days
/bin/sleep 180

## Tristan
/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --tristan --slc --startdate=10-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days

## Domyuo
/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --domuyo18 --slc --startdate=10-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days
/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --domuyo83 --slc --startdate=10-DAYS-AGO --enddate=TODAY --skipmd5check --deletezip30days


## Belgium
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --belgium --slc
## Sleep for minimum 5 minutes before downloading next, we set it to 7 minutes
## See new API policy: https://scihub.esa.int/news/News00040
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -1 --raw
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -1 --grd

## Capvert
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --capvert --slc
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -2 --raw
#/bin/sleep 420
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -2 --grd
#/bin/sleep 420


###/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --congo --raw
###/bin/sleep 420
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -3 --grd
#/bin/sleep 420

## Cameroon
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --cameroon --slc
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -4 --raw
#/bin/sleep 420

## Luxembourg
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --luxembourg --slc
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -5 --raw
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -5 --grd
#/bin/sleep 420


## Tanzania
#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh --tanzania --slc
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -6 --raw
#/bin/sleep 420

#/Users/doris/scripts/sentinel1_downloader_ingestiondate.sh -6 --grd
