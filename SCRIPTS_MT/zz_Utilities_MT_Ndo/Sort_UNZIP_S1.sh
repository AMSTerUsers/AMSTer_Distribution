#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at reading all the S1 RAW images from a given UNZIP dir 
# 	e.g. S1-DATA_YourPlace-SLC.UNZIP
# and store them in directories by modes (A or D) and Orb Nr (Trk) taken from their manifest.safe
# It then links back the raw images to the original UNZIP dir 
#
# Parameters : - path to dir with the raw archives to read.   
#				
#
# Dependencies:	- none
#
# New in Distro V 1.1:	-
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Feb 27, 2025"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) "
echo " "

RAW=$1					# path to dir with the raw archives to read (unzipped for S1 !)

RAWNOUNZIP=$(basename "${RAW}" | cut -d . -f1)	# e.g. S1-DATA-NEPAL-SLC without .UNZIP

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# test nr of CPUs
	case ${OS} in
		"Linux")
			NCPU=`nproc` 	;;
		"Darwin")
			#NCPU=`sysctl -n hw.ncpu`
			NCPU=$(gnproc)
			
			# must define a function because old bash on Mac does not know wait -n option
			waitn ()
				{ StartJobs="$(jobs -p)"
				  CurJobs="$(jobs -p)"
				  while diff -q  <(echo -e "$StartJobs") <(echo -e "$CurJobs") >/dev/null
				  do
					sleep 1
					CurJobs="$(jobs -p)"
				  done
				}

			;;
	esac

	CPU=$((NCPU-1))
	echo "Run max ${CPU} processes at a time "

cd ${RAW}

for S1IMGPATH in `find . -maxdepth 1 -type d -name "*.SAFE" ! -xtype l -printf "%f\n" `  # list the new dir but not the links
	do
		if test "$(jobs | wc -l)" -ge ${CPU}
			then
				case ${OS} in
					"Linux")
						wait -n 	;;
					"Darwin")
						waitn		;;
				esac
		fi
		# Run tests in pseudo parallelism
		{

			MODE=$(${PATHGNU}/gsed -n 's/.*<s1:pass>\(.\).*/\1/p' ${S1IMGPATH}/manifest.safe)	# i.e. get the first letter of word between > and < in line like <s1:pass>DESCENDING</s1:pass>, that is A or D
			S1TRK=$(${PATHGNU}/gsed -n 's/.*<safe:relativeOrbitNumber type="start">\([0-9]\+\)<.*/\1/p' ${S1IMGPATH}/manifest.safe)		# Get the orbit nr

			mkdir -p ../${RAWNOUNZIP}_${MODE}${S1TRK}.UNZIP
			mv ${S1IMGPATH} ../${RAWNOUNZIP}_${MODE}${S1TRK}.UNZIP
			
			# if less than 6 months, keep a link in dir:
			YEARFILE=`echo ${S1IMGPATH} | cut -c 18-21`
			MMFILE=`echo ${S1IMGPATH} | cut -c 22-23 | ${PATHGNU}/gsed 's/^0*//'`
			DATEFILE=`echo "${YEARFILE} + ( ${MMFILE} / 12 ) - 0.0001" | bc -l` # 0.0001 to avoid next year in december
			YRNOW=`date "+ %Y"`
			MMNOW=`date "+ %-m"`
			DATENOW=`echo "${YRNOW} + ( ${MMNOW} / 12 )" | bc -l`
			DATEHALFYRBFR=`echo "${DATENOW} - 0.5" | bc -l`
			TST=`echo "${DATEFILE} > ${DATEHALFYRBFR}" | bc -l`
			if [ ${TST} -eq 1 ]
				then
					ln -s ../${RAWNOUNZIP}_${MODE}${S1TRK}.UNZIP/${S1IMGPATH} ${RAW}
			fi

		} &
done
wait
