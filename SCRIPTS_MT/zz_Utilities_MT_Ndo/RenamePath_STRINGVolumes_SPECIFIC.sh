#!/bin/bash
# ----------------------------------------------------------------------------------
# RenamePath_STRINGVolumes_SPECIFIC.sh
#
# Replace all the occurrences of a string by another one in every
#    ./*YYYYMMDD*YYYYMMDD*/i12/TextFiles/InSARParameters.txt
# and
#    ./*YYYYMMDD*YYYYMMDD*/i12/TextFiles/geoProjectionParameters.txt
# found in the pwd.
#
# Both strings are taken literally, i.e. no character is interpreted as a regular
# expression, which allows strings such as $PATH_3611 or /Volumes/D3602 . A match is
# only accepted when it is not immediately followed by a letter, a digit or a _ , so
# that $PATH_3611 does not match in $PATH_36110 nor in $PATH_3611_OLD.
#
# Hard coded: - PARAMFILES="InSARParameters.txt geoProjectionParameters.txt"
#
#
# Usage :  RenamePath_STRINGVolumes_SPECIFIC.sh OLDSTRING NEWSTRING [-n]
#
#      -n : dry run; show what would be changed but do not touch any file
#
#   e.g. ChangeStringInParamFiles.sh '$PATH_3611' '$PATH_3601'
#        Mind the single quotes, or your shell will expand the variables before
#        the script even sees them.
#
# Must be launched from the dir that contains the pair dirs.
#
# New in Distro V 1.0:	- set up
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.0AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Sept 10, 2026"


echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 

OLDSTRING=""
NEWSTRING=""
DRYRUN="NO"

for ARG in "$@"
do
	case "${ARG}" in
		"-n")	DRYRUN="YES" ;;
		*)	if [ "${OLDSTRING}" = "" ]
				then OLDSTRING="${ARG}"
				else NEWSTRING="${ARG}"
			fi ;;
	esac
done

if [ "${OLDSTRING}" = "" ] || [ "${NEWSTRING}" = "" ]
	then
		echo "Usage: $(basename "$0") OLDSTRING NEWSTRING [-n]"
		echo "   e.g. $(basename "$0") '\$PATH_3611' '\$PATH_3601'"
		exit 1
fi

PARAMFILES="InSARParameters.txt geoProjectionParameters.txt"

# Show what is really searched: if the strings were not single quoted on the command line,
# the shell has expanded them before the script was even launched
# -----------------------------------------------------------------------------------------
echo "Searching  : ${OLDSTRING}"
echo "Replaced by: ${NEWSTRING}"
echo

# Replace, in file $1, every occurrence of the literal string $2 by the literal string $3
# ---------------------------------------------------------------------------------------
ReplaceLiteralString()
	{
	local FILE="$1"
	local OLD="$2"
	local NEW="$3"

	${PATHGNU}/gawk -v old="${OLD}" -v new="${NEW}" '
		{
		out = ""
		rest = $0
		while ( (p = index(rest, old)) > 0 )
			{
			after = substr(rest, p + length(old), 1)
			if (after ~ /^[A-Za-z0-9_]$/)
				{ out = out substr(rest, 1, p + length(old) - 1) }	# part of a longer name: keep as it is
			else
				{ out = out substr(rest, 1, p - 1) new }		# replace
			rest = substr(rest, p + length(old))
			}
		print out rest
		}' "${FILE}"
	}

NRFILES=0
NRFOUND=0
NRCHANGED=0

for PAIRDIR in *
do
	echo "${PAIRDIR}" | ${PATHGNU}/ggrep -Eq '[0-9]{8}.*[0-9]{8}' || continue
	[ -d "${PAIRDIR}/i12/TextFiles" ] || continue

	for PARAMFILE in ${PARAMFILES}
	do
		FILE="${PAIRDIR}/i12/TextFiles/${PARAMFILE}"
		[ -f "${FILE}" ] || continue
		NRFILES=$((NRFILES + 1))

		${PATHGNU}/ggrep -qF -- "${OLDSTRING}" "${FILE}" || continue
		NRFOUND=$((NRFOUND + 1))

		TMPFILE="${FILE}.ChangeString$$"
		ReplaceLiteralString "${FILE}" "${OLDSTRING}" "${NEWSTRING}" > "${TMPFILE}" || continue

		if cmp -s "${TMPFILE}" "${FILE}"
			then
				rm -f "${TMPFILE}"
			else
				NRCHANGED=$((NRCHANGED + 1))
				if [ "${DRYRUN}" = "YES" ]
					then
						echo "Would change ${FILE} :"
						diff "${FILE}" "${TMPFILE}" | ${PATHGNU}/ggrep -E '^[<>]' | sed 's/^/    /'
					else
						cat "${TMPFILE}" > "${FILE}"	# keeps the original inode, owner and permissions
						echo "Changed ${FILE}"
				fi
				rm -f "${TMPFILE}"
		fi
	done
done

echo
echo "${NRFILES} parameters files checked, ${NRCHANGED} to be changed or changed."

if [ ${NRFILES} -gt 0 ] && [ ${NRFOUND} -eq 0 ]
	then
		echo
		echo "None of these files contains the string ${OLDSTRING}"
		VARNAME=`env | ${PATHGNU}/gawk -F"=" -v VALUE="${OLDSTRING}" '$0 == $1"="VALUE {print $1 ; exit}'`
		if [ "${VARNAME}" != "" ]
			then
				echo "Note that this is exactly the value of \$${VARNAME} in your environment,"
				echo "which suggests that your shell has expanded the parameter."
				echo "Launch it again with single quotes, e.g. ${PRG} '\$${VARNAME}' '\$PATH_XXXX'"
		fi
fi