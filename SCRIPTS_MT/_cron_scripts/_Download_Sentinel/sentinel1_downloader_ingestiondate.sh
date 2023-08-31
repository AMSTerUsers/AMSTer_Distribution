#!/bin/bash

# Set DEBUG mode with command: set -xv
#set -xv

# Define default options and variables
VERSION="2.9.5"

# ------------------------------------------------------------
# Script to download ESA's Sentinel1 data from ESA-Site Scihub
# See latest news here: https://scihub.copernicus.eu/news/

# Based on script 'odata-demo.sh' from Scihub Site:
# See odata-demo.sh from scihub.copernicus.eu Site:
# List first 10 products since last <n> days, by product type and intersecting an AOI
# https://scihub.copernicus.eu/twiki/pub/SciHubUserGuide/5APIsAndBatchScripting/odata-demo.sh
# https://scihub.copernicus.eu/twiki/do/view/SciHubUserGuide/5APIsAndBatchScripting
#
# See ESA's 'APIs and Batch scripting' webpage:
# https://scihub.copernicus.eu/userguide/5APIsAndBatchScripting
# ------------------------------------------------------------

# ------------------------------------------------------------
# Changelog:
# ------------------------------------------------------------
# 2019.10.10 - Version 2.9.5
#
# Added new Country "Domuyo" - Ascending 18 
# Added new Country "Domuyo" - Descending 83 

# 2019.09.17 - Version 2.9.4
# Fix remoteFileSize bug: some changes on ESA-Site, the content of  the info seems lowercase
# - So filtering for "Content-Length" didn't work, lowercase "content-length" fixes it.
# Other fixes: don't display Content of Zip-File (only for DEBUG)


# 2019.08.13 - Version 2.9.3
# New: Now detects if remote file has 0 bytes: this avoids downloading infinetely Zip-files.
# 0 bytes files occured mainly with TRISTAN files.

# 2019.08.13 - Version 2.9.2
# Workaround: If "7z" is unsuccesful to unzip the file, we skip it and continue.

# 2019.07.16 - Version 2.9.1
# Fix: Added correct 'sensormode: SM' to 'query' for Tristan de Cuna
# Added sensormode: IW for Congo, Lux, Tanzania etc. 
# New: Added platformname to "Sentinel-1" for 'query'

# 2019.06.25 - Version 2.9.0
# New: Added Tristan de Cuna, -9 Tristan
# Tristan default ptype="(SLC AND sensoroperationalmode:SM)"


# 2019.02.26 - Version 2.8.2
# Change: If the Product-file was not properly downloaded, we just delete it and Redownload
# it again
#
# 2017.12.19 - Version 2.8.1
# New: Print the summary (zip-downloads, unzipped files) before the detailed log.

# 2017.12.12 - Version 2.8.0
# New: For summary download: Print sizes of remote & local files
# 		by adding remoteZipSizeArray & localZipSizeArray

# 2017.11.20 - Version 2.7.4
# Change: Renamed WORKING_DIR to ZIP_DOWNLOAD_DIR
# Other text changes for Log File

# 2017.11.17 - Version 2.7.3
# New: Added unzipArray to summarize the files unzipped at the end of the script
# Fix: The summary of download zip files was always empty, now printig everything
#		in the function download_quicklook_and_full_file_list

# 2017.11.16 - Version 2.7.2
# New:	print a summary of downloaded Zip files.
# 		Added downloadArray to print the result at the end of the script.

# 2017.11.16 - Version 2.7.1
# New: Option to force download Zip-File

# 2017.11.15 - Version 2.7.0fc1
# New: Option --deletezip30days : deletes the zip file if older than 30 days
# but only if UnZip-Dir is available (and contents bigger than Zip-File size)-
# New: Checks remote size of Zip-File to better detect if local Zip-File was correctly
#      downloaded.
# New: If the UnZip-Directory size is less than the remote Zip-File's size we redownload 
#      and decompress the file again.

# 2017.10.25 - Version 2.6.3
# New: If site is in maintenance mode the email contains the maintenance mode message
# Various bug fixes (nb_items was not set to 0 when an error occured)

# 2017.10.23 - Version 2.6.2
# - Added variable: MAINTENANCE_MODE.
#	This allows to send an email with Header: Sentinel1 Maintenance Mode detecteced
# - Removed variable: esaSiteDown

# 2017.10.10 - Version 2.6.1b1
# - New: Cancel download when Zip-File contains "doctype html" then the Site is in Maintenance mode
# 	This will (hopefully) avoid the curl error:
# 	curl: (3) Illegal characters found in URL

# 2017.10.06 - Version 2.6.0 (=2.6.0b4)
# Added command used in log file with "echo $0 $@"
# Added SCRIPT_EXEC_STARTDATE for Start and End of script date
# Renamed:
# ING_START_DATE to INGEST_START_DATE
# ING_END_DATE to INGEST_END_DATE
# Other small changes for info text

# 2017.10.04 - Version 2.6.0b3
# curl: (3) Illegal characters found in URL
# Looking at the log file this error was written:
# curl: (23) Failed writing body (0 != 14601)
# Updated curl from 7.55 to 7.56
#
# - Using Macports coreutils 'tee' command instead of macOS System /usr/bin/tee 
# macports coreutils installs in /opt/local/libexec/gnubin/tee 

# 2017.08.04 - Version 2.5.6
# Fix: Fixed a infinite loop bug in md5 check in version 2.5.5:
# ${prodid} and ${value} had braces is not understood by the request command
# you need to leave it as: $prodid and not as ${prodid}
# This bug occured for MD5_URL check and PRODUCT_NAME_URL
# MD5_URL="${ROOT_URL_ODATA}/Products('$prodid')/Checksum/Value/\$value"  # CORRECT
# MD5_URL="${ROOT_URL_ODATA}/Products('${prodid}')/Checksum/Value/\$value"  #ERROR: don't put braces for $prodid
#
# PRODUCT_NAME_URL="${ROOT_URL_ODATA}/Products('$prodid')/Name/\$value"  #CORRECT	
# PRODUCT_NAME_URL="${ROOT_URL_ODATA}/Products('${prodid}')/Name/\${value}"  #ERROR: don't put braces for $prodid and $value

# 2017.08.03 - Version 2.5.5
# -Change: curl verbose to silent download for quicklook file
# -Change: global variable i to local variable i in functions
# -Other small fixes

# 2017.08.02 - Version 2.5.4
# -Change: Removed ping test after all
# -New: Write out if list is empty at end of script
# -New: Write out script name with its version number at end of script

# 2017.08.02 - Version 2.5.3
# -Change: If ping testing was not successful it still continues, since the IP-Address is constantly changed
#          so sometimes the site is not pingable.
# -Change: Corrected link of Scihub News at: https://scihub.copernicus.eu/news/
# -Other bugfixes and enhancements

# 2017.08.01 - Version 2.5.2
# - New: Added ping test, sends email if scihub.copernic.eu site is down.
# - New: If "Empty Query Result. No Downloads are available." (but site is up):
#   send query XML file by email, so user can verify if the scihub.copernic.eu site
#   is in maintenance mode, or not.
# - Other bugfixes and enhancements

# 2017.07.26 - Version 2.5.1
# - SMB Volumes are no more mounted with mount command:
#	Using macOS "automount" feature to automatically mount SMB Volumes
#   in /Users/doris/NAS-Discs instead of mounting them to /Volumes/SMB_SHARENAME
#   See also: https://useyourloaf.com/blog/using-the-mac-os-x-automounter/
#  
# - Redownload / md5 cheksum loop fix: When zipped file was not correctly downloaded it would infinitely loop
#   to redownload / (re)check md5 file. Fixed (PRODUCT_FILE_URL was missing)...
# - Suppressed verbose for curl (too many text when downloading)
# - Create "logs" directory in $HOME/scripts if not present
# - Renamed var "lastdays" to "maxRows" (wich is the correct name of variable)
# - Other bugfixes and enhancements

# 2017.05.30 - Version 2.5.0:
# - This version checks the status of md5, curl and 7zip:
#   If status of any of these gives an error (status different from 0),
#   then we loop until we have correctly downloaded the zip file.
# - Other bug fixes

# 2017.05.29 Version 2.4.5:
# Added function: verify_md5_checksums

# 2017.05.29 Version 2.4.4:
# Renamed 7ZIP_PREFIX to UNZIP_PREFIX (since beginning of name has a number, which gives an error)
#
# 2017.05.26 Version 2.4.3:
# - First checks if file is already present and if yes
#   then verfifies the MD5 checksums and unzips them to UNZIP directory
# - Using 7zip for unzipping file instead of unzip

# 2017.05.26 Version 2.4.2:
# INGEST_END_DATE for Today was not calculated, fixed!
#
# ------------------------------------------------------------
# 2017.05.23 Version 2.4.1:
#
# Added UNZIP directory: $UNZIP_DIR (is the ${ZIP_DOWNLOAD_DIR} with .UNZIP at the end)
# - Unzips the downloaded zip file to directory $UNZIP_DIR
# ------------------------------------------------------------
# 2017.05.22 Version 2.4.0:
# You can now specifiy any "DAYS-AGO" / "WEEKS-AGO" or "MONTHS-AGO"
# for Ingestion Start Date
# e.g --startdate=7-DAYS-AGO
# e.g --startdate=100-DAYS-AGO
# e.g --startdate=5-WEEKS-AGO
# e.g --startdate=6-MONTHS-AGO

# 2017.05.18 Version 2.3.2:
# New - Added YESTERDAY to startdate
# --startdate=YESTERDAY --enddate=TODAY 
# For now, to calculate YESTERDAY we need GNU's coreutils to be installed.
# Soon fix by using macOS date command

# 2017.05.18 Version 2.3.1:
# You can download files using its ingestion date, like startdate and enddate:
# e.g.
# --startdate=2017-05-10 --enddate=2016-05-18
# --startdate=2017-05-10 --enddate=TODAY (will calculate 'today' to YYYY-MM-DD)
# --startdate=YESTERDAY --enddate=TODAY
# New: Now checks md5 values to see if file was properly downloaded, as suggested by scihub site.
# Other bug fixes and enhancements

# 2017.04.27 Version 2.2.2:
# - After switching to new directory scheme the LOG dir was missing and the tmp-result dir too
# - Added mkdir for the LOG_PATH, the missing log dir cancelled the downloads
# - mkdir -p ${LOG_PATH}
#
# - Renamed working dir: SENTINEL1-DATA-<COUNTRY_NAME>.... to S1-DATA-<COUNTRY_NAME>

# 2015.12.18 Version 2.2.1:
#
# Fixed a bug where the query-server's result-list only displayed and downloaded the last 10 days,
# instead of the $maxRows as a parameter.
# This works by adding: &rows=$maxRows&start=0
# So the correct command is: query_server "${ROOT_URL_SEARCH}?q=${query// /+}&rows=$maxRows&start=0"
# See also: # https://scihub.copernicus.eu/twiki/do/view/SciHubUserGuide/5APIsAndBatchScripting#Open_Search

# 2015.12.17 Version 2.2.0:
#	Changed Download Adress from:
#	Old > DHUS_SERVER_URL="https://scihub.esa.int/dhus"
#	New > DHUS_SERVER_URL="https://scihub.copernicus.eu/dhus"

# 2015.11.13 Version 2.1.1:
#	Cosmetic changes in Product File Download
#
# 2015.11.12 Version 2.1.0:
# 	curl > Removed -L --location and -C (continue option)
#	Now deletes the broken Product File before redownloading
#
# ------------------------------------------------------------

# Default values
# INGESTION Start and End Date
INGEST_START_DATE="TODAY"
INGEST_END_DATE="TODAY"

FULLHOSTNAME=$(/bin/hostname)
HOSTNAME=$(/bin/hostname -s)
LOG_DATE=$(/bin/date +"%Y%m%d%H%M")
SCRIPT_EXEC_STARTDATE=$(/bin/date +"%A, %d %B %Y @ %H:%M")

# Set the email recipients, separate with comma for multiple recipients
#EMAIL_RECIPIENTS="gilles@ecgs.lu"
EMAIL_RECIPIENTS="infodownload@ecgs.lu,ndo@ecgs.lu"
EMAIL_SUBJECT="[${HOSTNAME}] Sentinel1 Downloads for "

# Maximum days / rows = 100
## "The maximum number of rows to be returned in a single query is set to 100."
## "Requests for more than the maximum supported number of rows will result in an error ( http 500 )."
##  See here: https://scihub.copernicus.eu/userguide/5APIsAndBatchScripting
maxRows=100

# new since 2.5.1b1 - use automount feature of Mac OS X to mount smb network discs
SMB_SHARE_NAME="hp-D3600-Data_Share1" # do not use a slash at beginning and end
SMB_SHARE_MOUNTED_ON_LOCAL_DIR="${HOME}/NAS-Discs/$SMB_SHARE_NAME"
S1_WORKDIR="${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}/SAR_DATA/S1"
echo "Working Dir: S1_WORKDIR= ${S1_WORKDIR}"

##########################################################################################

#SMB_NETWORK_DISC="hp-storeeasy...."
#SMB_USER=" "
#SMB_PASS=" "
#SMB_SHARE_NAME=" " # do not use a slash at beginning and end

### Mounted SMB Share on Mac OS X, usually in /Volumes/
### /Volumes/hp-D3600-Data_Share1/SAR_DATA/S1/

#SMB_SHARE_MOUNTED_ON_LOCAL_DIR="/Volumes/$SMB_SHARE_NAME"

#S1_WORKDIR="${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}/SAR_DATA/S1/"

#SMB_MOUNT_POINT="smb://$SMB_USER:$SMB_PASS@$SMB_NETWORK_DISC/$SMB_SHARE_NAME"
#NEW_SMB_MOUNT_POINT="//$SMB_USER:$SMB_PASS@$SMB_NETWORK_DISC/$SMB_SHARE_NAME"

## 2. Create the mount dir in /Volumes if it doesn't exist (-p option)
#if [ ! -e ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR} ]; then
#    /bin/mkdir -p ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}
#fi


## 3. Finally mount the Network Disc
# /sbin/mount -t smbfs $NEW_SMB_MOUNT_POINT ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}

## Check if local mount point has been correctly mounted with 'mount' command
## Avoid to write to a folder with the same name of LOCAL_MOUNT_POINT
## We want to be sure that SMB_SHARE_MOUNTED_ON_LOCAL_DIR is a mounted volume, and not an "Mac OS X" folder
#if mount | ${PATHGNU}/grep "on ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}" > /dev/null; then
##########################################################################################

# Create the local log directory (if not present) to save the log-file locally if Network Disc can't be mounted
if [ ! -e "${HOME}/scripts/logs/" ]
	then
	/bin/mkdir -p $HOME/scripts/logs/
	/bin/mkdir -p $HOME/scripts/logs/sentinel1_disc-mount_error_logs/
fi

# Check if directory exists 
if [ -e "${S1_WORKDIR}" ]; then
	echo "${SMB_SHARE_MOUNTED_ON_LOCAL_DIR} mounted, continuing ..."
else
	ERROR_LOG="$HOME/scripts/logs/sentinel1_disc-mount_error_logs/disc-mount_error-$LOG_DATE.log"
	EMAIL_SUBJECT="[${HOSTNAME}] ALERT! Network Disc Mount error ! No Sentinel1 Downloads"
	
	echo "ALERT! This is script: $0 running on $FULLHOSTNAME" > $ERROR_LOG
	echo "Error: ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR} not mounted! Check the network disc with share-name: $SMB_SHARE_NAME !" >> $ERROR_LOG
	echo " There was an error mounting this disc." >> $ERROR_LOG

    # send an email using /usr/bin/mail
	/usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < $ERROR_LOG
    exit 1;
fi

# ESA-Site login details
DHUS_SERVER_URL="https://scihub.copernicus.eu/dhus"
DHUS_USER=""
DHUS_PASSWD=""

# Setting default variables
ptype="SLC"
COUNTRY="CONGO"
platformname="platformname:Sentinel-1"

# Default Sensor Mode = IW for Congo, Lux, Tanz - for Tristan: SM
#sensormode="(sensoroperationalmode:IW)"
	
VERBOSE=false
QUERY_RESULT_LIST=""
SKIPMD5CHECK=false
MAINTENANCE_MODE=false
DELETE_ZIPFILE_30DAYS=false
FORCE_DOWNLOAD=false

# Set variables depending to optional command line arguments
ROOT_URL_ODATA="${DHUS_SERVER_URL}/odata/v1"
ROOT_URL_SEARCH="${DHUS_SERVER_URL}/search"

# Third-party application, provide the correct path for curl, md5 and xmlstarlet
#CURL_PREFIX="/opt/local/bin/curl --limit-rate 3500K --max-time 7200 --silent --show-error -gu ${DHUS_USER}:${DHUS_PASSWD}"
CURL_PREFIX="/opt/local/bin/curl --limit-rate 6000K --max-time 14400 --silent --show-error -gu ${DHUS_USER}:${DHUS_PASSWD}"

#CURL_PREFIX="/opt/local/bin/curl --verbose --show-error -gu ${DHUS_USER}:${DHUS_PASSWD}"

XMLSTARLET_PREFIX="/opt/local/bin/xmlstarlet"
MD5_PREFIX="/sbin/md5 -q"
DU_PREFIX="/opt/local/libexec/gnubin/du -sb"
TEE_PREFIX="/opt/local/libexec/gnubin/tee"

# For unzipping, we're using 7zip with options:
# -aos: Skip extracting of existing files
# x: for extracting files with its directory content
UNZIP_PREFIX="/opt/local/bin/7z -aos x"

# Check if command 'curl' or 'xmlstarlet' is installed
if ! $(type ${CURL_PREFIX} &> /dev/null)
    then echo "Command \"${CURL_PREFIX}\" is missing, please install it or change the path in this script first.";
    exit 1
fi

if ! $(type $XMLSTARLET_PREFIX &> /dev/null)
    then echo "Command \"$XMLSTARLET_PREFIX\" is missing, please install it or change the path in this script first!";
    exit 1
fi

if ! $(type $MD5_PREFIX &> /dev/null)
    then echo "Command \"$MD5_PREFIX\" is missing, please install it or change the path in this script first!";
    exit 1
fi

if ! $(type $UNZIP_PREFIX &> /dev/null)
     then echo "Command \"$UNZIP_PREFIX\" is missing, please install it or change the path in this script first!";
    exit 1
fi

if ! $(type $DU_PREFIX &> /dev/null)
     then echo "Command \"$DU_PREFIX\" is missing, please install it or change the path in this script first!";
    exit 1
fi

if ! $(type $TEE_PREFIX &> /dev/null)
     then echo "Command \"$TEE_PREFIX\" is missing, please install it or change the path in this script first!";
    exit 1
fi

# Display help
function show_help
{
    echo "USAGE: sentinel1_downloader_ingestiondate.sh [OPTION_1] [OPTION_2] [OPTION_3] ... "
    echo "This script downloads Sentinel1 data of a given country using the ESA's OData interface of the Data Hub Service (DHuS)."
    echo " -h, --help       display this help message"
    echo ""
    echo "Choose Country, only one can be selected:"
    echo ""
    echo "      -1, --belgium    download Sentinel1 data of Belgium"
    echo "      -2, --capvert    download Sentinel1 data of Capvert" 
    echo "      -3, --congo      download Sentinel1 data of Congo"
    echo "      -4, --cameroon   download Sentinel1 data of Cameroon"
    echo "      -5, --luxembourg download Sentinel1 data of Luxembourg"
    echo "      -6, --tanzania   download Sentinel1 data of Tanzania"
    echo "      -7, --erta_ale   download Sentinel1 data of Ethiopia (Erta Ale)"
    echo "      -8, --hawaii     download Sentinel1 data of Hawaii"
    echo "      -9, --tristan    download Sentinel1 data of Tristan de Cuna"
    echo "		-10, --domuyo18	 download Sentinel1 data of Domuyo - ASCENDING 18"
    echo "		-11, --domuyo83	 download Sentinel1 data of Domuyo - DESCENDING 83"
    echo ""
    echo "Set product type:"
    echo "      -g, --grd        set product type to GRD"
    echo "      -o, --ocn        set product type to OCN"
    echo "      -r, --raw        set ptype to RAW"
    echo "      -s, --slc        set ptype to SLC"
    echo ""
    echo "Set ingestion start date:"
    echo "      --startdate=YYYY-MM-DD"
    echo "      or"
    echo "      --startdate=TODAY"
    echo "      --startdate=YESTERDAY"
    echo "      --startdate=xx-DAYS-AGO"
    echo "      --startdate=xx-WEEK-AGO"
    echo "      --startdate=xx-MONTH-AGO"
    echo ""
    echo "Set ingestion end date:"
    echo "      --enddate=YYYY-MM-DD"
    echo "      or"
    echo "      --enddate=TODAY"  
    echo ""
    echo "Skip md5 checksum:"
    echo "      --skipmd5check"
    echo ""
    echo "Delete Zip-File older than 30 days:"
    echo "      --deletezip30days"
    echo ""
    echo "Force download Zip-File.Caution: use only if you really want to (re)download the Zip-File(s)."
    echo "		This will not delete Zip-File older than 30 days"
    echo "		--force"
    echo ""
    echo " -v, --verbose    display curl command lines and results"
    echo " -V, --version    display the current version of the script"
    echo ""
}

# Parse command line arguments
for arg in "$@"
do
   case "$arg" in
    -h  | --help)       show_help;
                        exit 0
                        ;;
    
    -1  | --belgium)    COUNTRY="BELGIUM"  
                        polygon="POLYGON((2.2759179687511 49.39733675067,6.5825585937511 49.39733675067,6.5825585937511 51.523048670724,2.2759179687511 51.523048670724,2.2759179687511 49.39733675067))"
                        sensormode="(sensoroperationalmode:IW)"
                        ;;
                        
    -2  | --capvert)    COUNTRY="CAPVERT"
                        polygon="POLYGON((-24.805380859375 14.770554001959,-24.212119140625 14.770554001959,-24.212119140625 15.083713334744,-24.805380859375 15.083713334744,-24.805380859375 14.770554001959))"
                        sensormode="(sensoroperationalmode:IW)"
                        ;;
    
    -3  | --congo)      COUNTRY="DRCONGO"
                        polygon="POLYGON((28.63761230469 -3.7042857753737,29.725258789065 -3.7042857753737,29.725258789065 -0.54279843346273,28.63761230469 -0.54279843346273,28.63761230469 -3.7042857753737))"
                        sensormode="(sensoroperationalmode:IW)"
						;;
    
    -4  | --cameroon)   COUNTRY="CAMEROON"
                        polygon="POLYGON((8.9940576171883 3.9091132063575,9.460976562501 3.9091132063575,9.460976562501 4.4788700707381,8.9940576171883 4.4788700707381,8.9940576171883 3.9091132063575))"
                        sensormode="(sensoroperationalmode:IW)"
                        ;;

    -5  | --luxembourg) COUNTRY="LUXEMBOURG"
                        polygon="POLYGON((5.4674462890619 48.418939253948,8.2579736328119 48.418939253948,8.2579736328119 50.307533561486,5.4674462890619 50.307533561486,5.4674462890619 48.418939253948))"
                        sensormode="(sensoroperationalmode:IW)"
                        ;;
    
    -6  | --tanzania)   COUNTRY="TANZANIA"
                        polygon="POLYGON((35.674355468752 -3.1120759839556,36.959755859378 -3.1120759839556,36.959755859378 -1.3337017191793,35.674355468752 -1.3337017191793,35.674355468752 -3.1120759839556))"
    					sensormode="(sensoroperationalmode:IW)"
    					;;
    					
    -7  | --erta_ale)   COUNTRY="ERTA_ALE"
                        polygon="POLYGON((40.47309769928795 13.38637299084182,40.937128609315685 13.38637299084182,40.937128609315685 13.885019945672866,40.47309769928795 13.885019945672866,40.47309769928795 13.38637299084182))"
                        sensormode="(sensoroperationalmode:IW)"
                        ;;
                        
    -8  | --hawaii)     COUNTRY="HAWAII"
                        polygon="POLYGON((-155.43700607299937 19.195655095731155,-154.99082250566502 19.195655095731155,-154.99082250566502 19.44828597828061,-155.43700607299937 19.44828597828061,-155.43700607299937 19.195655095731155))"
                      	sensormode="(sensoroperationalmode:IW)"
                      	;;
	
	-9	| --tristan)	COUNTRY="TRISTAN"
						#Request POLYGON((-12.437366939445228 -37.19301009606267,-12.142885785004552 -37.19301009606267,-12.142885785004552 -37.032896613954165,-12.437366939445228 -37.032896613954165,-12.437366939445228 -37.19301009606267)))" ) AND ( beginPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] AND endPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] ) AND ( (platformname:Sentinel-1 AND producttype:SLC AND sensoroperationalmode:SM))
						polygon="POLYGON((-12.437366939445228 -37.19301009606267,-12.142885785004552 -37.19301009606267,-12.142885785004552 -37.032896613954165,-12.437366939445228 -37.032896613954165,-12.437366939445228 -37.19301009606267))"
						sensormode="(sensoroperationalmode:SM)"
						;;
	
	-10	| --domuyo18)	COUNTRY="DOMUYO"
						#Request POLYGON((-12.437366939445228 -37.19301009606267,-12.142885785004552 -37.19301009606267,-12.142885785004552 -37.032896613954165,-12.437366939445228 -37.032896613954165,-12.437366939445228 -37.19301009606267)))" ) AND ( beginPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] AND endPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] ) AND ( (platformname:Sentinel-1 AND producttype:SLC AND sensoroperationalmode:SM))
						polygon="POLYGON((-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818))"
						sensormode="(sensoroperationalmode:IW AND relativeorbitnumber:18)"
						;;
	
	-11	| --domuyo83)	COUNTRY="DOMUYO"
						#Request POLYGON((-12.437366939445228 -37.19301009606267,-12.142885785004552 -37.19301009606267,-12.142885785004552 -37.032896613954165,-12.437366939445228 -37.032896613954165,-12.437366939445228 -37.19301009606267)))" ) AND ( beginPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] AND endPosition:[2013-12-01T00:00:00.000Z TO 2018-05-01T23:59:59.999Z] ) AND ( (platformname:Sentinel-1 AND producttype:SLC AND sensoroperationalmode:SM))
						polygon="POLYGON((-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818))"
						sensormode="(sensoroperationalmode:IW AND relativeorbitnumber:83)"
						;;
			
    -g  |  --grd)       ptype="GRD";;
    -o  |  --ocn)       ptype="OCN";;
    -r  |  --raw)       ptype="RAW";;
    -s  |  --slc)       ptype="SLC";;
     
    # taken from: http://mywiki.wooledge.org/BashFAQ/035
    -sd |	--startdate)
                        # Takes an option argument, ensuring it has been specified.
                        if [ -n "$3" ]; then
                            INGEST_START_DATE=$3
                            echo "1. Start Date: ${INGEST_START_DATE}"
                            shift
                        else
                            printf 'ERROR: "--startdate" requires a non-empty option argument,e.g 2017-12-31 (YYYY-MM-DD).\n' >&2
                        exit 1
                         fi
                        ;;
    --startdate=?*)
                  		INGEST_START_DATE=${3#*=} # Delete everything up to "=" and assign the remainder.
               			echo "2. Start Date: ${INGEST_START_DATE}"
           				;;
        
    --startdate=)       # Handle the case of an empty --startdate=
                        printf 'ERROR: "--startdate" requires a non-empty option argument, e.g 2017-12-31 (YYYY-MM-DD) \n' >&2
                        exit 1
                        ;;
  
   	-ed |	--enddate)  # Takes an option argument, ensuring it has been specified.
               			if [ -n "$4" ]; then
                   				INGEST_END_DATE=$4
                   			echo "1. End Date: ${INGEST_END_DATE}"
                  			shift
               			else
                   		    printf 'ERROR: "--enddate" requires a non-empty option argument,e.g 2017-12-31 (YYYY-MM-DD).\n' >&2
                  			exit 1
               			fi
               			;;
    --enddate=?*)
                 		INGEST_END_DATE=${4#*=} # Delete everything up to "=" and assign the remainder.
               			echo "2. End Date: ${INGEST_END_DATE}"
                  		;;
    
    --enddate=)         # Handle the case of an empty --enddate=
           			    printf 'ERROR: "--enddate" requires a non-empty option argument, e.g 2017-12-31 (YYYY-MM-DD) \n' >&2
           			    exit 1
           			    ;;
           			    
    --skipmd5check)		SKIPMD5CHECK=true
    					;;
    					
    					# Delete the ZIPFILE older than 30days  
    --deletezip30days)	DELETE_ZIPFILE_30DAYS=true
    					;;
    					
    					# Force download priority
    --force)			FORCE_DOWNLOAD=true
    					;;
    									
    -v   | --verbose)   VERBOSE=true
    					;;
    
    -V   | --version)   show_version;
                        exit 0
                        ;;
    
    *)
        echo "Invalid option: $arg" >&2;
        show_help;
        exit 1
        ;;
   esac
done


# Check 3 arguments are given #
if [ $# -lt 4 ]
then
    printf "Usage: $0 countryname [--belgium, --capvert, --congo, --cameroon, --luxembourg, --tanzania, --erta_ale, --hawaii] "
    printf "ptype [--slc, --raw, --grd, --ocn] --startdate=YYYY-MM-DD --enddate=YYYY-MM-DD"
    echo ""
    exit
fi

if [[ ${INGEST_START_DATE} == *"-DAY"* ]]; then
    # We cut the string at first '-' e.g: 12-DAYS-AGO > result: 12
    DAYS_AGO=$(echo ${INGEST_START_DATE} | /usr/bin/cut -f 1 -d '-')
    INGEST_START_DATE=$(/bin/date -v -${DAYS_AGO}d '+%Y-%m-%d')    
    echo "$DAYS_AGO days ago choosen > calculated ingestion start date: ${INGEST_START_DATE}"

elif [[ ${INGEST_START_DATE} == *"-WEEK"* ]]; then
    # We cut the string at first '-' e.g: 12-WEEK-AGO > result: 12
    WEEKS_AGO=$(echo ${INGEST_START_DATE} | /usr/bin/cut -f 1 -d '-')
    INGEST_START_DATE=$(/bin/date -v -${WEEKS_AGO}w '+%Y-%m-%d')    
    echo "$WEEKS_AGO weeks ago choosen > calculated ingestion start date: ${INGEST_START_DATE}"
  
elif [[ ${INGEST_START_DATE} == *"-MONTH"* ]]; then
    # We cut the string at first '-' e.g: 12-MONTHS-AGO > result: 12
    MONTHS_AGO=$(echo ${INGEST_START_DATE} | /usr/bin/cut -f 1 -d '-')
    INGEST_START_DATE=$(/bin/date -v -${MONTHS_AGO}m '+%Y-%m-%d')    
    echo "$MONTHS_AGO months ago choosen > calculated ingestion start date: ${INGEST_START_DATE}"

elif [ "${INGEST_START_DATE}" == "YESTERDAY" ]; then
    INGEST_START_DATE=$(/bin/date -v -1d '+%Y-%m-%d')    
    echo "YESTERDAY ago choosen > calculated ingestion start date: ${INGEST_START_DATE}"

elif [ "${INGEST_START_DATE}" == "TODAY" ]; then
 	 INGEST_START_DATE=$(/bin/date "+%Y-%m-%d")
     echo "Ingestion Start Date: TODAY > calculated start date: ${INGEST_START_DATE}"
fi

if [ "${INGEST_END_DATE}" == "TODAY" ]; then
 	 INGEST_END_DATE=$(/bin/date "+%Y-%m-%d")
     echo "Ingestion End Date: TODAY > calculated end date: ${INGEST_END_DATE}"
fi

# Set the Working-Dir (were zipped files are downloaded) and the Unzip-Dir
ZIP_DOWNLOAD_DIR=${S1_WORKDIR}"/S1-DATA-"${COUNTRY}-${ptype}
UNZIP_DIR=${ZIP_DOWNLOAD_DIR}.UNZIP/

LOG_PATH=${S1_WORKDIR}"/S1_DOWNLOAD_LOGS/"
LOG_FILE=${LOG_PATH}"S1-${COUNTRY}-${ptype}_${INGEST_START_DATE}-til-${INGEST_END_DATE}_${LOG_DATE}.txt"

#Temp log file
LOG_SUMMARY=${LOG_PATH}"S1-${COUNTRY}-${ptype}_${INGEST_START_DATE}-til-${INGEST_END_DATE}_${LOG_DATE}-SUMMARY.txt"
LOG_ALL=${LOG_PATH}"S1-${COUNTRY}-${ptype}_${INGEST_START_DATE}-til-${INGEST_END_DATE}_${LOG_DATE}-ALL.txt"

QUERY_LOG_PATH=${LOG_PATH}"QUERY_RESULT_LIST/"
QUERY_RESULT_LOG="${QUERY_LOG_PATH}S1-${COUNTRY}-${ptype}_${INGEST_START_DATE}-til-${INGEST_END_DATE}_${LOG_DATE}.xml"

#echo "LOG_FILE: ${LOG_FILE}"
#echo "QUERY_RESULT_LOG: ${QUERY_RESULT_LOG}"

# Create the directories if not present
if [ ! -e ${ZIP_DOWNLOAD_DIR} ]
	then
	/bin/mkdir -p ${ZIP_DOWNLOAD_DIR}
fi

if [ ! -e $UNZIP_DIR ]
    then
    /bin/mkdir -p $UNZIP_DIR
fi

if [ ! -e ${LOG_PATH} ]
    then
    /bin/mkdir -p ${LOG_PATH}
fi

if [ ! -e ${QUERY_LOG_PATH} ]
    then
    /bin/mkdir -p ${QUERY_LOG_PATH}
fi

echo "This is script: $0 v${VERSION} running on $FULLHOSTNAME" | $TEE_PREFIX -a ${LOG_FILE}
echo "Script execution start date: ${SCRIPT_EXEC_STARTDATE}" 	  | $TEE_PREFIX -a ${LOG_FILE}
echo ""														  | $TEE_PREFIX -a ${LOG_FILE}

echo "Command used:"	| $TEE_PREFIX -a ${LOG_FILE}
echo "$0 $@"			| $TEE_PREFIX -a ${LOG_FILE}
echo "" 				| $TEE_PREFIX -a ${LOG_FILE}

echo "Working Dir:"		| $TEE_PREFIX -a ${LOG_FILE}
echo "${ZIP_DOWNLOAD_DIR}"	| $TEE_PREFIX -a ${LOG_FILE}
echo "" 				| $TEE_PREFIX -a ${LOG_FILE}

echo "Unzip Dir:"		| $TEE_PREFIX -a ${LOG_FILE}
echo "${UNZIP_DIR}"		| $TEE_PREFIX -a ${LOG_FILE}
echo "" 				| $TEE_PREFIX -a ${LOG_FILE}

echo "Log saved to:" 	| $TEE_PREFIX -a ${LOG_FILE}
echo "${LOG_FILE}" 		| $TEE_PREFIX -a ${LOG_FILE}
echo "" 				| $TEE_PREFIX -a ${LOG_FILE}

echo "Scihub Query Result List saved to:"	| $TEE_PREFIX -a ${LOG_FILE}
echo "${QUERY_RESULT_LOG}" 					| $TEE_PREFIX -a ${LOG_FILE}
echo "" 				   					| $TEE_PREFIX -a ${LOG_FILE}

# Always mount the SMB Disc via Applescript osascript, this avoids writing an empty 'DiscData' Folder to /Volumes/
#MOUNT_RESULT=$?

#if [ $MOUNT_RESULT -ge 1 ]
#then
#	echo "Problem mounting the Newtwork Disc, mount result: $MOUNT_RESULT, exiting now"
#	exit 1
#else
#	echo "Succesfully mounted Network Disc, discdata.... | Mount result: $MOUNT_RESULT"
#fi

# Redefine Email Subject
EMAIL_SUBJECT=${EMAIL_SUBJECT}"${COUNTRY} product=${ptype} - Ingestion Start:${INGEST_START_DATE} til:${INGEST_END_DATE}"


#function ping_esa_site
#{
#	# -q quiet
#	# -c nb of pings to perform
# 	echo "Checking if site scihub.copernicus.eu is up." | $TEE_PREFIX -a ${LOG_FILE}
# 	echo "ping command result:" | $TEE_PREFIX -a ${LOG_FILE}
# 	echo "" | $TEE_PREFIX -a ${LOG_FILE}
#	/sbin/ping -q -c10 scihub.copernicus.eu > /dev/null >> ${LOG_FILE}
#}

# Display a banner with the passed text (limited to 20 lines)
function show_text
{
   echo  "-------------------------------------"
   echo "$1" | /usr/bin/head -20
   [ $(/bin/echo "$1" | /usr/bin/wc -l) -gt 20 ] && /bin/echo "[Truncated to 20 lines]..."
   echo  "-------------------------------------"
	
}

# Return list of values for the passed field name from the result file depending on its json or xml format
function get_field_values
{
   /bin/echo "Entering get_field_values()"

   field_name="$1"
   QUERY_RESULT_LIST=$(/bin/cat "${QUERY_RESULT_LOG}" | ${XMLSTARLET_PREFIX} sel -T -t -m "//*[local-name()='entry']//*[local-name()='$field_name']" -v '.' -n)
}


function query_server
{
	#echo "Entering query_server()"
	#echo "query_server() QUERY_RESULT_LIST_LOG: ${QUERY_RESULT_LOG}"
	
   # Get URL and filter space characters
   URL="${1// /%20}"
	[ "$VERBOSE" = "true" ] && show_text "${CURL_PREFIX} \"$URL\""
    ${CURL_PREFIX} "$URL" > "${QUERY_RESULT_LOG}"
    
    [ "$VERBOSE" = "true" ] && show_text "$(${XMLSTARLET_PREFIX} fo "${QUERY_RESULT_LOG}")"
}

function show_numbered_list
{
   # Get number of items in the list
   LIST="$1"
   
   /bin/echo "--- Query Result List for the following parameters: ---" 
    
   RESULT_QUERY_MAINTENANCE=$(/bin/cat ${QUERY_RESULT_LOG} | ${PATHGNU}/grep "maintenance")
   RESULT_QUERY_ERROR=$(/bin/cat ${QUERY_RESULT_LOG} | ${PATHGNU}/grep "error")
     
   if [[ ${RESULT_QUERY_MAINTENANCE} == *"maintenance"* ]]; then
   		nb_items=0
   		MAINTENANCE_MODE=true
    	echo  "---------------------------------------------"
		echo "Maintenance Mode detected for ESA Scihub Site !"
    	echo  "----------------------------------------------"
		echo "Here's the content of the query result list:"
      	echo ""
      	/bin/cat ${QUERY_RESULT_LOG}
      	echo ""
        echo  "-------------------------------------"
		echo ""
	elif [[ ${RESULT_QUERY_ERROR} == *"error"* ]]; then
		nb_items=0
    	MAINTENANCE_MODE=true
    	echo  "------------------------------------------------------"
		echo "Error detected! ESA Scihub Site seems to have an error."
    	echo  "------------------------------------------------------"
		echo "Here's the content of the query result list:"
      	echo ""
      	/bin/cat ${QUERY_RESULT_LOG}
      	echo ""
        echo  "-------------------------------------"
		echo ""
   elif [ ! "$LIST" ]; then
		nb_items=0
		MAINTENANCE_MODE=false
      	echo "Empty Query Result List for:"
      	echo "Country: $COUNTRY | Product type: $ptype"
      	echo "Ingestion start date: ${INGEST_START_DATE}"
      	echo "Ingestion End date: ${INGEST_END_DATE}"
      	echo "Polygon choosed: ${polygon} " 
      	echo ""
      	echo " Here's the content of the query result list:"
      	echo ""
      	/bin/cat ${QUERY_RESULT_LOG}
      	echo ""
      	echo  "-------------------------------------"
		echo ""
   else
    # Loop on list and add number as prefix 
    nb_items=$(/bin/echo "$LIST" | /usr/bin/wc -l | /usr/bin/tr -d ' ')
    echo "Country: $COUNTRY"
    echo "Product type: $ptype"
	echo "Ingestion Start date:	${INGEST_START_DATE}"
	echo "Ingestion End date:	${INGEST_END_DATE}"
	echo "Polygon choosed: ${polygon}" 
	echo ""
	echo  "-------------------------------------"
	echo "Query Result List has ${nb_items} item(s): "
    echo  "-------------------------------------"
	
	OLD_IFS=$IFS
    IFS=$'\n'
    
	local i=0
    
    for item in $LIST
    do
    	i=$(expr ${i} + 1)
    	#printf "Nr.[%03d] " ${i}
    	#printf "Product-ID: ${item} \n"
    	printf "Nr.[%03d] Product-ID: ${item} \n"  ${i}
	done
	
    IFS=$OLD_IFS
    
    echo  "-------------------------------------"
	
	fi
}

function verify_md5_checksums
{
 	# Get the MD5 value to compare with the zipped file
    MD5_URL="${ROOT_URL_ODATA}/Products('$prodid')/Checksum/Value/\$value"
	md5OnlineUppercase=$(${CURL_PREFIX} "${MD5_URL}")
		    
	# Convert value to lowercase, since the command md5 outputs a lowercase value
	md5Online=`echo "$md5OnlineUppercase" | tr '[:upper:]' '[:lower:]'` 
    echo "+--MD5 checksum (scihub site): ${md5Online}"
	     
    # Check MD5 value of zipped file, lowercase value output
    echo "+--Calculating MD5 checksum of Zip file, be patient..."
	md5zipFile=$(${MD5_PREFIX} ${zippedProductFile})
	echo "+--MD5 checksum of file: ${md5zipFile}"
		
	# Compare MD5 values
	if [ "${md5zipFile}" = "${md5Online}" ]; then
	    echo "+--SUCCESS: MD5 checksums matches! Continuing..."
	        return 0;
	 else
	    echo "+--ERROR: MD5 checksums, Zip file seems broken!"
	    return -1;
	fi
}

function download_quicklook_and_full_file_list
{
	echo ""
  	echo "#### BEGIN PROCESSING ####"
	echo ""
	echo ""
	
  	cd ${ZIP_DOWNLOAD_DIR}
   	
    # Declare an indexed array "downloadArray" and initializes it to be empty. 
	# Add the name of the Zip-File downloaded.	
	# Will be printed at the end of the script
	declare -a downloadArray
	declare -a unzipArray
	
	declare -a remoteZipSizeArray
	declare -a localZipSizeArray
	
	local i=0
   	local curlReturnValue="0"
   	
	# Loop on list and add number as prefix
	for prodid in ${LIST}
	do
   		prodid=${prodid//\"/}
        
        ## DEBUG:
        ## echo "prodid = $prodid"
        
		# Build URL to get product name
		PRODUCT_NAME_URL="${ROOT_URL_ODATA}/Products('$prodid')/Name/\$value"
		## DEBUG:
		## echo "PRODUCT_NAME_URL: ${PRODUCT_NAME_URL}";
		prodname=$(${CURL_PREFIX} "${PRODUCT_NAME_URL}")
		## DEBUG:
		## printf "prodname:%s \n" $prodname

		# First check if ESA Site is down, if site is in maintenance mode the Zip-File contains
		# the text: "doctype html" or "maintenance"
		# e.g +-Zip-File name: <!doctype html>
		#	<title>The Sentinels Scientific Data Hub</title>
		#	<link href='https://fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>
		#	....
		#	Sorry for the inconvenience,<br/> 
		#	we're performing some maintenance at the moment.<br/>

		if [[ ${prodname} == *"doctype"* ]]; then
			echo "+-ALERT! ESA Download Site seems in maintenance mode, cancelling all downloads!"
			MAINTENANCE_MODE=true
			return 1
		fi # END -- if [[ ${prodname} == *"doctype html"* ]] 	
				
		# Check 
		# https://scihub.copernicus.eu/dhus/odata/v1/Products?$filter=Name eq 'S1A_IW_SLC__1SDV_20141101T165548_20141101T165616_003091_0038AA_558F'
		# Check if the big zipfile is already locally saved but we don't know if the file is fully downloaded
		# Make some file test on zipfile
		zippedProductFile="$prodname.zip"
		
		unzippedProductFile="$prodname.SAFE"
		unzippedProductFileDirectory="${UNZIP_DIR}${unzippedProductFile}"
		
		quicklookfile="$prodname.quick-look.png"
		local downloadRequired=false
		
        # Increment i to print out the filename number
       	i=$(expr ${i} + 1)

		printf "+-Product Nr.[%03d/%03d] ---\n" ${i} ${nb_items}
		printf "+-Product-ID: $prodid corresponds to:\n"
		printf "+-Remote Zip-File name: ${zippedProductFile}\n"
		
		PRODUCT_ZIPFILE_URL="${ROOT_URL_ODATA}/Products('$prodid')/\$value"	
       	
       	## DEBUG   	
		#remoteZipContent=$(${CURL_PREFIX} -sI "${PRODUCT_ZIPFILE_URL}" )
	   	#echo "remoteZipContent:${remoteZipContent}"
	   	#printf "+--DEBUG: Content of remote ZipFile:\n${remoteZipContent}"
	   	## END DEBUG
	   	
	   	# Old version: "Content-Length"
	   	#remoteZipFileSize=$(${CURL_PREFIX} -sI "${PRODUCT_ZIPFILE_URL}" | ${PATHGNU}/grep "Content-Length:" | awk '{print $2}')
	   	
	   	remoteZipFileSize=$(${CURL_PREFIX} -sI "${PRODUCT_ZIPFILE_URL}" | ${PATHGNU}/grep "content-length:" | awk '{print $2}')
	    #echo "remoteZipFileSize: $remoteZipFileSize"
	   	
	   	# Remove the \r from remoteZipFileSize
	   	remoteZipFileSize=$(echo "$remoteZipFileSize" | /usr/bin/tr -d '\r' )
	    
	    echo "+--Remote Zip-File size is ${remoteZipFileSize} bytes "
	    
	    if [ "${remoteZipFileSize}" -eq "0" ]; then
			printf "+--Remote Zip-File size is 0 bytes: maybe remote file is unavailable or your download quota is exceeded.\n\n"
			printf "+--Remote Zip-File size is 0 bytes: maybe remote file is unavailable or your download quota is exceeded.\n\n" >> ${LOG_FILE}
			printf "+-Skipping this download\n" >> ${LOG_FILE}
		fi
		
		# Check if local Zip-File exists and check its content		 	
		if [ "${remoteZipFileSize}" -gt "0" ]; then
		
			# Check if zip file already exists
			echo "+--Checking if local Zip-File already exists in ${ZIP_DOWNLOAD_DIR} " >> ${LOG_FILE}
		
			if test -f "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"; then
				
				# If Zip-File size is less than 1kB it means that an error occured or an error-message was written to it
				echo "+--Checking local Zip-File size" >> ${LOG_FILE}
				localZipfileSize=$(stat -c%s "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}")
				if [ ${localZipfileSize} -ge "0" ] && [ ${localZipfileSize} -le "1000" ]; then
				
					# if garbled Zip-file (containing the error-message) is older than 1 day (=1440 min) we delete it
					if [ test `find ${ZIP_DOWNLOAD_DIR}/${zippedProductFile} -mmin +1440` ]; then
						echo "+--Deleting garbled zipfile ${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
    					/bin/rm ${ZIP_DOWNLOAD_DIR}/${zippedProductFile}
					else
						# If zipfile is less than one day old, we check the content
						# of the zipfile (if download quota was exceeded)
						zipFileContent=$(/bin/cat ${ZIP_DOWNLOAD_DIR}/${zippedProductFile})
						
						if [[ ${zipFileContent} == *"quota"* ]]; then
							echo "+--Content of ZipFile: ${zipFileContent}"
							echo "+--Content of Zip-File: ${zipFileContent}" >> ${LOG_FILE}	
							echo "++ALERT! Quota download exceeded, cancelling all downloads !" 
							echo "++ALERT! Quota download exceeded, cancelling all downloads !" >> ${LOG_FILE}
							/usr/bin/mail -s "[${HOSTNAME}] Sentinel1 Download Quota exceeded for ${COUNTRY} product=${ptype} - Ingestion Start Date:${INGEST_START_DATE} til End Date:${INGEST_END_DATE}" "${EMAIL_RECIPIENTS}" < ${LOG_FILE}
							exit
						fi # END -- [[ ${zipFileContent} == *"quota"* ]];
					fi # END -- if test 'find....'
					
				fi # END -- if [ ${localZipfileSize} -ge "0" ] && [ ${localZipfileSize} -le "1000" ]; then
			else
				echo "+--Local Zip-File doesn't exist...continuing."
				echo "+--Local Zip-File doesn't exist...continuing." >> ${LOG_FILE}
			fi # END -- if test -f "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"; then
		
		if [ ${FORCE_DOWNLOAD} = false ]; then
	    
	    	if [ ! -d ${unzippedProductFileDirectory} ] && [ -e "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}" ]; then
				echo "+--Zip-File exists but UnZip-Dir missing !"
				echo "+--Zip-File already downloaded: YES"
				echo "+--UnZip-Dir: ${unzippedProductFile} missing!"
				echo "+--Location: ${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
				
				localZipFileSize=$(stat -c%s "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}")
				echo "+--Local Zip-File size in bytes:  ${localZipFileSize}"
				echo "+--Remote Zip-File size in bytes: ${remoteZipFileSize}"
				
				## DEBUG only
				#echo "+--Displaying content of ${zippedProductFile}"
				#echo "+--in dir: ${ZIP_DOWNLOAD_DIR}"
				#zipFileContent=$(/bin/cat ${ZIP_DOWNLOAD_DIR}/${zippedProductFile})
				#echo "+--Content of zipFile: ${zipFileContent}" 
				#echo "+--Content of zipFile: ${zipFileContent}" > ${LOG_FILE}
	
				if [ "${remoteZipFileSize}" -eq "${localZipFileSize}" ]; then
					echo "+--Zip-File seems OK. Unzipping file."
					# 7zip Manual: http://7zip.bugaco.com/7zip/MANUAL/index.htm
       				# 7zip: Skip extracting of existing files with option: -aos
       				${UNZIP_PREFIX} ${zippedProductFile} -o${UNZIP_DIR}
       				unzipReturnValue=$?

 	   				if [ "${unzipReturnValue}" -eq "0" ]; then
       	 				printf "+--Unzipping succesful for Zip-File Nr.[%03d/%03d]\n" ${i} ${nb_items}
       	 				downloadRequired=false
       	 				unzipArray+=("${unzippedProductFile}")
					else
						echo "+--ERROR: Unzipping file, redownload required!"
						downloadRequired=true
						fi
					else
						echo "+--ERROR: File sizes don't match, redownload required!"
						downloadRequired=true	
					fi # END -- if [ ${remoteZipFileSize} -eq ${localZipFileSize} ];
				
				elif [ -d "${unzippedProductFileDirectory}" ] && [ -e "${zippedProductFile}" ]; then
					echo "+--Zip-File & UnZip-Dir exists !"
      				downloadRequired=false
      				
					echo "+--UnZip-Dir exists: ${unzippedProductFile}"
					localDirSize=$($DU_PREFIX ${unzippedProductFileDirectory} | cut -f1)
					echo "+--UnZip-Dir size in bytes: ${localDirSize}"
			
					localZipFileSize=$($DU_PREFIX ${zippedProductFile} | cut -f1)
					echo "+--Local Zip-File size in bytes: ${localZipFileSize}"
			
  					if [ ${localDirSize} -ge ${remoteZipFileSize} ]; then
						echo "+--UnZip dir size >= as remote Zip-File, seems OK."
						downloadRequired=false
						echo "+--Checking if Zip-File is older than 30 days:"
       	   	
       	  				if [[ $(/usr/bin/find "${zippedProductFile}" -mtime +30 -print) ]]; then
  						echo "+--Zip-File is older than 30 days! Will be deleted!"
  							if [ ${DELETE_ZIPFILE_30DAYS} = true ]; then
  							echo "+--DELETE_ZIPFILE_30DAYS option set, deleting Zip-File!"
  							/bin/rm -rf "${zippedProductFile}"
  						else
  							echo "+--DELETE_ZIPFILE_30DAYS option not set, not deleting Zip-File."
  						fi	
  					else 
  						echo "+--Zip-File is not older than 30 days. Will not be deleted."
					fi # END -- if [ ${localDirSize} -ge ${remoteZipFileSize} ];
		   		else
					echo "+--UnZip-Dir size is smaller than Zip-File. Trying unzipping file."
					echo "+--Checking if local Zip-File size equals to remote size:"
				 
					if [ ${remoteZipFileSize} -eq ${localZipFileSize} ]; then
						echo "+---Sizes are equal. Trying to unzip file."
						# 7zip Manual: http://7zip.bugaco.com/7zip/MANUAL/index.htm
       	   				# 7zip: Skip extracting of existing files with option: -aos
       					${UNZIP_PREFIX} ${zippedProductFile} -o${UNZIP_DIR}
       					unzipReturnValue=$?
       				
 						if [ ${unzipReturnValue} -eq "0" ]; then
       		 				printf "+---Unzipping done for Zip-File Nr.[%03d/%03d]\n" ${i} ${nb_items}
       		 				downloadRequired=false
       		 				unzipArray+=("${unzippedProductFile}")
       		 			elif [ ${unzipReturnValue} -eq "2"]; then
       		 				printf "+---Fatal Error unzipping file Nr. [%03d/%03d]\n. Skipping!" ${i} ${nb_items}
       		 				downloadRequired=false	
						else
							echo "+---ERROR: Unzipping file, redownload required!"
							downloadRequired=true
						fi # END -- if [ ${unzipReturnValue} -eq "0" ];
					fi # END -- if [ $remoteZipFileSize -eq localZipFileSize ]; then
				
				fi # END - if [ ${localDirSize} -ge ${remoteZipFileSize} ]; 
			
			elif [ -d "${unzippedProductFileDirectory}" ] && [ ! -e "${zippedProductFile}" ]; then
			
				echo "+--Zip-File missing but UnZip-Dir exists!"
				echo "+--Checking size of UnZip-Dir: ${unzippedProductFile}"
			
				localDirSize=$($DU_PREFIX ${unzippedProductFileDirectory} | cut -f1)
				echo "+--UnZip-Dir size in bytes: ${localDirSize}"
				echo "+--Remote Zip-File size in bytes: ${remoteZipFileSize}"
			
  				if [ ${localDirSize} -ge ${remoteZipFileSize} ]; then
					echo "+--UnZip-Dir size is greater or same as Zip-File, seems OK, manual checking preferred."
					downloadRequired=false
		   		else
					echo "+--UnZip-Dir size is smaller than Zip-File. Redownload required."
					downloadRequired=true
				fi
			
			elif [ ! -d "${unzippedProductFileDirectory}" ] && [ ! -e "${zippedProductFile}" ]; then
				echo "+--Zip-File & UnZip-Dir missing. Download required."
				downloadRequired=true
			fi # END -- if [ -d ${unzippedProductFileDirectory} ] && [ -e "${zippedProductFile}" ];
	
		fi # END -- if [ $FORCE_DOWNLOAD=false ]			
		
      	# Download only if downloadRequired is true, or if we Force Download
      	# By default: downloadRequired and FORCE_DOWNLOAD are set to false
      
      	if [ "${downloadRequired}" = true ] || [ ${FORCE_DOWNLOAD} = true ]; then
      	  
      		# Set returnValue to 999:
	    	# Normally all unix commands (curl, 7zip) return value equals to "0", if everything is OK
	   		local returnValue="999"
	   		
   			ZIPDOWNLOAD_STARTDATE=$(/bin/date +"%A, %d %B %Y @ %H:%M (%Y%m%d%H%M)")

      		echo "+--Zip-File already downloaded: NO"
      		echo "+--Trying to download Product-ID as Zip-File."
	        echo "+--Remote Zip-File size in bytes: $remoteZipFileSize"
	        echo "+--Zip-File Download Start Date: ${ZIPDOWNLOAD_STARTDATE}"
	        	
      		# Use "-C -" to tell curl to automatically find out where/how to resume the transfer	
       	   	${CURL_PREFIX} -C - --silent --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
       	   	#{CURL_PREFIX} -C - --progress-bar --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
       	   	#${CURL_PREFIX} --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
       	   	curlReturnValue=$?
       	   		
	    	if [ ${curlReturnValue} -ne "0" ]; then
	    		printf "+--ERROR downloading  Zip-File Nr.[%03d/%03d]\n" ${i} ${nb_items}
	    		printf "+--ERROR: Maybe Site is down ? Check News at: https://scihub.copernicus.eu/news/ \n"
	    		return 1
	    	else
	    		printf "+--Zip-File download done! Saved as: ${zippedProductFile}\n"
	    		# Add the element to array
	    		downloadArray+=("${zippedProductFile}")
	    		remoteZipSizeArray+=("${remoteZipFileSize}")
	    		
	    		#Check the size of the local file, and store it in the array
	    		localZipFileSize=$($DU_PREFIX ${zippedProductFile} | cut -f1)
				localZipSizeArray+=("${localZipFileSize}")
	    	fi

			ZIPDOWNLOAD_ENDDATE=$(/bin/date +"%A, %d %B %Y @ %H:%M (%Y%m%d%H%M)")
 			printf "+--Zip-File Download End Date: ${ZIPDOWNLOAD_ENDDATE}\n"
	       	
	     	# Verifying md5 checksums
	     	# Loop through the checksum verification until the file was correctly downloaded
	    	while [ ${returnValue} -ne "0" ]
       		do
       			if [ ${SKIPMD5CHECK} = false ] ; then
       				# Verify md5 checksums of zipped file & scihub site
	    			verify_md5_checksums
	    			# If md5 checksums matches => returnValue=0, then we unzip the zipped file.
	    			returnValue=$?
	    			echo "md5 checksum returnValue :" ${returnValue}
	    		else
	    			printf "+--Skipping MD5 Checksum requested: YES\n"
         	  		returnValue="0" # set returnValue to 0 to continue unzipping
	    		fi # -- if [ ${SKIPMD5CHECK} = false ]
				
				# Check if zip file already exists
				echo "+--Checking if product zipfile already exists" > ${LOG_FILE}
				if [ -e "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}" ]; then
					echo "+--Checking product zipfile size" > ${LOG_FILE}
					
					# Check zipfileContent if download quoata was exceeded
					zipfileSize=$(stat -c%s "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}")
					
					if [ ${zipfileSize} -ge "0" ] && [ ${zipfileSize} -le "1000" ]; then
						echo "++ERROR: It seems your download quoata was exceeded..." >> ${LOG_FILE}
						zipFileContent=$(/bin/cat ${ZIP_DOWNLOAD_DIR}/${zippedProductFile})
						
						if [[ ${zipFileContent} == *"quota"* ]]; then
							echo "++ALERT! Quota download exceeded, cancelling all downloads !" >> ${LOG_FILE}
							echo "+--Content of zipFile: ${zipFileContent}" >> ${LOG_FILE}	
							/usr/bin/mail -s "[${HOSTNAME}] Sentinel1 Download Quota exceeded for ${COUNTRY} product=${ptype} - Ingestion Start Date:${INGEST_START_DATE} til End Date:${INGEST_END_DATE}" "${EMAIL_RECIPIENTS}" < ${LOG_FILE}
							exit
							#break # Skip entire rest of loop.
							#return 1
						fi # END -- [[ ${zipFileContent} == *"quota"* ]];	
			
					elif [ ${zipfileSize} -eq "0" ]; then
						printf "+--ERROR: Zip-File Nr.[%03d/%03d] has 0 bytes, will not be unzipped...\n" ${i} ${nb_items}
						# First we delete the file (or else it can loop infinitely if the file was not correctly downloaded)
	    				#echo "+---Deleting the broken product file: ${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
	    				#/bin/rm -v "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
	    				returnValue="999"
	    			else
	    				returnValue="0"
	    			fi # END -- if [ ${zipfileSize} -gt "0" && ${zipfileSize} -lt "1000" ]
	    
	    		else 
	    			returnValue="999"		
				fi	# END -- if test -f "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"; then
					

	    		# If returnValue = 0 means that we got no md5 checksum error
	    		if [ ${returnValue} -eq "0" ]; then
	    			
					printf "+--Unzipping file to dir: ${UNZIP_DIR}/${unzippedProductFile}\n"
					# 7zip Manual: http://7zip.bugaco.com/7zip/MANUAL/index.htm
       	   			# 7zip: Skip extracting of existing files with option: -aos
       				${UNZIP_PREFIX} ${zippedProductFile} -o${UNZIP_DIR}
       				unzipReturnValue=$?
 	   				echo "unzipReturnValue= ${unzipReturnValue}"
 	   				
 	   				if [ ${unzipReturnValue} -eq "0" ]; then
       				 	printf "+--Unzipping done for Zip-File Nr.[%03d/%03d]\n" ${i} ${nb_items}
       				 	unzipArray+=("${unzippedProductFile}")
       				 	returnValue="0"
       				elif [ ${unzipReturnValue} -eq "2" ]; then
       					echo "Error unzipping Zip-File"
       					returnValue="999"
       				fi			
       			fi
       			
       			if [ ${returnValue} -eq "999" ]; then
       				
    					printf "+--REDOWNLOAD: Zip-File Nr.[%03d/%03d] seems broken. Trying to redownload file!\n" ${i} ${nb_items}
    					# Since we want a return value from 7Zip, we don't use 'tee' to output to LOG_FILE
	    				# If you pipe the curl command to 'tee' you will get the return value, but not the returnvalue from curl itself!
	    				PRODUCT_ZIPFILE_URL="${ROOT_URL_ODATA}/Products('$prodid')/\$value"
	    				
	    				# First we delete the file (or else it can loop infinitely if the file was not correctly downloaded)
	    				echo "+---Deleting the broken product file: ${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
	    				/bin/rm -v "${ZIP_DOWNLOAD_DIR}/${zippedProductFile}"
	    				
	    				echo "+---Trying redownload!"
	    	 			#${CURL_PREFIX} -C - --silent --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
	    	 			#${CURL_PREFIX} -C - --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
	    	 			${CURL_PREFIX} --show-error -o "${zippedProductFile}" "${PRODUCT_ZIPFILE_URL}" 2>&1
	    	 			
	    				returnValue=$?
						echo "curl - returnValue=${returnValue}"
						
						if [ ${returnValue} -ne "0" ]; then
	    					printf "+--Error redownloading Zip-File! Maybe Site is down ? Check News here: https://scihub.copernicus.eu/news/ \n"
	    					break
	    				else
	    					printf "+--Redownloading Zip file [Nr.%03d/%03d] was successful.\n" ${i} ${nb_items}
	    					# Setting returnValue to 999 for do-while loop to reverify md5 checksum
	    					# and eventually redownload file if md5 checksum does not match.
	    					returnValue="0"
	    				fi # END -- if [ ${returnValue} -eq "999" ]
	    				
       			fi # END -- if [ ${unzipReturnValue} -eq "0" ]
       			
	    	done # END -- while [ ${returnValue} -ne "0" ]
		
	    		if [ ${returnValue} -ne "0" ]; then
	    			printf "+--ERROR downloading Product Zip-File [Nr.%03d/%03d]\n" ${i} ${nb_items}
	    		else			
      	 			printf "+--Download done for Product Zip-File [Nr.%03d/%03d]\n" ${i} ${nb_items}
				fi
    	
    		fi # END -- if [ ! -e "${zippedProductFile}" ] && [ "$downloadRequired" = true ]
	   	
	   	echo "+-Done for Zip-File"
	   	#echo "+-Sleeping for 1 minute before downloading Quicklook file"
	   	#sleep 60
       
		if [ -e "$quicklookfile" ]; then
      	    printf "+-Quick-look file already downloaded: YES\n"
	     elif [ ! -e "$quicklookfile" ]; then
       	    printf "+-Quick-look file already downloaded: NO\n"
	     	# Build URL to get quick-look
      		printf "+--Downloading the Quick-look PNG file.\n" 
       	    returnValue="999"
       	 
       	 	while [ ${returnValue} -ne "0" ]
       	    do
      	    	QUICKLOOK_URL="${ROOT_URL_ODATA}/Products('$prodid')/Nodes('$prodname.SAFE')/Nodes('preview')/Nodes('quick-look.png')/\$value"
        	
        		# Since we want a return value from curl, we don't use $TEE_PREFIX to output to LOG_FILE
	    		# If you pipe the curl command to $TEE_PREFIX you will get the return value, but no the one from curl itself!
	    		#${CURL_PREFIX} -C - --verbose -o "$quicklookfile" "${QUICKLOOK_URL}" 2>&1
	    		${CURL_PREFIX} -C - --silent --show-error -o "$quicklookfile" "${QUICKLOOK_URL}" 2>&1 
    			returnValue=$?
    			#echo "Curl Quicklook download return code: " ${returnValue}	
    		done
    	fi # END -- if [ ! -e "$quickLookFile" ] 
		
		echo "+--Quick-look file saved as: $quicklookfile"
        echo "+--Done for Quick-look File"
        
        printf "+-End Processing Product Nr.[%03d/%03d] ---\n" ${i} ${nb_items}
	  	echo ""
	  	
	  fi # END -- if [ $remoteZipFile -gt "0" ]
	  
	done # END -- for prodid in ${LIST}
    
    echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
	echo "#### --- SUMMARY --- ####" | $TEE_PREFIX -a ${LOG_SUMMARY}										
	echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}

	# Get the array length
	numberOfDownloadedFiles=${#downloadArray[@]}
	
	if [ ${numberOfDownloadedFiles} -gt "0" ]; then
		echo "The following $numberOfDownloadedFiles file(s) were downloaded to directory:" | $TEE_PREFIX -a ${LOG_SUMMARY}
		echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
		echo "$ZIP_DOWNLOAD_DIR" | $TEE_PREFIX -a ${LOG_SUMMARY}
		echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
		
		nbrFile=1;
		
	    for (( i = 0 ; i < ${numberOfDownloadedFiles} ; i=${i}+1 ));
    	do
    		printf "[%03d]: ${downloadArray[${i}]}\n" $nbrFile | $TEE_PREFIX -a ${LOG_SUMMARY}
    		printf "          -Remote-FileSize: ${remoteZipSizeArray[${i}]} bytes\n" | $TEE_PREFIX -a ${LOG_SUMMARY}
    		printf "          -Local-FileSize:     ${localZipSizeArray[${i}]} bytes \n" | $TEE_PREFIX -a ${LOG_SUMMARY}
    		echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
    		
    		nbrFile=$[${nbrFile} + 1]
    	done
    	
	else
		echo "*** No Zip-Files were downloaded. ***" | $TEE_PREFIX -a ${LOG_SUMMARY}
	fi # END -- if [ ${numberOfDownloadedFiles} -gt "0" ];
	echo ""  | $TEE_PREFIX -a ${LOG_SUMMARY}	
	
	# Get the array length
	numberOfUnzippedFiles=${#unzipArray[@]}

	if [ ${numberOfUnzippedFiles} -gt "0" ]; then
		echo "The following $numberOfUnzippedFiles file(s) were unzipped to directory:" | $TEE_PREFIX -a ${LOG_SUMMARY}
		
		echo "$UNZIP_DIR"  | $TEE_PREFIX -a ${LOG_SUMMARY}
		echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
		nbrFile=1;

		for iUnzipName in "${unzipArray[@]}"
		do
			printf "[%03d]: ${iUnzipName} \n" $nbrFile | $TEE_PREFIX -a ${LOG_SUMMARY}
			nbrFile=$[${nbrFile} +1]
		done
	else
		echo "*** No Zip-Files were unzipped. ***" | $TEE_PREFIX -a ${LOG_SUMMARY}
	fi # END -- if [ ${numberOfUnzippedFiles} -gt "0" ];
	echo "" | $TEE_PREFIX -a ${LOG_SUMMARY}
	
	echo "#### --- END SUMMARY --- ####" | $TEE_PREFIX -a ${LOG_SUMMARY}										
	echo ""  | $TEE_PREFIX -a ${LOG_SUMMARY}	
	echo ""  | $TEE_PREFIX -a ${LOG_SUMMARY}	
	echo "---- Detailed Logs ----" | $TEE_PREFIX -a ${LOG_SUMMARY}										
	echo ""  | $TEE_PREFIX -a ${LOG_SUMMARY}	
	
	
} # -- END -- function download_quicklook_and_full_file_list()


## Main Routine

# Pinging the site doesn't seem to work reliably, so we just turn it OFF
# Note: don't add the 'tee command' after calling function ping_esa_site
# or else the if conditional will be truncated to the 'tee' result value
# and not the one from the ping function command

##ping_esa_site.OFF
##if [ $? -ne 0 ]; then	
#	echo "" | $TEE_PREFIX -a ${LOG_FILE}
#	echo "Ping test of site scihub.copernicus.eu seems down, continuing anyway..." | $TEE_PREFIX -a ${LOG_FILE}
#	echo "Check latest News here: https://scihub.copernicus.eu/news/" | $TEE_PREFIX -a ${LOG_FILE}
#	echo "" | $TEE_PREFIX -a ${LOG_FILE}
#	echo "" | $TEE_PREFIX -a ${LOG_FILE}
	
	# Send an email using /usr/bin/mail
#	/usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < ${LOG_FILE}
#	exit -1
#else
#	echo "ESA's scihub.copernicus.eu seems OK, continuing..." | $TEE_PREFIX -a ${LOG_FILE}
#	echo "" | $TEE_PREFIX -a ${LOG_FILE}	
#fi

## Build query and replace blanks spaces by '+'
## This is the correct query, from odata-demos.sh:
## query="ingestiondate:[NOW-${maxRows}DAYS TO NOW] AND producttype:${ptype} AND footprint:\"Intersects(${polygon})\""
# Example for 2017-04-01 til 2017-05-01
# query="ingestiondate:[2017-04-01T00:00:00.000Z TO 2017-05-01T00:00:00.000Z] AND producttype:${ptype} AND footprint:\"Intersects(${polygon})\""
#
# Making queries with ingestion start date and ingestion end date
#query="ingestiondate:[${INGEST_START_DATE}T00:00:00:000Z TO ${INGEST_END_DATE}T00:00:00.000Z] AND producttype:${ptype} AND ${sensormode} AND footprint:\"Intersects(${polygon})\""
query="ingestiondate:[${INGEST_START_DATE}T00:00:00:000Z TO ${INGEST_END_DATE}T00:00:00.000Z] AND producttype:${ptype} AND ${platformname} AND ${sensormode} AND footprint:\"Intersects(${polygon})\""
#query="ingestiondate:[${INGEST_START_DATE}T00:00:00:000Z TO ${INGEST_END_DATE}T00:00:00.000Z] AND producttype:${ptype} AND ${platformname} AND ${sensormode} AND footprint:\"Intersects(${polygon})\""

query_server "${ROOT_URL_SEARCH}?q=${query// /+}&rows=$maxRows&start=0"
QUERY_RESULT_LIST=$(/bin/cat "${QUERY_RESULT_LOG}" | ${XMLSTARLET_PREFIX} sel -T -t -m '//_:entry/_:id/text()' -v '.' -n)

#echo "----------------------------------------" | $TEE_PREFIX -a ${LOG_FILE}
#echo "Query sent:" | $TEE_PREFIX -a ${LOG_FILE}
#echo "$query" | $TEE_PREFIX -a ${LOG_FILE}
#echo "----------------------------------------" | $TEE_PREFIX -a ${LOG_FILE}
#echo "" | $TEE_PREFIX -a ${LOG_FILE}

# Display result list

# Get nb_items from show_numbered_list
# Note when using "tee" to write to logfile we don't get the result of nb_items
# so we are redirecting directly to ${LOG_FILE}

show_numbered_list "${QUERY_RESULT_LIST}" >> ${LOG_FILE}

# Get the result from show_number_list and store it in variable "nb_items"
if [ ${nb_items} -gt "0" ]; then
	echo "" | $TEE_PREFIX -a ${LOG_FILE}
    download_quicklook_and_full_file_list "${QUERY_RESULT_LIST}" | $TEE_PREFIX -a ${LOG_FILE}
    echo "" | $TEE_PREFIX -a ${LOG_FILE}
    
elif [ "$MAINTENANCE_MODE" = true ]; then
	echo "----------------------------------------"   | $TEE_PREFIX -a ${LOG_FILE}
	echo "ESA-Site seems to be in Maintenance Mode !" | $TEE_PREFIX -a ${LOG_FILE}
	echo "----------------------------------------"   | $TEE_PREFIX -a ${LOG_FILE}
	echo "" | $TEE_PREFIX -a ${LOG_FILE}
else
	echo "---------------------------------------------" | $TEE_PREFIX -a ${LOG_FILE}
	echo "The Query Result List is empty. Nothing done!" | $TEE_PREFIX -a ${LOG_FILE}
	echo "---------------------------------------------" | $TEE_PREFIX -a ${LOG_FILE}
	echo "" | $TEE_PREFIX -a ${LOG_FILE}
fi

SCRIPT_EXEC_ENDDATE=$(/bin/date +"%A, %d %B %Y @ %H:%M")
echo "Script Start Date:	${SCRIPT_EXEC_STARTDATE}"	| $TEE_PREFIX -a ${LOG_FILE}
echo "Script End Date:	${SCRIPT_EXEC_ENDDATE}"			| $TEE_PREFIX -a ${LOG_FILE}
echo "## End of script ${0} ${VERSION} ###"			    | $TEE_PREFIX -a ${LOG_FILE}

# Send an email using /usr/bin/mail
if [ "$MAINTENANCE_MODE" = false ]; then
	 # Combine the summary log (before) and the log file together
	 /bin/cat ${LOG_SUMMARY} ${LOG_FILE} > ${LOG_ALL}
	 
	#/usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < ${LOG_FILE}
	/usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < ${LOG_ALL}
else
	/usr/bin/mail -s "[${HOSTNAME}] Sentinel1 Maintenance Mode detected for ${COUNTRY} product=${ptype} - Ingestion Start Date:${INGEST_START_DATE} til End Date:${INGEST_END_DATE}" "${EMAIL_RECIPIENTS}" < ${LOG_FILE}
fi	

# Exit
exit 0
