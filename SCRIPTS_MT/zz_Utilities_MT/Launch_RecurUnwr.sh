#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at launching recursive unwrapping with Snaphu based on a procedure developped by J-L Froger and Y. Fukushima. 
#
# Parameters : - path to file to unwrap.   
#
# Dependencies:	- python3, snaphu
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# DS (c) 2022/09/30 - could make better... when time.
# ./Launch_RecurUnwr.sh ~/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/crop_interf.r4 601 401 0.9 12.5 10 0.02773288 '/home/delphine/Documents/Unwr_INTERFERO_JLF/interfs/S1A/test/crop_coh.r4' 0.0627
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2022, Last modified on Sep 30, 2022"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

#Arguments
INTERFILE=$1
NUMCOL=$2
NUMLINE=$3
COEFREQ=$4
CUTINI=$5
NITMAX=$6
HWLEN=$7
COHFILE=$8
COHMUWPTHRESH=$9

echo $#
if [ $# -eq 7 ]; then 
	echo "No masking using white noise required"
	BRUIT=0
elif [ $# -eq 9 ]; then
	BRUIT=1
	echo "Interf will be masked using white noise where coherence < ${COHMUWPTHRESH}"
else
	echo "Error : bad number of arguments check launching command"
	exit
fi
############
# Datatype must be float when integrated in Master toolbox could be byte if used independently
#DATATYPE="byte" 
DATATYPE="float" 
#DATATYPE="float2byte"


############
echo "File to unwrap is : ${INTERFILE}"
echo "Size is columns : ${NUMCOL} and lines : ${NUMLINE}"

#Get infos on working directories
HMDIR=`pwd`
PATHFILES=$(dirname ${INTERFILE})
INTERFILENAME=`basename ${INTERFILE}`

# Create dir where to store intermediate files
WORKINGDIR=`echo ${PATHFILES}/RECUNWR`
if [ -d "${WORKINGDIR}" ]
then 
	echo "${WORKINGDIR} does exist." 
	if [ "$(ls -A ${WORKINGDIR})" ] 
	then 
		echo "but is not empty."
		echo "Please empty directory :  ${WORKINGDIR}"
		exit 
	else 
		echo "and is Empty"
	fi
else
	echo "${WORKINGDIR} does not exist. I will create it" 
	mkdir ${WORKINGDIR}
fi

# Copy input file in working dir
INPUTFILE=${WORKINGDIR}/${INTERFILENAME}
cp ${INTERFILE} ${INPUTFILE}

# Option Mask with coherence file
if [ `expr ${BRUIT}` == 1 ]
then
echo "Mask with coherence thresold"
	Maskwithseuilcoh.py ${INPUTFILE} ${NUMCOL} ${NUMLINE} ${COHFILE} ${COHMUWPTHRESH}
	INPUTFILE=${WORKINGDIR}/interf_WN.tmp
	MASKFILE=${WORKINGDIR}/mask.tmp
else
echo "No Mask"
	MASKFILE="None"
fi

# Check if number of lines and col is even, if not crop last line and/or col
NEEDADDCOLNAN=0
NEEDADDLINNAN=0
if [ `expr ${NUMCOL} % 2` == 0 ]
then
	echo "Ok, Number of columns is even"
else
	echo "Number of columns is Odd, Crop Last Column"
	CropLastCol_float.py ${INPUTFILE} ${NUMLINE} ${NUMCOL}
	INPUTFILE=`echo ${INPUTFILE}.CropLastCol`
	NEEDADDCOLNAN=1
#	if [ ${MASKFILE} != "None" ]
#	then
#		CropLastCol_float.py ${MASKFILE} ${NUMLINE} ${NUMCOL}	
#		MASKFILE=`echo ${MASKFILE}.CropLastCol`
#	fi
	NUMCOL=`echo ${NUMCOL} -1 | bc -l`
fi
if [ `expr ${NUMLINE} % 2` == 0 ]
then
	echo "Ok, Number of lines is even"
else
	echo "Number of lines is Odd, Crop Last Line"
	CropLastLine_float.py ${INPUTFILE} ${NUMLINE} ${NUMCOL}
	INPUTFILE=`echo ${INPUTFILE}.CropLastLine`
	NEEDADDLINNAN=1
#	if [ ${MASKFILE} != "None" ]
#	then
#		CropLastLine_float.py ${MASKFILE} ${NUMLINE} ${NUMCOL}
#		MASKFILE=`echo ${MASKFILE}.CropLastLine`
#	fi
	NUMLINE=`echo ${NUMLINE} -1 | bc -l`
fi

if [ ${MASKFILE} != "None" ]
then
	cp ${MASKFILE} ${PATHFILES}/mask_WN.r4
fi

#initalization
INPUTREF=${WORKINGDIR}/interf_ref.tmp
if [ ${DATATYPE} == "float" ]; then
	echo "input data in float processing only floats"
	#cp ${INPUTFILE} ${WORKINGDIR}/interf0_float.tmp
	init_interf_ref_float.py ${INPUTFILE} ${NUMCOL} ${NUMLINE}
	INPUTFILE=${WORKINGDIR}/interf0_float.tmp
elif  [ ${DATATYPE} == "byte" ]; then
	echo "input data in bytes processing only bytes"
	cp ${INPUTFILE} ${WORKINGDIR}/interf0_byte.tmp
	INPUTFILE=${WORKINGDIR}/interf0_byte.tmp
elif  [ ${DATATYPE} == "float2byte" ]; then
	echo "input data in float processing uses bytes"
	cp ${INPUTFILE} ${WORKINGDIR}/interf0_float.tmp
	INPUTFILE=${WORKINGDIR}/interf0_float.tmp
	INPUTREFfloat=${WORKINGDIR}/interf_ref_float.tmp
	cp ${INPUTFILE} ${INPUTREFfloat}
	init_interf_ref.py ${INPUTFILE} ${NUMCOL} ${NUMLINE}
	INPUTFILE=${WORKINGDIR}/interf0_byte.tmp

else
	echo "DATATYPE not known"
	exit
fi
#save interf_ref
cp ${INPUTFILE} ${INPUTREF}


PHACPX=${WORKINGDIR}/phasmooth.float
RESUNWR=${WORKINGDIR}/res_unwr.tmp
INTERFCUM=${WORKINGDIR}/interfcum.tmp
INTERFREWRPFLT=${WORKINGDIR}/rewrfilt.tmp
UNWRFLT=${WORKINGDIR}/unwrfilt.tmp
INTERFCUMSHIFTED=${WORKINGDIR}/interfshifted.tmp
INTERFRESID=${WORKINGDIR}/subtractinterf.tmp
ANG_RESID_FLOAT=${WORKINGDIR}/resid_float.tmp	

# Start iterations
for NIT in $( seq 1 $NITMAX )
do
	echo "* ITERATION No ${NIT} START*"
	#Smoothing Phase
if [ ${DATATYPE} == "float" ]; then
	smoothbyconv_floats.py ${INPUTFILE} ${NUMCOL} ${NUMLINE}
elif  [ ${DATATYPE} == "byte" ] || [ ${DATATYPE} == "float2byte" ]; then
	smoothbyconv_bytes.py ${INPUTFILE} ${NUMCOL} ${NUMLINE}
else
	echo "DATATYPE not known"
	exit
fi
   	
   	#Launch Snaphu
	cd ${WORKINGDIR}
	recur_unwr.sh ${PHACPX} ${NUMCOL}
	cd ${HMDIR}
	
	#Save unwrapping result of iteration NIT
	cp ${RESUNWR} ${WORKINGDIR}/res_unwr_${NIT}.UNWR 
		
	#Filter unwrappedPhase
	filtercut.py ${RESUNWR} ${NUMCOL} ${NUMLINE} ${NIT} ${CUTINI} ${COEFREQ}
	
	#Compute CumulInterf
	if [ `expr ${NIT}` == 1 ]
	then
	cp ${UNWRFLT} ${INTERFCUM}
	else
	add_unwrphase.py ${UNWRFLT} ${INTERFCUMSHIFTED}
	cp ${WORKINGDIR}/addinterf.tmp ${INTERFCUM}
	fi

	if [ ${DATATYPE} == "float" ]; then
		findshift_float.py ${INPUTREF} ${INTERFCUM} ${NUMCOL} ${NUMLINE}
	elif  [ ${DATATYPE} == "byte" ] || [ ${DATATYPE} == "float2byte" ]; then
		findshift_bytes.py ${INPUTREF} ${INTERFCUM} ${NUMCOL} ${NUMLINE}	
	else
		echo "DATATYPE not known"
		exit
	fi
	
	#Save CumulInterf of iteration NIT
	cp ${INTERFCUMSHIFTED} ${WORKINGDIR}/interfcum_${NIT}.UNWR 
	
	#Compute Residual Interf	
	if [ ${DATATYPE} == "float" ]; then
		subtract_interf_float.py ${INPUTFILE} ${INTERFREWRPFLT} #${NUMCOL} ${NUMLINE}
	elif  [ ${DATATYPE} == "byte" ] || [ ${DATATYPE} == "float2byte" ]; then
		subtract_interf_bytes.py ${INPUTFILE} ${INTERFREWRPFLT}
	else
		echo "DATATYPE not known"
		exit
	fi
	cp $INTERFRESID ${WORKINGDIR}/res_interf_${NIT}.oct
	cp $INTERFRESID ${INPUTFILE} 
	
done

add_unwrphase.py ${ANG_RESID_FLOAT} ${INTERFCUMSHIFTED}
TMP=${WORKINGDIR}/addinterf.tmp


write_unwr_defo.py ${TMP} ${HWLEN} ${NUMCOL} ${NUMLINE} ${NEEDADDCOLNAN} ${NEEDADDLINNAN}

INTERFCUMTOT=${WORKINGDIR}/interf_deroule_final.r4
DEFOCUMTOT=${WORKINGDIR}/defomap.r4
cp ${INTERFCUMTOT} ${PATHFILES}/unwrappedPhase.UNWR
cp ${DEFOCUMTOT} ${PATHFILES}/deformationMap.UNWR

#rm ${WORKINGDIR}/*.tmp* ${WORKINGDIR}/phasmooth.float

