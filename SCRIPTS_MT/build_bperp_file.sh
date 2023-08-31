#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at building a bperp_file for Baseline plot. 
#
# Parameters are:
# 		- the table_BpermMin_BperpMax_Tmin_Tmax.txt that contains "SlaveDate MasterDATE Bperp Delay"
#		- the SuperMaster date 
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#				- script plotspan.sh
#
#
# The script MUST be laucnhed in the dir that contains the approximateBaselinesTable.txt or allPairsListing.txt.
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0.1
# New in Distro V 2.0:	- do not get the Bp and Bt of all images with the SM from approximateBaselinesTable.txt 
#						  The only difference is that SM_Approx_baselines.txt contains BP with decimal values. 
# New in Distro V 2.1:	- works either with approximateBaselinesTable.txt (from L Libert) or allPairsListing.txt (from D Derauw). It takes the most recent one
# New in Distro V 2.2:	- remove header from table only if a header exists
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/04/06 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.2 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jan 13, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

TABLE=$1
SM=$2					

if [ $# -lt 1 ] ; then echo “Usage $0 table_BpermMin_BperpMax_Tmin_Tmax.txt [SuperMaster]”; exit; fi

echo "The script MUST be laucnhed in the dir that contains the approximateBaselinesTable.txt or allPairsListing.txt."

rm -f bperp_file
rm -f bperp_file.tmp bperp_file.txt

cp ${TABLE} bperp_file.tmp

TABLENAME=`echo "${TABLE}" | ${PATHGNU}/gawk -F '/' '{print $NF}'`
 
MinBp=`echo "${TABLENAME}" | cut -d _ -f2`
MaxBp=`echo "${TABLENAME}" | cut -d _ -f3`
MinBt=`echo "${TABLENAME}" | cut -d _ -f4`
MaxBt=`echo "${TABLENAME}" | cut -d _ -f5  | cut -d . -f1`

# get rid of header

if [ `${PATHGNU}/grep "Master" bperp_file.tmp | wc -c` -gt 0 ] 
	then 
		tail -n +3 bperp_file.tmp > bperp_file
	else 
		cp bperp_file.tmp bperp_file
fi 


# get the Bp and Bt for each image with super master 

if [ -f allPairsListing.txt ]  # i.e. DD tools were used
	then 
		if [ -f approximateBaselinesTable.txt ] # i.e. LL tools were used
			then 
				# search for the most recent tools used	
				if [ `ls -t approximateBaselinesTable.txt allPairsListing.txt | head -1` == "allPairsListing.txt" ] ; then TOOLS="DD" ; else TOOLS="LL" ; fi
			else 
				# only DD tools used
				TOOLS="DD"
		fi
	else 
		if [ -f approximateBaselinesTable.txt ] 
			then
				# only LL tools used
				TOOLS="LL"
			else
				echo "Can't find  approximateBaselinesTable.txt nor allPairsListing.txt; exit"
				exit 0 			
		fi
fi

case ${TOOLS} in 
			"LL")    
				grep -o "[^[:space:]]*"${SM}"[^[:space:]]*" approximateBaselinesTable.txt | ${PATHGNU}/gsed s/_/"	"/g > SM_Approx_baselines.txt
				;;
			"DD")   	
				cp allPairsListing.txt SM_Approx_baselines.txt
				# shape the file
				# remove header, sort, remove leading spaces
				${PATHGNU}/grep -v "#" SM_Approx_baselines.txt | sort | ${PATHGNU}/gsed "s/^[ \t]*//" > SM_Approx_baselines_sorted.txt
				# keep only lines containing SM and keep only col 1 (MAS), 2 (SLV), 3 (BP), and -4 (-Bt) tab separated
				cat SM_Approx_baselines_sorted.txt | ${PATHGNU}/grep "${SM}" | ${PATHGNU}/gawk -v OFS='\t' '{print $1,	$2,	$8,	-$9}' > SM_Approx_baselines.txt
				rm -f SM_Approx_baselines_sorted.txt
				;;		
esac


i=1
while read MAS SLV BpPAIR BtPAIR
do
		echo "Processing pair ${MAS} ${SLV}"
		echo " --> Bp and Bt are  ${BpPAIR} ${BtPAIR}" 
		# Get Bt and Bp for Master-SM pair
		if [ ${MAS} == ${SM} ]
			then 
				BpMAS=0
				BtMAS=0
			else 
				BpMAS=`grep ${MAS} SM_Approx_baselines.txt | cut -f3`
				BtMAS=`grep ${MAS} SM_Approx_baselines.txt | cut -f4`
				if [ ${MAS} -ge ${SM} ]
					then 
					 BtMAS=`echo "(${BtMAS} * -1)" | bc -l `
					 BpMAS=`echo "(${BpMAS} * -1)" | bc -l `
				fi
		fi
		echo " --> Bp and Bt of master_Superaster ${MAS}_${SM} are ${BpMAS} ${BtMAS}" 
		# Get Bt and Bp for Slave-SM pair
		if [ ${SLV} == ${SM} ]
			then 
				BpSLV=0	
				BtSLV=0
			else 
				BpSLV=`grep ${SLV} SM_Approx_baselines.txt | cut -f3`		
				BtSLV=`grep ${SLV} SM_Approx_baselines.txt | cut -f4`
				if [ ${SLV} -ge ${SM} ]
					then 
						BtSLV=`echo "(${BtSLV} * -1)" | bc -l `
						BpSLV=`echo "(${BpSLV} * -1)" | bc -l `
				fi
		fi 	
		echo " --> Bp and Bt of slave_Superaster ${SLV}_${SM} are ${BpSLV} ${BtSLV}" 
		echo "${i}  ${MAS}  ${SLV}  ${BtPAIR}  ${BpPAIR}  ${BtMAS}  ${BtSLV}  ${BpMAS}  ${BpSLV}" >> bperp_file.txt
		i=`expr "$i" + 1`
done < bperp_file

cp SM_Approx_baselines.txt SM_Approx_baselines_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt
cp bperp_file.txt bperp_file_${MinBp}_${MaxBp}_${MinBt}_${MaxBt}.txt

# plot
plotspan.sh bperp_file.txt ${MinBp} ${MaxBp} ${MinBt} ${MaxBt}

rm bperp_file.tmp bperp_file
