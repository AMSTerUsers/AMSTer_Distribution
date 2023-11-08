#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at checking unwrapping error in all triangles from a list computed with _Extract_Triangles.sh. 
#
# Parameters : - file with list of triangles
# 			   - path to deformation files (e.g. /Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4/Geocoded/DefoInterpolx2Detrend)
#			   - path to kml of zone to check
#			   - threshold to consider that there is no phase error
#
#
# Dependencies:	- gnu sed and awk for more compatibility
#			    - bc
#				- getStatForZoneInFile and ffa utilities from AMSTer Engine
#
# Hard coded:	- 
#
# New in Distro V 1.1:	- make all in a dir with explicit name 
#						- check that it works also if MAS and SLV were swapped at mass processing 
# New in Distro V 1.2:	- change file/link naming for shorter names. Too long names may crash; cp instead of link if too long
#						- made incremental: do not recompute triangles that are already in _Good_Closure.txt or _Wrong_Closure.txt
# New in Distro V 1.3:	- set COUNTGOOD or COUNTWRONG to 0 if _Good_Closure.txt or _Wrong_Closure.txt do not exist yet
#						- zap a Gremlin in line 86
# New in Distro V 1.4:	- skip triangle for which at least one of the pair dir is missing in SAR_MASSPROCESS
#						- select all images in _Wrong_Closure.txt that are not in _Good_Closure.txt and save it in _Pairs_To_Clean_From_WrongClosure_NotIn_GoodClosure.txt
# New in Distro V 1.5:  - replace if -s as -f -s && -f to be compatible with mac os if 
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

#source $HOME/.bashrc

TRIANGLES=$1			# path to file with list of triangles
PATHDEFO=$2				# path to deformation files (e.g. /Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4/Geocoded/DefoInterpolx2Detrend)
KML=$3					# kml of zone where one wants to check unwrapping errors
LIMIT=$4				# threshold limit above which a triangle is considered as affected by unwrapping error

cd ${PATHDEFO}
cd .. 
mkdir -p _Check_Triangles.txt

cd _Check_Triangles.txt
KMLNAME=$(basename "${KML}")
mkdir -p ${KMLNAME}_Thresold_${LIMIT}

RUNDIR=$(dirname "${PATHDEFO}")/_Check_Triangles.txt/${KMLNAME}_Thresold_${LIMIT}/
cd ${RUNDIR}

# only delete manually if do not want incremental use 
#rm -f _Wrong_Closure.txt _Good_Closure.txt _Missing_Closure.txt

while IFS=" : " read -r DUMMY i12 i23 i13;  # order of pairs does not matter
	do 

# debug
echo "Shall process ${i12} ${i23} ${i13}"
		# Check order of master and slaves
		MAS12=`echo "${i12}" | cut -d_ -f 1` # select _date_date_ where date is 8 numbers
		SLV12=`echo "${i12}" | cut -d_ -f 2`
		MAS23=`echo "${i23}" | cut -d_ -f 1`
		SLV23=`echo "${i23}" | cut -d_ -f 2`
		MAS13=`echo "${i13}" | cut -d_ -f 1`
		SLV13=`echo "${i13}" | cut -d_ -f 2`

		MASTERS=(${MAS12} ${MAS13} ${MAS23})
		SLAVES=(${SLV12} ${SLV13} ${SLV23})

		MASSORTED=($(printf '%s\n' "${MASTERS[@]}" | sort -u))
		SLVSORTED=($(printf '%s\n' "${SLAVES[@]}" | sort -u))

		MAS1=${MASSORTED[0]}
		MAS2=${MASSORTED[1]}

		SLV2=${SLVSORTED[0]}
		SLV3=${SLVSORTED[1]}

		TRIO="${i12} - ${i23} - ${i13}"
		if [ -f "${RUNDIR}/_Good_Closure.txt" ] && [ -s "${RUNDIR}/_Good_Closure.txt" ] ; then COUNTGOOD=`${PATHGNU}/grep "${TRIO}" ${RUNDIR}/_Good_Closure.txt 2>/dev/null | wc -c` ; else COUNTGOOD=0 ; fi
		if [ -f "${RUNDIR}/_Wrong_Closure.txt" ] && [ -s "${RUNDIR}/_Wrong_Closure.txt" ] ; then COUNTWRONG=`${PATHGNU}/grep "${TRIO}" ${RUNDIR}/_Wrong_Closure.txt  2>/dev/null | wc -c` ; else COUNTWRONG=0 ; fi

		#if [ ! -s ${MAS1}_${SLV3}_-_${MAS1}_${SLV2}_+_${MAS2}_${SLV3} ] ; then  # triangle not checked yet
		if [ ${COUNTGOOD} -gt 0 ] || [ ${COUNTWRONG} -gt 0 ] 
			then  # triangle already checked 
				echo "${i12} - ${i23} - ${i13} : already checked; skipping... "
			else # triangle not checked yet
				NAME12=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${MAS1}_${SLV2}*deg"` 
				NAME23=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${MAS2}_${SLV3}*deg"` 
				NAME13=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${MAS1}_${SLV3}*deg"` 

				# if it does not find the file, it may be due to MAS/SLV swapped processing for sake of efficiency during the mass processing. 
				# Phase, if MAS/SLV swapped, was already inverted, so no worry about the sign.
				if [ "${NAME12}" == "" ] ; then NAME12=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${SLV2}_${MAS1}*deg"` ; fi
				if [ "${NAME23}" == "" ] ; then NAME23=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${SLV3}_${MAS2}*deg"` ; fi
				if [ "${NAME13}" == "" ] ; then NAME13=`find ${PATHDEFO} -maxdepth 1 -type f -name "*${SLV3}_${MAS1}*deg"` ; fi

				if [ "${NAME12}" == "" ] || [ "${NAME23}" == "" ] || [ "${NAME13}" == "" ]
					then 
						echo "Missing at least one of the Pair in SAR_MASSPROCESS; can't process this traingle"
					else 
						if [ ! -h ${MAS1}_${SLV2} ] ; then ln -s ${NAME12} ${MAS1}_${SLV2} ; fi
						if [ ! -h ${MAS1}_${SLV3} ] ; then ln -s ${NAME13} ${MAS1}_${SLV3} ; fi
						if [ ! -h ${MAS2}_${SLV3} ] ; then ln -s ${NAME23} ${MAS2}_${SLV3} ; fi
						# Copy if no other choice because of too long name
						#if [ ! -s ${MAS1}_${SLV2} ] ; then cp ${NAME12} ${MAS1}_${SLV2} ; fi
						#if [ ! -s ${MAS1}_${SLV3} ] ; then cp ${NAME13} ${MAS1}_${SLV3} ; fi
						#if [ ! -s ${MAS2}_${SLV3} ] ; then cp ${NAME23} ${MAS2}_${SLV3} ; fi
			
						if [ ! -h 123.hdr ] ; then ln -s ${NAME12}.hdr 123.hdr ; fi
			
						if [ ! -s "${NAME12}" ] 
							then 
								echo "Pair12 probably missing: ${MAS1}_${SLV2}" >> _Missing_Closure.txt 
							else 
								if [ ! -s "${NAME13}" ] 
									then 
										echo "Pair13 probably missing: ${MAS1}_${SLV3}" >> _Missing_Closure.txt 
									else 
										if [ ! -s "${NAME23}" ] 
											then 
												echo "Pair23 probably missing: ${MAS2}_${SLV3} " >> _Missing_Closure.txt 
											else 
												#NaN2zero.py ${NAME12}
												#NaN2zero.py ${NAME13}
												#NaN2zero.py ${NAME23}
			
												#ffa ${RUNDIR}/${MAS1}_${SLV2} + ${RUNDIR}/${MAS2}_${SLV3}
												if [ ! -s ${RUNDIR}/${MAS1}_${SLV2}_+_${MAS2}_${SLV3} ] ; then ffa ${RUNDIR}/${MAS1}_${SLV2} + ${RUNDIR}/${MAS2}_${SLV3} ${RUNDIR}/${MAS1}_${SLV2}_+_${MAS2}_${SLV3}; fi
												ffa ${RUNDIR}/${MAS1}_${SLV3} - ${RUNDIR}/${MAS1}_${SLV2}_+_${MAS2}_${SLV3} ${RUNDIR}/123
			
												#extract mean value in kml
												avgrun=`getStatForZoneInFile ${RUNDIR}/123 ${KML}`
												AVG=`echo ${avgrun} | ${PATHGNU}/gsed s/-//`
			
												if [ 1 -eq "$(echo "${AVG} > ${LIMIT}" | bc)" ]
													then 
														echo "${i12} - ${i23} - ${i13} Unwrapping error: mean closure value |${avgrun}| exceed thresold ${LIMIT}" 
														echo "${i12} - ${i23} - ${i13} : ${avgrun}" >> _Wrong_Closure.txt
			
			
													else 
														echo "${i12} - ${i23} - ${i13} ok: mean closure value |${avgrun}|"
														echo "${i12} - ${i23} - ${i13} : ${avgrun}" >> _Good_Closure.txt
												fi
												rm -f 123 ${MAS1}_${SLV2}_+_${MAS2}_${SLV3} # 123.hdr 
										fi
								fi
						fi
				fi
			
		fi
		
# debug 
	
done < "${TRIANGLES}"
#done < /Volumes/hp-1650-Data_Share1/SAR_SM/MSBAS/ARGENTINE/set1/_Triangles/List_Triangels.txt 

# select only the pairs, sort and uniq them:
cat _Good_Closure.txt | cut -d : -f1 | ${PATHGNU}/gsed "s% - %\r%g" | sort |uniq > _Good_Pairs.txt
cat _Wrong_Closure.txt | cut -d : -f1 | ${PATHGNU}/gsed "s% - %\r%g" | sort |uniq > _Wrong_Pairs.txt

# select all pairs that are in Wrong but not in Good (to be removed from Modei.txt for instance using Remove_Pairs_From_BaselineOptimisation.sh)
echo " Pairs listed in _Wrong_Closure.txt that are not in _Good_Closure.txt are saved in _Pairs_To_Clean_From_WrongClosure_NotIn_GoodClosure.txt"
${PATHGNU}/grep -Fv -f _Good_Pairs.txt _Wrong_Pairs.txt > _Pairs_To_Clean_From_WrongClosure_NotIn_GoodClosure.txt

#find . -maxdepth 1 -type f -name "*" -exec cp -n {} /${KMLNAME}_Thresold_${LIMIT}/ \;
#cp _Good_Closure.txt ${KMLNAME}_Thresold_${LIMIT}/
#cp _Wrong_Closure.txt ${KMLNAME}_Thresold_${LIMIT}/
#cp ${KML} ${KMLNAME}_Thresold_${LIMIT}/

echo "------------------------------------"
echo "All triangle tested"
echo "------------------------------------"

