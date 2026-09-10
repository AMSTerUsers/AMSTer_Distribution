#!/bin/bash
# RenamePath_Volumes_SPECIFIC.sh
#
# Replace the old hard coded external disk path
#
#         ${OLDPATH}${DISKREF}/blabla        e.g. /Users/YourName/Your/Dirs/whatever3602/blabla
#
# by  $PATH_${DISKREF}/blabla , i.e. by default the literal string
#
#         $PATH_3602/blabla
#
# or, with the -e option, by the value of that variable in the present environment
#
#         /Volumes/D3602/blabla
#
# DISKREF is searched among : 1650 3600 3601 3602 1660 3610 3611 3612 DataSAR
#
# This is done in every file below the pwd of the form :
#    ./*YYYYMMDD*YYYYMMDD*/i12/TextFiles/InSARParameters.txt
#    ./*YYYYMMDD*YYYYMMDD*/i12/TextFiles/geoProjectionParameters.txt
#    ./*YYYYMMDD*.csl/Info/externalSlantRangeDEM*.txt
#
# Hardcoded : - DISKREFS="1650 3600 3601 3602 1660 3610 3611 3612 DataSAR"
#             - PARAMFILES="InSARParameters.txt geoProjectionParameters.txt"
#
#
# Usage :  RenamePath_Volumes_SPECIFIC.sh OLDPATH [-n] [-e]
#
#      OLDPATH : everything that comes before DISKREF in the old path, e.g.
#                /Users/YourName/Your/Dirs/whatever
#                It is concatenated as is with DISKREF, so if "whatever" is empty,
#                provide the trailing slash : /Users/YourName/Your/Dirs/
#      -n      : dry run; show what would be changed but do not touch any file
#      -e      : expand $PATH_DISKREF, i.e. write its present value instead of its name
#
# Must be launched from the dir that contains the pair dirs or the csl dirs.
# i.e. /PAIRS/i12/TextFiles/InSARParameters.txt, or
#      /.../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
#
# Dependencies:	- gnu sed and awk for more compatibility. 
#
# New in Distro V 1.0:	- set up
# New in Distro V 1.1 20260910:	- also for .../SAR_SM/RESAMPLED/SAT/TRK/CROPDIR/
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
echo " "

OLDPATH=""
DRYRUN="NO"
EXPAND="NO"

for ARG in "$@"
do
	case "${ARG}" in
		"-n") DRYRUN="YES" ;;
		"-e") EXPAND="YES" ;;
		"-l") EXPAND="NO" ;;					# literal is the default anyway
		*)    OLDPATH="${ARG}" ;;
	esac
done

if [ "${OLDPATH}" = "" ]
	then
		echo "Usage: $(basename "$0") OLDPATH [-n] [-e]"
		echo "   e.g. $(basename "$0") /Users/YourName/Your/Dirs/whatever"
		exit 1
fi

DISKREFS="1650 3600 3601 3602 1660 3610 3611 3612 DataSAR"
PAIRPARAMFILES="InSARParameters.txt geoProjectionParameters.txt"

# Prepare the new string for each disk, once for all
# --------------------------------------------------
for DISKREF in ${DISKREFS}
do
	if [ "${EXPAND}" = "YES" ]
		then
			eval "VALUE=\"\${PATH_${DISKREF}}\""
			VALUE="${VALUE%/}"					# the / is already in the file, just after DISKREF
			eval "NEWPATH_${DISKREF}=\"\${VALUE}\""
		else
			eval "NEWPATH_${DISKREF}='\$PATH_${DISKREF}'"
	fi
	eval "WARNED_${DISKREF}=NO"
done

# Replace, in file $1, every occurrence of the literal string $2 by the literal string $3.
# The match is accepted only when it is followed by a /, a blank, or the end of the line,
# so that e.g. .../whatever3602_old/ is not mistaken for .../whatever3602/
# ----------------------------------------------------------------------------------------
ReplaceLiteralString()
	{
	local FILE="$1"
	local OLDSTRING="$2"
	local NEWSTRING="$3"

	${PATHGNU}/gawk -v old="${OLDSTRING}" -v new="${NEWSTRING}" '
		{
		out = ""
		rest = $0
		while ( (p = index(rest, old)) > 0 )
			{
			after = substr(rest, p + length(old), 1)
			if (after == "" || after == "/" || after == " " || after == "\t")
				{ out = out substr(rest, 1, p - 1) new }			# replace
			else
				{ out = out substr(rest, 1, p + length(old) - 1) }	# keep as it is
			rest = substr(rest, p + length(old))
			}
		print out rest
		}' "${FILE}"
	}

# Change all the disk paths in file $1
# ------------------------------------
NRFILES=0
NRCHANGED=0

RenameDiskPathsInFile()
	{
	local FILE="$1"
	local TMPFILE="${FILE}.RenameDiskPath$$"
	local DISKREF OLDSTRING NEWSTRING ALREADYWARNED

	NRFILES=$((NRFILES + 1))
	cp "${FILE}" "${TMPFILE}"

	for DISKREF in ${DISKREFS}
	do
		OLDSTRING="${OLDPATH}${DISKREF}"
		${PATHGNU}/ggrep -qF -- "${OLDSTRING}" "${TMPFILE}" || continue

		eval "NEWSTRING=\"\${NEWPATH_${DISKREF}}\""
		if [ "${NEWSTRING}" = "" ]
			then
				eval "ALREADYWARNED=\"\${WARNED_${DISKREF}}\""
				if [ "${ALREADYWARNED}" = "NO" ]
					then
						echo "Warning: \$PATH_${DISKREF} is not defined in your environment;"
						echo "         ${OLDSTRING}/... is left untouched."
						eval "WARNED_${DISKREF}=YES"
				fi
				continue
		fi

		ReplaceLiteralString "${TMPFILE}" "${OLDSTRING}" "${NEWSTRING}" > "${TMPFILE}.new" \
			&& mv -f "${TMPFILE}.new" "${TMPFILE}"
	done

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
					cat "${TMPFILE}" > "${FILE}"		# keeps the original inode, owner and permissions
					echo "Changed ${FILE}"
			fi
			rm -f "${TMPFILE}"
	fi
	}

# Search the dirs to process in the pwd : csl dirs and/or pair dirs
# -----------------------------------------------------------------
for DIR in *
do
	[ -d "${DIR}" ] || continue

	case "${DIR}" in
		*.csl|*.cls)
			# csl image dir, named *YYYYMMDD*.csl
			echo "${DIR}" | ${PATHGNU}/ggrep -Eq '[0-9]{8}' || continue
			for FILE in "${DIR}"/Info/externalSlantRangeDEM*.txt
			do
				[ -f "${FILE}" ] || continue
				RenameDiskPathsInFile "${FILE}"
			done
			;;

		*)
			# pair dir, named *YYYYMMDD*YYYYMMDD*
			echo "${DIR}" | ${PATHGNU}/ggrep -Eq '[0-9]{8}.*[0-9]{8}' || continue
			for PARAMFILE in ${PAIRPARAMFILES}
			do
				FILE="${DIR}/i12/TextFiles/${PARAMFILE}"
				[ -f "${FILE}" ] || continue
				RenameDiskPathsInFile "${FILE}"
			done
			;;
	esac
done

echo
echo "${NRFILES} parameters files checked, ${NRCHANGED} to be changed or changed."