#!/bin/bash
# -----------------------------------------------------------------------------------------
# Restore_Duplicate_Pairs_ToKill.sh
#
# PURPOSE
#   Move back the products that were wrongly moved to ___Duplicated_ToKill by
#   Remove_Duplicate_Pairs_File.sh (bug caused by '>>' introduced on 2026/09/09).
#
# HOW IT WORKS
#   For each Mode dir in Geocoded/ (e.g. Coh, DefoInterpolDetrend) that contains a
#   ___Duplicated_ToKill dir:
#     1. list the date pairs (yyyymmdd_yyyymmdd) found in the Mode dir
#     2. list the date pairs found in ___Duplicated_ToKill
#     3. a pair that is in ___Duplicated_ToKill but NOT in the Mode dir was moved by mistake
#        (a true duplicate always leaves one copy behind in the Mode dir)
#     4. for each such pair, move back the NEWEST file (and its .hdr etc.) to the Mode dir
#
#   Pairs that still exist in the Mode dir are left untouched, as are the older versions
#   (the true duplicates), which stay in ___Duplicated_ToKill.
#   The Ampli dir is ignored.
#
# USAGE
#   Restore_Duplicate_Pairs_ToKill.sh /path/to/Geocoded           -> dry run (nothing moved)
#   Restore_Duplicate_Pairs_ToKill.sh /path/to/Geocoded --apply   -> really moves the files
# Dependencies:
#	 - grep
#
# New in Distro V 1.1 DS:		- Comment and script in proper english 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2025/08/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1,1 AMSTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Oct 05, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
GEOCODED_DIR="${1%/}"          # first argument, without trailing slash
OPTION="$2"                    # optional second argument: --apply

DRY_RUN=1
[ "${OPTION}" == "--apply" ] && DRY_RUN=0

if [ -z "${GEOCODED_DIR}" ] || [ ! -d "${GEOCODED_DIR}" ] ; then
	echo "Usage: $(basename "$0") /path/to/Geocoded [--apply]"
	exit 1
fi

if [ ${DRY_RUN} -eq 1 ] ; then
	echo "=== DRY RUN: nothing will be moved (add --apply to move files) ==="
else
	echo "=== APPLY MODE: files will be moved ==="
fi

# ---------------------------------------------------------------------------
# Helper: print the date pairs (yyyymmdd_yyyymmdd) found in the *deg files of a dir
# One pair per line, sorted, without repetition.
# ---------------------------------------------------------------------------
list_date_pairs_in_dir() {
	local DIR="$1"

	# Take the files ending with "deg" located directly in DIR (no subdir)
	find "${DIR}" -maxdepth 1 -type f -name "*deg" 2>/dev/null \
		| while read -r FILE_PATH ; do
			# Keep the file name only, then extract the first yyyymmdd_yyyymmdd it contains
			basename "${FILE_PATH}" | grep -Eo "[0-9]{8}_[0-9]{8}" | head -1
		done \
		| sort -u
}

# ---------------------------------------------------------------------------
# Main loop: one iteration per Mode dir
# ---------------------------------------------------------------------------
TMP_DIR=`mktemp -d`                              # temporary dir for the pair lists
PAIRS_IN_MODE_DIR="${TMP_DIR}/pairs_in_mode_dir.txt"
PAIRS_IN_TOKILL_DIR="${TMP_DIR}/pairs_in_tokill_dir.txt"
PAIRS_TO_RESTORE="${TMP_DIR}/pairs_to_restore.txt"

NR_PAIRS_RESTORED=0

for MODE_DIR in "${GEOCODED_DIR}"/*/ ; do
	MODE_NAME=`basename "${MODE_DIR}"`
	TOKILL_DIR="${MODE_DIR}___Duplicated_ToKill"

	# Skip Ampli: its duplicates are never cleaned by Remove_Duplicate_Pairs_File.sh
	[ "${MODE_NAME}" == "Ampli" ] && continue

	# Skip Mode dirs without ___Duplicated_ToKill: nothing to restore
	[ -d "${TOKILL_DIR}" ] || continue

	# Step 1 and 2: date pairs present in each dir
	list_date_pairs_in_dir "${MODE_DIR}"   > "${PAIRS_IN_MODE_DIR}"
	list_date_pairs_in_dir "${TOKILL_DIR}" > "${PAIRS_IN_TOKILL_DIR}"

	# Step 3: pairs present ONLY in ___Duplicated_ToKill (= moved by mistake)
	# comm -13 keeps the lines that are only in the 2nd file
	comm -13 "${PAIRS_IN_MODE_DIR}" "${PAIRS_IN_TOKILL_DIR}" > "${PAIRS_TO_RESTORE}"

	NR_PAIRS_FOR_MODE=`wc -l < "${PAIRS_TO_RESTORE}" | tr -d ' '`
	echo ""
	echo "--- ${MODE_NAME}: ${NR_PAIRS_FOR_MODE} pair(s) to restore"

	# Step 4: restore the newest file of each pair
	while read -r DATE_PAIR ; do
		[ -z "${DATE_PAIR}" ] && continue

		# Newest file (ls -t sorts by modification time, newest first) of that pair in ToKill
		NEWEST_FILE_PATH=`ls -t "${TOKILL_DIR}"/*"${DATE_PAIR}"*deg 2>/dev/null | head -1`
		[ -z "${NEWEST_FILE_PATH}" ] && continue
		NEWEST_FILE_NAME=`basename "${NEWEST_FILE_PATH}"`

		echo "  restore ${DATE_PAIR}: ${NEWEST_FILE_NAME} (+ associated files)"

		if [ ${DRY_RUN} -eq 0 ] ; then
			# The trailing * also moves the associated files (e.g. .hdr)
			# -n : never overwrite a file that already exists in the Mode dir
			mv -n "${TOKILL_DIR}/${NEWEST_FILE_NAME}"* "${MODE_DIR}"
		fi

		NR_PAIRS_RESTORED=$((NR_PAIRS_RESTORED+1))
	done < "${PAIRS_TO_RESTORE}"
done

rm -rf "${TMP_DIR}"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [ ${DRY_RUN} -eq 1 ] ; then
	echo "=== Total: ${NR_PAIRS_RESTORED} pair(s) to restore (dry run) ==="
else
	echo "=== Total: ${NR_PAIRS_RESTORED} pair(s) restored ==="
fi
