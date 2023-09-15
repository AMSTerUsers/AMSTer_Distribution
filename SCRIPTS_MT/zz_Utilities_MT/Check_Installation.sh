#!/bin/bash
# This script aims at checking the installation. 
#
# Parameters are: none
#
# Dependencies:	all the required components for MasTer, that is 
#				- gnu sed, awk, grep, seq, date 
#               - Appel's osascript for opening terminal windows if OS is Mac
#               - x-terminal-emulator for opening terminal windows if OS is Linux
#			    - say for Mac or espeak for Linux
#				- scripts ...
#
# New in Distro V 1.0.1: - accounts for usage with msbasv4, i.e. that requires additional info in header files 
# New in Distro V 1.1.0: - cope with new S1 orbit dir state variable 
# New in Distro V 2.0.0: - Adapted to install V3  
# New in Distro V 2.1.0: - Adapted to new architecture as installed by MasTer_install.sh V 2.6 Beta
# New in Distro V 2.2.0: - several improvements...
#						 - check clang for Linux installation
# New in Distro V 2.2.1: - Rename _Sources_ME dir
# New in Distro V 2.3.0: - add parallel
# New in Distro V 2.4.0: - add check some config files 
# New in Distro V 2.4.1: - typo in if test (-gt0) 
# New in Distro V 2.4.2: - Do not use DISPLAY state variable with Linux ! 
# New in Distro V 2.5.0: - test optimtoolbox, MasTerOrganizer, TSCombiFiles and TemplatesForPlots directories are OK
#						 - search for msbas v 1-20
#						 - add test pyqt6, networkx, mpich, pip, gsl and appscript (Mac)
#						 - tells that osgeo is test for gdal
# New in Distro V 3.0 20230916:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2020/06/15 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V3.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2020, Last modified on Sept 16, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc
# ^^^ ----- Hard coded lines to check --- ^^^ 

cd 
eval HOMEDIR=$(pwd)

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"
echo

function EchoInverted()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo "${smso}${MESSAGE}${rmso}"
	}

function TestVariable()
	{
	# PROVIDE WWITH GNU VERSION FIRST
	unset VARTOTEST1
	unset VARTOTEST2
	local VARTOTEST1=$1	
	local VARTOTEST2=$2	

	if [ $# -eq 2 ] 
		then 
			type -t ${VARTOTEST1}  >/dev/null
			if [ `echo $?` == "0" ]
				then
					# Get all versions of VARTOTEST1
					NRVAR1=`which -a ${VARTOTEST1} | tr -s / | sort | uniq | wc -l`
					if [ ${NRVAR1} -eq 1 ]
						then 
							#only one version of cmd
							VERVARTOTEST1=$(${VARTOTEST1} --version  2> /dev/null | head -1 )
							WHICHVAR1=$(which ${VARTOTEST1})
							#echo "--> ${VARTOTEST1}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VERVARTOTEST1}$(tput sgr 0)	(in: $(dirname ${WHICHVAR1}))"
							printf "%-60s%-20s\n" "--> ${VARTOTEST1}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VERVARTOTEST1}$(tput sgr 0) (in: $(dirname ${WHICHVAR1}))"
						elif [ ${NRVAR1} -eq 0 ]
						then 
							#echo "    ${VARTOTEST1}	$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"  # red on white text
							printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)    ${VARTOTEST1}" "missing $(tput sgr 0)"
						elif [ ${NRVAR1} -gt 1 ]
						then 
							echo "    ${VARTOTEST1}	$(tput setaf 1)$(tput setab 7)has more than one GNU version ? - pelase check: $(tput sgr 0)"  # red on white text
							#printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)    ${VARTOTEST1}" "missing $(tput sgr 0)"
							which -a ${VARTOTEST1} | tr -s / | sort | uniq | sed "s/^/\t/"
						else
							echo "    I can't figure out what is going on with '${VARTOTEST1}	$(tput setaf 1)$(tput setab 7) - pelase check: $(tput sgr 0)"  # red on white text
					fi
							
					type -t ${VARTOTEST2}  >/dev/null
					if [ `echo $?` == "0" ]
						then
							# Get all versions of VARTOTEST2
							NRVAR2=`which -a ${VARTOTEST2} | tr -s / | sort | uniq | wc -l`
							if [ ${NRVAR2} -eq 1 ]
								then 
									#only one version of cmd
									VERVARTOTEST2=$(${VARTOTEST2} --version  2> /dev/null | head -1 )
									WHICHVAR2=$(which ${VARTOTEST2})

									# IF VERVARTOTEST EMPTY AND MAC OSX TRY 
	 								if [ "${VERVARTOTEST2}" == ""  ] && [ ${OS} == "Darwin" ]
 										then 
 											# Probably BSD version
 											VERVARTOTEST2=$(man ${VARTOTEST2} | ${PATHGNU}/gsed '$!d; s/ *BSD *//g' | cut -d " " -f 1-3 ) 
 				 							VERVARTOTEST1=`echo ${VERVARTOTEST1} | cut -d " " -f2-`
											VERVARTOTEST2=`echo ${VERVARTOTEST2} | cut -d " " -f2-`
 				 							if [ "${VERVARTOTEST1}" != "${VERVARTOTEST2}" ] 
 				 								then 
 				 									#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})).  $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc $(tput sgr 0)"  # green text
	 												printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${VARTOTEST})).  $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc $(tput sgr 0)"
 				 								else
 				 									#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})).  "  # green text
	 												printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). "

											fi
										else
											#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${WHICHVAR1}))"
											printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${WHICHVAR1})). "
											VERVARTOTEST1=`echo ${VERVARTOTEST1} | cut -d " " -f2-`
											VERVARTOTEST2=`echo ${VERVARTOTEST2} | cut -d " " -f2-`
											if [ "${VERVARTOTEST1}" != "${VERVARTOTEST2}" ] 
												then 
 				 									#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})).  $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"  # green text
 				 									printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"
 				 								else
 				 									#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})).  "  # green text
													printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). "
											fi
									fi
									

								elif [ ${NRVAR2} -eq 0 ]
								then 
									#echo "    ${VARTOTEST2}	$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"  # red on white text
									printf "%-60s%-20s\n" "    ${VARTOTEST2}" "$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
								elif [ ${NRVAR2} -gt 1 ] # usually only two, i.e. one gnu and one BSD if Mac OSX
								then 
									echo "    $(tput setaf 3)${VARTOTEST2} has more than one version: $(tput sgr 0)"  # yellow
									for VARTOTEST in `which -a ${VARTOTEST2} | tr -s / | sort | uniq`
										do
											VERVARTOTEST=$(${VARTOTEST} --version  2> /dev/null | head -1 | cut -d " " -f 2- )
											# IF VERVARTOTEST EMPTY AND MAC OSX TRY 
											if [ "${VERVARTOTEST}" == ""  ] && [ ${OS} == "Darwin" ]
												then 
													# Probably BSD version
													VERVARTOTEST=$(man ${VARTOTEST2} | ${PATHGNU}/gsed '$!d; s/ *BSD *//g' | cut -d " " -f 1-3 ) 
				 									#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})).  $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"  # green text
													printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"
												else
													# Probably link to gnu version or other
													VERVARTOTEST1=`echo ${VERVARTOTEST1} | cut -d " " -f2- | ${PATHGNU}/gsed 's/.* //'`
													VERVARTOTEST=`echo ${VERVARTOTEST} | cut -d " " -f2- | ${PATHGNU}/gsed 's/.* //'`
													if [ "${VERVARTOTEST1}" != "${VERVARTOTEST}" ] 
														then 
															#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0)	(in: $(dirname ${VARTOTEST})). $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"
															printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). $(tput setaf 3) Beware if different from GNU version; ensure that path to GNU version comes first in bashrc  $(tput sgr 0)"
														else 
															#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0)	(in: $(dirname ${VARTOTEST}))$(tput setaf 2) same as GNU version$(tput sgr 0) "
															printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VARTOTEST2} ${VERVARTOTEST}$(tput sgr 0) (in: $(dirname ${VARTOTEST})). $(tput setaf 2) same as GNU version$(tput sgr 0)"
													fi

											fi
									done

								else
									echo "    I can't figure out what is going on with '${VARTOTEST2}	$(tput setaf 1)$(tput setab 7) - pelase check: $(tput sgr 0)"  # red on white text
							fi

					fi
				else 
					#echo "--> ${VARTOTEST1}	$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
					printf "%-60s%-20s\n" "--> ${VARTOTEST1}" "$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
					
					type -t ${VARTOTEST2}  >/dev/null
					if [ `echo $?` == "0" ]
						then
							VERVARTOTEST2=$(${VARTOTEST2} --version  2> /dev/null| head -1 2>&1) 
							WHICHVAR2=$(which ${VARTOTEST2})
							#echo "    ${VARTOTEST2}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VERVARTOTEST2}$(tput sgr 0)	(in: $(dirname ${WHICHVAR2}))"  # green text
							printf "%-60s%-20s\n" "    ${VARTOTEST2}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VERVARTOTEST2}$(tput sgr 0) (in: $(dirname ${WHICHVAR2}))"
							VERVARTOTEST2=`echo ${VERVARTOTEST2} | cut -d " " -f2-`
						else 
							#echo "    ${VARTOTEST2}	$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"  # red on white text
							printf "%-60s%-20s\n" "    ${VARTOTEST2}" "$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
					fi
			fi
		else 
			type -t ${VARTOTEST1}  >/dev/null
			if [ `echo $?` == "0" ]
				then
					VERVARTOTEST1=$(${VARTOTEST1} --version  2> /dev/null | head -1)
					WHICHVAR1=$(which ${VARTOTEST1})
					#echo "--> ${VARTOTEST1}:$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VERVARTOTEST1}$(tput sgr 0) (in: $(dirname ${WHICHVAR1}))"
					printf "%-60s%-20s\n" "--> ${VARTOTEST1}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VERVARTOTEST1}$(tput sgr 0) (in: $(dirname ${WHICHVAR1}))"
				else 
					#echo "--> ${VARTOTEST1}	$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
					printf "%-60s%-20s\n" "--> ${VARTOTEST1}" "$(tput setaf 1)$(tput setab 7)missing $(tput sgr 0)"
			fi
	fi
	}

function TestVariableShort()
	{
	unset VARTOTEST
	local VARTOTEST=$1	
	type -t ${VARTOTEST}  >/dev/null
	if [ `echo $?` == "0" ]
		then
			WHICHVAR=$(which ${VARTOTEST})
			case "${VARTOTEST}" in 
				"snaphu")
					snaphu > tmp.txt
					VERVARTOTEST=`cat tmp.txt | ${PATHGNU}/grep snaphu | head -1 | cut -d " " -f2`
					rm tmp.txt
					;;
				"cpxfiddle")
					cpxfiddle 2> tmp.txt
					VERVARTOTEST=`cat tmp.txt | ${PATHGNU}/grep version | cut -d " " -f6`
					;;
				"msbas"*)
					VERVARTOTEST=`echo ${VARTOTEST} | cut -c 6-`
					;;
				*)
				    ;;
			esac
			printf "%-60s%-20s\n" "--> ${VARTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VERVARTOTEST}$(tput sgr 0) (in: ${WHICHVAR})"

		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ${VARTOTEST}" "missing $(tput sgr 0)"
	fi
	}
	
function TestPythonModule()
	{
		unset MODULE
		unset PATHTOPY
		local MODULE=$1	
		local PATHTOPY=$2
		
		${PATHTOPY} -c "import ${MODULE}"  2> /dev/null
		if [ $? == "0" ] ; then 
				if [ "${MODULE}" == "osgeo" ] ; then COMMENTGDAL="(gdal)" ; else COMMENTGDAL="" ; fi
				VER=`${PATHTOPY} -c "import ${MODULE}; print(${MODULE}.__version__)"  2> /dev/null`
				if [ "${VER}" == "" ] 
					then 
						echo "    ${MODULE}:$(tput setaf 2)	passed$(tput sgr 0)		Version	nr is missing though ${COMMENTGDAL} "
					else
						echo "    ${MODULE}:$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VER}$(tput sgr 0) ${COMMENTGDAL}" 
				fi
			else 
				echo "    ${MODULE}:	$(tput setaf 1)$(tput setab 7)missing$(tput sgr 0) ${COMMENTGDAL}"
		fi
	}

function TestPythonModuleQt()
	{
		unset MODULE
		unset PATHTOPY
		unset APPL
		local MODULE=$1	
		local APPL=$2
		local PATHTOPY=$3
		
		${PATHTOPY} -c "from ${MODULE} import ${APPL}"  2> /dev/null
		if [ $? == "0" ]
			then 
				echo "    PyQt6:$(tput setaf 2)	passed$(tput sgr 0)		Version	nr is missing though" 
			else 
				echo "    PyQt6:	$(tput setaf 1)$(tput setab 7)missing$(tput sgr 0)"
		fi
	}


function TestVarBashrc()
	{

		unset VARTOTEST
		unset TST
		local VARTOTEST=$1	
		
		TST=`cat ${HOMEDIR}/.bashrc | grep "export ${VARTOTEST}" | grep -v "#"  2>/dev/null`
		if [ "${TST}" == "" ] 
			then 
				printf "%-60s%-20s\n" "--> ${VARTOTEST}:" "$(tput setaf 1)$(tput setab 7)missing$(tput sgr 0)"
			else 
				printf "%-60s%-20s\n" "--> ${VARTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Value :	$(tput setaf 2)${TST}$(tput sgr 0)"
		fi
	}

function TestDirs()
	{
		unset DIRTOTEST
		unset TST
		local DIRTOTEST=$1	
		
		if [ ! -d "${DIRTOTEST}" ] 
			then 
				printf "%-75s%-20s\n" "--> ${DIRTOTEST}:" "$(tput setaf 1)$(tput setab 7)unreachable ! $(tput sgr 0)"
			else 
				printf "%-75s%-20s\n" "--> ${DIRTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)"

		fi
	}


function CheckLib3()
	{
		unset LIBTOTEST
		unset LIB
		unset EXT1
		unset EXT2
		unset VER

		local LIBTOTEST=$1	
		
		LIB=`echo ${LIBTOTEST} | cut -d - -f1`
		EXT1=`echo ${LIBTOTEST} | cut -d - -f2`
		EXT2=`echo ${LIBTOTEST} | cut -d - -f3`
						
		if [ `ldconfig -p | ${PATHGNU}/grep ${LIB} | wc -l` -gt 0 ] 
			then 
				VER=$(dpkg  -l | ${PATHGNU}/grep ${LIB} | ${PATHGNU}/grep ${EXT1} | ${PATHGNU}/grep ${EXT2} | ${PATHGNU}/gawk '{ print $3 }' | head -1 )			# if more than one version, take only the first one... 
				#echo "--> ${LIBTOTEST}-${EXT1}:$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VERHD}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> ${LIBTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}-${EXT1} : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}:" "failed$(tput sgr 0)"
		fi
	}
function CheckLib2()
	{
		unset LIBTOTEST
		unset LIB
		unset EXT1
		unset VER

		local LIBTOTEST=$1	
		
		LIB=`echo ${LIBTOTEST} | cut -d - -f1`
		EXT1=`echo ${LIBTOTEST} | cut -d - -f2`
						
		if [ `ldconfig -p | ${PATHGNU}/grep ${LIB} | wc -l` -gt 0 ] 
			then 
				VER=$(dpkg  -l | ${PATHGNU}/grep ${LIB} | ${PATHGNU}/grep ${EXT1} | ${PATHGNU}/gawk '{ print $3 }'  | head -1 )			# if more than one version, take only the first one... 
				#echo "--> ${LIBTOTEST}-${EXT1}:$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VERHD}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> ${LIBTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}-${EXT1} : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}:" "failed$(tput sgr 0)"
		fi
	}
function CheckLib1()
	{
		unset LIBTOTEST
		unset VER

		local LIBTOTEST=$1	
				
		if [ `ldconfig -p | ${PATHGNU}/grep ${LIBTOTEST} | wc -l` -gt 0 ] 
			then 
				if [ "${LIBTOTEST}" == "gdal" ]
					then 
						VER=$(gdalinfo --version | ${PATHGNU}/grep "GDAL" | ${PATHGNU}/gawk '{ print $2 }' )
					else
						VER=$(dpkg  -l | ${PATHGNU}/grep ${LIBTOTEST} | ${PATHGNU}/gawk '{ print $3 }'  | head -1 )			# if more than one version, take only the first one... 
				fi
				#echo "--> ${LIBTOTEST}-${EXT1}:$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VERHD}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> ${LIBTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}-${EXT1} : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}:" "failed$(tput sgr 0)"
		fi
	}

function CheckLibMAC()
	{
		unset LIBTOTEST
		unset VER

		local LIBTOTEST=$1	
		
		if [ `port list 2>/dev/null | ${PATHGNU}/grep ${LIBTOTEST} | wc -l` -gt 0 ] 
			then 
				VER=$(port info "${LIBTOTEST}" 2>/dev/null | ${PATHGNU}/grep " @" | ${PATHGNU}/gawk '{ print $2 }' )
				printf "%-60s%-20s\n" "--> ${LIBTOTEST}:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				if [" ${LIBTOTEST}" == "clang-14" ]
					then 
						CLANGVER=`clang --version 2>/dev/null`
						echo "$(tput setaf 1)$(tput setab 7)--> clang-14 : failed$(tput sgr 0)"	
						if [ `clang --version 2>/dev/null  | wc -w ` -gt 0 ] 
							then 
								echo " Although the following version exists:"
								gcc --version
						fi
					else
						printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ${LIBTOTEST}:" "failed$(tput sgr 0)"
				fi
		fi
	}



clear 

echo "Testing components for MasTer"
echo "-----------------------------"
echo "-----------------------------"
echo ""
echo "1) STATE VARIABLES in bashrc or bash_profile"
echo "--------------------------------------------"
TestVarBashrc "PATHGNU"
case ${OS} in 
		"Linux") 
			if [ "${PATHGNU}" != "/usr/bin" ] ; then echo "$(tput setaf 1)$(tput setab 7)    PATHGNU not /usr/bin as expected for Linux. Please check$(tput sgr 0)" ; fi 
			;;
		"Darwin")
			if [ "${PATHGNU}" != "/opt/local/bin" ] ; then echo "$(tput setaf 1)$(tput setab 7)    PATHGNU not /opt/local/bin as expected for Mac. Please check$(tput sgr 0)" ; fi 
			;;
esac		
TestVarBashrc "PATHFIJI"
TestVarBashrc "PATHCONV"
TestVarBashrc "PATHTOCPXFIDDLE"
TestVarBashrc "PATH_1650"
TestVarBashrc "PATH_3600"
TestVarBashrc "PATH_3601"
TestVarBashrc "PATH_3602"
TestVarBashrc "PATH_DataSAR"
TestVarBashrc "PATH_SCRIPTS"
TestVarBashrc "S1_ORBITS_DIR"
TestVarBashrc "ENVISAT_PRECISES_ORBITS_DIR"
TestVarBashrc "EARTH_GRAVITATIONAL_MODELS_DIR"
TestVarBashrc "EXTERNAL_DEMS_DIR"
echo "    $(tput setaf 3)EXTERNAL_DEMS_DIR is not mandatrory and actually not used with MasTer Toolbox $(tput sgr 0)"
echo ""

echo "2) MasTer Toolbox main components" 
echo "---------------------------------"
echo ""

# test presence of MasTer Toolbox main components in $PATH
##########################################################
echo "Directories in \$PATH in bashrc:" 
	WHICHME=$(dirname $(which initInSAR))
	TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHME | wc -l)
	if [ $TMP -ge 1 ] 
		then 
			printf "%-60s%-20s\n" "--> MasTerEngine in \$PATH:" "$(tput setaf 2)passed	($WHICHME)$(tput sgr 0)"
		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTerEngine in \$PATH:" "failed$(tput sgr 0)"
	fi


	WHICHSCRIPTS=$(dirname $(which FUNCTIONS_FOR_MT.sh))
	TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
	if [ $TMP -ge 1 ] 
		then 
			printf "%-60s%-20s\n" "--> MasTer Toolbox SCRIPTS in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS)$(tput sgr 0)"

			# test if utilities ok as well 
			WHICHSCRIPTSUTIL=zz_Utilities_MT
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox SCRIPTS Utilities in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox SCRIPTS Utilities in \$PATH:" "failed $(tput sgr 0)"
			fi
			# test if utilities_Ndo ok as well 
			WHICHSCRIPTSUTIL=zz_Utilities_MT_Ndo
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox SCRIPTS Utilities_Ndo in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox SCRIPTS Utilities_Ndo in \$PATH:" "failed $(tput sgr 0)"
			fi
			# test if _cron_scripts  ok as well 
			WHICHSCRIPTSUTIL=_cron_scripts
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox cron SCRIPTS in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox cron SCRIPTS in \$PATH:" "failed $(tput sgr 0)"
			fi
			
			# test if MasTerOrganizer  ok as well 
			WHICHSCRIPTSUTIL=MasTerOrganizer
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox MasTerOrganizer SCRIPTS in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox MasTerOrganizer SCRIPTS in \$PATH:" "failed $(tput sgr 0)"
			fi

			# test if optimtoolbox  ok as well 
			WHICHSCRIPTSUTIL=optimtoolbox
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox optimtoolbox SCRIPTS in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox optimtoolbox SCRIPTS in \$PATH:" "failed $(tput sgr 0)"
			fi

			# test if TemplatesForPlots  ok as well 
			WHICHSCRIPTSUTIL=TemplatesForPlots
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox TemplatesForPlots SCRIPTS in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox TemplatesForPlots SCRIPTS in \$PATH:" "failed $(tput sgr 0)"
			fi

			# test if TSCombiFiles  ok as well 
			WHICHSCRIPTSUTIL=TSCombiFiles
			TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHSCRIPTS | wc -l)
			if [ $TMP -ge 1 ] 
				then 
					printf "%-60s%-20s\n" "--> MasTer Toolbox TSCombiFiles files in \$PATH:" "$(tput setaf 2)passed	($WHICHSCRIPTS/$WHICHSCRIPTSUTIL)$(tput sgr 0)"
				else 
					printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox TSCombiFiles files in \$PATH:" "failed $(tput sgr 0)"
			fi


		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox SCRIPTS in \$PATH:" "failed $(tput sgr 0)"

	fi

	# test msbas and msbasv1 to v20
	which msbas > List_msbas.txt
	for i in `seq 1 20` ; do which msbasv$i; done >> List_msbas.txt
	NROFMSBAS=$(cat List_msbas.txt | wc -l)
	if [ ${NROFMSBAS} -gt 1 ] ; then echo "$(tput setaf 3)You have ${NROFMSBAS} msbas versions:$(tput sgr 0)"	; fi	#yellow text

	j=0
	for VERMSBAS in `cat List_msbas.txt`
	do
		j=`echo "$i + 1" | bc -l`
		WHICHMSBAS=$(dirname $(which ${VERMSBAS}))
		TMP=$(echo $PATH | ${PATHGNU}/grep $WHICHMSBAS | wc -l)
		if [ $TMP -ge 1 ] 
			then 
				printf "%-60s%-20s\n" "--> $(basename ${VERMSBAS}) in \$PATH:" "$(tput setaf 2)passed	($WHICHMSBAS)$(tput sgr 0)"
			else 
				printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> $(basename ${VERMSBAS})  in \$PATH:" "failed $(tput sgr 0)"
		fi
	done  

	TMP=$(echo $PATH | ${PATHGNU}/grep "/SAR/EXEC"| wc -l)
	if [ $TMP -ge 1 ]
		then 
			printf "%-60s%-20s\n" "--> /SAR/EXEC in \$PATH:" "$(tput setaf 2)passed $(tput sgr 0)"
		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> /SAR/EXEC in \$PATH:" "failed $(tput sgr 0)"

	fi

	echo ""

	# test versions
	###############

	echo "Executables and versions:" 

#  MasTerEngine
	LASTDIRINFO=`find ${HOMEDIR}/SAR/MasTerToolbox/MasTerEngine/_Sources_ME/Older -type d -name "V*" -printf "%T@ %Tc %p\n" 2>/dev/null | sort -n | tail -1 `  # get last creater dir
	#	Get everything after the last /:
	LASTDIRNAME="${LASTDIRINFO##*/}"
	MEVER=`echo ${LASTDIRNAME} | cut -d _ -f1`
	type -t initInSAR  >/dev/null
	if [ `echo $?` == "0" ]
		then
			WHICHVAR=$(which initInSAR)
			printf "%-60s%-20s\n" "--> MasTerEngine : " "$(tput setaf 2)passed$(tput sgr 0) 	(Version ${MEVER}. At least initInSAR is in: $(dirname ${WHICHVAR}))"
		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTerEngine" "failed: missing at least initInSAR $(tput sgr 0)"

	fi
	type -t getLineThroughStack  >/dev/null
	if [ `echo $?` == "0" ]
		then
			WHICHVAR=$(which getLineThroughStack)
			printf "%-60s%-20s\n" "--> MasTerEngine MSBAStools : " "$(tput setaf 2)passed$(tput sgr 0) 	(Version ${MEVER}. At least getLineThroughStack is in: $(dirname ${WHICHVAR}))"
		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTerEngine MSBAStools" "failed: missing at least getLineThroughStack $(tput sgr 0)"
	fi

# SCRIPTS
	type -t FUNCTIONS_FOR_MT.sh  >/dev/null
	if [ `echo $?` == "0" ]
		then
			WHICHVAR=$(which FUNCTIONS_FOR_MT.sh)
			printf "%-60s%-20s\n" "--> MasTer Toolbox SCRIPTS : " "$(tput setaf 2)passed$(tput sgr 0) 	(At least FUNCTIONS_FOR_MT.sh is in: $(dirname ${WHICHVAR}))"
		else 
			printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> MasTer Toolbox SCRIPTS" "failed: missing at least FUNCTIONS_FOR_MT.sh is in: $(dirname ${WHICHVAR}) $(tput sgr 0)"
	fi

# MSBAS
	which msbas > List_msbas.txt
	for i in `seq 1 20` ; do which msbasv$i; done >> List_msbas.txt
	NROFMSBAS=$(cat List_msbas.txt | wc -l)
	if [ ${NROFMSBAS} -gt 1 ] ; then echo "$(tput setaf 3)You have ${NROFMSBAS} msbas versions:$(tput sgr 0)"	; fi	#yellow text

	j=0
	for VERMSBAS in `cat List_msbas.txt`
	do
		j=`echo "$i + 1" | bc -l`
		TestVariableShort "$(basename ${VERMSBAS})"


	done  
	rm -f List_msbas.txt

echo ""

echo "3) Third party software"
echo "-----------------------"  # For both Mac and Linux:
# Test parallel
TestVariable "parallel" 

# Test gmt
TestVariable "gmt" 

# test gnuplot
TestVariable "gnuplot"
if [ `which gnuplot | wc -l` -gt 0 ] && [ "$(dirname $(which gnuplot))" != "${PATHGNU}" ] ; then echo "    $(tput setaf 1)$(tput setab 7)Gnu version not in \$PATHGNU? Please check!$(tput sgr 0)" ; fi 

# test bc
TestVariable "bc  "

# test convert (and hence ImageMagic/Fiji)
TestVariable "convert"

# test gdalinfo
TestVariable "gdalinfo"

# test snaphu
TestVariableShort "snaphu"

# test cpxfiddle
TestVariableShort "cpxfiddle"

# test wget
TestVariable "wget"

# test curl
TestVariable "curl"

# When two versions are expected, PROVIDE WWITH GNU VERSION FIRST
# test gnu sed
echo
TestVariable "gsed" " sed" 
echo
# test gnu awk 
TestVariable "gawk" " awk"
echo
# test gnu grep
TestVariable "ggrep" " grep"
echo
# test gnu seq
TestVariable "gseq" " seq"
echo
# test gnu find
TestVariable "gfind" " find"
echo
# test gnu stat
TestVariable "gstat" " stat"
echo
# test gnu date 
TestVariable "gdate" " date" 
echo
# test gnu uniq
TestVariable "guniq" " uniq"
echo ""
# test gnu readlink
TestVariable "greadlink" " readlink"
echo ""
# test gnu xargs
TestVariable "gxargs" " xargs"
echo ""
# test gnu du
TestVariable "gdu" " du"
echo ""
echo ""

# Test python in expected path
EXPECTEDPYTHON=`/opt/local/bin/python --version 2>/dev/null`
if [ "${EXPECTEDPYTHON}" == "" ]
	then 
		echo "--> python:	$(tput setaf 1)$(tput setab 7)failed$(tput sgr 0)		No python found in /opt/local/bin"  
	else 
		EXPECTEDPYTHONVER=`echo "${EXPECTEDPYTHON}" | awk '{print $2}' | cut -d. -f 1 `
		if [ "${EXPECTEDPYTHONVER}" == "3" ]
			then  
				echo "--> python:	$(tput setaf 2)passed$(tput sgr 0)		Need V${EXPECTEDPYTHONVER} for MasTer. ${EXPECTEDPYTHON} found in /opt/local/bin"
				TSTMODULES="YES"
				# check a possible default dir for python if called without path
				DEFAULTPYTH=$(which -a python | tr -s / | sort | uniq)
				if [ "${DEFAULTPYTH}" != "/opt/local/bin/python" ] && [ "${DEFAULTPYTH}" != "/opt/local/bin/python3" ]
					then 
						LISTDEFAULTPY=`echo "${DEFAULTPYTH}" | grep -v "/opt/local/bin/python"`
						echo "       $(tput setaf 3)Warning: a python exist in a default directory that is not the expected /opt/local/bin, i.e.:  $(tput sgr 0)"  
						echo "${DEFAULTPYTH}" | sed "s/^/\t\t/"
				fi
			else 
				echo "--> python:	$(tput setaf 1)$(tput setab 7)failed$(tput sgr 0)		${EXPECTEDPYTHON} found in /opt/local/bin, though V3 is mandatroy"  
		fi
fi
# Test python3 in expected path
EXPECTEDPYTHON3=`/opt/local/bin/python3 --version 2>/dev/null`
if [ "${EXPECTEDPYTHON3}" == "" ]
	then 
		echo "--> python3:	$(tput setaf 1)$(tput setab 7)failed$(tput sgr 0)		No python3 found in /opt/local/bin"  
	else 
		echo "--> python3:	$(tput setaf 2)passed$(tput sgr 0)		${EXPECTEDPYTHON3} required for MasTer found in /opt/local/bin"
		TSTMODULES="YES"
		# check a possible default dir for python if called without path
		DEFAULTPYTH3=$(which -a python3 | tr -s / | sort | uniq)
		if [ "${DEFAULTPYTH3}" != "/opt/local/bin/python3" ] && [ "${DEFAULTPYTH3}" != "/opt/local/bin/python" ]
			then 
				LISTDEFAULTPY3=`echo "${DEFAULTPYTH3}" | grep -v "/opt/local/bin/python3"`
				echo "       $(tput setaf 3)Warning: a python3 exist in a default directory that is not the expected /opt/local/bin, i.e.:  $(tput sgr 0)"
				echo "${LISTDEFAULTPY3}" | sed "s/^/\t\t/"
		fi

fi
echo ""

# Check python modules
if [ "${TSTMODULES}" == "YES" ] 
	then 
		echo "--> Check modules for  /opt/local/bin/python 	$(tput setaf 2)$(tput sgr 0)"
		TestPythonModule numpy /opt/local/bin/python
		TestPythonModule scipy /opt/local/bin/python
		TestPythonModule matplotlib /opt/local/bin/python
		TestPythonModule utm /opt/local/bin/python
		TestPythonModule osgeo /opt/local/bin/python 		# for gdal
		TestPythonModule pip /opt/local/bin/python
		TestPythonModule networkx /opt/local/bin/python
		TestPythonModuleQt PyQt6.QtWidgets QApplication /opt/local/bin/python
		 
		case ${OS} in 
			"Linux") 
				TestPythonModule opencv /opt/local/bin/python
				;;
				
			"Darwin")
				TestPythonModule cv2 /opt/local/bin/python
				TestPythonModule appscript /opt/local/bin/python
				;;
		esac


fi



echo ""
echo "4) Specific system-based functions"
echo "----------------------------------"  # For Mac or Linux
case ${OS} in 
	"Linux") 
		echo "Testing libraries for MSBAS, MasTerEngine etc..." 
		CheckLib1 "clang"	
		CheckLib2 "libfftw3-dev"
		CheckLib2 "libfftw3-long3"
		CheckLib2 "libfftw3-single3"
		CheckLib2 "libgeotiff-dev"
		CheckLib2 "libtiff-dev"		
		CheckLib1 "libxml2"
		CheckLib2 "libxml2-dev"
		CheckLib2 "liblapack-dev"
		CheckLib2 "libomp-dev"		
		CheckLib2 "libopenblas-dev"	
		CheckLib1 "mpich"	
#		CheckLib3 "imagemagick-6-common"
#		CheckLib1 "graphicsmagick"						
 		if [ `convert  | wc -l` -gt 0 ] 
 			then 
 				VER=$(${PATHGNU}/convert -version 2>/dev/null | ${PATHGNU}/grep "Version" | ${PATHGNU}/gawk '{ print $3 " " $4 }')
 				#echo "--> ImageMagick :$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VERLPK}$(tput sgr 0)"
 				printf "%-60s%-20s\n" "--> ImageMagick :" "$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VER}$(tput sgr 0)"
 			else
 				#echo "$(tput setaf 1)$(tput setab 7)--> ImageMagick  : failed$(tput sgr 0)"	
 				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ImageMagick:" "failed$(tput sgr 0)"
 		fi

		CheckLib1 "gdal"				# version nr can't be obtained as others 
		CheckLib2 "libgdal-dev"
#		CheckLib1 "libgdal26"
		CheckLib2 "libhdf5-dev"
		CheckLib2 "libnetcdf-dev"		
		CheckLib2 "libgsl-dev"
		
		CheckLib1 "gfortran"

		if [ `g++ --version 2>/dev/null | wc -l` -gt 0 ] 
			then 
				VER=$(g++ --version | ${PATHGNU}/grep g++  | ${PATHGNU}/gawk '{ print $3 }' )
				#echo "--> g++:$(tput setaf 2)	  passed$(tput sgr 0)		Version	$(tput setaf 2)${VERLPK}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> g++:" "$(tput setaf 2)passed$(tput sgr 0)		Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> g++ : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> g++:" "failed$(tput sgr 0)"
		fi
	
		echo ""		
		echo "Testing specific Linux features:"
		TestVariableShort "x-terminal-emulator"
		TestVariableShort "espeak"
		TestVarBashrc "OPENBLAS_NUM_THREADS="

		;;
	"Darwin")
		echo "Testing libraries for MSBAS, MasTerEngine etc..." 
		CheckLibMAC "hdf5"
		CheckLibMAC "libgeotiff"
		CheckLibMAC "lapack"
#		CheckLibMAC "atlas"
		CheckLibMAC "tiff"
		CheckLibMAC "libxml2"
		CheckLibMAC "fftw-3"
		CheckLibMAC "fftw-3-long"
		CheckLibMAC "fftw-3-single"
		CheckLibMAC "libomp"
		CheckLibMAC "libkml"
		CheckLibMAC "clang-14"
		CheckLibMAC "mpich"
		CheckLibMAC "gsl"
				
		if [ `convert  | wc -l` -gt 0 ] 
			then 
				VER=$(${PATHGNU}/convert -version 2>/dev/null | ${PATHGNU}/grep "Version" | ${PATHGNU}/gawk '{ print $3 " " $4 }')
				#echo "--> ImageMagick :$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${VERLPK}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> ImageMagick:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> ImageMagick  : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ImageMagick:" "failed$(tput sgr 0)"
		fi		
		if [ `gdalinfo 2>/dev/null | wc -l` -gt 0 ] 
			then 
				VER=$(gdalinfo --version | ${PATHGNU}/grep "GDAL" | ${PATHGNU}/gawk '{ print $2 }' )
				#echo "--> gdal :$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${VERLPK}$(tput sgr 0)"
				printf "%-60s%-20s\n" "--> gdal:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${VER}$(tput sgr 0)"
			else
				#echo "$(tput setaf 1)$(tput setab 7)--> gdal  : failed$(tput sgr 0)"	
				printf "%-75s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> gdal:" "failed$(tput sgr 0)"
		fi		
		

		echo ""
		echo "Testing specific Mac features:"
		TestVariableShort "osascript"
		TestVariableShort "say"


		;;
esac	
echo ""

echo ""
echo "5) Testing access to mandatory disk/directories:"
echo "------------------------------------------------"  # For Mac and Linux

TestDirs "${PATH_DataSAR}/SAR_AUX_FILES"  
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/DEM"

TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ENV_ORB"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ENV_ORB/vor_gdr_d"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/ERS"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB/AUX_POEORB"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/ORBITS/S1_ORB/AUX_RESORB"
TestDirs "${PATH_DataSAR}/SAR_AUX_FILES/Param_files_SuperMaster"

if [ ! -d "${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96" ] 
	then 
		printf "%-75s%-20s\n" "--> ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96:" "$(tput setaf 1)$(tput setab 7)unreachable ! $(tput sgr 0)"
	else 
		
		printf "%-75s%-20s\n" "--> ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96:" "$(tput setaf 2)passed$(tput sgr 0)"
		if [ ! -f "${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC" ] 
			then 
				printf "%-75s%-20s\n" "--> ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC:" "$(tput setaf 1)$(tput setab 7)missing ! $(tput sgr 0)"
				echo "    Download it from https://web.archive.org/web/20130314064801/http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC"
			else 
				printf "%-75s%-20s\n" "--> File ${PATH_DataSAR}/SAR_AUX_FILES/EGM/EGM96/WW15MGH.DAC:" "$(tput setaf 2)passed$(tput sgr 0)"
		fi		
fi


echo ""
echo "6) Testing some configs in mandatory files (Linux only):"
echo "-----------------------------------------------"  # For Mac and Linux
if [ -f "/etc/ImageMagick/policy.xml" ] ; then 
	if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "rights=" | grep "pattern="  | grep \"PS\" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "rights=" | grep "pattern="  | grep \"PS\" | grep "read\|write" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains read & write rights for PS:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain read & write rights for PS:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain rights for PS :	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "rights=" | grep "pattern="  | grep \"EPS\" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "rights=" | grep "pattern="  | grep \"EPS\" | grep "read\|write" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains read & write rights for EPS:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain read & write rights for EPS:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain rights for EPS :	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "resource" | grep "name=" | grep "height" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "resource" | grep "name=" | grep "height" | grep "32" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains height value up to 32KP:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain height value up to 32KP:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain height value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "resource" | grep "name=" | grep "width" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "resource" | grep "name=" | grep "width" | grep "32" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains width value up to 32KP:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain width value up to 32KP:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain width value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "name=" | grep "disk" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick/policy.xml | grep "name=" | grep "disk" | grep "8GiB" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains disk value up to 8GiB:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain disk value up to 8GiB:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain disk value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi
fi

if [ -f "/etc/ImageMagick-6/policy.xml" ] ; then 

	if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "rights=" | grep "pattern="  | grep \"PS\" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "rights=" | grep "pattern="  | grep \"PS\" | grep "read\|write" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains read & write rights for PS:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain read & write rights for PS:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain rights for PS :	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "rights=" | grep "pattern="  | grep \"EPS\" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "rights=" | grep "pattern="  | grep \"EPS\" | grep "read\|write" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains read & write rights for EPS:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain read & write rights for EPS:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain rights for EPS :	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "resource" | grep "name=" | grep "height" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "resource" | grep "name=" | grep "height" | grep "32" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains height value up to 32KP:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain height value up to 32KP:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain height value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "resource" | grep "name=" | grep "width" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "resource" | grep "name=" | grep "width" | grep "32" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains width value up to 32KP:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain width value up to 32KP:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain width value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi

	if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "name=" | grep "disk" | wc -l` -gt 0 ]
		then 
			if [ `grep "policy domain=" /etc/ImageMagick-6/policy.xml | grep "name=" | grep "disk" | grep "8GiB" | wc -l` -gt 0 ]
				then 
					echo "ImageMagick config file contains disk value up to 8GiB:	$(tput setaf 2)OK$(tput sgr 0)"
				else
					echo "ImageMagick config file does not contain disk value up to 8GiB:	$(tput setaf 1)$(tput setab 7)NOT OK$(tput sgr 0)"
			fi
		else 
				echo "ImageMagick config file does not contain disk value:	$(tput setaf 3)Please check$(tput sgr 0)"
	fi
fi



echo ""
echo "7) Testing usefull stuffs though not mandatory:"
echo "-----------------------------------------------"  # For Mac and Linux

# gitkraken 
GITVER=`gitkraken --version 2>/dev/null`
GITVER2=`/Applications/GitKraken.app/Contents/MacOS/GitKraken --version 2>/dev/null` 
if [ "${GITVER}" == "" ] && [ "${GITVER2}" == "" ] 
	then 
		#echo "$(tput setaf 3)--> Gitkraken  : failed (or insdtalled in unconventional place), though it is not mnadatory$(tput sgr 0)"	
		printf "%-60s%-20s\n" "$(tput setaf 3)--> Gitkraken:" "failed (or insdtalled in unconventional place), though it is not mnadatory$(tput sgr 0)"
	else 
		#echo "--> Gitkraken :$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${GITVER}${GITVER2}$(tput sgr 0)"
		printf "%-60s%-20s\n" "--> Gitkraken:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${GITVER}${GITVER2}$(tput sgr 0)"
fi
# gimp 
GIMPVER=`gimp -version 2>/dev/null`
if [ "${GIMPVER}" == "" ] 
	then 
		if [ "${OS}" == "Darwin" ]	
			then 
				if [ `port list 2>/dev/null | ${PATHGNU}/grep gimp2 | wc -l` -gt 0 ] 
					then 
						GIMPVER=$(port info 'gimp2' 2>/dev/null | ${PATHGNU}/grep " @" | ${PATHGNU}/gawk '{ print $2 }' )
						#echo "--> GIMP (gimp2):$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${GIMPVER}$(tput sgr 0)"
						printf "%-60s%-20s\n" "--> GIMP (gimp2):" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${GIMPVER}$(tput sgr 0)"
					else
						#echo "$(tput setaf 1)$(tput setab 7)--> GIMP (gimp2) : failed , though it is not mnadatory(tput sgr 0)"	
						printf "%-60s%-20s\n" "$(tput setaf 3)--> GIMP (gimp2):" "failed, though it is not mnadatory$(tput sgr 0)"
				fi	
			else 
				#echo "$(tput setaf 3)--> GIMP  : 		failed, though it is not mnadatory$(tput sgr 0)"	
				printf "%-60s%-20s\n" "$(tput setaf 3)--> GIMP (gimp2):" "failed, though it is not mnadatory$(tput sgr 0)"
		fi	
	else 
		#echo "--> GIMP :$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${GIMPVER} $(tput sgr 0)"
		printf "%-60s%-20s\n" "--> GIMP:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${GIMPVER}$(tput sgr 0)"
fi
#Java
JAVAVER=`java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.version'  | grep -v ".date" | head -1 `
if [ "${JAVAVER}" == "" ] 
	then 
		#echo "$(tput setaf 3)--> JAVA  : 		failed, though it is not mnadatory$(tput sgr 0)"	
		printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> JAVA:" "failed$(tput sgr 0)"
	else 
		#echo "--> JAVA :$(tput setaf 2)		passed$(tput sgr 0)	Version	$(tput setaf 2)${JAVAVER} $(tput sgr 0)"
		#printf "%-60s%-20s\n" "--> JAVA:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${JAVAVER}$(tput sgr 0)"
		printf "%-60s%-20s\n" "--> JAVA:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${JAVAVER#"${JAVAVER%%[![:space:]]*}"}$(tput sgr 0)" # JAVAVER without leading spaces
fi
# Fiji
FIJIVERMAC=`${PATHFIJI}/ImageJ-macosx --headless -h 2>&1 > /dev/null | grep launcher`
FIJIVERLNX=`${PATHFIJI}/ImageJ-linux64 --headless -h 2>&1 > /dev/null | grep launcher`

if [ "${FIJIVERMAC}" == "" ] && [ "${FIJIVERLNX}" == "" ]
	then 
		echo "$(tput setaf 3)--> ImageJ-Fiji  : failed, though it is not mnadatory$(tput sgr 0)"
		printf "%-60s%-20s\n" "$(tput setaf 1)$(tput setab 7)--> ImageJ-Fiji:" "failed$(tput sgr 0)"	
	else 
		#echo "--> ImageJ-Fiji  :$(tput setaf 2)	passed$(tput sgr 0)		Version	$(tput setaf 2)${FIJIVERMAC}${FIJIVERLNX}$(tput sgr 0)"
		printf "%-60s%-20s\n" "--> ImageJ-Fiji:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${FIJIVERMAC}${FIJIVERLNX}$(tput sgr 0)"
fi
#QGIS
QGISVER=`/Applications/QGIS.app/Contents/MacOS/QGIS --version 2>/dev/null`
QGISVER2=`qgis --version 2>/dev/null`
if [ "${QGISVER}" == "" ] && [ "${QGISVER2}" == "" ]
	then 
		#echo "$(tput setaf 3)--> QGIS : 		failed, though it is not mnadatory$(tput sgr 0)"
		printf "%-60s%-20s\n" "$(tput setaf 3)--> QGIS:" "failed, though it is not mnadatory$(tput sgr 0)"	
	else 
		#echo "--> QGIS :$(tput setaf 2)		passed$(tput sgr 0)		Version	$(tput setaf 2)${QGISVER}${QGISVER2} $(tput sgr 0)"
		printf "%-60s%-20s\n" "--> QGIS:" "$(tput setaf 2)passed$(tput sgr 0)	Version	$(tput setaf 2)${QGISVER}${QGISVER2} $(tput sgr 0)"
		echo "    QGIS : You may want to install the following plugins (to do from within QGIS): "
		echo "  	- point sampling tool"
		echo "  	- PointConnetor"
		echo "  	- Profile tool"
		echo "  	- Qdraw"
		echo "  	- QuickMapServices"
		echo "  	- RasterDataPlotting	(may require to install python first) "
		echo "  	- Serval"
		echo "  	- Temporal/Spectal Profile Tool"
		echo "  	- Value Tool"
fi

 
if [ "${OS}" == "Linux" ] ; then 
	echo 
	echo
	EchoInverted "$(tput setaf 2)   //  As final notes: if you intend to run cron jobs, $(tput sgr 0)"
	EchoInverted "$(tput setaf 2)   //  	1) ensure that the following lines are commented in your .bashrc (if any) !! : $(tput sgr 0)"
	echo "				# If not running interactively, don't do anything"
	echo " 					case $- in"
	echo "						*i*) ;;"
	echo "						*) return;;"
	echo "					esac"
	EchoInverted "$(tput setaf 2)   //  	2) ensure that the following state variable are exported at the beginning or the crontab !! : $(tput sgr 0)"
	cd 
	cat .bashrc | grep "export" | grep -v "#" | sed -e "s/^[ \t]*//" | sed "s/^/\t\t/" # remove all leading white space then add a tab at beginning of each line for lisibility 
fi	


echo ""
echo "8) Summary of all mounted hard disk (just for your info...):"
echo "------------------------------------------------------------"  # For Mac and Linux
echo "------------------------------------------------------------" 

if [ "${OS}" == "Darwin" ]	
	then 
		MOUNTPOINT="/Volumes/"
	else 
		MOUNTPOINT="/mnt/"	
fi	
echo 
echo "Disks mounted by smb:"
echo "---------------------" 
	ls ${MOUNTPOINT} | df -h -T smbfs | grep "Filesystem" 				# Only the header 
	ls ${MOUNTPOINT} | df -h -T smbfs | grep -v "Filesystem" | sort 	# All but the header sorted

echo 
echo "Local disks:"
echo "------------" 
	ls ${MOUNTPOINT} | df -h -T apfs | grep "Filesystem" 				# Only the header 
	ls ${MOUNTPOINT} | df -h -T apfs | grep -v "Filesystem" | sort 	# All but the header sorted

echo 
echo 
echo 
echo "---------------------------------------------------------------------------------------------------"  
echo "$(tput setaf 2) In case of problem, you may want to run again the MasTer_Installer.sh $(tput sgr 0)"
echo
 
