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
# New in Distro V 7.1 20250417:	- Get date where to store source from file name instead of 2nd param if source is named AMSTerEngineYYYYMMDDi.tar.xz where i may be a letter
#								  If not named like taht a second parameter remains mandatory for archiving the source 
# New in Distro V 7.2 20260702:	- ParalleliseME now passes PKGMGR to make, so InSAR/sources and MSBASTools/sources
#								  makefiles can select Homebrew (macOS Tahoe/26+) vs MacPorts on Darwin
#								 (requires updated InSAR/sources/makefile and MSBASTools/sources/makefile with the new PKGMGR branch)
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
filename="$(basename "${NEWAMSTERENGINE}")"

if [ $# -lt 1 ] ; then echo  "Usage $0 PATH_TO_TAR [DATE_OF_VERSION]" ; exit; fi

if [ $# -eq 1 ] 
	then 
		if [[ "$filename" =~ ^AMSTerEngine([0-9]{8}[a-zA-Z]?)\.tar\.xz$ ]]
			then
				echo " // AMSTer Engine source is provdied with usual format, that is AMSTerEngineYYYYMMDDi.tar.xz," 
				echo " //               where i is an optional letter if there is more than one version in that day"
				DATEAMSTERENGINE="${BASH_REMATCH[1]}"
				echo " // Hence source will be archived in dir named V${DATEAMSTERENGINE}_AMSTerEngine"
			else 
				echo " // AMSTer Engine source not provdied with usual format, that is AMSTerEngineYYYYMMDDi.tar.xz,"
				echo " //                where i is an optional letter if there is more than one version in that day"
				echo " // Hence the script needs to be provided with a second parameter as the date of the version :"
				echo				
				echo  "Usage $0 PATH_TO_TAR DATE_OF_VERSION " ; exit
		fi
fi

if [ $# -eq 2 ] ; then 
	DATEAMSTERENGINE=$2		# eg YYYYMMDD 
fi

echo 

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



# Functions 
###########
function ParalleliseME()
	{
		SEARCHSTRING=$1 	# YES or NO
		
		# Check if the line for parallelisation exists in the makefile 
 		if ${PATHGNU}/ggrep -qF "USEOPENMP" makefile 
 			then
 				if [ "${SEARCHSTRING}" == "YES" ]
					then 
						echo " using the parallelisation option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = YES
						#${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = YES"'/' makefile
						make USEOPENMP=YES PKGMGR=${PKGMGR}
					else 
						echo " without using the parallelisation option"
						# replace the line containing "USEOPENMP =" whatever the option is set as USEOPENMP = NO
						#${PATHGNU}/gsed -i 's/.*'"USEOPENMP ="'.*/'"USEOPENMP = NO"'/' makefile
						make PKGMGR=${PKGMGR}
				fi
			else
			    if [ "${SEARCHSTRING}" == "YES" ]
			    	then 
			  			echo "The parallelisation option line doesn't exist in the makefile ? It must have a line like this: "
			    		echo "USEOPENMP = ... or USEOPENMP?=..."
			    		echo "Your version of AMSTer Engine seems not planned for parallelisation. Compile it as it is..."
						make PKGMGR=${PKGMGR}
					else 
			  			echo "The parallelisation option line doesn't exist in the makefile but you do not want to anyway. "
			    		echo "Compile it as it is..."
						make PKGMGR=${PKGMGR}
			    fi
		fi
	}

function DetectMacArch()
	{
	# Determine the REAL hardware architecture, even if this Terminal/shell is currently
	# running translated under Rosetta 2 (e.g. "Open using Rosetta" ticked for Terminal.app/iTerm,
	# or the script was launched with "arch -x86_64 bash ..."). Sets MACARCH (arm64/x86_64)
	# and ROSETTA (yes/no) = whether THIS shell process is currently running translated.
	unset MACARCH
	unset ROSETTA
	local RUNARCH
	local TRANSLATED
	RUNARCH=$(uname -m)
	TRANSLATED=$(sysctl -n sysctl.proc_translated 2>/dev/null)
	if [ "${RUNARCH}" == "arm64" ]
		then
			MACARCH="arm64"
			ROSETTA="no"
		elif [ "${TRANSLATED}" == "1" ]
			then
				MACARCH="arm64"		# real hardware is Apple Silicon ; this shell just happens to run translated
				ROSETTA="yes"
			else
				MACARCH="x86_64"		# genuine Intel Mac
				ROSETTA="no"
	fi
	}

function DetectBrewPrefix()
	{
	# Locate an existing Homebrew installation, preferring the one NATIVE for this Mac's
	# real hardware architecture (Apple Silicon -> /opt/homebrew, Intel -> /usr/local).
	# Sets BREWPREFIX and BREWNATIVE (yes/no/unknown). Warns (via BREWNATIVE=no) if only a
	# non-native (Rosetta-translated) Homebrew is found, so the caller can offer to fix it.
	unset BREWPREFIX
	unset BREWNATIVE

	local NATIVEPREFIX
	local OTHERPREFIX
	if [ "${MACARCH}" == "arm64" ]
		then NATIVEPREFIX="/opt/homebrew" ; OTHERPREFIX="/usr/local"
		else NATIVEPREFIX="/usr/local" ; OTHERPREFIX="/opt/homebrew"
	fi

	if [ -x "${NATIVEPREFIX}/bin/brew" ]
		then
			BREWPREFIX="${NATIVEPREFIX}"
			BREWNATIVE="yes"
		elif [ -x "${OTHERPREFIX}/bin/brew" ]
			then
				BREWPREFIX="${OTHERPREFIX}"
				BREWNATIVE="no"
			elif command -v brew &> /dev/null
				then
					BREWPREFIX=$(brew --prefix 2>/dev/null)
					BREWNATIVE="unknown"
			else
				# Homebrew not installed yet anywhere ; target the native prefix for the fresh install later in the script
				BREWPREFIX="${NATIVEPREFIX}"
				BREWNATIVE="yes"
	fi

	# Make sure brew (once installed) is usable in this very shell/script, even in a fresh Terminal
	if [ -x "${BREWPREFIX}/bin/brew" ] ; then eval "$(${BREWPREFIX}/bin/brew shellenv)" ; fi
	}


############
# Check OS #
############
# MACOS PACKAGE MANAGER STRATEGY:
#   - macOS Tahoe (OSX_MAJOR -ge 26) and later: use Homebrew (some options/variants
#     this script needs are not available - or not installable - through MacPorts anymore).
#   - Older macOS: keep using MacPorts as before (unchanged behaviour).
#   PKGMGR is set to either "brew" or "port" and is used everywhere a Mac package
#   needs to be installed/checked (see fct PortInstall, BrewInstall, CheckLasPortVersion...).

OS=$(uname -a | cut -d " " -f 1 )
echo "Running on ${OS}"
echo

# These AMSTerEngine/msbas .tar.xz archives are created on macOS, which preserves
# macOS-specific extended attributes (quarantine flag, Finder info, etc.) as PAX
# extended tar headers. GNU tar (Linux) doesn't understand these keywords and prints
# a harmless "Ignoring unknown extended header keyword" warning for each one -
# extraction still works correctly. Silence just that specific warning on Linux.
# (BSD tar on macOS doesn't need this - it's the one producing those headers.)
TARWARNFLAG=""
if [ "${OS}" == "Linux" ] ; then TARWARNFLAG="--warning=no-unknown-keyword" ; fi

TSTSH=$(echo "$SHELL")
if [ "${OS}" == "Darwin" ] 
	then 
		DetectMacArch

		# If this Terminal/shell is running translated under Rosetta 2 on an Apple Silicon Mac,
		# relaunch natively right away so Homebrew, compilers and every command below run as
		# arm64 (mixing translated and native tools causes real, hard-to-diagnose problems).
		if [ "${ROSETTA}" == "yes" ] 
			then 
				echo " // This Terminal/shell is currently running translated (Rosetta 2) though this Mac is Apple Silicon (arm64). "
				echo " // Relaunching ${PRG} natively as arm64 to avoid mixing translated and native tools... "
				exec arch -arm64 /bin/bash "$0" "$@"
				exit	# should never be reached (exec replaces the process) ; safety net only
		fi

		if [ "${TSTSH}" == "/bin/bash" ] 
			then 
				echo " // Your OS is probably older than v 10.15 or shell was already changed to bash. No action required. "
			else	
				echo " // Your OS is probably v 10.15 or more recent. Need to change default shell Zsh with bash for scripts compatibility issues. "
				chsh -s /bin/bash 	
				echo " // It will only be effective in a new Terminal, hence close the present Terminal and relaunch the prensent script in that new terminal"
				exit
		fi
		
		PROCESSOR="${MACARCH}"

		OSX_VER=$(sw_vers -productVersion)
		OSX_MAJOR=$(echo "$OSX_VER" | cut -d. -f1)
		OSX_MINOR=$(echo "$OSX_VER" | cut -d. -f2)

		# Decide which Mac package manager to use
		if [ "${OSX_MAJOR}" -ge 26 ] 
			then 
				PKGMGR="brew"
				echo " // Detected macOS ${OSX_VER} (Tahoe or later) -> Homebrew will be used instead of MacPorts. "
			else 
				PKGMGR="port"
		fi
		DetectBrewPrefix

fi
				

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
			tar ${TARWARNFLAG} -xf *.tar.xz
	fi

if [ -d ${PATHSOURCES}/V${DATEAMSTERENGINE}_AMSTerEngine/${TARDIRNAME}/Archives ]
	then 
		# seems to be the new version of AMSTerEngine distrubution, that is made for the installer
		VERSION=NEW
		cd ${TARDIRNAME}/Archives
		TARNAME=`ls Mas*.tar.xz`
		echo "   Decompress ${TARNAME}.tar.xz..."
		tar ${TARWARNFLAG} -xf Mas*.tar.xz
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



