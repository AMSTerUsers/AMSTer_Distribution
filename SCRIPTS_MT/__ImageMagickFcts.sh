#!/bin/bash
# -----------------------------------------------------------------------------------------
# __ImageMagickFcts.sh
#
# Single place where AMSTer decides HOW to call the image manipulation tool, so that
# TimeSeriesInfo_HP.sh, AmpDefo_map.sh and AmpTif_map.sh all behave the same way on a
# given machine.
#
# This file is meant to be SOURCED, not executed:
#		source ${PATH_SCRIPTS}/SCRIPTS_MT/__ImageMagickFcts.sh
#
# It sets:
#	TOOL		: "imagemagick" or "graphicsmagick"		(kept for backward compatibility)
#	IMCONVERT	: the command to use instead of a bare "convert", i.e. one of
#			  "convert" (ImageMagick 6), "magick" (ImageMagick 7 without the
#			  legacy convert alias) or "gm convert" (GraphicsMagick).
#			  Use it UNQUOTED so that "gm convert" splits in two words:
#				${IMCONVERT} in.jpg -resize 400x400 out.jpg
#	FONT_OPT	: "-font SomeFont" or an empty string when no usable font was found.
#			  If FONT_OPT is already set when this file is sourced (e.g. by
#			  __HardCodedLines.sh) it is left untouched, empty value included.
#
# and defines:
#	do_composite BASE OVERLAY GRAVITY GEOMETRY	: overlay OVERLAY on BASE, in place
#
# Dependencies: ImageMagick 6/7 or GraphicsMagick
#
# New in Distro V 1.0 20260804:	- based on the detection block of TimeSeriesInfo_HP.sh V6.5
#				  (V6.0/V6.1), extended to ImageMagick 7 and to
#				  GraphicsMagick installations that provide no "convert"
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# -----------------------------------------------------------------------------------------

# --- Which tool do we have ? -------------------------------------------------------------
# Beware: some GraphicsMagick installations provide no "convert" at all, and ImageMagick 7
# may ship without the legacy "convert" alias. Test all the cases with a case statement, i.e.
# without any pipe, so that a shell running with "set -o pipefail" can not break it (cf. V6.1).
_IMVer="$(convert -version 2>/dev/null)"
case "${_IMVer}" in
	*ImageMagick* )
		TOOL="imagemagick"
		IMCONVERT="convert" ;;
	*GraphicsMagick* )
		TOOL="graphicsmagick"
		IMCONVERT="gm convert" ;;
	* )
		_IMVer="$(gm version 2>/dev/null)"
		case "${_IMVer}" in
			*GraphicsMagick* )
				TOOL="graphicsmagick"
				IMCONVERT="gm convert" ;;
			* )
				_IMVer="$(magick -version 2>/dev/null)"
				case "${_IMVer}" in
					*ImageMagick* )
						TOOL="imagemagick"
						IMCONVERT="magick" ;;
					* )
						echo " // Neither ImageMagick nor GraphicsMagick was found - quit here !!"
						exit 1 ;;
				esac ;;
		esac ;;
esac
unset _IMVer
echo " // Use ${TOOL} (command: ${IMCONVERT})"

# --- Which font can we use ? -------------------------------------------------------------
# Recent convert versions do not know "Helvetica" anymore, and asking for a font that is not
# installed makes convert fail (cf. V2.0 and V6.2 of TimeSeriesInfo_HP.sh). Probe a short
# list and fall back to no -font option at all, which is always safe.
if [ -z "${FONT_OPT+set}" ] 		# i.e. FONT_OPT not set at all, not even to an empty string
	then
		FONT_OPT=""
		_FontProbe="${TMPDIR:-/tmp}/.AMSTer_fontprobe_$$.png"
		for _Font in DejaVu-Sans DejaVuSans LiberationSans-Regular FreeSans Helvetica Arial
			do
				if ${IMCONVERT} -size 20x20 xc:white -pointsize 10 -font "${_Font}" -draw "text 1,15 'A'" "${_FontProbe}" 2>/dev/null
					then
						FONT_OPT="-font ${_Font}"
						break
				fi
			done
		rm -f "${_FontProbe}"
		unset _Font _FontProbe
		if [ "${FONT_OPT}" == "" ]
			then echo " // No usable font found; text will be drawn with the default font"
			else echo " // Use font option: ${FONT_OPT}"
		fi
	else
		echo " // Use font option inherited from the environment: ${FONT_OPT}"
fi

# --- Overlay two images ------------------------------------------------------------------
# GraphicsMagick has no "-composite" in convert, it needs "gm composite" with the operands
# in the reverse order.
function do_composite()
	{
	local base="$1"
	local overlay="$2"
	local gravity="$3"
	local geometry="$4"

	if [ "${TOOL}" == "imagemagick" ]
		then
			${IMCONVERT} "${base}" "${overlay}" -gravity "${gravity}" -geometry "${geometry}" -composite "${base}"
		else
			gm composite -gravity "${gravity}" -geometry "${geometry}" "${overlay}" "${base}" "${base}"
	fi
	}

# --- Overlay a png/jpg on a base image, safely ---------------------------------------------
# AddOverlay BASE IMAGE RESIZE GRAVITY POSITION
# Rescale IMAGE to RESIZE in the scratch file "Temp", then overlay it on BASE.
# The point of this function is that the scratch file is REMOVED first and that the result of
# the rescaling is TESTED: when IMAGE is missing (typically an artwork that was never added to
# TSCombiFiles) the previous content of Temp used to be pasted instead, which silently
# duplicated whatever was overlaid before (e.g. the colour bar, three times in a row).
function AddOverlay()
	{
	local base="$1"
	local image="$2"
	local resize="$3"
	local gravity="$4"
	local position="$5"
	local scratch="Temp"

	if [ ! -s "${image}" ]
		then
			echo "!!! Missing ${image} --> nothing overlaid at ${position}"
			echo "!!!   --> check ${PATH_SCRIPTS}/SCRIPTS_MT/TSCombiFiles/ and ../_CombiFiles/"
			return 0
	fi
	rm -f "${scratch}"
	if ${IMCONVERT} "${image}" -resize "${resize}" "${scratch}"
		then
			do_composite "${base}" "${scratch}" "${gravity}" "${position}"
		else
			echo "!!! Can not rescale ${image} --> nothing overlaid at ${position}"
	fi
	}