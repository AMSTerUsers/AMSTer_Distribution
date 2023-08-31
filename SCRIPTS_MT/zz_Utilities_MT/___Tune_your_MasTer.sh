#!/bin/bash
# This script is aiming at updating all hard coded lines in MasTer scripts used in personal instalation,
#  i.e. that would differ from the scripts downloaded or synchrosized e.g. from Github.
# It helps to keep the updated scripts consistent with your own installation. 
#
# It is hence recommanded to run it after each synchronisation with the GitHub repository for instance. 
#
# You must first build your own set of calls of function UpdateLineInScript for each hard coded line to change. 
# Hence everything is hardcoded below and there is no parameter for this script. 
#
# If some special characters mess up during update, you may need to add them in functions RemoveSpecChar and RestoreSpecChar.
#  Do not forget to add your replacement string in the test array LISTOFSCTRINGS
#
# ATTENTION : - It is mandatory that your initial line (the one you search for) and the new line 
#               (the one that will be used to replace the initial one) MUST be clean of 
#			  	  - double quotes (single are ok)
#				  - $
#				  - @ because we use it as sed separator... 
#                If some of these are present, they MUST be preceded by a backslash 
#  Be aware that if your line appears multiple time, it will change it multiple time 
#
# Each scripts to be updated MUST be provided to UpdateLineInScript with its full path.
#
# It is advised to test the script for instance by creating a file named Test_Syntax.txt and 
# copy the following 3 lines in it (without leading #) : 
#
#   This line will be unchanged, but the following 
#   abc ${a var}, == [why] {not} (brackets) "and quotes" && 'double quotes' || /a/PATH/${here} and 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ "seems 'ok' though" hopefully
#   should be capitalized 
#
# then run the present script with the 4 following lines hard coded in the body of the present script, i.e. below the functions definition
#
#   DEFAULTLINE="abc \${a var}, == [why] {not} (brackets) \"and quotes\" && 'double quotes' || /a/PATH/\${here} and 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ \"seems 'ok' though\" hopefully"
#   PERSOLINE="ABC \${A Var}, == [Why] {Not} (Brackets) \"And Quotes\" && 'Double Quotes' || /A/path/\${Here} And 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ \"Seems 'OK' Though\" Hopefully"
#	YOURSCRIPTTOUPDATE="/$HOME/Test_Syntax.txt"
#	UpdateLineInScript "${YOURSCRIPTTOUPDATE}" "${DEFAULTLINE}" "${PERSOLINE}"
#
# After successful run of the script, the second line of Test_Syntax.txt must have been updated and the file
# should now look like:
#
#   This line will be unchanged, but the following 
#   ABC ${A Var}, == [Why] {Not} (Brackets) "And Quotes" && 'Double Quotes' || /A/path/${Here} And 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ "Seems 'OK' Though" Hopefully
#   will be capitalized 
#
# NOTE THAT A \ (back slash sign) MUST BE ADDED MANUALLY BEFORE EACH OCCURRENCE OF A $ (dollar sign) OR 
#    A " (double quote sign) IN THE DEFINITION OF THE LINES TO SEARCH (DEFAULTLINE) AND REPLACE (PERSOLINE)
#    IN THE PRESENT SCRIPT. 
#    YOU DO NOT HAVE TO ADD THESE \ IN THE ORIGINAL FILE TO CHANGE OF COURSE. 
#
# For security, the script will backup your original scripts (e.g. Test_Syntax.txt in the case of the test) with  
# an .original.perso extension (e.g. Test_Syntax.txt.original.perso). If you are satified with your updated script,
# you can delete that backup because it will not be overwriten at next run of the script. 
#
# New in V 1.1: - make the modified script executable 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2020/09/16 - could make better... when time.
# ****************************************************************************************
FCTVER="Distro V1.1.0 MasTer script utilities"
FCTAUT="Nicolas d'Oreye, (c)2016-2020, Last modified on Oct 09, 2020"

# Some warning... 
echo
echo -e "  $(tput setaf 1)$(tput setab 7)ATTENTION : It is mandatory that your initial line (theone you search for) and the new line $(tput sgr 0)"
echo -e "  $(tput setaf 1)$(tput setab 7)             (the one that will be used to replace the initial one) MUST be clean of        $(tput sgr 0)"
echo -e "  $(tput setaf 1)$(tput setab 7)               - double quotes (single are ok)                                              $(tput sgr 0)"
echo -e "  $(tput setaf 1)$(tput setab 7)               - $                                                                          $(tput sgr 0)"
echo -e "  $(tput setaf 1)$(tput setab 7)             If some of these are present, they MUST be preceded by a backslash             $(tput sgr 0)"
echo

################################
###  Some functions
################################
function RemoveSpecChar()
	{
	unset FILETOCHANGE	
	local FILETOCHANGE=$1	
	
	# First check that script does not contains one of the replacing strings 
	LISTOFSCTRINGS="DOUBLEQUOTES SINGLEQUOTES OPENBRAKET CLOSEBRAKET OPENSQBRAKET CLOSESQBRAKET BACKSLASH DOLLAR AMPERSAND PIPE SEMICOLM UNDERSCRE STARLET PLUUUS DOOOT KESTION"
	for WORD in ${LISTOFSCTRINGS}; do
    	if grep -q ${WORD} "${FILETOCHANGE}"; then
  			echo "Can't proceed with replacement of special characters because ${WORD} is present in ${FILETOCHANGE}"
  			exit 
		fi
	done
	# Clean double quotes
	${PATHGNU}/gsed "s@\"@DOUBLEQUOTES@g" ${FILETOCHANGE} > ${FILETOCHANGE}.cln
	# Clean single quotes
	${PATHGNU}/gsed "s@'@SINGLEQUOTES@g" ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean open bracket
	${PATHGNU}/gsed "s@{@OPENBRAKET@g" ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean close bracket
	${PATHGNU}/gsed "s@}@CLOSEBRAKET@g" ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean open square bracket
	${PATHGNU}/gsed "s@\[@OPENSQBRAKET@g" ${FILETOCHANGE}.cln.tmp > ${FILETOCHANGE}.cln
	# Clean close square bracket
	${PATHGNU}/gsed "s@\]@CLOSESQBRAKET@g" ${FILETOCHANGE}.cln > ${FILETOCHANGE}.cln.tmp
	# Clean back slashes
	${PATHGNU}/gsed 's@\\@BACKSLASH@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean dollar
	${PATHGNU}/gsed 's@\$@DOLLAR@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean &
	${PATHGNU}/gsed 's@\&@AMPERSAND@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean pipe
	${PATHGNU}/gsed 's@|@PIPE@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean pipe
	${PATHGNU}/gsed 's@;@SEMICOLM@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean underscore
	${PATHGNU}/gsed 's@\_@UNDERSCRE@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean star
	${PATHGNU}/gsed 's@\*@STARLET@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean plus
	${PATHGNU}/gsed 's@\+@PLUUUS@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Clean dot
	${PATHGNU}/gsed 's@\.@DOOOT@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Clean question mark
	${PATHGNU}/gsed 's@\?@KESTION@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	
	mv -f ${FILETOCHANGE}.cln.tmp ${FILETOCHANGE}.cln
	}

function RestoreSpecChar()
	{
	unset FILETOCHANGE	
	local FILETOCHANGE=$1	
	
	# Restore double quotes
	${PATHGNU}/gsed "s@DOUBLEQUOTES@\"@g" ${FILETOCHANGE} > ${FILETOCHANGE}.cln
	# Restore single quotes
	${PATHGNU}/gsed "s@SINGLEQUOTES@'@g" ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore open bracket
	${PATHGNU}/gsed "s@OPENBRAKET@{@g" ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore close bracket
	${PATHGNU}/gsed "s@CLOSEBRAKET@}@g" ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore open square bracket
	${PATHGNU}/gsed "s@OPENSQBRAKET@\[@g" ${FILETOCHANGE}.cln.tmp > ${FILETOCHANGE}.cln
	# Restore close square bracket
	${PATHGNU}/gsed "s@CLOSESQBRAKET@\]@g" ${FILETOCHANGE}.cln > ${FILETOCHANGE}.cln.tmp
	# Restore back slashes
	${PATHGNU}/gsed 's@BACKSLASH@\\@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore dollar
	${PATHGNU}/gsed 's@DOLLAR@\$@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore &
	${PATHGNU}/gsed 's@AMPERSAND@\&@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore pipe
	${PATHGNU}/gsed 's@PIPE@|@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore pipe
	${PATHGNU}/gsed 's@SEMICOLM@;@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore underscore
	${PATHGNU}/gsed 's@UNDERSCRE@\_@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore star
	${PATHGNU}/gsed 's@STARLET@\*@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore plus
	${PATHGNU}/gsed 's@PLUUUS@\+@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp
	# Restore dot
	${PATHGNU}/gsed 's@DOOOT@\.@g' ${FILETOCHANGE}.cln.tmp  > ${FILETOCHANGE}.cln
	# Restore question mark
	${PATHGNU}/gsed 's@KESTION@\?@g' ${FILETOCHANGE}.cln  > ${FILETOCHANGE}.cln.tmp

	mv -f ${FILETOCHANGE}.cln.tmp ${FILETOCHANGE}.cln
	}


# function for changing line in script; takes care of special characters in file and line
function UpdateLineInScript()
	{
	unset SCRIPT			# With path 
	unset DEFAULTLINE
	unset PERSOLINE	
	local SCRIPT=$1
	local DEFAULTLINE=$2
	local PERSOLINE=$3	
	
 	echo -e "$(tput setaf 3)Replace in  ${SCRIPT}$(tput sgr 0)"
 	echo -e "$(tput setaf 3)the original line:$(tput sgr 0)"
 	echo "  ${DEFAULTLINE} "
 	echo -e "$(tput setaf 3)with:$(tput sgr 0)"
 	echo "  ${PERSOLINE}"
 	echo

	# keep a backup of original perso script
	cp -n ${SCRIPT} ${SCRIPT}.original.perso

	# First, remove special characters in script, which will be renamed as script.cln
	RemoveSpecChar ${SCRIPT}
	
	# Remove special characters in line to search, which will be saved in as DefaultLine.txt.cln
	echo "${DEFAULTLINE}" > DefaultLine.txt
	RemoveSpecChar DefaultLine.txt
	DEFAULTLINECLEAN=`cat DefaultLine.txt.cln`
	# Remove special characters in replacing line, which will be saved in as PersoLine.txt.cln
	echo "${PERSOLINE}" > PersoLine.txt
	RemoveSpecChar PersoLine.txt
	PERSOLINECLEAN=`cat PersoLine.txt.cln`

	# swap lines
	${PATHGNU}/gsed "s@${DEFAULTLINECLEAN}@${PERSOLINECLEAN}@g" ${SCRIPT}.cln > ${SCRIPT}.swap
	# restore special characters in modofoed script 
	RestoreSpecChar ${SCRIPT}.swap
	mv -f ${SCRIPT}.swap.cln ${SCRIPT}

	# clean temp files 
	rm PersoLine.txt PersoLine.txt.cln DefaultLine.txt DefaultLine.txt.cln
	rm ${SCRIPT}.swap ${SCRIPT}.cln
	}


################################
###  Your changes here below 
################################
### REMEMBER : 
###   DEFAULTLINE and PERSOLINE must be entered below without quotes inside the line. 
###   If quotes are present in line, they MUST be replaced by \"
###   Also $ MUST be replaced by \$
###   The script to modify must be set as YOURSCRIPTTOUPDATE with its path

# Uncomment the lines below for testing
#DEFAULTLINE="abc \${a var}, == [why] {not} (brackets) \"and quotes\" && 'double quotes' || /a/PATH/\${here} and 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ \"seems 'ok' though\" hopefully"
#PERSOLINE="ABC \${A Var}, == [Why] {Not} (Brackets) \"And Quotes\" && 'Double Quotes' || /A/path/\${Here} And 1 ; 2 : 3 , 4 . 5 - 6 -- 7 _ 8 __ \"Seems 'OK' Though\" Hopefully"
#YOURSCRIPTTOUPDATE="/$HOME/Test_Syntax.txt"
UpdateLineInScript "${YOURSCRIPTTOUPDATE}" "${DEFAULTLINE}" "${PERSOLINE}"
chmod +x ${YOURSCRIPTTOUPDATE}
