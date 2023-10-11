#!/bin/bash
######################################################################################
# This script inverts coh where 	0 was mask and 1 was keep in 
#									2 is mask and 0 is keep 
# These "inverted" masks are expected by MasTer Engine from V 20231009  
#
# The input mask is expected as usual to be in bytes, in Lat Long, without NaN.
# The output mask will have the same name as the input mask though with additional string 
#	_0keep
#
# Parameters: - path to coh mask to invert
#
# Dependencies: - Change_Val.py
#
# New in V 2.0:	
#
# I know, it is a bit messy and can be improved.. when time. But it works..
# N.d'Oreye, v 1.0 2023/10/11 -                         
######################################################################################
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2023, Last modified on oct 11, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

INPUTMASK=$1

PATHMASK=`dirname ${INPUTMASK}`
MASKNAME=`basename ${INPUTMASK}`

# test if there is an extention
if [[ ${MASKNAME} == *.* ]]
	then 
		# if more than one dot: exit because hard to figure out the right naming
		#if [ $(echo "${MASKNAME}" | tr -cd '.' | wc -c) -gt 1 ]
		#	then 
		#		echo "Your name seems to contain several dots. I can't be sure of your hdr file. Please remove dots in name"
		#		exit
		#	else 
				# test if dot is in name or .hdr 
				MASKONLYNAME="${MASKNAME%.*}"
				if [ -f ${MASKONLYNAME}.hdr ]
					then 
						# ok seems normal case 
						MASKEXT=".${MASKNAME##*.}"
						MASKONLYNAME="${MASKNAME%.*}"
					else 
						# beware, probably dot in name and no extension
						MASKEXT=""
						MASKONLYNAME="${MASKNAME}"
				fi
		#fi
	else 
		MASKEXT=""
		MASKONLYNAME="${MASKNAME}"
fi

Change_Val.py "${INPUTMASK}" 0 2 byte 
Change_Val.py "${INPUTMASK}_0.0_ReplacedBy_2.0" 1 0 byte 
 

mv -f "${INPUTMASK}_0.0_ReplacedBy_2.0_1.0_ReplacedBy_0.0" ${PATHMASK}/${MASKONLYNAME}_0keep${MASKEXT}
cp ${PATHMASK}/${MASKONLYNAME}.hdr ${PATHMASK}/${MASKONLYNAME}_0keep.hdr

rm -f "${INPUTMASK}_0.0_ReplacedBy_2.0"
