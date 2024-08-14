#!/bin/bash
######################################################################################
# This script is aiming at copying the jpg and binaries + hdr from a given mode 
#      in _AMPLI in original dir.
#
# Parameters :  - ORIGIN dir (usually TARGET dir from ALL2GIF.sh script)
#					Usually something like ..YourPath.../SAR_SM/AMPLITUDES/SAT/TRK/REGION
#
# Dependencies:	 none
#
# New in Distro V 1.0:	- Based on developpement version 1.2 and Beta V1.0.2
# New in Distro V 1.1:	- Also for S1 calibarted images
# New in Distro V 1.2:	- mute error if no sigma0 images
#						- report if dir is missing jpg file 
# New in Distro V 1.3:	- proper path to list of missing files
# New in Distro V 2.0:	- link mv and instead of cp to spare room 
#						- parallelised 
# New in Distro V 2.1:	- debug links
#						- link and move only if target does not exist yet
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20240813:	- For Mac OSX, use coreutils fct gnproc instead of sysctl -n hw.ncpu 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 13, 2024"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " " 

ORIGIN=$1  # Usually something like ..YourPath.../SAR_SM/AMPLITUDES/SAT/TRK/REGION

if [ $# -lt 1 ] ; then echo “Usage $0 ORIGINDIR”; exit; fi

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
echo "// Run max ${CPU} processes at a time "


cd ${ORIGIN}

mkdir -p _AMPLI

DESTINATION=${ORIGIN}/_AMPLI/

ls | ${PATHGNU}/grep -v txt | ${PATHGNU}/grep -v _AMPLI  > DirList.txt

echo "Missing jpg file in :" > ${ORIGIN}/_Missing_files.txt
for DIR in `cat DirList.txt`
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
		cd ${DIR}/i12/InSARProducts
		if [ `ls *.jpg 2>/dev/null | wc -l` -eq 0 ] 
			then 
				echo "// Missing jpg in ${DIR}" 
				echo "${DIR}" >> ${ORIGIN}/_Missing_files.txt
			else 
				for file in `find * -maxdepth 1 -type f -name "*.jpg"` # i.e. not the likns 
					do 
						PREFIXFIG=`basename ${file} | cut -c 1-2`
						if [ ${PREFIXFIG} == "S1" ] # For S1, remove info about S1A or S1B in naming to avoid unsorted images in gif			
							then
								IMAGE=`echo ${file} | sed "s/S1A_//" | sed "s/S1B_//"`
								#cp -n ${file} ${DESTINATION}/${IMAGE} 
								mv -nf ${file} ${DESTINATION}/${IMAGE}
								test -e ${ORIGIN}/${DIR}/i12/InSARProducts/${file} || ln -s ${DESTINATION}/${IMAGE} ${ORIGIN}/${DIR}/i12/InSARProducts/${file}
								# ln -sf ${DESTINATION}/${IMAGE} ${DESTINATION}/${file} # Keep track of original name - do not use while it duplicates the images in the gif
							else
								#cp -n ${file} ${DESTINATION}
								mv -nf ${file} ${DESTINATION}/${file}
								test -e ${ORIGIN}/${DIR}/i12/InSARProducts/${file} || ln -s ${DESTINATION}/${file} ${ORIGIN}/${DIR}/i12/InSARProducts
						fi
					done
			
				for file in `find * -maxdepth 1 -type f -name "*.mod.fl?p.hdr"` # i.e. not the likns *.mod.fl?p.hdr
					do 
						#cp -n ${file} ${DESTINATION}
						mv -nf ${file} ${DESTINATION}/${file}
						test -e ${ORIGIN}/${DIR}/i12/InSARProducts/${file} || ln -s ${DESTINATION}/${file} ${ORIGIN}/${DIR}/i12/InSARProducts
				done
			
				for file in `find * -maxdepth 1 -type f -name "*.mod.fl?p"` # i.e. not the likns *.mod.fl?p 
					do 
						#cp -n ${file} ${DESTINATION}
						mv -nf ${file} ${DESTINATION}/${file}
						test -e ${ORIGIN}/${DIR}/i12/InSARProducts/${file} || ln -s ${DESTINATION}/${file} ${ORIGIN}/${DIR}/i12/InSARProducts
				done

				#if [ `ls *.sigma0.* 2>/dev/null | wc -l` -ge 1 ] 
				#	then 
				#		for file in *.sigma0.fl?p ; do cp -n ${file} ${DESTINATION} ; done 
				#fi
				for file in `find * -maxdepth 1 -type f -name "*.sigma0.*" | grep -v .ras*` # i.e. not the likns *.sigma0.* ; will do also jpg and hdr
					do 
						#cp -n ${file} ${DESTINATION}
						mv -nf ${file} ${DESTINATION}/${file}
						test -e ${ORIGIN}/${DIR}/i12/InSARProducts/${file} || ln -s ${DESTINATION}/${file} ${ORIGIN}/${DIR}/i12/InSARProducts
				done
			
				if [ `find * -maxdepth 1 -type f -name "incidence.fl?p.hdr" | wc -l` -eq 0 ]
					then
						for file in incidence.fl?p.hdr ; do cp -n ${file} ${DESTINATION} ; done
						for file in incidence.fl?p ; do cp -n ${file} ${DESTINATION} ; done
				fi
		fi
		cd ${ORIGIN}
	} &
done 
wait 

rm DirList.txt


