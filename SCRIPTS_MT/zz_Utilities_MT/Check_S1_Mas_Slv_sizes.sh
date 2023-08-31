#!/bin/bash
######################################################################################
# This script check the size in lines and columns of the master SLC and interpolated slave SLC
#   and compare them with the file sizes in bytes
#
# Must be launnched in pair dir where interfero is computed (or crashed)
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2019/04/25 -                         
######################################################################################

SOURCEDIR=`basename $PWD`

CROPDIR="$(dirname "$(pwd)")"  # Get the path of dir one level up...
REGIONTRK1=`basename ${CROPDIR}`
REGIONTRK2="$(basename "$(dirname "$CROPDIR")")"  # Uggly command to get the name of dir another level up, i.e. 2 levels...
#REGIONTRK3="$(basename "$(dirname "$(dirname "$REGIONTRK")")")"  # Uggly command to get the name of dir another level up, i.e. 3 levels...

# to cope with architecture from SinglePair or MassPorcessing
if [ ${REGIONTRK2} == "S1" ] ; then REGIONTRK=${REGIONTRK1} ; else REGIONTRK=${REGIONTRK2}  ; fi

#MAS=`echo "${SOURCEDIR}" | cut -d S -f 2 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select _date_date_ where date is 8 numbers
#SLV=`echo "${SOURCEDIR}" | cut -d S -f 3 | ${PATHGNU}/grep -Eo "[0-9]{8}" ` # select _date_date_ where date is 8 numbers

MAS=`echo "${SOURCEDIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}" | head -1` # select _date_date_ where date is 8 numbers
SLV=`echo "${SOURCEDIR}" | ${PATHGNU}/grep -Eo "[0-9]{8}" | tail -1` # select _date_date_ where date is 8 numbers

# get MASTER info from SAR_CSL
MASINFOLOC=`ls -f $PATH_1650/SAR_CSL/S1/${REGIONTRK}/NoCrop/* | ${PATHGNU}/grep ${MAS} | cut -d : -f 1`
MASINFO=`echo  ${MASINFOLOC}/Info/SLCImageInfo.txt`

MASCOL=`grep "Range dimension" ${MASINFO}  | ${PATHGNU}/grep -Eo "[0-9]*"`
MASLIN=`grep "Azimuth dimension" ${MASINFO}  | ${PATHGNU}/grep -Eo "[0-9]*"`

MASBYTES=`echo "(${MASCOL} * ${MASLIN} * 8) " | bc` 

MASSLC=`ls ${MASINFOLOC}/Data/SLCData.??`
MASSIZE=`wc -c < ${MASSLC}`

MASDIFF=`echo "(${MASBYTES} - ${MASSIZE}) " | bc` 

echo "Master (${MAS}) is	${MASSIZE} bytes and ${MASCOL} x ${MASLIN}, which (x8) is supposed to be ${MASBYTES} bytes => diff master is ${MASDIFF}	bytes"

# get SLAVE info from PROCESS_PAIR/i12/Resampled.csl
SLVINFOLOC=`ls -f i12/InSARProducts/* | ${PATHGNU}/grep ${SLV} | ${PATHGNU}/grep "interpolated.csl"  | cut -d : -f 1`

SLVINFO=`echo  ${SLVINFOLOC}/Info/SLCImageInfo.txt`

SLVCOL=`grep "Range dimension" ${SLVINFO}  | ${PATHGNU}/grep -Eo "[0-9]*"`
SLVLIN=`grep "Azimuth dimension" ${SLVINFO}  | ${PATHGNU}/grep -Eo "[0-9]*"`

SLVBYTES=`echo "(${SLVCOL} * ${SLVLIN} * 8) " | bc` 

SLVSLC=`ls ${SLVINFOLOC}/Data/SLCData.??`
SLVSIZE=`wc -c < ${SLVSLC}`

SLVDIFF=`echo "(${SLVBYTES} - ${SLVSIZE}) " | bc` 

echo "Slave (${SLV}) is	${SLVSIZE} bytes and ${SLVCOL} x ${SLVLIN}, which (x8) is supposed to be ${SLVBYTES} bytes => diff slave is ${SLVDIFF}	bytes"
