#!/bin/bash
######################################################################################
# This script aims at running a serie of PlotTS.sh to extract the values of time series 
# from a list of pixels. The list, provided as a parameter, is in the form of LINE COL nr. 
# The script runs all the processings in parallel on all CPU's but one. 
# It also remove the eps figure. If you want to keep it, comment the line in script below.
#
# It will then store all the time series values timeLineLINE_COL.txt in a dir SVD.
#
# Ensure that there is no unwanted timeLineLINE_COL.txt list already present in the directory.
#
# NOTE: Must be run where all the deformation maps are located, i.e. /MSBAS/REGION/zz_LOSorUDorEW_...
#
# Parameters : - list of pixels in 2 columns in the form of LINE COL nr.
#
# Dependencies:	- PlotTS.sh
#
# New in 1.1 (Jan 20 2023):	- limit parallel at MAXCPU=5 CPU's (hard coded), or max CPU-1 if less than MAXCPU are available.
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240813:	- For Mac OSX, use coreutils fct gnproc instead of sysctl -n hw.ncpu 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 13, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

PIXLIST=$1

MAXCPU=1		# Seems slower when parallelised !! Keep 1 or make test on your computer... 


# pseudo parallel by running on all but one CPU (fatser than gnuparallel) 
-------------------------------------------------------------------------
# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

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
echo "Max ${CPU} +1 available "

if [ ${CPU} -lt ${MAXCPU} ] 
	then 
		echo "Run ${CPU} processes at a time "
	else 
		CPU=${MAXCPU} 
		echo "Limit to ${CPU} processes at a time to avoid overloading disk reading/writing"
fi

# for VAR in YOUR_LOOP, e.g.
while read -r LIN COL
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
		PlotTS.sh ${LIN} ${COL} -g
		rm -f timeLine${LIN}_${COL}.eps
	} &
done  < ${PIXLIST}
wait 


mkdir SVD
mv timeLine*.txt SVD
