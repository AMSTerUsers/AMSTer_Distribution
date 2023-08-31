#!/bin/sh

# This script deletes the Sentinel-1 ZIP & PNG files older than 120 days on the 
# HP-D3600 in dir: SAR_DATA/S1/
# Mounted path: /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/
#
# Version: 1.0 - 20190717
#

workingDirArray=("/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DRCONGO-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-TRISTAN-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_A18"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_D83")

for i in "${workingDirArray[@]}"
do
   : 
   # do whatever on $i
   echo "Processing dir: $i"
   echo "Deleting Sentinel1-ZIP files older than 120 days in ${i}"
   /usr/bin/find ${i} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
   echo "Deleting Sentinel1-Quicklook PNG files older than 120 days in ${i}"
   /usr/bin/find ${i} -type f -name "*.png" -mtime +120 -exec rm -v {} \;
   echo "-------------------------------------------------------------------------------------------------------------"
   
done				  

echo "Done!"

# --------------------------------------------------------------------------------------------------
#WORKING_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DRCONGO-SLC"
##/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DRCONGO-SLC -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
##/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DRCONGO-SLC -type f -name "*.png" -mtime +120 -exec rm -v {} \;
#echo "Deleting ZIP files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;

#echo "Deleting PNG files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.png" -mtime +120 -exec rm -v {} \;

# --------------------------------------------------------------------------------------------------
#WORKING_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC"
##/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
##/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC -type f -name "*.png" -mtime +120 -exec rm -v {} \;
#echo "Deleting ZIP files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;

#echo "Deleting PNG files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.png" -mtime +120 -exec rm -v {} \;

# --------------------------------------------------------------------------------------------------
#WORKING_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-TRISTAN-SLC"
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-TRISTAN-SLC -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-TRISTAN-SLC -type f -name "*.png" -mtime +120 -exec rm -v {} \;
#echo "Deleting ZIP files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;

#echo "Deleting PNG files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.png" -mtime +120 -exec rm -v {} \;

# --------------------------------------------------------------------------------------------------
#WORKING_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_A18"
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_A18 -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_A18 -type f -name "*.png" -mtime +120 -exec rm -v {} \;
#echo "Deleting ZIP files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;

#echo "Deleting PNG files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.png" -mtime +120 -exec rm -v {} \;

# --------------------------------------------------------------------------------------------------
#WORKING_DIR="/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_D83"
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_D83 -type f -name "*.zip" -mtime +120 -exec rm -v {} \;
#/usr/bin/find /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO/Domuyo_D83 -type f -name "*.png" -mtime +120 -exec rm -v {} \;
#echo "Deleting ZIP files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.zip" -mtime +120 -exec rm -v {} \;

#echo "Deleting PNG files older than 120 days in ${WORKING_DIR}"
#/usr/bin/find ${WORKING_DIR} -type f -name "*.png" -mtime +120 -exec rm -v {} \;

