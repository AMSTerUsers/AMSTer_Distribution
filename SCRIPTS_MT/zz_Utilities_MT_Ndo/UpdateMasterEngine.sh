#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at updateing MasTer Engine by compiling the sources and soring them 
# in appropriate palce and clean compilation directories. It compiles the main software and the tools. 
#
# Parameters :  - path to zipper source of MasTer Engine to update 
#				- Date of version to update (YYYYMMDD)
#				- optional: if -p, compile MasTer Engine with parallelisation
#
# Dependencies:	 
#				- __HardCodedLines.sh for Path to MT directory depending on the Operating Sytem
#
#
# New in Distro V 1.1: - can be launched with source in any dir or already in .../_Sources_ME/Older/VYYYYMMDD_MasterEngine
# New in Distro V 2.0: - Debug dir name when was not in ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine
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
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2017/12/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V6.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# Define path to MasTerEngine and its sources
	PathSourcesME
	#PATHMASTERENGINE=${HOME}/SAR/MasTerToolbox/MasTerEngine
	#PATHSOURCES=${PATHMASTERENGINE}/_Sources_ME/Older
# ^^^ ----- Hard coded lines to check --- ^^^ 


NEWMASTERENGINE=$1		# eg /Users/doris/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/FE19E5F2-8360-413D-BF92-8849E4A7F75E/MasTerEngine20211013.tar.xz
DATEMASTERENGINE=$2		# eg YYYYMMDD

if [ $# -lt 2 ] ; then echo  "Usage $0 PATH_TO_TAR DATE_OF_VERSION " ; exit; fi

# Ask if want to install with parallelistaion
while true; do
	read -p "Do you want to compile MasTer Engine with the parallelisation option ? [Y/N] "  yn
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
			    		echo "If your version of MasTer Engine is not planned for parallelistaion, just run the script without the -p option."
			    		exit
			    fi
		fi
	}


# Crash if path to ${NEWMASTERENGINE} contains white spaces 
if [ `echo "${NEWMASTERENGINE}" | ${PATHGNU}/grep  \  | wc -l` -gt 0 ] ; then echo "Move your MasTerEngine source in a dir without white spaces in name !" ; exit ; fi


if [ `dirname ${NEWMASTERENGINE}` != ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine ]
	then 
		echo "updating from source located anywhere but ${PATHMASTERENGINE}/_Sources_ME/Older/V${DATEMASTERENGINE}_MasterEngine"
		mkdir -p ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine
		cp -f ${NEWMASTERENGINE} ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine/
	else 
		echo "updating from  ${PATHMASTERENGINE}/_Sources_ME/Older/V${DATEMASTERENGINE}_MasterEngine"
fi

cd ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine

	if [ `ls *.tar.xz  | wc -l` -gt 1 ] 
		then 
			echo "More than one tar file. Please check"
			exit 
		else 
			TARDIRNAME=`ls *.tar.xz | cut -d . -f 1`
			echo "Decompress ${TARDIRNAME}.tar.xz..."
			tar -xf *.tar.xz
	fi

if [ -d ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine/${TARDIRNAME}/Archives ]
	then 
		# seems to be the new version of MasterEngine distrubution, that is made for the installer
		VERSION=NEW
		cd ${TARDIRNAME}/Archives
		TARNAME=`ls Mas*.tar.xz`
		echo "   Decompress ${TARNAME}.tar.xz..."
		tar -xf Mas*.tar.xz
		cd InSAR/sources
	else
		# seems to be the old version of MasterEngine distrubution
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
echo "Compile MasTerEngine "

if [ "${PARALLELOPTION}" == "-p" ]
	then 
		ParalleliseME "YES" 
	else 
		ParalleliseME "NO" 
fi

#make 

cp _History.txt ${PATHMASTERENGINE}/

cd ../bin
if [ -f initInSAR ] 
	then 
		echo
		echo "I will move all the binaries to ${PATHMASTERENGINE} from here, that is: "
		pwd
		mv -f * ${PATHMASTERENGINE}/
	else 
		echo "I can't find the binaries to move to ${PATHMASTERENGINE} from here. I am probably not at the right place. Please check. "
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
		echo "I will move all the binaries to ${PATHMASTERENGINE} from here, that is: "
		pwd
		mv -f * ${PATHMASTERENGINE}/
	else 
		echo "I can't find the binaries to move to ${PATHMASTERENGINE} from here. I am probably not at the right place. Please check. "
		pwd
		exit
fi
cd ../..

echo 
echo

while true; do
	read -p "Do you want to clean ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine/${TARDIRNAME} ?"  yn
	case $yn in
		[Yy]* ) 
			cd ${PATHSOURCES}/V${DATEMASTERENGINE}_MasterEngine/
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



