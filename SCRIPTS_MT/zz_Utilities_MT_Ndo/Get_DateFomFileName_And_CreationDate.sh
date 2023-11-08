#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at getting the date from the file (or dir) name and the creation 
#  date for all images files in dir. It also displays the difference in days.
# This script is used to check e.g. the latency of CSK images provided by the Virunga Supersite  
#
# MUST BE LAUNCHED FROM DIR WHERE IMG ARE(e.g. ${PATH_3601}/SAR_DATA_Other_Zones/CSK/SuperSite/Auto_Curl_DATED)
#
# Parameters :  - file (f) or dir (d)
#
# Dependencies:	 
#    	- stat
#		- gsed
#
# Hard coded:	- type of file to search for (e.g. *.zip) 
#
#
# New in Distro V 1.0.1:	- add number of days since last image 
# New in Distro V 1.0.2 (Mar 15, 2022):	- add average over last XX images (hard coded) 
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

TYPE=$1

Random=$(echo ${RANDOM:0:3})
touch tmp_${Random}.txt 

case ${TYPE} in  
	"f") 
		# for files
		for IMGFILE in `find . -maxdepth 1 -name "*.zip"`
		do 
			#echo -e "Checking ${IMGFILE}: \c"
			DATENAME=`echo ${IMGFILE} | cut -d "_" -f 9 | cut -c 1-8`
			DATECREA=`stat ${IMGFILE} | tail -1 | cut -d : -f2 | cut -d " " -f2 | ${PATHGNU}/gsed "s%-%%g" `
			DIFF=`echo "($(date +%s -d ${DATECREA})-$(date +%s -d ${DATENAME}))/86400" | bc -l | cut -d . -f 1`
		
			echo "Iamge ${DATENAME} created on ${DATECREA}; i.e. delay = ${DIFF} days" >> tmp_${Random}.txt 
		done ;;
	"d")
		# fir dirs
		FORMERDATE=20010101
		for IMGFILE in `find . -maxdepth 1 -type d -name "2*"`
		do 
			#echo -e "Checking ${IMGFILE}: \c"
			DATENAME=`echo ${IMGFILE} | cut -d "/" -f 2`
			DATECREA=`stat ${IMGFILE} | tail -1 | cut -d : -f2 | cut -d " " -f2 | ${PATHGNU}/gsed "s%-%%g" `
			DELIVERYDIFF=`echo "($(date +%s -d ${DATECREA})-$(date +%s -d ${DATENAME}))/86400" | bc -l | cut -d . -f 1`
			# completer script pour delta entre temps entre avant derniere img et derniere info (last created and img last-1)
			TIMESINCELAST=`echo "($(date +%s -d ${DATENAME})-$(date +%s -d ${FORMERDATE}))/86400" | bc -l | cut -d . -f 1`
			LASTINFO=`echo "($(date +%s -d ${DATECREA})-$(date +%s -d ${FORMERDATE}))/86400" | bc -l | cut -d . -f 1`
			FORMERDATE=${DATENAME}
			echo "Image ${DATENAME} was created on ${DATECREA}, i.e. nr of days between acquisition and delivered: ${DELIVERYDIFF} ;	Nr of days between two last images: ${TIMESINCELAST}   ;	Nr of days withtout info: ${LASTINFO}" >> tmp_${Random}.txt 
		done ;;
	
	*) echo "Enter f or d if you want to check files or directories names" ;;
esac 


sort tmp_${Random}.txt 

DATETODAY=`date +%s `
DATETODAYFULL=`date +%Y%m%d`
DATELAST=`cat tmp_${Random}.txt | tail -1 | cut -d " " -f 2`
DIFF=`echo "((${DATETODAY})-$(date +%s -d ${DATELAST}))/86400" | bc -l | cut -d . -f 1`
echo "Today, ${DATETODAYFULL}, nr of days withtout info since last image was acquired is:  ${DIFF}"

count=0;
total=0; 

NLASTIMG=60

tail -${NLASTIMG} tmp_${Random}.txt | cut -d " " -f 15,23,31 > tmp_${Random}_Lastimg.txt

for i in $( awk '{ print $1; }' tmp_${Random}_Lastimg.txt  )
   do 
     total=$(echo $total+$i | bc )
     ((count++))
   done
AVG1=`echo "scale=2; $total / $count" | bc`
count=0;
total=0; 

for i in $( awk '{ print $2; }' tmp_${Random}_Lastimg.txt  )
   do 
     total=$(echo $total+$i | bc )
     ((count++))
   done
AVG2=`echo "scale=2; $total / $count" | bc`
count=0;
total=0; 

for i in $( awk '{ print $3; }' tmp_${Random}_Lastimg.txt  )
   do 
     total=$(echo $total+$i | bc )
     ((count++))
   done
AVG3=`echo "scale=2; $total / $count" | bc`
echo
echo "Statistics over last ${NLASTIMG} images:"
echo "  Average delay between acquisition and delivered: ${AVG1} days ;	Average delay between two images: ${AVG2} days  ;	Average nr of days without info: ${AVG3}" 

rm -f tmp_${Random}.txt tmp_${Random}_Lastimg.txt
