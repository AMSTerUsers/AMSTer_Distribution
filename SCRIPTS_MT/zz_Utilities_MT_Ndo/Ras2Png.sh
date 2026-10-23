#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script transforms all the sun raster files from the directory into png files.  
# It runs in parallel on all the available CPUs but one. 
# It is incremental, hence it skips the files already transformed.  
#
# Parameters :  - None
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# Dependencies:	 
#    	- ImageMagick 
#
#
# V 1.0 (Sept 27, 2023)
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 2.1 20240813:	- For Mac OSX, use coreutils fct gnproc instead of sysctl -n hw.ncpu 
# New in Distro V 2.2 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.2 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 


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
echo "Run max ${CPU} processes at a time "

# for VAR in YOUR_LOOP, e.g.
for RASFIG in `find . -maxdepth 1 -type f -name "*.ras"`
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
		RASFIGNOEXT=$(echo "${RASFIG}" | rev | cut -d. -f2- | rev)
		if [ -f "${RASFIGNOEXT}.png" ]
			then 
				echo "${RASFIGNOEXT}.png already exists"
			else 
				echo "transforming ${RASFIGNOEXT}.png..."
				mogrify -format png ${RASFIG}
		fi	
	} &
done 
wait 




