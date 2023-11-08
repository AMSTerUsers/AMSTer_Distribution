#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at checking unwrapping error in a triangle of interferos. 
# Note that order of defo is irrelevant because script will take care of searching the right order based on dates in names
#
# Parameters : - path to defo_12
#			   - path to defo_23
#			   - path to defo_13
#			   - path to kml of zone to check
#			   - threshold to consider that there is no phase error
#
#
# Dependencies:	- gnu sed and awk for more compatibility
#			    - bc
#				- getStatForZoneInFile and ffa utilities from CIS
#
# Hard coded:	- 
#
# New in Distro V 1.1:	- change file/link naming for shorter names. Too long names may crash; if still crash, use cp instead of link if too long
# New in Distro V 1.2: - remove stray \ before _ while calling grep to cope with new grep syntax and avoid waring
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

i12=$1			# path to defo
i23=$2			# path to defo
i13=$3			# path to defo
KML=$4
LIMIT=$5

# Check order of master and slaves
PATHDEFO=$(dirname "${i12}")
NAME12TMP=$(basename "${i12}")
NAME13TMP=$(basename "${i13}")
NAME23TMP=$(basename "${i23}")

MAS12=`echo "${NAME12TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 2` # select _date_date_ where date is 8 numbers
SLV12=`echo "${NAME12TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 3`
MAS23=`echo "${NAME23TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 2`
SLV23=`echo "${NAME23TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 3`
MAS13=`echo "${NAME13TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 2`
SLV13=`echo "${NAME13TMP}" | ${PATHGNU}/grep -Eo "_[0-9]{8}_[0-9]{8}_" | cut -d_ -f 3`


cd ${PATHDEFO}
cd .. 
mkdir -p _Check_Triangles.txt
RUNDIR=$(dirname "${PATHDEFO}")/_Check_Triangles.txt
cd _Check_Triangles.txt
ln -s ${i12} ./${MAS12}_${SLV12}
ln -s ${i13} ./${MAS13}_${SLV13}
ln -s ${i23} ./${MAS23}_${SLV23}
#Needed to extract mean value in kml
ln -s ${i12}.hdr 123.hdr 

# cp -n ${i12} ./${MAS12}_${SLV12}
# cp -n ${i13} ./${MAS13}_${SLV13}
# cp -n ${i23} ./${MAS23}_${SLV23}
# cp -n ${i12}.hdr 123.hdr 

MASTERS=(${MAS12} ${MAS13} ${MAS23})
SLAVES=(${SLV12} ${SLV13} ${SLV23})

MASSORTED=($(printf '%s\n' "${MASTERS[@]}" | sort -u))
SLVSORTED=($(printf '%s\n' "${SLAVES[@]}" | sort -u))

MAS1=${MASSORTED[0]}
MAS2=${MASSORTED[1]}
echo "Masters are ${MAS1} ${MAS2}" 

SLV2=${SLVSORTED[0]}
SLV3=${SLVSORTED[1]}
echo "Slaves are ${SLV2} ${SLV3}" 

NAME12=`find * -name "${MAS1}_${SLV2}" `
NAME23=`find * -name "${MAS2}_${SLV3}"`
NAME13=`find * -name "${MAS1}_${SLV3}"`

echo "files are ${NAME12}"
echo "          ${NAME23} "
echo "          ${NAME13}" 

#NaN2zero.py ${NAME12}
#NaN2zero.py ${NAME13}
#NaN2zero.py ${NAME23}

if [ ! -s ${RUNDIR}/${NAME12}_+_${NAME23} ] ; then ffa ${RUNDIR}/${NAME12} + ${RUNDIR}/${NAME23} ${RUNDIR}/${NAME12}_+_${NAME23}; fi
ffa ${RUNDIR}/${NAME13} - ${RUNDIR}/${NAME12}_+_${NAME23} ${RUNDIR}/123

#ffa ${RUNDIR}/${NAME12} + ${RUNDIR}/${NAME23} ${RUNDIR}/123
#ffa ${RUNDIR}/${NAME13} - ${RUNDIR}/123 ${RUNDIR}/tmp


#extract mean value in kml
avg=`getStatForZoneInFile ${RUNDIR}/123 ${KML}`

if [ 1 -eq "$(echo "${avg} > ${LIMIT}" | bc)" ] ; then echo "Unwrapping error: mean closure value ${avg} > ${LIMIT}" ; else echo "ok: mean closure value ${avg}" ; fi

rm -f 123 ${NAME12}_+_${NAME23} # 123.hdr 

echo "------------------------------------"
echo "Triangle tested"
echo "------------------------------------"

