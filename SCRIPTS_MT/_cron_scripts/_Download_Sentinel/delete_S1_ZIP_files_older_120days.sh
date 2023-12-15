#!/bin/sh

# This script deletes the Sentinel-1 ZIP & PNG files older than DAYS_TO_DEL days (hard coded) 
# on the HP-D3600 in dir: SAR_DATA/S1/
# Mounted path: /Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/
# Version: 1.0.1 - 2021103 - added var: DAYS_TO_DEL

# Version: 1.0 - 20190717
#
DAYS_TO_DEL="60"

workingDirArray=("/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DRCONGO-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-LUXEMBOURG-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-DOMUYO-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-GUADELOUPE-SLC"
				 "/Users/doris/NAS-Discs/hp-D3600-Data_Share1/SAR_DATA/S1/S1-DATA-KARTHALA_SM-SLC"
                 "/Users/doris/NAS-Discs/hp-D3601-Data_RAID6/SAR_DATA_Other_Zones/S1/S1-DATA-TRISTAN-SLC"
                 "/Users/doris/NAS-Discs/hp-D3601-Data_RAID6/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION-SLC"
                 "/Users/doris/NAS-Discs/hp-D3601-Data_RAID6/SAR_DATA_Other_Zones/S1/S1-DATA-REUNION_SM-SLC"
                 "/Users/doris/NAS-Discs/hp-D3601-Data_RAID6/SAR_DATA_Other_Zones/S1/S1-DATA-HAWAII-SLC")

for i in "${workingDirArray[@]}"
do
   : 
   # do whatever on $i
   echo "Processing dir: $i"
   echo "Deleting Sentinel1-ZIP files older than ${DAYS_TO_DEL}  days in ${i}"
   /usr/bin/find ${i} -type f -name "*.zip" -ctime +${DAYS_TO_DEL}d -exec rm -vf {} \;
   echo "Deleting Sentinel1-Quicklook PNG files older than ${DAYS_TO_DEL} days in ${i}"
   /usr/bin/find ${i} -type f -name "*.png" -ctime +${DAYS_TO_DEL}d -exec rm -vf {} \;
   echo "-------------------------------------------------------------------------------------------------------------"
   
done				  

echo "Done!"


