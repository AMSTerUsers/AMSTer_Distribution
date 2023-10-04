#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script transforms all the sun raster files from the directory into png files.  
# It runs in parallel on all the available CPUs but one. 
# It is incremental, hence it skips the files already transformed.  
#
# Parameters :  - None
#
# Dependencies:	 
#    	- ImageMagick 
#
#
# New in Distro V 1.0:	- 
# 
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/25 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0.MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 27, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"

# test nr of CPUs
# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		NCPU=`nproc` 	;;
	"Darwin")
		NCPU=`sysctl -n hw.ncpu` 
		
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




