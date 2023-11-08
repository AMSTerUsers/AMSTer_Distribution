#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at updateing AMSTEer Engine by compiling the sources and soring them 
# in appropriate palce and clean compilation directories. It compiles the main software and the tools. 
#
# Parameters :  - path to zipper source of AMSTEer Engine to update 
#				- Date of version to update (YYYYMMDD)
#				- optional: if -p, compile AMSTEer Engine with parallelisation
#
# Dependencies:	 
#				- __HardCodedLines.sh for Path to MT directory depending on the Operating Sytem
#
#
# New in Distro V 1.1: - can be launched with source in any dir or already in .../_Sources_ME/Older/VYYYYMMDD_MasterEngine
# New in Distro V 2.0: - Debug dir name when was not in ${PATHSOURCES}/V${DATEAMSTERENGINE}_MasterEngine
#					   - cope with new tar.xz files distributed by D Derauw for its installer 
# New in Distro V 2.1: - exit if path to MasTerEngine source contains white spaces 
# New in Distro V 2.2: - copy _History.txt in exec dir in order to get info about the last compiled version 
# New in Distro V 3.0: - Path to MasTerEngine (former CIS) now the same for Mac and Linux
# New in Distro V 4.0: - Take into account new location of MasTer Toolbox elements
# New in Distro V 4.1: - Stop if not 2 param provided
# New in Distro V 4.2: - Rename _Sources_ME dir
# New in Distro V 5.0: - Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 5.1: - Allows option for compilation with parallelisation 
# New in Distro V 5.2: - Use new makefile with variable for parallelisation 
# New in Distro V 5.3: - manage the parallelisation option as requested from MasTerEngine V20230826
# New in Distro V 6.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 7.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V7.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Define path to AMSTerEngine and its sources
	PathSourcesAE
# ^^^ ----- Hard coded lines to check --- ^^^ 


NEWAMSTERENGINE=$1		# eg /Users/doris/SAR/AMSTer/AMSTerEngine/_Sources_AE/Older/V20231018_AMSTerEngine
DATEAMSTERENGINE=$2		# eg YYYYMMDD

if [ $# -lt 2 ] ; then echo  "Usage $0 PATH_TO_TAR DATE_OF_VERSION " ; exit; fi

# Ask if want to install with parallelistaion
while true; do
	read -p "Do you want to compile AMSTer Engine with the parallelisation option ? [Y/N] "  yn
	case $yn in
		[Yy]* ) 				
				echo "  OK, I will do it."
				PARALLELOPTION="-p"
				break ;;
		[Nn]* ) 
				echo "  OK, I will compile it without the parallel option."
				PARALLELOPTION=""
				break ;;
			* )  
				echo "Please answer [y]es or [n]o.";;
		esac	
	done					

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

# Functions 
function ParalleliseME()
	{
		SEARCHSTRING=$1 	# YES or NO
		
		# Check if the line for parallelisation exists in the makefile 
 		if ${PATHGNU}/ggrep -qF "USEOPENMP" makefile 
 			then
 				if [ "${SEARCHSTRING}" == "YES" ]
					then 
						echo " using the parallelistaion option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = YES
						#${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = YES"'/' makefile
						make USEOPENMP=YES
					else 
						echo " without using the parallelistaion option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = NO
						#${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = NO"'/' makefile
						make
				fi
			else
			    if [ "${SEARCHSTRING}" == "YES" ]
			    	then 
			  			echo "The parallelistaion option line doesn't exist in the makefile ? It must have a line like this: "
			    		echo "USEOPENMP = ... or USEOPENMP?=..."
			    		echo "If your version of AMSTer Engine is not planned for parallelistaion, just run the script without the -p option."
			    		exit
			    fi
		fi
	}


# Crash if path to ${NEWAMSTERENGINE} contains white spaces 
if [ `echo "${NEWAMSTERENGINE}" | ${PATHGNU}/grep  \  | wc -l` -gt 0 ] ; then echo "Move your AMSTerEngine source in a dir without white spaces in name !" ; exit ; fi


if [ `dirname ${NEWAMSTERENGINE}` != ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine ]
	then 
		echo "updating from source located anywhere but ${PATHAMSTerENGINE}/_Sources_AE/Older/V${DATEAMSTERENGINE}_AMSTerEngine"
		mkdir -p ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine
		cp -f ${NEWAMSTERENGINE} ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine/
	else 
		echo "updating from  ${PATHAMSTerENGINE}/_Sources_AE/Older/V${DATEAMSTERENGINE}_AMSTerEngine"
fi

cd ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine

	if [ `ls *.tar.xz  | wc -l` -gt 1 ] 
		then 
			echo "More than one tar file. Please check"
			exit 
		else 
			TARDIRNAME=`ls *.tar.xz | cut -d . -f 1`
			echo "Decompress ${TARDIRNAME}.tar.xz..."
			tar -xf *.tar.xz
	fi

if [ -d ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine/${TARDIRNAME}/Archives ]
	then 
		# seems to be the new version of AMSTerEngine distrubution, that is made for the installer
		VERSION=NEW
		cd ${TARDIRNAME}/Archives
		TARNAME=`ls Mas*.tar.xz`
		echo "   Decompress ${TARNAME}.tar.xz..."
		tar -xf Mas*.tar.xz
		cd InSAR/sources
	else
		# seems to be the old version of AMSTerEngine distrubution
		VERSION=OLD
		if [ -d ${TARDIRNAME} ]		# because sometimes tar decompress in current dir or in dir named by the tar file...
			then 
				cd ${TARDIRNAME}/InSAR/sources
			else 
				TARDIRNAME=""
				cd InSAR/sources			
		fi
fi 

echo
echo "Compile AMSTerEngine "

if [ "${PARALLELOPTION}" == "-p" ]
	then 
		ParalleliseME "YES" 
	else 
		ParalleliseME "NO" 
fi

#make 

cp _History.txt ${PATHAMSTERENGINE}/

cd ../bin
if [ -f initInSAR ] 
	then 
		echo
		echo "I will move all the binaries to ${PATHAMSTERENGINE} from here, that is: "
		pwd
		mv -f * ${PATHAMSTERENGINE}/
	else 
		echo "I can't find the binaries to move to ${PathSourcesAE} from here. I am probably not at the right place. Please check. "
		pwd
		exit
fi
cd ../..

## May need to do the MSBAS Tools as well 
echo
echo "-------------------------------"
echo "Compile MSBAS Tools as well "

cd MSBASTools/sources

if [ "${PARALLELOPTION}" == "-p" ]
	then 
		ParalleliseME "YES" 
	else 
		ParalleliseME "NO" 
fi
#make 

cd ../bin
if [ -f getLineThroughStack ] 
	then 
		echo
		echo "I will move all the binaries to ${PATHAMSTERENGINE} from here, that is: "
		pwd
		mv -f * ${PATHAMSTERENGINE}/
	else 
		echo "I can't find the binaries to move to ${PATHAMSTERENGINE} from here. I am probably not at the right place. Please check. "
		pwd
		exit
fi
cd ../..

echo 
echo

while true; do
	read -p "Do you want to clean ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine/${TARDIRNAME} ?"  yn
	case $yn in
		[Yy]* ) 
			cd ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine/
			if [ "${TARDIRNAME}" == "" ]
				then 
					rm -R InSAR
					rm -R MSBASTools
				else
					rm -R ${TARDIRNAME}
			fi
			break ;;
		[Nn]* ) 
			exit 1	
			break ;;
		* ) echo "Please answer yes or no.";;
	esac
done



