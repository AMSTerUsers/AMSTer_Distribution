#!/bin/sh

# Log: V20231213


#############
## Domyuo
# Ascending
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --domuyoA18 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

# Descending
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --domuyoD83 --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60


# PF
# Ascending SM
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFascSM --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

# Descending SM
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFdescSM --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

# Ascending IW
/Users/doris/scripts/sentinel1_emergency_downloader.sh --PFascIW --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

# Descending IW
/Users/doris/scripts/S1-Copernicus/s1_downloader.sh --PFdescIW --slc --startdate=15-DAYS-AGO --enddate=TODAY
/bin/sleep 60

