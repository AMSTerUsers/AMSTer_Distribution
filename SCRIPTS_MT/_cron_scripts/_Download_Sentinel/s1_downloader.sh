#!/opt/local/bin/bash
#
# Script to download SENTINEL-1 productFiles based on AOI (Area of Interest)
# SENTINEL APIs documentation (replace SciHub interfaces):
# https://documentation.dataspace.copernicus.eu/APIs/OData.html
#
# It will send an e-mail summarising the results. 
#
# It also unzip the downloaded images
#
# This script is provided as an example and must be tuned to your needs:
# - Mounting of the disks is performed for Mac computer; change the method if needed
# - sending the mail is performed with Mac app; change the method if needed 
# - your e-mail address
# - your login and password to esa web site 
# - your path where to save the data
# - and of course, your targets (footprints, orbits etc...)
#
# Dependencies: 
# - curl, wget
# - 7zip
# - app to send mail 
# ...
#
# Written by G. Celli for AMSTer software at ECGS

VERSION="1.0.0-2024.06.18"

# Default values
# Start and End Date - obsolate
START_DATE=$1
END_DATE=$2

FULLHOSTNAME=$(/bin/hostname)
HOSTNAME=$(/bin/hostname -s)
LOG_DATE=$(/bin/date +"%Y%m%d%H%M")
SCRIPT_EXEC_STARTDATE=$(/bin/date +"%A, %d %B %Y @ %H:%M")

# List the Catalogue only - when passing "--list-only" it will not try to download product files, but 
LIST_CATALOGUE_ONLY=false

# Set the email recipients, separate with comma for multiple recipients
EMAIL_RECIPIENTS="YourEmail@Address.com"

#EMAIL_SUBJECT="[${HOSTNAME}] Sentinel1 emergency download for "
EMAIL_SUBJECT="SENTINEL-1 downloads for "

##########################################################################################

# Use macOS automount feature to mount smb network discs
# Whole SMB_URL=/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/
SMB_SHARE_NAME="hp-D3600-Data_Share1" # do not use a slash at beginning and end
SMB_SHARE_MOUNTED_ON_LOCAL_DIR="${HOME}/NAS-Discs/${SMB_SHARE_NAME}"
S1_WORKDIR="${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}/SAR_DATA/S1"
echo "Working Dir: S1_WORKDIR= ${S1_WORKDIR}"

# new since inclusion of Piton de la Fournaise (Sept 30 2020)
SMB_SHARE_NAME_OTHER="hp-D3601-Data_RAID6" # do not use a slash at beginning and end
SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER="${HOME}/NAS-Discs/${SMB_SHARE_NAME_OTHER}"
S1_WORKDIR_OTHER="${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/SAR_DATA_Other_Zones/S1"
echo "And Working Dir: S1_WORKDIR_OTHER= ${S1_WORKDIR_OTHER}"

##########################################################################################

# Third-party applications, provide the correct path for curl, jq and others

# GNU stat command
CMD_CURL="/opt/local/bin/curl "
CMD_GNU_STAT="/opt/local/bin/gstat"
CMD_JQ="/opt/local/bin/jq"

# Use wget to download quicklook-file, handles way better URLs with dollar "$" signs
CMD_WGET="/opt/local/bin/wget"

CMD_DU="/opt/local/libexec/gnubin/du -sb"
CMD_TEE="/opt/local/libexec/gnubin/tee"

# For unzipping, we're using 7zip with options:
# -aos: Skip extracting of existing files
# x: for extracting files with its directory content
CMD_UNZIP="/opt/local/bin/7zz x -bb0 -bd -aos "


##########################################################################################
# ESA-Site login details
USERNAME="YourLogin"
PASSWORD="YourPassword"
##########################################################################################

# Display help
function show_help
{
    echo "USAGE: sentinel1_downloader.sh [COUNTRY] --startdate=YYYY-MM-DD --endate=YYYY-MM-DD  [OPTION_3] ... "
    echo "This script downloads Sentinel1 data of a given country using the ESA's COPERNICUS OData interface."
    echo " -h, --help       display this help message"
    echo ""
    echo ""
    echo "Choose Country, only one can be selected:"
    echo ""
    echo "      -1, --belgium    download Sentinel1 data of Belgium"
    echo "      -2, --capvert    download Sentinel1 data of Capvert"
    echo "      -3a, --congo      download Sentinel1 data of Congo A174"
    echo "      -3d, --congo      download Sentinel1 data of Congo D21"
    echo "      -4, --cameroon   download Sentinel1 data of Cameroon"
    echo "      -5a, --luxembourg download Sentinel1 data of Luxembourg A88"
    echo "      -5d, --luxembourg download Sentinel1 data of Luxembourg D139"
    echo "      -6, --tanzania   download Sentinel1 data of Tanzania"
    echo "      -7, --erta_ale   download Sentinel1 data of Ethiopia (Erta Ale)"
    echo "      -8a, --hawaii     download Sentinel1 data of Hawaii A124"
    echo "      -8d, --hawaii     download Sentinel1 data of Hawaii D87"
    echo "      -9, --tristan    download Sentinel1 data of Tristan de Cuna"
    echo "		-10, --domuyo18	 download Sentinel1 data of Domuyo - ASCENDING 18"
    echo "		-11, --domuyo83	 download Sentinel1 data of Domuyo - DESCENDING 83"
    echo "		-12, --PFascSM	 download Sentinel1 data of Piton de la Fournaise - ASCENDING 144 Strip Map mode"
    echo "		-13, --PFdescSM	 download Sentinel1 data of Piton de la Fournaise - DESCNDING 151 Strip Map mode"
    echo "		-14, --PFascSM	 download Sentinel1 data of Piton de la Fournaise - ASCENDING 144 IW mode"
    echo "		-15, --PFdescSM	 download Sentinel1 data of Piton de la Fournaise - DESCNDING 151 IW mode"
    echo "		-16, --karthala86 download Sentinel1 data of Karthala - ASCENDING 86 Strip Map mode"
    echo "		-17, --guadeloupeD54 download Sentinel1 data of Gudaeloupe - DESCENDING 54 IW mode"
    echo "		-18, --guadeloupeA164 download Sentinel1 data of Gudaeloupe - ASCENDING 164 IW mode"
    echo ""
    echo "Set product type (default: SLC)"
    echo "      -g, --grd        set product type to GRD"
    echo "      -o, --ocn        set product type to OCN"
    echo "      -r, --raw        set prodType to RAW"
    echo "      -s, --slc        set prodType to SLC"
    echo ""
    echo "Set Start date:"
    echo "      --last-48hours 	:try to download last files 48h ago (when available)"
    echo "      or:"
    echo "	--startdate=YYYY-MM-DD"
    echo "      or:"
    echo "      --startdate=TODAY"
    echo "      --startdate=YESTERDAY"
    echo "      --startdate=xx-DAYS-AGO"
    echo "      --startdate=xx-WEEK-AGO"
    echo "      --startdate=xx-MONTH-AGO"
    echo ""
    echo "Set End date:"
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
    echo ""
    echo " -l, --list-only: don't download anything just list the queries"
    echo ""
}

# Set default values
# relativeOrbitNumber by default to empty
relOrbitNumber=""
# productType to SLC
prodType="SLC"

# Parse command line arguments
for arg in "$@"
do
   case "$arg" in
    -h  | --help)       show_help;
                        exit 0
                        ;;

    -1  | --belgium)    COUNTRY="BELGIUM"
                        polygon="POLYGON((2.2759179687511 49.39733675067,6.5825585937511 49.39733675067,6.5825585937511 51.523048670724,2.2759179687511 51.523048670724,2.2759179687511 49.39733675067))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
                        ;;

    -2  | --capvert)    COUNTRY="CAPVERT"
                        polygon="POLYGON((-24.805380859375 14.770554001959,-24.212119140625 14.770554001959,-24.212119140625 15.083713334744,-24.805380859375 15.083713334744,-24.805380859375 14.770554001959))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
                        ;;

    -3a  | --congoA174)  COUNTRY="DRCONGO"
     					#footprint:"Intersects(POLYGON((28.877000477879644 -1.771099490525117,29.510581143494434 -1.771099490525117,29.510581143494434 -1.1466480690884282,28.877000477879644 -1.1466480690884282,28.877000477879644 -1.771099490525117)))" ) AND ( ingestionDate:[2021-05-28T00:00:00.000Z TO 2021-05-28T23:59:59.999Z ] ) AND ( (platformname:Sentinel-1 AND producttype:SLC)
                        # Bigger
                        #polygon="POLYGON((28.63761230469 -3.7042857753737,29.725258789065 -3.7042857753737,29.725258789065 -0.54279843346273,28.63761230469 -0.54279843346273,28.63761230469 -3.7042857753737))"
                        # New since 2021.05.27 - requested by Nicolas - smaller for Nyiragongo & area
                        polygon="POLYGON((28.877000477879644 -1.771099490525117,29.510581143494434 -1.771099490525117,29.510581143494434 -1.1466480690884282,28.877000477879644 -1.1466480690884282,28.877000477879644 -1.771099490525117))"
                        sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="174"
						;;

    -3d  | --congoD21)  COUNTRY="DRCONGO"
     					#footprint:"Intersects(POLYGON((28.877000477879644 -1.771099490525117,29.510581143494434 -1.771099490525117,29.510581143494434 -1.1466480690884282,28.877000477879644 -1.1466480690884282,28.877000477879644 -1.771099490525117)))" ) AND ( ingestionDate:[2021-05-28T00:00:00.000Z TO 2021-05-28T23:59:59.999Z ] ) AND ( (platformname:Sentinel-1 AND producttype:SLC)
                        # Bigger
                        #polygon="POLYGON((28.63761230469 -3.7042857753737,29.725258789065 -3.7042857753737,29.725258789065 -0.54279843346273,28.63761230469 -0.54279843346273,28.63761230469 -3.7042857753737))"
                        # New since 2021.05.27 - requested by Nicolas - smaller for Nyiragongo & area
                        polygon="POLYGON((28.877000477879644 -1.771099490525117,29.510581143494434 -1.771099490525117,29.510581143494434 -1.1466480690884282,28.877000477879644 -1.1466480690884282,28.877000477879644 -1.771099490525117))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="21"
						;;
                    
   
    -4  | --cameroon)   COUNTRY="CAMEROON"
                        polygon="POLYGON((8.9940576171883 3.9091132063575,9.460976562501 3.9091132063575,9.460976562501 4.4788700707381,8.9940576171883 4.4788700707381,8.9940576171883 3.9091132063575))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
                        ;;

    -5a  | --luxembourgA88) COUNTRY="LUXEMBOURG"
                        #polygon="POLYGON((5.4674462890619 48.418939253948,8.2579736328119 48.418939253948,8.2579736328119 50.307533561486,5.4674462890619 50.307533561486,5.4674462890619 48.418939253948))"
                        # incl. Belgium
                        polygon="POLYGON((2.4495477846656244 51.09857384337633,3.404380618761151 51.42802325283006,4.555534222483794 51.555813466481226,5.198038559445268 51.51140532353608,7.134475241676382 50.91890083858132,6.313497477781164 50.06165685491578,6.679368002995337 49.618519748347836,8.169621117892092 49.1362978376153,7.812674264024606 48.76711197844659,6.715062688382086 48.82589534889004,6.313497477781164 49.0895684890138,6.099329365460672 49.34022139167058,5.474672371192572 49.34022139167058,5.028488803858213 49.68207378905507,4.716160306724163 49.80893300681208,4.153969011882872 49.906733443756224,3.9219535568690054 50.07311281836337,3.984419256295816 50.19894786989019,3.5917777170415803 50.26744571831401,3.0474337648936642 50.60279667420565,2.556631840825871 50.78368908203797,2.4495477846656244 51.09857384337633,2.4495477846656244 51.09857384337633))"
                        sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="88"
                        ;;

    -5d  | --luxembourgD139) COUNTRY="LUXEMBOURG"
                        #polygon="POLYGON((5.4674462890619 48.418939253948,8.2579736328119 48.418939253948,8.2579736328119 50.307533561486,5.4674462890619 50.307533561486,5.4674462890619 48.418939253948))"
                        # incl. Belgium
                        polygon="POLYGON((2.4495477846656244 51.09857384337633,3.404380618761151 51.42802325283006,4.555534222483794 51.555813466481226,5.198038559445268 51.51140532353608,7.134475241676382 50.91890083858132,6.313497477781164 50.06165685491578,6.679368002995337 49.618519748347836,8.169621117892092 49.1362978376153,7.812674264024606 48.76711197844659,6.715062688382086 48.82589534889004,6.313497477781164 49.0895684890138,6.099329365460672 49.34022139167058,5.474672371192572 49.34022139167058,5.028488803858213 49.68207378905507,4.716160306724163 49.80893300681208,4.153969011882872 49.906733443756224,3.9219535568690054 50.07311281836337,3.984419256295816 50.19894786989019,3.5917777170415803 50.26744571831401,3.0474337648936642 50.60279667420565,2.556631840825871 50.78368908203797,2.4495477846656244 51.09857384337633,2.4495477846656244 51.09857384337633))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="139"
                        ;;

    -6  | --tanzania)   COUNTRY="TANZANIA"
                        polygon="POLYGON((35.674355468752 -3.1120759839556,36.959755859378 -3.1120759839556,36.959755859378 -1.3337017191793,35.674355468752 -1.3337017191793,35.674355468752 -3.1120759839556))"
    					sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
    					;;

    -7  | --erta_ale)   COUNTRY="ERTA_ALE"
                        polygon="POLYGON((40.47309769928795 13.38637299084182,40.937128609315685 13.38637299084182,40.937128609315685 13.885019945672866,40.47309769928795 13.885019945672866,40.47309769928795 13.38637299084182))"
                        sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
                        ;;
    -8a  | --hawaiiA124)     COUNTRY="HAWAII"
                        polygon="POLYGON((-155.43700607299937 19.195655095731155,-154.99082250566502 19.195655095731155,-154.99082250566502 19.44828597828061,-155.43700607299937 19.44828597828061,-155.43700607299937 19.195655095731155))"
                      	sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="124"
                        SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
                        SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
                        S1_WORKDIR=${S1_WORKDIR_OTHER}/
                      	;;


    -8d  | --hawaiiD87)     COUNTRY="HAWAII-DESC87"
                        polygon="POLYGON((-155.43700607299937 19.195655095731155,-154.99082250566502 19.195655095731155,-154.99082250566502 19.44828597828061,-155.43700607299937 19.44828597828061,-155.43700607299937 19.195655095731155))"
                      	sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="87"
                        SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
                        SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
                        S1_WORKDIR=${S1_WORKDIR_OTHER}/
                      	;;

	-9	| --tristan)	COUNTRY="TRISTAN"
						polygon="POLYGON((-12.437366939445228 -37.19301009606267,-12.142885785004552 -37.19301009606267,-12.142885785004552 -37.032896613954165,-12.437366939445228 -37.032896613954165,-12.437366939445228 -37.19301009606267))"
						sensormode="SM"
                        orbitDirection="DESCENDING"
                        relOrbitNumber=""
                        SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
                        SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
                        S1_WORKDIR=${S1_WORKDIR_OTHER}/
                        ;;

	-10	| --domuyoA18)	COUNTRY="DOMUYO"
						polygon="POLYGON((-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818))"
						sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="18"
                        ;;

	-11	| --domuyoD83)	COUNTRY="DOMUYO"
						polygon="POLYGON((-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818))"
						sensormode="IW"
                        orbitDirection="DESCENDING"
						relOrbitNumber="83"
                        ;;

	-12	| --PFascSM)	COUNTRY="REUNION_SM"
						polygon="POLYGON((55.1977713794396 -21.40237876278574, 55.87579310257687 -21.40252330702253, 55.86371241079386 -20.87304877303437, 55.19472552487835 -20.87433374588863, 55.1977713794396 -21.40237876278574))"
						sensormode="SM"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="144"
						# Will be stored on a different HD
						SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
						SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
						S1_WORKDIR=${S1_WORKDIR_OTHER}/
                        CHANGELOGDIR="SM"
						;;

	-13	| --PFdescSM)	COUNTRY="REUNION_SM"
						polygon="POLYGON((55.1977713794396 -21.40237876278574, 55.87579310257687 -21.40252330702253, 55.86371241079386 -20.87304877303437, 55.19472552487835 -20.87433374588863, 55.1977713794396 -21.40237876278574))"
						sensormode="SM"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="151"
						# Will be stored on a different HD
						SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
						SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
						S1_WORKDIR=${S1_WORKDIR_OTHER}/
                        CHANGELOGDIR="SM"
						;;

	-14	| --PFascIW)	COUNTRY="REUNION"
						polygon="POLYGON((55.1977713794396 -21.40237876278574, 55.87579310257687 -21.40252330702253, 55.86371241079386 -20.87304877303437, 55.19472552487835 -20.87433374588863, 55.1977713794396 -21.40237876278574))"
						sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="144"
						# Will be stored on a different HD
						SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
						SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
						S1_WORKDIR=${S1_WORKDIR_OTHER}/
                        CHANGELOGDIR="IW"
						;;

	-15	| --PFdescIW)	COUNTRY="REUNION"
						polygon="POLYGON((55.1977713794396 -21.40237876278574, 55.87579310257687 -21.40252330702253, 55.86371241079386 -20.87304877303437, 55.19472552487835 -20.87433374588863, 55.1977713794396 -21.40237876278574))"
						sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="151"
						# Will be stored on a different HD
						SMB_SHARE_NAME=${SMB_SHARE_NAME_OTHER}/
						SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER}/
						S1_WORKDIR=${S1_WORKDIR_OTHER}/
                        CHANGELOGDIR="IW"
						;;
	-16	| --karthala86)	COUNTRY="KARTHALA_SM"
						polygon="POLYGON((43.2069351946721 -11.3434508578491, 43.5403432377049 -11.3458995003596, 43.5403432377049 -11.9512819903538, 43.2044377561476 -11.9512819903538, 43.2069351946721 -11.3434508578491))"
						sensormode="SM"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="86"
						# Will be stored on a different HD
						SMB_SHARE_NAME=${SMB_SHARE_NAME}/
						SMB_SHARE_MOUNTED_ON_LOCAL_DIR=${SMB_SHARE_MOUNTED_ON_LOCAL_DIR}/
						S1_WORKDIR=${S1_WORKDIR}/
                        CHANGELOGDIR="SM"
						;;
	-17	| --guadeloupeD54)	COUNTRY="GUADELOUPE"
						polygon="POLYGON((-60.97642182170839 16.51471201845488,-61.82468479885705 16.52432647142963, -61.81692856642155 15.86193868727157, -60.98425058771025 15.8650629729729, -60.97642182170839 16.51471201845488))"
						sensormode="IW"
                        orbitDirection="DESCENDING"
                        relOrbitNumber="54"
						# Will be stored on a different HD
						;;
	-18	| --guadeloupeA164)	COUNTRY="GUADELOUPE"
						polygon="POLYGON((-60.97642182170839 16.51471201845488,-61.826997 16.49533, -61.81692856642155 15.86193868727157, -60.98425058771025 15.8650629729729, -60.97642182170839 16.51471201845488))"
						sensormode="IW"
                        orbitDirection="ASCENDING"
                        relOrbitNumber="164"
						# Will be stored on a different HD
						;;

    -g  |  --grd)       prodType="GRD";;
    -o  |  --ocn)       prodType="OCN";;
    -r  |  --raw)       prodType="RAW";;
    -s  |  --slc)       prodType="SLC";;

    # taken from: http://mywiki.wooledge.org/BashFAQ/035
    -sd |	--startdate)
                        # Takes an option argument, ensuring it has been specified.
                        if [ -n "$3" ]; then
                            START_DATE=$3
                            echo "1. Start Date: ${START_DATE}"
                            shift
                        else
                            printf 'ERROR: "--startdate" requires a non-empty option argument,e.g 2017-12-31 (YYYY-MM-DD).\n' >&2
                        exit 1
                         fi
                        ;;
    --startdate=?*)
                 	START_DATE=${3#*=} # Delete everything up to "=" and assign the remainder.
               		echo "2. Start Date: ${START_DATE}"
           				;;

    --startdate=)       # Handle the case of an empty --startdate=
                        printf 'ERROR: "--startdate" requires a non-empty option argument, e.g 2017-12-31 (YYYY-MM-DD) \n' >&2
                        exit 1
                        ;;

  -ed |	--enddate)  # Takes an option argument, ensuring it has been specified.
       			if [ -n "$4" ]; then
       				END_DATE=$4
               			echo "1. End Date: ${END_DATE}"
               			shift
               			else
                		    printf 'ERROR: "--enddate" requires a non-empty option argument,e.g 2017-12-31 (YYYY-MM-DD).\n' >&2
  	             			exit 1
        		fi
               		;;
    --enddate=?*)
                	END_DATE=${4#*=} # Delete everything up to "=" and assign the remainder.
               		echo "2. End Date: ${END_DATE}"
                  	;;

    --enddate=)         # Handle the case of an empty --enddate=
           		printf 'ERROR: "--enddate" requires a non-empty option argument, e.g 2017-12-31 (YYYY-MM-DD) \n' >&2
           		exit 1
           		;;

    --skipmd5check)	SKIPMD5CHECK=true
    			;;

    			# Delete the ZIPFILE older than 30days
    --deletezip30days)	DELETE_ZIPFILE_30DAYS=true
    					;;

    		        # Force download priority
    --force)		FORCE_DOWNLOAD=true
    					;;
    -v   | --verbose)   VERBOSE=true
    					;;

    -V   | --version)   show_version;
                        exit 0
                        ;;

    --list-only)	LIST_CATALOGUE_ONLY=true
    				;;

    --last-48hours)	LAST_48HOURS_DOWNLOAD=true
    					;;

    *)
        echo "Invalid option: $arg" >&2;
        show_help;
        exit 1
        ;;
   esac
done

# Check 2 arguments are given #
if [ $# -lt 3 ]
then
	echo "Usage: $0 <COUNTRY> [<COUNTRY> can be: --belgium, --capvert, --congo, --cameroon, --domuyo18, --domuyo83,  --erta_ale, --hawaii, --luxembourg, --tanzania, etc...] "
	echo "<productType>:[can be: --slc, --raw, --grd, --ocn] --last-48hours OR --startdate=YYYY-MM-DD --enddate=YYYY-MM-DD"
	echo "NOTE: when using --last-48hours don't use --startdate and --enddate"
    echo "Check with --help to get full list of countrynames"
	echo ""
    exit
fi

##########################################################################################

if [[ ${START_DATE} == *"-DAY"* ]]; then
    # We cut the string at first '-' e.g: 12-DAYS-AGO > result: 12
    DAYS_AGO=$(echo "${START_DATE}" | /usr/bin/cut -f 1 -d '-')
    START_DATE=$(/bin/date -v -"${DAYS_AGO}"d '+%Y-%m-%d')
    echo "${DAYS_AGO} days ago choosen > calculated Start date: ${START_DATE}"

elif [[ ${START_DATE} == *"-WEEK"* ]]; then
    # We cut the string at first '-' e.g: 12-WEEK-AGO > result: 12
    WEEKS_AGO=$(echo "${START_DATE}" | /usr/bin/cut -f 1 -d '-')
    START_DATE=$(/bin/date -v -"${WEEKS_AGO}"w '+%Y-%m-%d')
    echo "$WEEKS_AGO weeks ago choosen > calculated Start date: ${START_DATE}"

elif [[ ${START_DATE} == *"-MONTH"* ]]; then
    # We cut the string at first '-' e.g: 12-MONTHS-AGO > result: 12
    MONTHS_AGO=$(echo "${START_DATE}" | /usr/bin/cut -f 1 -d '-')
    START_DATE=$(/bin/date -v -"${MONTHS_AGO}"m '+%Y-%m-%d')
    echo "$MONTHS_AGO months ago choosen > calculated Start date: ${START_DATE}"

elif [ "${START_DATE}" == "YESTERDAY" ]; then
    START_DATE=$(/bin/date -v -1d '+%Y-%m-%d')
    echo "YESTERDAY ago choosen > calculated Start date: ${START_DATE}"

elif [ "${START_DATE}" == "TODAY" ]; then
 	 START_DATE=$(/bin/date "+%Y-%m-%d")
     echo "Start Date: TODAY > calculated start date: ${START_DATE}"
fi

if [ "${END_DATE}" == "TODAY" ]; then
 	 END_DATE=$(/bin/date "+%Y-%m-%d")
     echo "End Date: TODAY > calculated end date: ${END_DATE}"
fi
##########################################################################################

# Create the local log directory (if not present) to save the log-file locally if Network Disc can't be mounted
if [ ! -e "${HOME}/scripts/logs/" ]
	then
	/bin/mkdir -p "$HOME/scripts/logs/"
	/bin/mkdir -p "$HOME/scripts/logs/sentinel1_disc-mount_error_logs/"
fi

# Check if directory exists
if [ -e "${S1_WORKDIR}" ] && [ -e "${S1_WORKDIR_OTHER}" ] ; then
	echo "${SMB_SHARE_MOUNTED_ON_LOCAL_DIR} mounted and"
	echo "${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER} mounted and , continuing ..."
else
	ERROR_LOG="$HOME/scripts/logs/sentinel1_disc-mount_error_logs/disc-mount_error-$LOG_DATE.log"
	EMAIL_SUBJECT="[${HOSTNAME}] ALERT! Network Disc Mount error ! No Sentinel1 Downloads"

	echo "ALERT! This is script: $0 running on $FULLHOSTNAME" > "${ERROR_LOG}"

	if [ ! -e "${S1_WORKDIR}" ] ; then
		echo "Error: ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR} not mounted! Check the network disc with share-name: $SMB_SHARE_NAME !" >> "${ERROR_LOG}"
	else
		echo "Error: ${SMB_SHARE_MOUNTED_ON_LOCAL_DIR_OTHER} not mounted! Check the network disc with share-name: $SMB_SHARE_NAME_OTHER !" >> "${ERROR_LOG}"
	fi

	echo " There was an error mounting this disc." >> "${ERROR_LOG}"

    # send an email using /usr/bin/mail
	/usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < "${ERROR_LOG}"
    exit 1;
fi

##########################################################################################

# Set the Working-Dir (were zipped files are downloaded) and the Unzip-Dir
ZIP_DOWNLOAD_DIR="${S1_WORKDIR}/S1-DATA-${COUNTRY}-${prodType}"
UNZIP_DIR="${ZIP_DOWNLOAD_DIR}.UNZIP/"

##########################################################################################

# Adapt log dir to avoid clash while running several requests for PF - NdO Oct 12 2020
case ${CHANGELOGDIR} in
    "SM")
        LOG_PATH="${S1_WORKDIR}/S1_COPERNICUS_DOWNLOAD_SM_LOGS/"
        mkdir -p "${LOG_PATH}"  ;;
    "IW")
        LOG_PATH="${S1_WORKDIR}/S1_COPERNICUS_DOWNLOAD_IW_LOGS/"
        mkdir -p "${LOG_PATH}" ;;
    *)
        LOG_PATH="${S1_WORKDIR}/S1_COPERNICUS_DOWNLOAD_LOGS/"
        mkdir -p "${LOG_PATH}" ;;
esac
##########################################################################################

LOG_FILE=${LOG_PATH}"S1-${COUNTRY}-${prodType}_${START_DATE}-to-${END_DATE}_${LOG_DATE}-LOG.txt"
#LOG_SUMMARY=${LOG_PATH}"S1-${COUNTRY}-${prodType}_${START_DATE}-to-${END_DATE}_${LOG_DATE}-SUMMARY.txt"
LOG_SUMMARY_HEADER=${LOG_PATH}"S1-COPERNICUS_summary-header.txt"
LOG_SUMMARY=${LOG_PATH}"S1-COPERNICUS_summary.txt"

LOG_ALL=${LOG_PATH}"S1-${COUNTRY}-${prodType}_${START_DATE}-to-${END_DATE}_${LOG_DATE}-ALL.txt"

#CATALOGUE_LOG_PATH=${LOG_PATH}"S1-CATALOGUE-RESULT/"
#mkdir -p "${CATALOGUE_LOG_PATH}"

LOG_CATALOGUE_RESULT=${LOG_PATH}"S1-${COUNTRY}-${prodType}_${START_DATE}-to-${END_DATE}_${LOG_DATE}_CATALOGUE.json"
QUICKLOOK_FILE_URL=${LOG_PATH}"quicklookURL.txt"

##########################################################################################

# Create the directories if not present
if [ ! -e "${ZIP_DOWNLOAD_DIR}" ]
	then
	/bin/mkdir -p "${ZIP_DOWNLOAD_DIR}"
fi

if [ ! -e "$UNZIP_DIR" ]
    then
    /bin/mkdir -p "$UNZIP_DIR"
fi

if [ ! -e "${LOG_PATH}" ]
    then
    /bin/mkdir -p "${LOG_PATH}"
fi

##########################################################################################
echo "" | ${CMD_TEE} -a "${LOG_FILE}"
echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
echo " DETAILED LOG" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
echo "" | ${CMD_TEE} -a "${LOG_FILE}"

echo "This is script: $0 v${VERSION} running on $FULLHOSTNAME"	| ${CMD_TEE} -a "${LOG_FILE}"
echo "Script execution start date: ${SCRIPT_EXEC_STARTDATE}" 	| ${CMD_TEE} -a "${LOG_FILE}"
echo ""														  	| ${CMD_TEE} -a "${LOG_FILE}"

echo "Command used:"	| ${CMD_TEE} -a "${LOG_FILE}"
echo "$0 $*"			| ${CMD_TEE} -a "${LOG_FILE}"
echo "" 				| ${CMD_TEE} -a "${LOG_FILE}"

echo "Working Dir:"			| ${CMD_TEE} -a "${LOG_FILE}"
echo "${ZIP_DOWNLOAD_DIR}"	| ${CMD_TEE} -a "${LOG_FILE}"
echo "" 					| ${CMD_TEE} -a "${LOG_FILE}"

echo "Unzip Dir:"		| ${CMD_TEE} -a "${LOG_FILE}"
echo "${UNZIP_DIR}"		| ${CMD_TEE} -a "${LOG_FILE}"
echo "" 				| ${CMD_TEE} -a "${LOG_FILE}"

echo "Log saved to:" 	| ${CMD_TEE} -a "${LOG_FILE}"
echo "${LOG_FILE}" 		| ${CMD_TEE} -a "${LOG_FILE}"
echo "" 				| ${CMD_TEE} -a "${LOG_FILE}"

#echo "COPERNICUS Query Result List saved to:"	| ${CMD_TEE} -a "${LOG_FILE}"
#echo "${LOG_CATALOGUE_RESULT}" 					| ${CMD_TEE} -a "${LOG_FILE}"
#echo "" 				   					| ${CMD_TEE} -a "${LOG_FILE}"

##########################################################################################
# EMAIL
##########################################################################################

# Redefine Email Subject
if [ "${LAST_48HOURS_DOWNLOAD}" = true ]; then
	EMAIL_SUBJECT=${EMAIL_SUBJECT}"${COUNTRY} product=${prodType} - 48hours ago"
else
	EMAIL_SUBJECT=${EMAIL_SUBJECT}"${COUNTRY} product=${prodType} - from: ${START_DATE} to: ${END_DATE}"
fi

##########################################################################################

catalogueItems=100
catalogueListOrder="desc"

platformname="SENTINEL-1"

# Generate string with sensormode_prodType__1S e.g: IW_SLC__1S
SENSORMODE_PRODTYPE="${sensormode}_${prodType}__1S"

##########################################################################################


#	-11	| --domuyo83)	COUNTRY="DOMUYO"
#polygon="POLYGON((-70.6898267839218 -36.90762895618818,-70.03362627002683 -36.89749957901811,-70.09693399654567 -36.05291395012518,-70.71831691721114 -36.06796170586554,-70.6898267839218 -36.90762895618818))"
#sensormode="IW AND relOrbitNumber=83)"
#ZIP_DOWNLOAD_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO-SLC"
#orbitDirection="DESCENDING"
#relOrbitNumber="83"
#sensormode="IW"
#prodType="SLC"

#orbitDirection="ASCENDING"
#relOrbitNumber="174"

#orbitDirection="DESCENDING"
#relOrbitNumber="21"

#START_DATE="2023-11-03T00:00:00.000Z"
#END_DATE="2023-12-06T00:00:00.000Z"

##########################################################################################

# this works
# CURL_CATALOGUE_QUERY="https://catalogue.dataspace.copernicus.eu/odata/v1/Products?\$filter=OData.CSC.Intersects(area=geography'SRID=4326;POLYGON((12.655118166047592 47.44667197521409,21.39065656328509 48.347694733853245,28.334291357162826 41.877123516783655,17.47086198383573 40.35854475076158,12.655118166047592 47.44667197521409))') and ContentDate/Start gt 2022-05-20T00:00:00.000Z and ContentDate/Start lt 2022-05-21T00:00:00.000Z"

## QUERY CURL CATALOGUE - prepare OPTIONS
#CURL_CAT_OPT="https://catalogue.dataspace.copernicus.eu/odata/v1/Products?\$filter="
#CURL_CAT_OPT+="Collection/Name eq '${platformname}'"
#CURL_CAT_OPT+=" and OData.CSC.Intersects(area=geography'SRID=4326;${polygon}')"
#CURL_CAT_OPT+=" and PublicationDate gt ${START_DATE} and PublicationDate lt ${END_DATE}&\$orderby=PublicationDate ${catalogueListOrder}"
#CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq '${prodType}')"
#CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'orbitDirection' and att/OData.CSC.StringAttribute/Value eq '${orbitDirection}')"
#CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'operationalMode' and att/OData.CSC.StringAttribute/Value eq '${sensormode}')"
#CURL_CAT_OPT+="&\$top=${catalogueItems}"
#CURL_CATALOGUE_QUERY="${CURL_CAT_OPT}"


function get_curl_catalogue_with_orbitnumber() {
    local CURL_CAT_OPT=""
    ## To get all attributes (e.g to get relativeOrbitNumber) -  example from ESA Copernicus Support Team - Friday 2023.11.24:
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?&$filter=(startswith(Name,'S1') and (contains(Name,'SLC')) and ((Online eq false or Online eq true) and Attributes/OData.CSC.IntegerAttribute/any(att:att/Name eq 'relativeOrbitNumber' and att/OData.CSC.IntegerAttribute/Value eq 122))) and ContentDate/Start ge 2022-01-01T00:00:00.000Z and ContentDate/Start lt 2022-01-25T23:59:59.999Z&$orderby=ContentDate/Start 
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?&$filter=
    # (startswith(Name,'S1') and (contains(Name,'SLC')) and ((Online eq false or Online eq true)
    # and Attributes/OData.CSC.IntegerAttribute/any(att:att/Name eq 'relativeOrbitNumber'
    # and att/OData.CSC.IntegerAttribute/Value eq 122)))
    # and ContentDate/Start ge 2022-01-01T00:00:00.000Z
    # and ContentDate/Start lt 2022-01-25T23:59:59.999Z
    # &$orderby=ContentDate/Start

    # With relativeOrbitNumber - expand assets to get the quicklook-file URL-address
    CURL_CAT_OPT="https://catalogue.dataspace.copernicus.eu/odata/v1/Products?&\$filter="
    CURL_CAT_OPT+="OData.CSC.Intersects(area=geography'SRID=4326;${polygon}')"
    CURL_CAT_OPT+=" and (startswith(Name,'S1') and (contains(Name,'${prodType}'))"
    CURL_CAT_OPT+=" and ((Online eq true)"
    CURL_CAT_OPT+=" and Attributes/OData.CSC.IntegerAttribute/any(att:att/Name eq 'relativeOrbitNumber'"
    CURL_CAT_OPT+=" and att/OData.CSC.IntegerAttribute/Value eq ${relOrbitNumber})))"
    CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'orbitDirection' and att/OData.CSC.StringAttribute/Value eq '${orbitDirection}')"
    CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'operationalMode' and att/OData.CSC.StringAttribute/Value eq '${sensormode}')"
    CURL_CAT_OPT+=" and PublicationDate gt ${START_DATE}T00:00:00.000Z"
    CURL_CAT_OPT+=" and PublicationDate lt ${END_DATE}T23:59:59.999Z"
    CURL_CAT_OPT+="&\$orderby=ContentDate/Start ${catalogueListOrder}"
    CURL_CAT_OPT+="&\$count=false"
    #CURL_CAT_OPT+="&\$expand=Attributes"
    CURL_CAT_OPT+="&\$expand=Assets"
    CURL_CAT_OPT+="&\$top=${catalogueItems}"

    # Replace SPACE with char %20
    CURL_CAT_OPT="${CURL_CAT_OPT// /%20}"
    # Replace ' with char %27
    CURL_CAT_OPT="${CURL_CAT_OPT//\'/%27}"
    # Return type for this function
    echo "${CURL_CAT_OPT}"
}

function get_curl_catalogue_without_orbitnumber() {
    local CURL_CAT_OPT=""

    # 2023.12.14 - reply from ESA request ID  1885 - https://helpcenter.dataspace.copernicus.eu/hc/en-gb/requests/1885
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?&$filter=(startswith(Name,'S1') and (contains(Name,'SLC')) and ((Online eq false or Online eq true))) and ContentDate/Start ge 2022-01-01T00:00:00.000Z and ContentDate/Start lt 2022-01-25T23:59:59.999Z&$orderby=ContentDate/Start
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?&$filter=(startswith(Name,'S1') and (contains(Name,'SLC'))
    # and ((Online eq false or Online eq true)))
    # and ContentDate/Start ge 2022-01-01T00:00:00.000Z and ContentDate/Start lt 2022-01-25T23:59:59.999Z&$orderby=ContentDate/Start


    # 2023.12.05 - To get Catalogue without (knowing) relativeOrbitNumer (from ESA Copernicus support team 2023.12.05) - e.g Luxembourg
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$filter=Collection/Name eq 'SENTINEL-1' and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq 'IW_SLC__1S') and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'orbitDirection' and att/OData.CSC.StringAttribute/Value eq 'ASCENDING') and (OData.CSC.Intersects(area=geography'SRID=4326;POLYGON((2.4495477846656244 51.09857384337633,3.404380618761151 51.42802325283006,4.555534222483794 51.555813466481226,5.198038559445268 51.51140532353608,7.134475241676382 50.91890083858132,6.313497477781164 50.06165685491578,6.679368002995337 49.618519748347836,8.169621117892092 49.1362978376153,7.812674264024606 48.76711197844659,6.715062688382086 48.82589534889004,6.313497477781164 49.0895684890138,6.099329365460672 49.34022139167058,5.474672371192572 49.34022139167058,5.028488803858213 49.68207378905507,4.716160306724163 49.80893300681208,4.153969011882872 49.906733443756224,3.9219535568690054 50.07311281836337,3.984419256295816 50.19894786989019,3.5917777170415803 50.26744571831401,3.0474337648936642 50.60279667420565,2.556631840825871 50.78368908203797,2.4495477846656244 51.09857384337633,2.4495477846656244 51.09857384337633))') and ContentDate/Start gt 2022-05-14T00:00:00.000Z) and ContentDate/Start lt 2022-05-21T00:00:00.000Z&$orderby=ContentDate/Start&$count=True&$expand=Attributes
    # https://catalogue.dataspace.copernicus.eu/odata/v1/Products?$filter=
    # Collection/Name eq 'SENTINEL-1'
    # and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq 'IW_SLC__1S')
    # and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'orbitDirection' and att/OData.CSC.StringAttribute/Value eq 'ASCENDING')
    # and (OData.CSC.Intersects(area=geography'SRID=4326;POLYGON((2.4495477846656244 51.09857384337633,3.404380618761151 51.42802325283006,4.555534222483794 51.555813466481226,5.198038559445268 51.51140532353608,7.134475241676382 50.91890083858132,6.313497477781164 50.06165685491578,6.679368002995337 49.618519748347836,8.169621117892092 49.1362978376153,7.812674264024606 48.76711197844659,6.715062688382086 48.82589534889004,6.313497477781164 49.0895684890138,6.099329365460672 49.34022139167058,5.474672371192572 49.34022139167058,5.028488803858213 49.68207378905507,4.716160306724163 49.80893300681208,4.153969011882872 49.906733443756224,3.9219535568690054 50.07311281836337,3.984419256295816 50.19894786989019,3.5917777170415803 50.26744571831401,3.0474337648936642 50.60279667420565,2.556631840825871 50.78368908203797,2.4495477846656244 51.09857384337633,2.4495477846656244 51.09857384337633))')
    # and ContentDate/Start gt 2022-05-14T00:00:00.000Z)
    # and ContentDate/Start lt 2022-05-21T00:00:00.000Z
    # &$orderby=ContentDate/Start
    # &$count=True&$expand=Attributes
    
    # Without knowing or setting the orbitNumber - Expand assets to get the quicklook-file URL-address

    CURL_CAT_OPT="https://catalogue.dataspace.copernicus.eu/odata/v1/Products?\$filter="
    CURL_CAT_OPT+="Collection/Name eq 'SENTINEL-1'"
    CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq '${SENSORMODE_PRODTYPE}')"
    CURL_CAT_OPT+=" and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'orbitDirection' and att/OData.CSC.StringAttribute/Value eq '${orbitDirection}')"
    CURL_CAT_OPT+=" and (OData.CSC.Intersects(area=geography'SRID=4326;${polygon}')"
    CURL_CAT_OPT+=" and ContentDate/Start gt ${START_DATE}T00:00:00.000Z)"
    CURL_CAT_OPT+=" and ContentDate/Start lt ${END_DATE}T23:59:59.999Z"
    CURL_CAT_OPT+="&\$orderby=ContentDate/Start ${catalogueListOrder}"
    CURL_CAT_OPT+="&\$count=false"
    #CURL_CAT_OPT+="&\$expand=Attributes"
    CURL_CAT_OPT+="&\$expand=Assets"
    CURL_CAT_OPT+="&\$top=${catalogueItems}"
    
    # Replace SPACE with char %20
    CURL_CAT_OPT="${CURL_CAT_OPT// /%20}"

    # Replace ' with char %27
    CURL_CAT_OPT="${CURL_CAT_OPT//\'/%27}"
    
    # Return type for this function
    echo "${CURL_CAT_OPT}"
}

#echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "" | ${CMD_TEE} -a "${LOG_FILE}"
echo "Getting catalogue of Product-IDs...." | ${CMD_TEE} -a "${LOG_FILE}"
#echo "" | ${CMD_TEE} -a "${LOG_FILE}"

if [[ -z $relOrbitNumber ]]; then
    #echo "Orbit Number not provided" | ${CMD_TEE} -a "${LOG_FILE}"
    CURL_CAT_OPT=$(get_curl_catalogue_without_orbitnumber)
    #echo "CURL CATALOGUE OPTION: ${CURL_CAT_OPT}}"
else
    #echo "relativeOrbitNumber provided: ${relOrbitNumber}" | ${CMD_TEE} -a "${LOG_FILE}"
    CURL_CAT_OPT=$(get_curl_catalogue_with_orbitnumber)
    #echo "CURL CATALOGUE OPTION: ${CURL_CAT_OPT}"
fi

#echo "Generated catalogue URL - can be copy/pasted to a Web-Browser:" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "${CURL_CAT_OPT}" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "" | ${CMD_TEE} -a "${LOG_FILE}"

#${CMD_CURL} "${CURL_CAT_OPT}" -H "Accept: application/json" > "${LOG_CATALOGUE_RESULT}"

#CATALOG_QUERY_OUTPUT=$(${CMD_CURL} "${CURL_CAT_OPT}" -H "Accept: application/json" > "${LOG_CATALOGUE_RESULT}")

#echo "------------------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "CATALOG_QUERY_OUTPUT: ${CATALOG_QUERY_OUTPUT}" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "-----------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
#echo "" | ${CMD_TEE} -a "${LOG_FILE}"

# Print all found ProductIDs

${CMD_CURL} "${CURL_CAT_OPT}" -H "Accept: application/json" > "${LOG_CATALOGUE_RESULT}"

# Create an array with ($(command)) and filter JSON by .value.[].Id 
# try JSON extraction with 'jq' with https://jqplay.org/
declare -a productIDArray
declare -a productNameArray
declare -a remoteZipFileSizeArray
declare -a productFilePublicatioDateArray
declare -a quicklookFilesArray

# Bash - prefer mapfile to fill array - see: https://www.shellcheck.net/wiki/SC2207
mapfile -t productIDArray < <($CMD_JQ --raw-output '.value.[].Id' "${LOG_CATALOGUE_RESULT}")
mapfile -t productNameArray < <($CMD_JQ --raw-output '.value.[].Name' "${LOG_CATALOGUE_RESULT}")
mapfile -t remoteZipFileSizeArray < <($CMD_JQ --raw-output '.value.[].ContentLength' "${LOG_CATALOGUE_RESULT}")
mapfile -t productFilePublicatioDateArray < <($CMD_JQ --raw-output '.value.[].PublicationDate' "${LOG_CATALOGUE_RESULT}")
mapfile -t quicklookFilesArray < <($CMD_JQ --raw-output '.value.[].Assets.[].DownloadLink' "${LOG_CATALOGUE_RESULT}")

echo "" | ${CMD_TEE} -a "${LOG_FILE}"

echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
echo "List of Products found from ${START_DATE} to ${END_DATE}" | ${CMD_TEE} -a "${LOG_FILE}"
echo "" | ${CMD_TEE} -a "${LOG_FILE}"

numberOfProducts=${#productIDArray[@]}

echo "-Nr - | -- Product-ID ---------------------- | -- ProductName --------------------------------------------------------- | - Size --- | - Publishing Date ------ |" | ${CMD_TEE} -a "${LOG_FILE}"

for ((i=0; i < numberOfProducts; i++));
do
    #printf "[%03d]: ${productIDArray[$i]} | ${productNameArray[$i]} | ${remoteZipFileSizeArray[$i]} | ${productFilePublicatioDateArray[$i]} | ${quicklookFilesArray[$i]}\n" ${i} | ${CMD_TEE} -a "${LOG_FILE}"
    printf "[%03d] | ${productIDArray[$i]} | ${productNameArray[$i]} | ${remoteZipFileSizeArray[$i]} | ${productFilePublicatioDateArray[$i]} \n" $((i+1)) | ${CMD_TEE} -a "${LOG_FILE}"
done

#echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"

echo "" | ${CMD_TEE} -a "${LOG_FILE}"
   

##########################################################################################
# DOWNLOAD 
##########################################################################################

if [[ "$LIST_CATALOGUE_ONLY" = false ]];
then
    echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "PROCESSING DOWNLOADS" | ${CMD_TEE} -a "${LOG_FILE}" 
    # Prepare productFile download by generating the required ACCESS_TOKEN
    echo "Getting new access token..." | ${CMD_TEE} -a "${LOG_FILE}"

    # See: https://documentation.dataspace.copernicus.eu/APIs/OData.html#product-download
    RAW_ACCESS_TOKEN=$(${CMD_CURL} -d 'client_id=cdse-public' \
                                -d "username=${USERNAME}" -d "password=${PASSWORD}" \
                                -d 'grant_type=password' \
                                'https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token') > access_token.txt
    # We use the simpler "jq" command (Copernicus website uses 'Python3' and 'awk' to extract "access_token")
    access_token_with_quotes=$(echo "${RAW_ACCESS_TOKEN}" | $CMD_JQ '.access_token')

    # Remove double-quotes
    ACCESS_TOKEN="${access_token_with_quotes//\"/}"

    REFRESH_TOKEN_WITH_QUOTES=$(echo "${RAW_ACCESS_TOKEN}" | $CMD_JQ '.refresh_token')
    # Remove double-quotes
    REFRESH_TOKEN="${REFRESH_TOKEN_WITH_QUOTES//\"/}"

    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo "Acces Token: ${ACCESS_TOKEN}" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo "Refresh Token: ${REFRESH_TOKEN}" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"

    # Reset bash built-n "SECONDS"
    SECONDS=0

    # Acces time limit in seconds (10 minutes)
    # After this time limit continue to download with the refreshed ACCESS TOKEN
    ACCESS_TOKEN_TIME_LIMIT_IN_SECONDS=600
    
    #TOKEN_REFRESHED=false
    download_required=false

    declare -a downloadedFilesArray # succesfully downloaded product files
    declare -a downloadedFileSizeArray
    declare -a failedDownloadsArray
    declare -a unzippedFilesArray
    declare -a failedUnzippedFilesArray

    echo "" | ${CMD_TEE} -a "${LOG_FILE}"
    
    for (( i=0; i < numberOfProducts; i++ ));
    do
        prodID="${productIDArray[$i]}"              # e.g: 7d96670d-8229-4041-ab36-f43163bb6f38
        prodName="${productNameArray[$i]}"          # e.g: S1A_IW_SLC__1SDV_20231211T095725_20231211T095752_051605_063B0A_B6F1.SAFE
        zippedProdName="${prodName}.zip"            # e.g: S1A_IW_SLC__1SDV_20231211T095725_20231211T095752_051605_063B0A_B6F1.SAFE.zip
        prodSize="${remoteZipFileSizeArray[$i]}"    # e.g.:  8143757724

        printf "+-[%03d]:${prodID} | ${prodName} | ${prodSize}\n" $((i+1)) | ${CMD_TEE} -a "${LOG_FILE}"

        echo "+--Checking local presence of zipped product file..." | ${CMD_TEE} -a "${LOG_FILE}"

        if [ -e "${ZIP_DOWNLOAD_DIR}/${zippedProdName}" ]; then
            echo "+--Local file exists!" | ${CMD_TEE} -a "${LOG_FILE}"
            localZipFileSize=$(${CMD_GNU_STAT} -c %s "${ZIP_DOWNLOAD_DIR}/${zippedProdName}")
            echo "+--Local file size = ${localZipFileSize} | Remote file size: ${prodSize}" | ${CMD_TEE} -a "${LOG_FILE}"

            if [ "${localZipFileSize}" -ne "${prodSize}" ];
            then
                echo "+--Local file: ${zippedProdName} not correctly downloaded!" | ${CMD_TEE} -a "${LOG_FILE}"
                echo "+--Deleting local file: ${zippedProdName} (server doesn't support resume download)." | ${CMD_TEE} -a "${LOG_FILE}"
                echo "+--Will be downloaded next."  | ${CMD_TEE} -a "${LOG_FILE}"
                /bin/rm "${ZIP_DOWNLOAD_DIR}/${zippedProdName}"
                download_required=true
            else
                echo "+--No download required: Local and remote file sizes matches." | ${CMD_TEE} -a "${LOG_FILE}"
                echo "" | ${CMD_TEE} -a "${LOG_FILE}"
                download_required=false
            fi
        else
            echo "+--Remote product file not downloaded yet." | ${CMD_TEE} -a "${LOG_FILE}"
            download_required=true
        fi  

        if [[ ${download_required} = true ]];
        then 

            echo "+--Trying to download remote product file..." | ${CMD_TEE} -a "${LOG_FILE}"
                       
            if [[ SECONDS -ge $ACCESS_TOKEN_TIME_LIMIT_IN_SECONDS ]];
            then
            
                echo "+->$SECONDS seconds since last download(s) passed, refeshing access token..." | ${CMD_TEE} -a "${LOG_FILE}"
                
                # Generate a new refresh token with previous REFRESH_TOKEN
                RAW_REFRESHED_TOKEN=$(${CMD_CURL} --location --request POST \
                    'https://identity.dataspace.copernicus.eu/auth/realms/CDSE/protocol/openid-connect/token' \
                    -H 'Content-Type: application/x-www-form-urlencoded' \
                    -d 'grant_type=refresh_token' \
                    -d "refresh_token=${REFRESH_TOKEN}" \
                    -d 'client_id=cdse-public')

                # Extract the new refreshed token, remove double-quotes and set ACCESS_TOKEN with refreshed token
                # We use the simpler "jq" command (Copernicus website uses 'Python3' and 'awk' to extract "access_token")
                #REFRESHED_TOKEN_WITH_QUOTES=$(echo ${RAW_REFRESHED_TOKEN} | jq '.refresh_token')
                REFRESHED_ACCESS_TOKEN_WITH_QUOTES=$(echo "${RAW_REFRESHED_TOKEN}" | $CMD_JQ '.access_token')
                
                # Remove double-quotes and set ACCESS_TOKEN with REFRESHED_TOKEN
                ACCESS_TOKEN="${REFRESHED_ACCESS_TOKEN_WITH_QUOTES//\"/}"

                # RESET time & token since we have to refresh the token after 3600s
                # set SECONDS to Zero and ACCESS_TOKEN_TIME_LIMIT_IN_SECONDS to 1h (3600s)
                #SECONDS=0
                ACCESS_TOKEN_TIME_LIMIT_IN_SECONDS=3600
            fi

            curl_prod_opts=( -H \"Authorization: Bearer "${ACCESS_TOKEN}"\" 
                        "'https://catalogue.dataspace.copernicus.eu/odata/v1/Products("${prodID}")/\$value'" 
                        "--location-trusted --output ${ZIP_DOWNLOAD_DIR}/${zippedProdName}")

            #echo "curl_prod_opts: => ${curl_prod_opts[*]} <="
            #eval "${CMD_CURL}" --fail "${curl_prod_opts[*]}"

            if  eval "${CMD_CURL}" --fail "${curl_prod_opts[*]}"; then
                
                echo "+--SUCCESS! Download done." | ${CMD_TEE} -a "${LOG_FILE}"
                downloadedFilesArray+=("${zippedProdName}")
                downloadedFileSizeArray+=("${prodSize}")

                # Quicklook file URL: curl and wget have problems to read dollar signs (need tp convert /$value to /\$value )
                # get Quicklook file URL - if we store the URL to a file we can read it with 'wget -i'
                # https://catalogue.dataspace.copernicus.eu/odata/v1/Assets(6fe22346-965c-41e2-9ac4-e2b604e40a4c)/$value
                quicklookURL=${quicklookFilesArray[$i]}
                echo "${quicklookURL}" > "${QUICKLOOK_FILE_URL}"

                quicklookFileName="${prodName}.png"
                #echo "+--DEBUG: Downloading Quicklook file from  URL: ${quicklookURL}" | ${CMD_TEE} -a "${LOG_FILE}"
                echo "+--Downloading Quicklook file: ${quicklookFileName}" | ${CMD_TEE} -a "${LOG_FILE}"
                
                # Since the URL contains a dollar sign at the end with "$value" read the file with '-i'
                ${CMD_WGET} -O "${ZIP_DOWNLOAD_DIR}/${quicklookFileName}" -i "${QUICKLOOK_FILE_URL}"
                # Remove the quicklook file
                /bin/rm "${QUICKLOOK_FILE_URL}"
            else 
                echo "+-FAIL! Download failed for ${zippedProdName}" | ${CMD_TEE} -a "${LOG_FILE}"
                echo "+--Deleting failed downloaded Zip-file." | ${CMD_TEE} -a "${LOG_FILE}"
                /bin/rm "${ZIP_DOWNLOAD_DIR}/${zippedProdName}"
                failedDownloadsArray+=("${zippedProdName}")
                
            fi

            secs=$SECONDS
            hrs=$(( secs/3600 )); mins=$(( (secs-hrs*3600)/60 )); secs=$(( secs-hrs*3600-mins*60 ))
            printf '+--Download time spent: %02d:%02d:%02d\n' $hrs $mins $secs | ${CMD_TEE} -a "${LOG_FILE}"
            echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
            echo "" | ${CMD_TEE} -a "${LOG_FILE}"        
        fi
    done

    #echo "" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo " END PROCESSING DOWNLOADS" | ${CMD_TEE} -a "${LOG_FILE}" 
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "" | ${CMD_TEE} -a "${LOG_FILE}"
    

   
    ##########################################################################################
    # Unzip files 
    ##########################################################################################
    
    numberOfDownloadedFiles=${#downloadedFilesArray[@]}

    if [[ $numberOfDownloadedFiles -gt 0 ]]; then

    echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "UNZIPPING FILES" | ${CMD_TEE} -a "${LOG_FILE}" 
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "" | ${CMD_TEE} -a "${LOG_FILE}"

    echo "+-Trying to unzip ${numberOfDownloadedFiles} files to ${UNZIP_DIR}" | ${CMD_TEE} -a "${LOG_FILE}"

        for (( i=0; i < numberOfDownloadedFiles; i++ ));
        do
            #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
            prodFileToUnzip="${downloadedFilesArray[$i]}"
            remoteZipFileSize="${downloadedFileSizeArray[$i]}"

            printf "+-[%03d]: ${prodFileToUnzip} with size: ${remoteZipFileSize} bytes \n" $((i+1)) | ${CMD_TEE} -a "${LOG_FILE}"

            # Check if unzipped directory exists - we need to remove .zip from prodFileToUnzip
            # e.g prodFileToUnzip: S1A_IW_SLC__1SDV_20231211T095659_20231211T095727_051605_063B0A_4A67.SAFE.zip
            # after: unzippedProdName: S1A_IW_SLC__1SDV_20231211T095659_20231211T095727_051605_063B0A_4A67.SAFE
            unzippedProdName="${prodFileToUnzip//.zip//}"
            
            unzippedProdNameDirectory="${UNZIP_DIR}${unzippedProdName}"

            if [[  -d "${unzippedProdNameDirectory}" ]]; then
					echo "+-UnZip-Dir: ${unzippedProdNameDirectory}  exists !" | ${CMD_TEE} -a "${LOG_FILE}"
      				
                    localDirSize=$(${CMD_DU} "${unzippedProdNameDirectory}" | cut -f1 )
					echo "+-UnZip-Dir size in bytes: ${localDirSize}" | ${CMD_TEE} -a "${LOG_FILE}"

                if [[ "${localDirSize}" -ge "${remoteZipFileSize}" ]]; then
                    echo "+-Unzip-Dir size is bigger or equal to remote Zip-File, seems OK." | ${CMD_TEE} -a "${LOG_FILE}"
                    echo "+-UnZipping product file not required."  | ${CMD_TEE} -a "${LOG_FILE}"

                elif [[ "${localDirSize}" -lt "${remoteZipFileSize}" ]]; then
                    echo "+-Unzip-Dir is smaller than size of ${prodFileToUnzip}"  | ${CMD_TEE} -a "${LOG_FILE}"
                    echo "+-Unzip-Dir size ${localDirSize} | Zip-File size: ${remoteZipFileSize}"
                    hrs=$(( secs/3600 )); mins=$(( (secs-hrs*3600)/60 )); secs=$(( secs-hrs*3600-mins*60 ))
                    unzipRatio=$(( localDirSize / remoteZipFileSize))
                    #echo "+--Unzip-Dir is probably OK. Please check its content manually."  | ${CMD_TEE} -a "${LOG_FILE}"
                    
                    echo "+-Unzip Ratio: $unzipRatio"
                    # In Bash - decimals are not supported. Either use integers only, or use bc or awk to compare.
                    # https://www.shellcheck.net/wiki/SC2072
                    if [[ $(echo "${unzipRatio} <= 0.90" | bc) == 1 ]]; then
                        echo "+--Unzip-Ratio is <= 0.90: Unzip-Dir seems to have missing or corrupted files, please check content."  | ${CMD_TEE} -a "${LOG_FILE}"
                    else
                        echo "+--Unzip-Dir is probably OK, please check manually."  | ${CMD_TEE} -a "${LOG_FILE}"
                    fi
                fi    
            else
                echo "+--Trying to unzip file: ${prodFileToUnzip} to ${UNZIP_DIR}/" | ${CMD_TEE} -a "${LOG_FILE}"
                ${CMD_UNZIP} "${ZIP_DOWNLOAD_DIR}/${prodFileToUnzip}" -o"${UNZIP_DIR}"
                unzipReturnVal=$?
                if [ "${unzipReturnVal}" -eq 0 ]; then
                    echo "+--Unzipping done for Zip-File: ${prodFileToUnzip}" | ${CMD_TEE} -a "${LOG_FILE}"
                    unzippedFilesArray+=("${prodFileToUnzip}")
                else
                    printf "+--Fatal Error unzipping file ${prodFileToUnzip}. Skipping!" | ${CMD_TEE} -a "${LOG_FILE}"
                    echo "+--Zipped file ${prodFileToUnzip} will be deleted and redownloaded by next launch."
                    failedUnzippedFilesArray+=("${prodFileToUnzip}")
                fi # END -- if [ ${unzipReturnVal} -eq "0" ];
            fi
            echo "" | ${CMD_TEE} -a "${LOG_FILE}"
        done
    
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    #echo "END UNZIPPING FILES" | ${CMD_TEE} -a "${LOG_FILE}" 
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"

    fi  # unzipping files

    #echo "" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_FILE}"
    echo " Done for ${platformname} ${COUNTRY} ${prodType} $sensormode $relOrbitNumber $orbitDirection" | ${CMD_TEE} -a "${LOG_FILE}"
    echo " in dir: ${ZIP_DOWNLOAD_DIR}" | ${CMD_TEE} -a "${LOG_FILE}"
    echo "" | ${CMD_TEE} -a "${LOG_FILE}"
    
    ##########################################################################################
    # SUMMARY Header
    ##########################################################################################

    # Create LOG Summary - use a redirect to file - do not append to file with 'tee' command for the first line since it can generate null character
    echo "${platformname} download process done for ${COUNTRY} | productType:${prodType}" > "${LOG_SUMMARY_HEADER}"
    echo "sensormode=$sensormode | relativeOrbitNumber:$relOrbitNumber | orbitDirection:$orbitDirection" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "Catalog query Start Date:${START_DATE} to End Date:${END_DATE}" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "Elapsed time: $((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds." | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "Working dir: ${ZIP_DOWNLOAD_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    echo "Log file written to: ${LOG_ALL}"
    echo "" | ${CMD_TEE} -a "${LOG_SUMMARY_HEADER}"
    
    ##########################################################################################
    # SUMMARY various infos
    ##########################################################################################
    echo "--------------------------------------------" | ${CMD_TEE} "${LOG_SUMMARY}" # note not -a for appending
    echo "SUMMARY" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    
    numberOfDownloadedFiles=${#downloadedFilesArray[@]}

    if [[ numberOfDownloadedFiles -gt 0 ]]; then
        # For the first echo don't append to the summary log or else it will append to previous summary file.
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "+-Total of downloaded files: $numberOfDownloadedFiles" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "+--Succesfully downloaded the following files in ${ZIP_DOWNLOAD_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        
        for (( i=0; i < numberOfDownloadedFiles; i++ ));
        do
            printf "+->[%03d]: ${downloadedFilesArray[$i]} \n" $((i+1)) | ${CMD_TEE} -a "${LOG_SUMMARY}"
        done
    else
        # For the first echo don't append to the summary log or else it will append to previous summary file.    
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "* No product file(s) downloaded." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    fi

    numberOfFailedDownloads=${#failedDownloadsArray[@]}
    if [[ numberOfFailedDownloads -gt 0 ]]; then
        
        # For the first echo don't append to the summary log or else it will append to previous summary file.
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "+-Total of failed downloads: $numberOfFailedDownloads" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "+--Failed downloads of the following files in: ${ZIP_DOWNLOAD_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        
        for (( i=0; i < numberOfFailedDownloads; i++ ));
        do
            printf "+->[%03d]:${failedDownloadsArray[$i]} \n" $((i+1)) | ${CMD_TEE} -a "${LOG_SUMMARY}"
        done
    else
        # For the first echo don't append to the summary log or else it will append to previous summary file.    
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "* No failed downloads reported." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    fi

    
    numberOfUnzippedFiles=${#unzippedFilesArray[@]}
    if [[ numberOfUnzippedFiles -gt 0 ]]; then
        # For the first echo don't append to the summary log or else it will append to previous summary file.          
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "+-Total of unzipped files: $numberOfUnzippedFiles." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 

        echo "+--Unzipped the following product files in ${UNZIP_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        for (( i=0; i < numberOfUnzippedFiles; i++ ));
        do
            printf "+->[%03d]:${unzippedFilesArray[$i]} \n" $((i+1)) | ${CMD_TEE} -a "${LOG_SUMMARY}"
        done
   
    else
        # For the first echo don't append to the summary log or else it will append to previous summary file.    
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "* No product files unzipped." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    fi
    
    

    numberOfFailedUnzippedFiles=${#failedUnzippedFilesArray[@]}

    if [[ numberOfFailedUnzippedFiles -gt 0 ]]; then
        # For the first echo don't append to the summary log or else it will append to previous summary file.          
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "+-Failed unzipped files: " | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "+-Total of failed unzipped files: ${numberOfFailedUnzippedFiles}." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "+-Failed to unzip these files in ${UNZIP_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY}"

        for (( i=0; i < numberOfFailedUnzippedFiles; i++ ));
        do
            printf "+->[%03d]:${failedUnzippedFilesArray[$i]} \n" $((i+1)) | ${CMD_TEE} -a "${LOG_SUMMARY}"
        done
    else
        # For the first echo don't append to the summary log or else it will append to previous summary file.    
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
        echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}" 
        echo "* No failed unzipped files reported." | ${CMD_TEE} -a "${LOG_SUMMARY}"
        #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    fi

    echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    echo "Processing done in: ${ZIP_DOWNLOAD_DIR}" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    echo "Log file written to: ${LOG_ALL}"

    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    #echo "END SUMMARY" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    #echo "--------------------------------------------" | ${CMD_TEE} -a "${LOG_SUMMARY}"
    #echo "" | ${CMD_TEE} -a "${LOG_SUMMARY}"

    # Combine the summary header and summary log and the log file together into LOG_ALL
    /bin/cat "${LOG_SUMMARY_HEADER}" "${LOG_SUMMARY}" "${LOG_FILE}" > "${LOG_ALL}"
    # Remove the logs - just leave the LOG_ALL
    /bin/rm "${LOG_SUMMARY_HEADER}"
    /bin/rm "${LOG_SUMMARY}"
    /bin/rm "${LOG_FILE}"
    /bin/rm "${LOG_CATALOGUE_RESULT}"


    if [[ $numberOfDownloadedFiles -gt 0 ]]; then
        /usr/bin/mail -s "${EMAIL_SUBJECT}" "${EMAIL_RECIPIENTS}" < "${LOG_ALL}"
    fi

fi # END - if [[ LIST_QUERY_ONLY = false ]]
