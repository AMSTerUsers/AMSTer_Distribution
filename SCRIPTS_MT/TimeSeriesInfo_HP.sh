#!/bin/bash
#
#	Dependencies:
#	- ImageJ
#	- ghostscript (to avoid ImageJ issue)
#   - Parameters file must be present in "MSBAS/Region/_CombiFiles" to extract several parameters from it.
#   - 'satview.jpg' and 'AMSTer.png' must be present in "MSBAS/Region/_CombiFiles" = Google earth image cropped using headers parameters of deformation file
#
#	Arguments:
#	- Argument 1 = eps file (TimeLine)
#	- Argument 2 = Amplitude-coherence-deformation file (jpg)
#   - Argument 3 = Resolution rate between satview.jpg and SAR images. (information in parameters file in "MSBAS/Region/_CombiFiles")
#
#		Action:
#		- Extract from the name of the file the coordinate sof both points 
#		- Write in an array of 4 elements these values, values can be adapted to the region.
#		- Define a rule for the position of the crop (can be adapted to the region.)
#		- Crop the Amp-coh-defo image for each pair of points and resize it.
#		- Calculates the coordinates of two points inside this crop.
#		- Add the cropped with points marked by a cross and save the file as _Combi.jpg.
#		- Add legend jpg file on the combi.
#		- If Argument2 is the EW amp-coh-defo, add also the Up-Down deformation legend.
#		- Add also an interpretation of the sens of displacement between 2 points for each deformation direction. (can be adapted to the region.)
#		- Move the new time series in (images/Time_Series/TS_all) folder and keep the original one in the specific folder.
#
# Dependencies ghost-script should be install ( test by cmd: gs --version)
# 		- Brew Install ghostscript
#		- sudo chown -R `whoami` /usr/local/share/ghostscript
#		- brew link --overwrite ghostscript
# (Purpose is to avoid issue with convert command like ("error/convert.c/ConvertImageCommand/3273."))
#
# Hard coded: 	- Folder where amplitude image with circle are locate ("TS_all" line 94)
#				- tag for web site (cfr line 195)
#				- __HardCodedLines.sh
#
# New in Distro V 1.1:	- allows plotting Vertical or EW only
#						- some cosmetic 
#						- change shell zsh in bash
#						  (By Nicolas d'Oreye) 
# New in Distro V 1.2:	- update file naming timeSeries_ (By Maxime Jaspard) 
# New in Distro V 1.3:	- Add a crop of Google earth on LOS time series
# New in Distro V 1.4:	- force mv results ; add short nap before moving to allow convert to finish the job
# New in Distro V 1.5:  - Extraction XXYY from Timeline filename is different (line 112, old style still here)
# New in Distro V 1.51: - Small correction to allow orbit number in MSBAS folder's name "ex: zz_LOS_Asc88_Auto_2_0.04_Einstein"
# New in Distro V 1.6:  - zap a gremlin in current header
# New in Distro V 1.7:  - change all _combi as _Combi for uniformisation 
# New in Distro V 2.0:  - Use Helevetica font with Mac and FreeSans with Linux because recent convert version does not know Helvetica anymore
# New in Distro V 3.0: 	- Use hard coded lines definition from __HardCodedLines.sh
# New in Distro V 4.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 5.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 5.1 20231120:	- Add logo to timestamp  (l392)
# New in Distro V 5.2 20240603:	- Extract "LOS" from speed deformation filename instead of complete path (since ALOS2)
# New in Distro V 5.3 20240620:	- from VD_5.2, come back in complete path with replacing the extraction of "LOS" to "_LOS" to filter "ALOS" stuff 
# New in Distro V 5.4 20241104:	- Adapt legend picture if deformation NS available
# New in Distro V 6.0. 20250825:	- Test if using ImageMagick or GraphicsMagick and adapt syntax of convert accordingly
# New in Distro V 6.1 20250904:	- Avoid possible failure of double test (eg when shell has set -o pipefail enabled) in fct to test convert version
#								- replace convert composite command by gm composite when using GraphicsMagick
# New in Distro V 6.2 20250916:	- use no specific font with convert to avoid error when font not found
# New in Distro V 6.3 20250917:	- Do not display message about Rate if only 2 parameters are provided, which is OK for EW & UD comp.
# New in Distro V 6.4 20260323:	- add case Legend_GEOM_LineOfSight if no LOS is defined 
# New in Distro V 6.5 20260804:	- add  elif [[ $(basename ${Legend}) = "Legend_GEOM_NS.jpg" ]] 
# New in Distro V 6.6 20260804:	- move the ImageMagick/GraphicsMagick detection, the font test and 
#								  do_composite to __ImageMagickFcts.sh, so that AmpDefo_map.sh and 
#								  AmpTif_map.sh use the same tool and the same font as this script 
#								- call ${IMCONVERT} instead of convert everywhere (copes with 
#								  ImageMagick 6, ImageMagick 7 "magick" and GraphicsMagick "gm convert") 
#								- remove the dead EW-->UD leftovers in the Legend_GEOM_UD and 
#								  Legend_GEOM_EW branches 
# New in Distro V 6.7 20260804:	- all the overlays go through AddOverlay (in __ImageMagickFcts.sh), which 
#								  removes the Temp scratch file first and tests the rescaling. A missing 
#								  artwork used to leave the previous Temp in place, so the colour bar was 
#								  pasted again at +15+650 and +15+1080 --> 3 colour bars and no drawing 
#								- remove the dead EW-->NS leftover in the Legend_GEOM_NS branch too 
# New in Distro V 6.8 20260804:	- the drawings explaining the sense of displacement describe the 
#								  DECOMPOSITION and not the plotted component, so there is no 
#								  TS_Displ_Pos_EW.png nor TS_Displ_Pos_UD.png: the Legend_GEOM_EW, 
#								  Legend_GEOM_UD and Legend_GEOM_NS branches asked for files that never 
#								  existed. They now call SetDisplArtwork, which picks TS_Displ_*_NS.png 
#								  for a 3 components run and TS_Displ_*.png for a 2 components run, 
#								  exactly as the Legend_EW.jpg case already did 
# New in Distro V 6.9 20260804:	- say WHICH of satview.jpg or RateResoSatView is missing when the Google 
#								  Earth crop is skipped, instead of the stale _COMP/_LOS message 
# New in Distro V 7.0 20260804:	- satview crop: read the actual size of satview.jpg and clamp the crop 
#								  geometry to it. An out of bounds geometry made convert fail with 
#								  "geometry does not contain image", hence no crop2 at all and 4 more 
#								  failing -draw calls afterwards 
#								- satview crop: compare RateResoSatView with the rate deduced from 
#								  the actual size of satview.jpg and the msbas grid (Crop_L), and 
#								  use the deduced one when they disagree by more than 5% 
#								- the msbas GeoTIFF products carry 0 as nodata (GDAL_NODATA=0) and 
#								  neither ImageJ nor convert know that tag, so all the voids used to 
#								  be painted as a valid 0 m/yr, that is white at the centre of the 
#								  diverging colour table. On a run restricted to a sub-window the 
#								  voids dominate the histogram, the auto stretch collapses towards 0 
#								  and the velocity map comes out entirely white. The decoration 
#								  thumbnails are now rebuilt from the GeoTIFF with the colour scale 
#								  computed on the CROP WINDOW ONLY and with the nodata masked through 
#								  the "nv" entry of the gdaldem colour table 
#								- ENVI runs, or any run where the GeoTIFF or gdal can not be found, 
#								  keep the historical behaviour (crop of the AMPLI_COH jpg) 
#								- define IMIDENTIFY next to IMCONVERT, and a scratch dir cleaned by 
#								  a trap on EXIT 
# New in Distro V 7.1 20260804:	- FindRateTif was looking for MSBAS_LINEAR_RATE_<COMP>.tif, but 
#								  TS_AddLegend_LOS.sh copies the product into _images as 
#								  MSBAS_LINEAR_RATE_GEOM_<Orbit>.tif and asks AmpTif_map.sh for 
#								  AMPLI_COH_<that name>.jpg. The tif was therefore never found, 
#								  EXTIMG fell back to "envi" and the thumbnail kept being cropped 
#								  from the white jpg. It is now derived from the jpg itself, by 
#								  dropping the AMPLI_COH_ prefix and changing the extension 
#								- the "nv" entry of gdaldem is NOT usable to mask the nodata. 
#								  Tested with GDAL 3.8: last in the file it is ignored, first in 
#								  the file it is parsed as a value 0 entry and drags the whole ramp 
#								  towards its colour. And with -alpha, gdaldem interpolates the 
#								  alpha column like R, G and B, so valid pixels came out semi 
#								  transparent in proportion to |value|. 0 now gets a narrow notch 
#								  of NODATACOL made of plain value entries, which is deterministic 
#								- checked that array[1] is really X and array[2] really Y despite 
#								  the timeLine<LIN>_<PIX>_... naming: see the comment below 
# New in Distro V 7.2 20260804:	- the colour bar of Legend_*.jpg is the ImageJ HSB hue ramp that 
#								  CreateColorFrame.py burns in (Hue = deformation, Saturation = 
#								  mask, Brightness = white), not a blue-white-red table. The 
#								  thumbnail therefore looked nothing like its own colour bar. The 
#								  gdaldem colour table is now built by SAMPLING that colour bar 
#								  (NSTOPS samples between Margin and Margin+LegendWidth, at mid 
#								  height between FrameTop and FrameBott), so any ramp 
#								  CreateColorFrame.py may use is followed automatically. 
#								  COLLOW/COLZERO/COLHIGH are only the fallback now 
#								- add SCALEFROM: WINDOW keeps the per crop limits (colour bar 
#								  figures then do not apply, the real ones are written on the 
#								  thumbnail), LEGEND uses the limits the bar was built with so that 
#								  bar and thumbnail agree in colour AND in value #
# New in Distro V 7.3 20260804:	- checked against CreateColorFrame.py V3.1 and the Fiji macro of 
#								  AmpTif_map.sh, which together define the colour code exactly: 
#								    min_ADR/max_ADR = nanmin/nanmax over the VALID pixels only 
#								    (NoData becomes NaN in ReadTiff), the bar spans min_ADR to 
#								    max_ADR, pixel [0;0] is forced to max_ADR + range/5 and 
#								    resetMinAndMax + 8-bit then give 
#								    hue8 = 255*(v - min_ADR)/(1.2*range), 
#								    i.e. min_ADR = hue 0 (red) and max_ADR = hue 212.5 (pink). 
#								  Three consequences: 
#								- SCALEFROM defaults to LEGEND now. min_ADR/max_ADR ignore the 
#								  NoData, so that range is NOT dragged by the 96% of zeros: it 
#								  gives a thumbnail that is neither washed out NOR at odds with the 
#								  figures printed on the bar. WINDOW stays available for extra 
#								  contrast on a small window 
#								- the limits are no longer forced symmetric when the ramp comes from 
#								  the bar. That hue ramp is sequential, not diverging: 0 is an 
#								  ordinary value inside it (which is exactly what PosZero marks), so 
#								  centring the scale on 0 would shift every hue 
#								- NODATACOL is white, because AmpTif_map.sh renders the voids white 
#								  (Saturation = mask = 0) and that hue ramp never yields white. 
#								  CreateColorFrame.py turns the NoData into NaN before computing 
#								  anything, so a genuine 0 m/yr pixel is white in the big map too: 
#								  thumbnail and map now behave identically 
#								- replicate the LegendWidth clamp of CreateColorFrame.py (its line 
#								  334) when sampling the bar. With a 500 px raster, Margin = 40 and 
#								  LegendWidth = 500 the real bar is 420 px wide, so sampling the 500 
#								  of TS_parameters.txt ran past the end of the ramp 
#								- NSTOPS raised to 128 (mean channel error against a reference map 
#								  rebuilt from CreateColorFrame.py: 11.9 at 16 stops, 7.1 at 64, 
#								  6.8 at 128, 6.7 at 256, the floor being the jpg artefacts) 
# New in Distro V 7.4 20260804:	- the colour bar produced by the Fiji step can come out UNIFORMLY RED, 
#								  and V7.3 sampled its ramp, so it faithfully reproduced a broken 
#								  bar: nearly red thumbnails. The ramp is now COMPUTED from the 
#								  colour code instead of being read from an image (RAMPSOURCE=HUE): 
#								    hue8 = 255*(v-min)/((1+1/HUEPAD)*(max-min)), RGB = HSB(hue8/255,1,1) 
#								  which is exactly what CreateColorFrame.py line 431 plus 
#								  resetMinAndMax + 8-bit + the HSB stack of AmpTif_map.sh produce. 
#								  Checked against a reference map rebuilt from CreateColorFrame.py: 
#								  97.3% of the pixels within 24 levels, i.e. as good as sampling a 
#								  CORRECT bar, but immune to a broken one. 
#								  RAMPSOURCE=LEGEND keeps the V7.3 sampling, TABLE the built-in one 
#								- add REDRAWBAR (default YES): rebuild the colour bar pasted on the 
#								  figure from that same ramp, at the geometry of TS_parameters.txt and 
#								  labelled in cm/yr, so that bar and map agree even while the Fiji 
#								  step still produces a red bar. Legend_*.jpg is not modified, only 
#								  what gets pasted; the branch tests still use its name 
#								- LIKELY CAUSE of the red bar, to be fixed in CreateColorFrame.py: 
#								  WriteTiff writes the NaN back as the NoData value of the INPUT when 
#								  that value is finite (its lines 190-193). With an undeclared or 
#								  mismatched sentinel such as -3.4e38 the *_2.0.tif then contains 
#								  -3.4e38, ImageJ knows nothing about GDAL_NODATA, resetMinAndMax 
#								  takes -3.4e38 as the minimum and every real value collapses onto 
#								  hue8 = 255, which is red. V3.1 cleaned min_ADR/max_ADR but the 
#								  sentinel is still written into the raster ImageJ reads 
# New in Distro V 7.5 20260804:	- all components figure (Legend_EW.jpg branch): the +30+1530 slot now 
#								  holds the Google Earth crop instead of the UD velocity map, as it 
#								  already did in every single component branch. UD stays visible in 
#								  the plot itself. The UD colour bar at +10+1900 is dropped with it, 
#								  since there is no longer a UD map for it to describe 
#								- if no satview crop could be built (satview.jpg missing, or ENVI run 
#								  with no rate given) the historical UD map is used instead, so the 
#								  slot is never left empty 
#								- ANNOTATESCALE defaults to AUTO: the limits are written on the 
#								  thumbnail only with SCALEFROM=WINDOW, where the colour bar does not 
#								  describe them. They are printed in cm/yr with 2 decimals, as on the 
#								  bar, instead of the raw full precision limits which ran out of the 
#								  box 
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V7.5 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 04, 2026"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
	# define FONT_OPT="-font $FONT, where FONT is searched among DejaVuSans, LiberationSans-Regular or Arial" 
	# TimeSeriesInfoHPWebTag to tag the plot with the address of the web page
# ^^^ ----- Hard coded lines to check --- ^^^ 

#Read Arguments:
TimeLine=$1			# Read the Time Series jpg file
AmpliCohDefo=$2
Rate=$3

RUNDIR=$(pwd)

WorkDir=$(dirname ${AmpliCohDefo})

echo " TimeLine = ${TimeLine}"
echo " AmpliCohDefo = ${AmpliCohDefo}"
echo "WorkDir = ${WorkDir}"
if [ $# -eq 3 ] ; then echo "Rate between pixel number on eps file and image to crop = ${Rate}" ; fi

ParamFile=${WorkDir}/TS_parameters.txt
bn=$(basename ${TimeLine})

#cp ${TimeLine} ${WorkDir}/${bn}
cp ${TimeLine} ${WorkDir}
TimeLine=${WorkDir}/${bn}
SatView=${WorkDir}/satview.jpg

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"

function GetParam()
	{
	unset PARAM 
	PARAM=$1
	PARAM=`${PATHGNU}/grep -m 1 ${PARAM} ${ParamFile} | cut -f1 -d \# | ${PATHGNU}/gsed "s/	//g" | ${PATHGNU}/gsed "s/ //g"`
	eval PARAM=${PARAM}
	echo ${PARAM}
	}
	
Crop_X=$(GetParam Crop_X)
Crop_Y=$(GetParam Crop_Y)
Crop_L=$(GetParam Crop_L)		# NdO Aug 04 2026: needed to check RateResoSatView (see below)
CrossTresh=$(GetParam CrossTresh)
CrossBig=$(GetParam CrossBig)
CrossSmall=$(GetParam CrossSmall)
WebPage=$(GetParam WebPage)

# Choose the drawings that explain the sense of displacement between the two crosses.
# BEWARE: these drawings describe the DECOMPOSITION and not the plotted component, hence there 
# is no _EW nor _UD version of them:
#	TS_Displ_Pos_NS.png / TS_Displ_Neg_NS.png	--> 3 components run (EW, UD and NS)
#	TS_Displ_Pos.png    / TS_Displ_Neg.png		--> 2 components run (EW and UD)
# $1 = path of the zz_NS_* companion dir to test; it may well not exist.
# Sets DisplPos and DisplNeg.
function SetDisplArtwork()
	{
	local NSDir="$1"

	if [ -d "${NSDir}" ] && [ -n "$(ls -A "${NSDir}" 2>/dev/null)" ]
		then
			echo " // 3 components run (${NSDir} exists and is not empty) --> use the _NS drawings"
			DisplPos="${WorkDir}/TS_Displ_Pos_NS.png"
			DisplNeg="${WorkDir}/TS_Displ_Neg_NS.png"
		else
			echo " // 2 components run (no ${NSDir}) --> use the EW+UD drawings"
			DisplPos="${WorkDir}/TS_Displ_Pos.png"
			DisplNeg="${WorkDir}/TS_Displ_Neg.png"
	fi
	}

# When this script is called by TS_AddLegend_LOS.sh we are IN the component dir, i.e.
# MSBAS/Region/zz_<COMP>_<REMARKDIR>, so the companion NS dir is ../zz_NS_<REMARKDIR>.
# When it is called by TS_AddLegend_EW_UD.sh we are in MSBAS/Region and REMARKDIR is taken 
# from the eps file name instead (see the Legend_EW.jpg case below).
RemarkFromDir=$(basename "${RUNDIR}" | ${PATHGNU}/gsed -E 's/^zz_[A-Za-z0-9]+_//')
NSCompanionDir="$(dirname "${RUNDIR}")/zz_NS_${RemarkFromDir}"

# Different usage of composite function depending on the version of imagesmagick or graphicmagick:
# NdO Aug 04 2026: moved to __ImageMagickFcts.sh so that AmpDefo_map.sh and AmpTif_map.sh 
# use exactly the same detection. It sets TOOL, IMCONVERT and FONT_OPT (the latter only if 
# __HardCodedLines.sh did not already define it) and defines do_composite. 
source ${PATH_SCRIPTS}/SCRIPTS_MT/__ImageMagickFcts.sh

# NdO Aug 04 2026: identify command matching the convert flavour detected just above 
# (ImageMagick 6 "identify", ImageMagick 7 "magick identify", GraphicsMagick "gm identify")
case "${IMCONVERT}" in
	*"gm convert"*)	IMIDENTIFY="gm identify" ;;
	*magick*)		IMIDENTIFY="magick identify" ;;
	*)				IMIDENTIFY="identify" ;;
esac

export GDAL_PAM_ENABLED=NO		# no .aux.xml sidecar files please

# Scratch dir for the temporary windows and colour tables built below. 
# mktemp without a template fails on Mac, mktemp -d -t is the portable form there. 
TMPD=$(mktemp -d 2>/dev/null || mktemp -d -t amster)
trap 'rm -rf "${TMPD}"' EXIT

# ---------------------------------------------------------------------------------------
# NdO Aug 04 2026 (V7.0): colour scale of the decoration thumbnails 
#
# The msbas GeoTIFF products carry 0 as nodata (GDAL_NODATA=0). Neither ImageJ nor convert 
# know that tag (42113 is gdal specific), so every void used to be painted as a valid 
# 0 m/yr, that is WHITE at the centre of a diverging colour table. When the run is 
# restricted to a sub-window, or simply when the region decorrelates, the voids dominate 
# the histogram, any percentile auto stretch collapses towards 0 and the whole velocity map 
# comes out white. 
#
# The thumbnails are therefore rebuilt from the GeoTIFF, with the colour scale computed on 
# the SAME window as the crop, and with the nodata made transparent through the "nv" entry 
# of the gdaldem colour table. 
#
# BEWARE: the colour table below must match the colour bar of Legend_*.jpg, otherwise the 
# thumbnail colours will not mean what the legend says. Edit COLLOW/COLZERO/COLHIGH here. 
# ---------------------------------------------------------------------------------------

COLLOW="0 0 255"			# colour of the most negative value  (blue)
COLZERO="255 255 255"		# colour of zero                     (white)
COLHIGH="255 0 0"			# colour of the most positive value  (red)
NODATACOL="255 255 255"		# colour of the masked voids, as R G B. White, because that is what 
							# AmpTif_map.sh produces (Saturation = mask = 0 --> white) and the hue 
							# ramp of CreateColorFrame.py never yields white, so it is unambiguous. 
							# If you fall back on the diverging COLLOW/COLZERO/COLHIGH below, change 
							# it to something else (e.g. "102 102 102"), as white is COLZERO there. 
SCALEFROM="LEGEND"			# WINDOW = limits computed on the crop window only. The thumbnail then 
							#          uses the full colour range but the figures printed on the 
							#          colour bar of Legend_*.jpg do NOT apply to it: the true 
							#          limits are written on the thumbnail itself (ANNOTATESCALE). 
							# LEGEND = same limits as the colour bar, so the bar and the thumbnail 
							#          agree both in colour AND in value. This is the default: 
							#          CreateColorFrame.py takes them as nanmin/nanmax over the 
							#          VALID pixels only, so this range is not dragged by the 
							#          240001 zeros and the thumbnail is not washed out either. 
							#          Needs the *_scale.txt side file of AmpTif_map.sh V1.4 or 
							#          above; falls back on WINDOW when it is missing. 
SCALEMODE="MINMAX"			# MINMAX = min/max of the window 
							# SIGMA  = mean +/- 2 sigma, more robust to outliers
							# Made symmetric around 0 ONLY when the built-in diverging table is 
							# used, because there 0 must land on COLZERO. The hue ramp of 
							# CreateColorFrame.py is sequential, not diverging: 0 is an ordinary 
							# value in the middle of it (that is what PosZero marks on the bar), so 
							# forcing symmetry there would shift every hue.
RAMPSOURCE="HUE"			# Where the colour ramp comes from: 
							# HUE    = computed from the colour code of CreateColorFrame.py + the 
							#          Fiji macro of AmpTif_map.sh, i.e. 
							#          hue8 = 255*(v - min)/((1 + 1/HUEPAD)*(max - min)) and 
							#          RGB  = HSB(hue8/255, 1, 1). This is the INTENDED ramp and it 
							#          does not care whether the bar image itself came out right. 
							# LEGEND = sampled out of the colour bar of Legend_*.jpg, i.e. whatever 
							#          the bar actually shows. Only use this once the bar is known 
							#          to be correct: a broken bar gives a broken thumbnail. 
							# TABLE  = the built-in diverging COLLOW/COLZERO/COLHIGH below. 
HUEPAD=5					# the "5" of CreateColorFrame.py line 431: 
							# Array_DefoMod[0] = max_ADR + (max_ADR - min_ADR)/5, which stretches 
							# the 8-bit range by 1 + 1/5 = 1.2 so that max_ADR lands on pink 
							# (hue8 = 212) instead of cycling back to red. Change both together. 
NSTOPS=128					# number of stops of the generated / sampled colour table
REDRAWBAR="YES"				# YES: rebuild the colour bar overlaid on the figure from the same ramp 
							# as the thumbnails, instead of using the Legend_*.jpg of AmpTif_map.sh. 
							# Set it to NO once the bar produced by the Fiji step is correct again. 
							# The original Legend_*.jpg is not touched, only what is pasted. 
ANNOTATESCALE="AUTO"		# write the actual limits on the thumbnail. 
							# AUTO = only with SCALEFROM=WINDOW, where the limits change from one 
							#        pair of points to the next and the colour bar does not describe 
							#        them. With SCALEFROM=LEGEND the bar already carries the very 
							#        same figures, so the annotation would be redundant. 
							# YES / NO force it either way. 

# The eps files are named timeLine<LIN1>_<PIX1>_<LIN2>_<PIX2> by PlotTS.sh, which suggests that
# array[1] is a LINE, i.e. a ROW, and that feeding it to X1 transposes everything. It does NOT:
# verified on timeLine293_268_257_284 against MSBAS_LINEAR_RATE_EW.tif, the rate of the two time
# series (-0.0050 and -0.1587 m/yr) is found at tif[268][293] and tif[284][257], i.e. at
# column=array[1] and row=array[2]. So array[1] really is X and array[2] really is Y, and the
# assignments below are right. Do not "fix" them.

# Size of a raster through gdal. usage: SIZE=$(GetTifSize file.tif)  --> "500 500"
GetTifSize()
	{
	gdalinfo "$1" 2>/dev/null | ${PATHGNU}/grep -m1 "^Size is" | ${PATHGNU}/gsed 's/^Size is //' | tr -d ',' 
	}

# Size of any image through convert. usage: SIZE=$(GetImgSize file.jpg)  --> "1142 1148"
GetImgSize()
	{
	local W H
	W=$(${IMIDENTIFY} -format "%w" "$1" 2>/dev/null | head -1)
	H=$(${IMIDENTIFY} -format "%h" "$1" 2>/dev/null | head -1)
	echo "${W} ${H}"
	}

# Locate the msbas GeoTIFF the AMPLI_COH jpg was built from. 
# TS_AddLegend_LOS.sh copies MSBAS_LINEAR_RATE_<TagOrbit>.tif into _images as 
# MSBAS_LINEAR_RATE_GEOM_<Orbit>.tif and asks AmpTif_map.sh for AMPLI_COH_<same name>.jpg, so 
# the product is simply the jpg without the AMPLI_COH_ prefix and with a tif extension. That 
# covers GEOM_EW, GEOM_UD, GEOM_NS, GEOM_Asc, GEOM_Desc, GEOM_LineOfSight and anything else 
# the Orbit detection of TS_AddLegend_LOS.sh may come up with. 
# The _2.0 companion is deliberately NOT accepted: CreateColorFrame.py burns the colour ramp 
# into its first rows and forces its pixel [0;0] 20% above the max. 
# Echoes nothing when not found. 
# usage: RATETIF=$(FindRateTif "${AmpliCohDefo}")
FindRateTif()
	{
	local ACD="$1"
	local DIR=$(dirname "${ACD}")
	local BN=$(basename "${ACD}")
	local ROOT EXT CAND
	ROOT=$(echo "${BN}" | ${PATHGNU}/gsed 's/^AMPLI_COH_//' | ${PATHGNU}/gsed 's/\.[^.]*$//')
	if [ -z "${ROOT}" ] ; then echo "" ; return 1 ; fi
	for EXT in tif tiff TIF TIFF
		do
			if [ -e "${DIR}/${ROOT}.${EXT}" ] ; then echo "${DIR}/${ROOT}.${EXT}" ; return 0 ; fi
		done
	# not in _images (first run, or _images cleaned): take the original product in the run dir
	CAND=$(find "${RUNDIR}" -maxdepth 1 -type f -name "MSBAS_LINEAR_RATE_*" ! -name "*_2.0*" \
		\( -name "*.tif" -o -name "*.tiff" \) 2>/dev/null | head -1)
	if [ -n "${CAND}" ] ; then echo "${CAND}" ; return 0 ; fi
	echo ""
	return 1
	}

# Clamp a square window to a raster. Echoes "posX posY L". 
# usage: WIN=$(ClampWin ${W} ${H} ${posX} ${posY} ${L})
ClampWin()
	{
	local W="$1" ; local H="$2" ; local PX="$3" ; local PY="$4" ; local LL="$5"
	if [ -n "${W}" ] && [ -n "${H}" ]
		then
			if [ ${LL} -gt ${W} ] ; then LL=${W} ; fi
			if [ ${LL} -gt ${H} ] ; then LL=${H} ; fi
			if [ $((PX + LL)) -gt ${W} ] ; then PX=$((W - LL)) ; fi
			if [ $((PY + LL)) -gt ${H} ] ; then PY=$((H - LL)) ; fi
			if [ ${PX} -lt 0 ] ; then PX=0 ; fi
			if [ ${PY} -lt 0 ] ; then PY=0 ; fi
	fi
	echo "${PX} ${PY} ${LL}"
	}

# Symmetric colour scale limits computed on ONE window of a raster, nodata excluded. 
# Echoes "min max", e.g. "-0.13 0.13". Falls back on the whole raster when the window holds 
# no valid pixel at all. 
# usage: SCALE=$(GetCropScale file.tif ${posX} ${posY} ${L})
GetCropScale()
	{
	local TIF="$1" ; local PX="$2" ; local PY="$3" ; local LL="$4" ; local SYM="$5"
	local VRT="${TMPD}/scale_win.vrt"
	local INFO MIN MAX MEAN STD A

	rm -f "${VRT}"
	gdal_translate -q -of VRT -srcwin ${PX} ${PY} ${LL} ${LL} "${TIF}" "${VRT}" 2>/dev/null

	# the VRT inherits NoDataValue from the source, so gdalinfo -stats ignores the voids
	INFO=$(gdalinfo -stats "${VRT}" 2>/dev/null)
	MIN=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_MINIMUM=" | cut -d = -f 2)
	MAX=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_MAXIMUM=" | cut -d = -f 2)
	MEAN=$(echo "${INFO}" | ${PATHGNU}/grep -m1 "STATISTICS_MEAN="    | cut -d = -f 2)
	STD=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_STDDEV="  | cut -d = -f 2)

	if [ -z "${MIN}" ] || [ -z "${MAX}" ]
		then
			echo " // WARNING: window ${LL}x${LL}+${PX}+${PY} holds no valid pixel," >&2
			echo " //          colour scale computed on the whole raster instead" >&2
			INFO=$(gdalinfo -stats "${TIF}" 2>/dev/null)
			MIN=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_MINIMUM=" | cut -d = -f 2)
			MAX=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_MAXIMUM=" | cut -d = -f 2)
			MEAN=$(echo "${INFO}" | ${PATHGNU}/grep -m1 "STATISTICS_MEAN="    | cut -d = -f 2)
			STD=$(echo "${INFO}"  | ${PATHGNU}/grep -m1 "STATISTICS_STDDEV="  | cut -d = -f 2)
	fi
	if [ -z "${MIN}" ] || [ -z "${MAX}" ] ; then echo "" ; return 1 ; fi

	# SYM=YES: symmetric limits rounded up to 0.01, needed by a diverging table so that 0 lands 
	# on COLZERO. SYM=NO: the plain limits, as a sequential hue ramp has no privileged centre. 
	A=$(${PATHGNU}/gawk -v mn="${MIN}" -v mx="${MAX}" -v me="${MEAN}" -v sd="${STD}" \
		-v mode="${SCALEMODE}" -v sym="${SYM}" 'BEGIN {
			if (mode == "SIGMA") { lo = me - 2*sd ; hi = me + 2*sd }
			else                 { lo = mn ; hi = mx }
			if (sym == "YES") {
				alo = (lo < 0 ? -lo : lo) ; ahi = (hi < 0 ? -hi : hi)
				a = (alo > ahi ? alo : ahi)
				a = int(a*100 + 0.999999)/100
				if (a <= 0) a = 0.01
				printf "%.2f %.2f", -a, a
			} else {
				if (hi <= lo) hi = lo + 1e-6
				printf "%.9g %.9g", lo, hi
			}
		}')
	if [ -z "${A}" ] ; then echo "" ; return 1 ; fi
	echo "${A}"
	}

# Build the gdaldem colour table from the AMSTer colour code itself, without reading any image.
# CreateColorFrame.py forces its pixel [0;0] to max + (max-min)/HUEPAD, then the Fiji macro of
# AmpTif_map.sh does resetMinAndMax() + 8-bit, so the byte that ends up in the Hue slice is
#     hue8 = 255 * (v - min) / ((1 + 1/HUEPAD) * (max - min))
# and the figure is HSB(hue8/255, mask/255, 255), i.e. for a valid pixel HSB(hue8/255, 1, 1):
# min -> hue 0 (red), max -> hue8 212 (pink), which is the "Red to Pink" of CreateColorFrame.py.
# usage: BuildCptHue ${LO} ${HI} ${EPS1} ${EPS2} out.cpt
BuildCptHue()
	{
	local LO="$1" ; local HI="$2" ; local E1="$3" ; local E2="$4" ; local CPT="$5"

	rm -f "${CPT}"
	${PATHGNU}/gawk -v lo="${LO}" -v hi="${HI}" -v e1="${E1}" -v e2="${E2}" \
		-v n="${NSTOPS}" -v pad="${HUEPAD}" -v nd="${NODATACOL}" 'BEGIN {
			if (hi <= lo) exit 1
			if (pad <= 0) pad = 5
			span = (1 + 1/pad) * (hi - lo)
			# HSB(h,1,1) -> RGB, exactly as java.awt.Color.HSBtoRGB with s = b = 1
			for (i = 0; i < n; i++) {
				V[i] = lo + (hi - lo) * i / (n - 1)
				h = (V[i] - lo) / span			# 0 .. 1/1.2*... , always < 1
				h6 = h * 6 ; k = int(h6) ; f = h6 - k
				if      (k == 0) { r = 255      ; g = 255*f     ; b = 0        }
				else if (k == 1) { r = 255*(1-f); g = 255       ; b = 0        }
				else if (k == 2) { r = 0        ; g = 255       ; b = 255*f    }
				else if (k == 3) { r = 0        ; g = 255*(1-f) ; b = 255      }
				else if (k == 4) { r = 255*f    ; g = 0         ; b = 255      }
				else             { r = 255      ; g = 0         ; b = 255*(1-f)}
				R[i] = int(r + 0.5) ; G[i] = int(g + 0.5) ; B[i] = int(b + 0.5)
			}
			# ramp colour at 0, to bracket the nodata notch without spreading a halo
			r0 = R[0] ; g0 = G[0] ; b0 = B[0]
			for (i = 0; i < n - 1; i++)
				if (V[i] <= 0 && 0 <= V[i+1]) {
					q = (V[i+1] == V[i]) ? 0 : (0 - V[i]) / (V[i+1] - V[i])
					r0 = R[i] + q*(R[i+1]-R[i]) ; g0 = G[i] + q*(G[i+1]-G[i])
					b0 = B[i] + q*(B[i+1]-B[i]) ; break
				}
			done0 = 0
			for (i = 0; i < n; i++) {
				if (!done0 && V[i] > -e2) {
					printf "%.9f %d %d %d\n", -e2, r0, g0, b0
					printf "%.9f %s\n", -e1, nd
					printf "%.9f %s\n",  e1, nd
					printf "%.9f %d %d %d\n",  e2, r0, g0, b0
					done0 = 1
				}
				if (V[i] < -e2 || V[i] > e2)
					printf "%.9f %d %d %d\n", V[i], R[i], G[i], B[i]
			}
			if (!done0) {
				printf "%.9f %d %d %d\n", -e2, r0, g0, b0
				printf "%.9f %s\n", -e1, nd
				printf "%.9f %s\n",  e1, nd
				printf "%.9f %d %d %d\n",  e2, r0, g0, b0
			}
		}' > "${CPT}"
	if [ ! -s "${CPT}" ] ; then rm -f "${CPT}" ; return 1 ; fi
	return 0
	}

# Redraw the colour bar from the same ramp as the thumbnails, at the same geometry as the one
# AmpTif_map.sh produces (Margin, LegendWidth, LegendHeight, FrameTop, FrameBott, MarkUp, MarkDown,
# LegValPos, LegAdj* of TS_parameters.txt) so that it drops in place of Legend_*.jpg. The ramp is
# emitted as an ASCII PPM, which needs no tool beyond convert.
# Values are labelled in cm/yr, i.e. *100, as CreateColorFrame.py does for the figure.
# usage: BuildColourBar ${LO} ${HI} ${LEGW} out.jpg
BuildColourBar()
	{
	local LO="$1" ; local HI="$2" ; local LEGW="$3" ; local OUT="$4"
	local M LW LH FT FB MU MD LVP LUP LAZ LAM LAX LAU
	local LWMAX PL PR PZ PU MINCM MAXCM

	M=$(GetParam Margin)        ; LW=$(GetParam LegendWidth)
	LH=$(GetParam LegendHeight) ; FT=$(GetParam FrameTop) ; FB=$(GetParam FrameBott)
	MU=$(GetParam MarkUp)       ; MD=$(GetParam MarkDown)
	LVP=$(GetParam LegValPosH)  ; LUP=$(GetParam LegUnitPosH)
	LAZ=$(GetParam LegAdjZero)  ; LAM=$(GetParam LegAdjMin)
	LAX=$(GetParam LegAdjMax)   ; LAU=$(GetParam LegAdjUnit)
	if [ -z "${M}" ] || [ -z "${LW}" ] || [ -z "${LH}" ] || [ -z "${FT}" ] || [ -z "${FB}" ] ; then return 1 ; fi
	if [ -z "${LEGW}" ] ; then LEGW=$(( LW + 2 * M )) ; fi

	# same clamp as CreateColorFrame.py line 334
	LWMAX=$(( LEGW - 2 * M ))
	if [ ${LWMAX} -lt 1 ] ; then return 1 ; fi
	if [ ${LW} -gt ${LWMAX} ] ; then LW=${LWMAX} ; fi

	rm -f "${TMPD}/bar.ppm" "${OUT}"
	${PATHGNU}/gawk -v lo="${LO}" -v hi="${HI}" -v pad="${HUEPAD}" -v w="${LEGW}" -v h="${LH}" \
		-v m="${M}" -v lw="${LW}" -v ft="${FT}" -v fb="${FB}" 'BEGIN {
			if (hi <= lo || w < 1 || h < 1) exit 1
			if (pad <= 0) pad = 5
			span = (1 + 1/pad) * (hi - lo)
			printf "P3\n%d %d\n255\n", w, int(h)
			for (y = 0; y < int(h); y++) {
				for (x = 0; x < w; x++) {
					if (y >= ft && y < fb && x >= m && x < m + lw) {
						hh = ((hi - lo) * (x - m) / (lw - 1)) / span
						h6 = hh * 6 ; k = int(h6) ; f = h6 - k
						if      (k == 0) { r = 255      ; g = 255*f     ; b = 0        }
						else if (k == 1) { r = 255*(1-f); g = 255       ; b = 0        }
						else if (k == 2) { r = 0        ; g = 255       ; b = 255*f    }
						else if (k == 3) { r = 0        ; g = 255*(1-f) ; b = 255      }
						else if (k == 4) { r = 255*f    ; g = 0         ; b = 255      }
						else             { r = 255      ; g = 0         ; b = 255*(1-f)}
						printf "%d %d %d\n", int(r+0.5), int(g+0.5), int(b+0.5)
					} else printf "255 255 255\n"
				}
			}
		}' > "${TMPD}/bar.ppm"
	if [ ! -s "${TMPD}/bar.ppm" ] ; then return 1 ; fi

	PL=${M} ; PR=$(( M + LW ))
	PZ=$(${PATHGNU}/gawk -v lo="${LO}" -v hi="${HI}" -v lw="${LW}" -v m="${M}" \
		'BEGIN {v = lo/(hi-lo)*lw ; if (v < 0) v = -v ; printf "%d", v + m}')
	PU=$(( PL - LAM + LAU ))
	MINCM=$(${PATHGNU}/gawk -v v="${LO}" 'BEGIN {printf "%.2f", v*100}')
	MAXCM=$(${PATHGNU}/gawk -v v="${HI}" 'BEGIN {printf "%.2f", v*100}')

	${IMCONVERT} "${TMPD}/bar.ppm" \
		-fill black -stroke black -strokewidth 2 \
		-draw "line ${PL},${MU} ${PL},${MD}" \
		-draw "line ${PZ},${MU} ${PZ},${MD}" \
		-draw "line ${PR},${MU} ${PR},${MD}" \
		-stroke none -pointsize $(GetParam LegendTxtSize) ${FONT_OPT} \
		-draw "text $(( PZ - LAZ )),${LVP} '0'" \
		-draw "text $(( PL - LAM )),${LVP} '${MINCM}'" \
		-draw "text $(( PR - LAX )),${LVP} '${MAXCM}'" \
		-draw "text ${PU},${LUP} '[cm/year]'" \
		"${OUT}" || return 1
	[ -s "${OUT}" ] || return 1
	return 0
	}

# Build the gdaldem colour table by SAMPLING THE COLOUR BAR of Legend_*.jpg, so that the
# thumbnail uses exactly the ramp CreateColorFrame.py burnt into the legend (an ImageJ HSB hue
# ramp: Hue = deformation, Saturation = mask, Brightness = white, cf. AmpTif_map.sh) and not some
# blue-white-red table of our own. The bar sits at x = [Margin ; Margin+LegendWidth] and
# y = [FrameTop ; FrameBott] of the legend, all four read from TS_parameters.txt.
# The nodata notch of NODATACOL is inserted at 0, bracketed by the ramp colour interpolated at 0
# so that no grey halo spreads around zero.
# Returns 1 if anything is missing, so that the caller can fall back on COLLOW/COLZERO/COLHIGH.
# usage: BuildCptFromLegend "${Legend}" ${LO} ${HI} ${EPS1} ${EPS2} out.cpt
BuildCptFromLegend()
	{
	local LEG="$1" ; local LO="$2" ; local HI="$3" ; local E1="$4" ; local E2="$5" ; local CPT="$6"
	local M LW FT FB YY LEGW LWMAX

	[ -e "${LEG}" ] || return 1
	M=$(GetParam Margin) ; LW=$(GetParam LegendWidth)
	FT=$(GetParam FrameTop) ; FB=$(GetParam FrameBott)
	if [ -z "${M}" ] || [ -z "${LW}" ] || [ -z "${FT}" ] || [ -z "${FB}" ] ; then return 1 ; fi
	YY=$(( (FT + FB) / 2 ))

	# CreateColorFrame.py reduces LegendWidth to WidthRaw - 2*Margin when the bar does not fit in 
	# the raster (its line 334), and TS_parameters.txt knows nothing about that. With a 500 px 
	# raster, Margin = 40 and LegendWidth = 500 the real bar is 420 px, not 500: sampling 500 px 
	# would run past the end of the ramp and pick up whatever sits there. The legend jpg is the 
	# crop of the composite, so its own width gives WidthRaw back. 
	LEGW=$(GetImgSize "${LEG}" | cut -d ' ' -f 1)
	if [ -n "${LEGW}" ]
		then
			LWMAX=$(( LEGW - 2 * M ))
			if [ ${LWMAX} -lt 1 ] ; then return 1 ; fi
			if [ ${LW} -gt ${LWMAX} ]
				then
					echo " // LegendWidth ${LW} does not fit in ${LEGW} px, clamped to ${LWMAX} as CreateColorFrame.py does" >&2
					LW=${LWMAX}
			fi
	fi

	# one row of the bar, reduced to NSTOPS averaged samples, as ASCII PPM (portable to
	# ImageMagick 6, ImageMagick 7 and GraphicsMagick, unlike txt: or %[pixel:...])
	rm -f "${CPT}"
	${IMCONVERT} "${LEG}" -crop ${LW}x1+${M}+${YY} +repage -scale ${NSTOPS}x1! -depth 8 \
		-compress none ppm:- 2>/dev/null \
		| ${PATHGNU}/gsed 's/#.*//' | tr -s ' \t\r\n' '\n' | ${PATHGNU}/grep -v '^$' \
		| ${PATHGNU}/gawk -v lo="${LO}" -v hi="${HI}" -v e1="${E1}" -v e2="${E2}" \
			-v n="${NSTOPS}" -v nd="${NODATACOL}" '
			{ t[NR] = $1 }
			END {
				# ASCII PPM: t[1]="P3", t[2]=width, t[3]=height, t[4]=maxval, then the triplets
				if (NR < 4 + 3*n) exit 1
				for (i = 0; i < n; i++) {
					V[i] = lo + (hi - lo) * i / (n - 1)
					R[i] = t[5 + 3*i] ; G[i] = t[6 + 3*i] ; B[i] = t[7 + 3*i]
				}
				# ramp colour at 0, to bracket the nodata notch
				r0 = R[0] ; g0 = G[0] ; b0 = B[0]
				for (i = 0; i < n - 1; i++)
					if (V[i] <= 0 && 0 <= V[i+1]) {
						f = (V[i+1] == V[i]) ? 0 : (0 - V[i]) / (V[i+1] - V[i])
						r0 = R[i] + f * (R[i+1] - R[i])
						g0 = G[i] + f * (G[i+1] - G[i])
						b0 = B[i] + f * (B[i+1] - B[i])
						break
					}
				done0 = 0
				for (i = 0; i < n; i++) {
					if (!done0 && V[i] > -e2) {
						printf "%.9f %d %d %d\n", -e2, r0, g0, b0
						printf "%.9f %s\n", -e1, nd
						printf "%.9f %s\n",  e1, nd
						printf "%.9f %d %d %d\n",  e2, r0, g0, b0
						done0 = 1
					}
					if (V[i] < -e2 || V[i] > e2)
						printf "%.9f %d %d %d\n", V[i], R[i], G[i], B[i]
				}
				if (!done0) {
					printf "%.9f %d %d %d\n", -e2, r0, g0, b0
					printf "%.9f %s\n", -e1, nd
					printf "%.9f %s\n",  e1, nd
					printf "%.9f %d %d %d\n",  e2, r0, g0, b0
				}
			}' > "${CPT}"
	if [ ! -s "${CPT}" ] ; then rm -f "${CPT}" ; return 1 ; fi
	return 0
	}

# Build one thumbnail from the msbas GeoTIFF: crop the window, colour it with a scale 
# computed on that window only, mask the nodata, resize and optionally annotate the limits. 
# Returns 1 when anything is missing, so that the caller can fall back on the jpg crop. 
# usage: CropFromTif file.tif ${posX} ${posY} ${L} ${Tx} out.jpg
CropFromTif()
	{
	local TIF="$1" ; local PX="$2" ; local PY="$3" ; local LL="$4" ; local TXX="$5" ; local OUT="$6"
	local SIZE WIN W H SCALE LO HI

	command -v gdal_translate >/dev/null 2>&1 || return 1
	command -v gdaldem        >/dev/null 2>&1 || return 1

	SIZE=$(GetTifSize "${TIF}")
	W=$(echo ${SIZE} | cut -d ' ' -f 1)
	H=$(echo ${SIZE} | cut -d ' ' -f 2)
	if [ -z "${W}" ] || [ -z "${H}" ] ; then return 1 ; fi

	WIN=$(ClampWin ${W} ${H} ${PX} ${PY} ${LL})
	PX=$(echo ${WIN} | cut -d ' ' -f 1)
	PY=$(echo ${WIN} | cut -d ' ' -f 2)
	LL=$(echo ${WIN} | cut -d ' ' -f 3)

	SCALE=$(GetCropScale "${TIF}" ${PX} ${PY} ${LL} "${SYMSCALE}") || return 1
	if [ -z "${SCALE}" ] ; then return 1 ; fi
	LO=$(echo ${SCALE} | cut -d ' ' -f 1)
	HI=$(echo ${SCALE} | cut -d ' ' -f 2)
	SCALESRC="the window ${LL}x${LL}+${PX}+${PY} only"
	HI0=$(${PATHGNU}/gawk -v a="${LO}" -v b="${HI}" 'BEGIN {
			m = (a < 0 ? -a : a) ; n = (b < 0 ? -b : b) ; printf "%.9g", (n > m ? n : m) }')

	# SCALEFROM=LEGEND: take the very limits the colour bar was built with, so that the figures 
	# printed on the bar apply to the thumbnail as well. 
	if [ "${SCALEFROM}" = "LEGEND" ]
		then
			SCALEFILE="${LEGENDFORCPT%.*}_scale.txt"
			if [ -s "${SCALEFILE}" ]
				then
					LO=$(${PATHGNU}/gawk '{print $1; exit}' "${SCALEFILE}")
					HI=$(${PATHGNU}/gawk '{print $2; exit}' "${SCALEFILE}")
					# An AmpTif_map.sh older than V1.4 wrote these in cm/yr while the raster is in 
					# m/yr. Detect the factor 100 by comparing with the window we just measured 
					# instead of trusting the file blindly. 
					FIX=$(${PATHGNU}/gawk -v a="${LO}" -v b="${HI}" -v w="${HI0}" 'BEGIN {
							m = (a < 0 ? -a : a) ; n = (b < 0 ? -b : b)
							if (n > m) m = n
							if (w <= 0) { print "1" ; exit }
							print (m > 20 * w) ? "100" : "1"
						}')
					if [ "${FIX}" = "100" ]
						then
							echo " // WARNING: ${SCALEFILE} looks like cm/yr, converting to raster units"
							LO=$(${PATHGNU}/gawk -v v="${LO}" 'BEGIN {printf "%.9g", v/100}')
							HI=$(${PATHGNU}/gawk -v v="${HI}" 'BEGIN {printf "%.9g", v/100}')
					fi
					SCALESRC="$(basename "${SCALEFILE}"), i.e. the same as the colour bar"
					# with the built-in diverging table 0 must sit at COLZERO, so symmetrise
					if [ "${SYMSCALE}" = "YES" ]
						then
							SCALE=$(${PATHGNU}/gawk -v a="${LO}" -v b="${HI}" 'BEGIN {
									m = (a < 0 ? -a : a) ; n = (b < 0 ? -b : b)
									if (n > m) m = n
									m = int(m*100 + 0.999999)/100
									if (m <= 0) m = 0.01
									printf "%.2f %.2f", -m, m }')
							LO=$(echo ${SCALE} | cut -d ' ' -f 1)
							HI=$(echo ${SCALE} | cut -d ' ' -f 2)
							SCALESRC="${SCALESRC}, symmetrised for the diverging table"
					fi
				else
					echo " // WARNING: ${SCALEFILE} not found (AmpTif_map.sh older than V1.4 ?)"
					echo " //          --> falling back on the window limits"
			fi
	fi
	if [ -z "${LO}" ] || [ -z "${HI}" ] ; then return 1 ; fi
	echo " // Colour scale from ${SCALESRC}: ${LO} to ${HI}"
	USEDLO="${LO}" ; USEDHI="${HI}"		# published for BuildColourBar

	# Colour table. The nodata (0) must NOT get the colour of the centre of the scale, otherwise 
	# the voids look like a valid 0 m/yr, which is the whole point of this rewrite. 
	# BEWARE: the "nv" entry of gdaldem is NOT usable here. Tested with GDAL 3.8: placed last it 
	# is silently ignored, placed first it is parsed as a value 0 entry and drags the whole ramp 
	# towards its colour; and adding a 4th (alpha) column with -alpha is worse, as gdaldem then 
	# interpolates the alpha exactly like R, G and B, so valid pixels come out semi transparent 
	# in proportion to |value|. 
	# Instead, 0 is given a narrow notch of NODATACOL built from plain value entries only, which 
	# is fully deterministic. The notch is 1/1000000 of the scale, far below the float32 noise of 
	# a velocity field, so in practice only the pixels that really are exactly 0 fall in it. 
	EPS1=$(${PATHGNU}/gawk -v h="${HI}" 'BEGIN {printf "%.10f", h/1000000}')
	EPS2=$(${PATHGNU}/gawk -v h="${HI}" 'BEGIN {printf "%.10f", h/500000}')

	rm -f "${TMPD}/vel.cpt"
	RAMPOK="NO"
	if [ "${RAMPSOURCE}" = "HUE" ]
		then
			if BuildCptHue "${LO}" "${HI}" "${EPS1}" "${EPS2}" "${TMPD}/vel.cpt"
				then
					RAMPOK="YES"
					echo " // Colour ramp computed from the AMSTer colour code (hue 0 = ${LO} --> hue 212 = ${HI}, HUEPAD=${HUEPAD})"
			fi
	fi
	if [ "${RAMPOK}" = "NO" ] && [ "${RAMPSOURCE}" != "TABLE" ]
		then
			if BuildCptFromLegend "${LEGENDFORCPT}" "${LO}" "${HI}" "${EPS1}" "${EPS2}" "${TMPD}/vel.cpt"
				then
					RAMPOK="YES"
					echo " // Colour ramp sampled from $(basename "${LEGENDFORCPT}") (${NSTOPS} stops)"
			fi
	fi
	if [ "${RAMPOK}" = "NO" ]
		then
			echo " // Falling back on the built-in diverging COLLOW/COLZERO/COLHIGH"
			{
			printf '%s %s\n'  "${LO}"    "${COLLOW}"
			printf -- '-%s %s\n' "${EPS2}" "${COLZERO}"
			printf -- '-%s %s\n' "${EPS1}" "${NODATACOL}"
			printf '%s %s\n'  "${EPS1}"  "${NODATACOL}"
			printf '%s %s\n'  "${EPS2}"  "${COLZERO}"
			printf '%s %s\n'  "${HI}"    "${COLHIGH}"
			} > "${TMPD}/vel.cpt"
	fi

	rm -f "${TMPD}/win.tif" "${TMPD}/col.png"
	gdal_translate -q -srcwin ${PX} ${PY} ${LL} ${LL} "${TIF}" "${TMPD}/win.tif" 2>/dev/null || return 1
	gdaldem color-relief "${TMPD}/win.tif" "${TMPD}/vel.cpt" "${TMPD}/col.png" -of PNG -q 2>/dev/null || return 1

	rm -f "${OUT}"
	${IMCONVERT} "${TMPD}/col.png" -resize ${TXX}% "${OUT}" || return 1

	# The limits now change from one pair of points to the next, so write them on the thumb. 
	# -draw is used rather than -annotate/-undercolor, which GraphicsMagick does not have. 
	DOANNOT="${ANNOTATESCALE}"
	if [ "${DOANNOT}" = "AUTO" ]
		then
			if [ "${SCALEFROM}" = "LEGEND" ] ; then DOANNOT="NO" ; else DOANNOT="YES" ; fi
	fi
	if [ "${DOANNOT}" = "YES" ] && [ -e "${OUT}" ]
		then
			local OSZ OW OH LOTXT HITXT
			OSZ=$(GetImgSize "${OUT}")
			OW=$(echo ${OSZ} | cut -d ' ' -f 1)
			OH=$(echo ${OSZ} | cut -d ' ' -f 2)
			# in cm/yr and 2 decimals, as on the colour bar, otherwise the raw limits run out of the box
			LOTXT=$(${PATHGNU}/gawk -v v="${LO}" 'BEGIN {printf "%.2f", v*100}')
			HITXT=$(${PATHGNU}/gawk -v v="${HI}" 'BEGIN {printf "%.2f", v*100}')
			if [ -n "${OH}" ]
				then
					${IMCONVERT} "${OUT}" \
						-fill white -stroke none -draw "rectangle 0,$((OH-17)) 165,${OH}" \
						-fill black -pointsize 13 ${FONT_OPT} \
						-draw "text 3,$((OH-4)) '${LOTXT} / ${HITXT} cm/yr'" "${OUT}"
			fi
	fi
	return 0
	}

# NdO Aug 04 2026: the satview block overwrites L, posX, posY, Tx, TxR, XX and all the 
# New*/X1*/Y1* cross variables with values scaled by Rate. The Legend_EW.jpg branch rebuilds 
# the UD thumbnail much later and needs the DEFORMATION MAP geometry, not the satview one. 
# That used to work only because Rate is not passed in the EW+UD workflow, so the satview 
# block was skipped; snapshot and restore makes it independent of that. 
SaveDefoGeom()
	{
	D_L=${L} ; D_posX=${posX} ; D_posY=${posY} ; D_Tx=${Tx} ; D_TxR=${TxR} ; D_XX=${XX}
	D_NewX1=${NewX1} ; D_NewX2=${NewX2} ; D_NewY1=${NewY1} ; D_NewY2=${NewY2}
	D_X11=${X11} ; D_X12=${X12} ; D_X21=${X21} ; D_X22=${X22}
	D_Y11=${Y11} ; D_Y12=${Y12} ; D_Y21=${Y21} ; D_Y22=${Y22}
	}

RestoreDefoGeom()
	{
	L=${D_L} ; posX=${D_posX} ; posY=${D_posY} ; Tx=${D_Tx} ; TxR=${D_TxR} ; XX=${D_XX}
	NewX1=${D_NewX1} ; NewX2=${D_NewX2} ; NewY1=${D_NewY1} ; NewY2=${D_NewY2}
	X11=${D_X11} ; X12=${D_X12} ; X21=${D_X21} ; X22=${D_X22}
	Y11=${D_Y11} ; Y12=${D_Y12} ; Y21=${D_Y21} ; Y22=${D_Y22}
	}

echo "----------------------------------------------"
echo "-----------Script TimeSeriesInfo starts:"
echo "----------------------------------------------"
sleep 2
echo $TimeLine
# Uniformisation of filename (PlotTS.sh vs PlotTS_all_comp.sh)
if [[ "$TimeLine" == *"timeLines_"* ]]
	then # most probably from PlotTS_all_comp.sh
		TimeLine_unifo=$(echo "${TimeLine//timeLines_/timeLine_}")  
	else # most probably from PlotTS.sh
		TimeLine_unifo=$(echo "${TimeLine//timeLine/timeLine_}") 
		#TimeLine_unifo=${TimeLine}
fi  # To cope with LOS version

echo "TimeLine_unifo = $TimeLine_unifo"
#XXYY=$(echo `expr "$TimeLine_unifo" : '.*timeLine_\([0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*\)'`)   # Look for 4 consecutive coordinates of 3 digits each separate by "_"
XXYY=$(echo ${TimeLine_unifo} | ${PATHGNU}/grep -Eo "[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*")
echo $XXYY

# NdO Aug 04 2026: tif or ENVI products ? The caller may export EXTIMG; if it did not, guess 
# it from what is on disk. Everything below falls back on the historical jpg crop when the 
# GeoTIFF is not found, so a wrong guess is not fatal. 
RATETIF=$(FindRateTif "${AmpliCohDefo}")
# Name of the colour bar matching this AMPLI_COH jpg. It is rebuilt further down as ${Legend} for
# the overlay; we need it earlier here to sample its ramp for the thumbnails.
LEGENDFORCPT=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE/Legend}")

# Can we sample the ramp out of that bar ? If yes the ramp is the sequential hue ramp of
# CreateColorFrame.py and the limits must NOT be made symmetric; if no we fall back on the
# built-in diverging table, which does need 0 at its centre.
RAMPFROMLEGEND="NO"
if [ -e "${LEGENDFORCPT}" ] && [ -n "$(GetParam Margin)" ] && [ -n "$(GetParam LegendWidth)" ] \
	&& [ -n "$(GetParam FrameTop)" ] && [ -n "$(GetParam FrameBott)" ]
	then RAMPFROMLEGEND="YES"
	else RAMPFROMLEGEND="NO"
fi
# Only the built-in diverging table needs 0 at the centre of the scale. Both the computed hue ramp
# and the sampled bar are sequential ramps in which 0 is an ordinary value.
case "${RAMPSOURCE}" in
	HUE)	SYMSCALE="NO" ;;
	LEGEND)	if [ "${RAMPFROMLEGEND}" = "YES" ] ; then SYMSCALE="NO" ; else SYMSCALE="YES" ; fi ;;
	*)		SYMSCALE="YES" ;;
esac

if [ -z "${EXTIMG}" ]
	then
		if [ -n "${RATETIF}" ] ; then EXTIMG="tif" ; else EXTIMG="envi" ; fi
fi
echo " EXTIMG = ${EXTIMG}"
if [ -n "${RATETIF}" ]
	then echo " Rate GeoTIFF = ${RATETIF}"
	else echo " No MSBAS_LINEAR_RATE_<COMP>.tif found --> thumbnails cropped from ${AmpliCohDefo}"
fi

##########################################################
###        Create crop on Speed deformation map        ###
##########################################################

for i in `seq 1 4`
do
array[$i]=$(echo $XXYY | cut -d '_' -f $i)		#Extract each coordinate in an array
done

X1=$((${array[1]} - ${Crop_X}))	# Origin image is cropped at 1000 pixels from left and top
Y1=$((${array[2]} - ${Crop_Y}))
X2=$((${array[3]} - ${Crop_X}))
Y2=$((${array[4]} - ${Crop_Y}))
echo "array = ${array[*]}"
echo "$X1 $X2 $Y1 $Y2"

#Define the size of the crop LxH + posX + posY (posX and posY are the distance from the top left of the original image)

L=$((($X2-$X1)*2))	# Define the lengt of the crop
L=${L#-}			# Keep absolute value

H=$((($Y2-$Y1)*2))	# Define the lengt of the crop
H=${H#-}			# Keep absolute value

if [ $H -gt $L ]; then L=$H ; fi	#To have a standart square for each combination of points a and b
									# We will continue only with L value (size of the square side)
#Force a minimum size for this Square to avoid extra zoom for points very close to each other
XTresh=$((${CrossTresh}/2))

	if [ $L -lt ${XTresh} ] 
		then 
		echo " Crop is limited to a square of ${XTresh}"
		L=${XTresh}
		XX=${CrossSmall}
		else
		XX=${CrossBig}
		fi

	posX=$(((($X1+$X2)/2)-($L/2)))	# Define  X position from top left
	if [ $posX -le 0 ]
		then 
			posX=0
	fi
	posY=$(((($Y1+$Y2)/2)-($L/2)))	# Define  Y position from top left
	if [ $posY -le 0 ]
		then 
			posY=0
	fi
	
# Crop the image to the calculate value
echo " L = $L ++ H= $H  ++ posX = $posX ++ posY = $posY "

# Define the resize rate depending on the size of the square. We want a constant square of 350 pixels.
Tx=$(echo "scale=2;(36000/$L)" |bc)
echo " Taux = $Tx"
TxR=$(echo "scale=3;($Tx/100)" | bc)
#TxR=`echo "scale=2;(Tx/100)" | bc`
echo " Taux en % = "$TxR


crop=$(echo "${TimeLine//.eps/_crop.jpg}")  #Define the name of the crop file

# NdO Aug 04 2026: keep the crop inside the image, convert refuses an out of bounds geometry
SIZEACD=$(GetImgSize "${AmpliCohDefo}")
WINACD=$(ClampWin $(echo ${SIZEACD} | cut -d ' ' -f 1) $(echo ${SIZEACD} | cut -d ' ' -f 2) ${posX} ${posY} ${L})
posX=$(echo ${WINACD} | cut -d ' ' -f 1)
posY=$(echo ${WINACD} | cut -d ' ' -f 2)
L=$(echo ${WINACD} | cut -d ' ' -f 3)
echo " Clamped to the image: L = $L ++ posX = $posX ++ posY = $posY "

# NdO Aug 04 2026: rebuild the thumbnail from the GeoTIFF when we can, so that the colour 
# scale is computed on the crop window only and the nodata is masked instead of being painted 
# white. Fall back on the historical crop of the AMPLI_COH jpg otherwise. 
if [ "${EXTIMG}" = "tif" ] && [ -n "${RATETIF}" ] && [ -e "${RATETIF}" ]
	then
		echo " // Thumbnail rebuilt from ${RATETIF}"
		if ! CropFromTif "${RATETIF}" ${posX} ${posY} ${L} ${Tx} "${crop}"
			then
				echo " // --> failed, fall back on cropping ${AmpliCohDefo}"
				${IMCONVERT} $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop
				${IMCONVERT} $crop -resize $Tx% $crop
		fi
	else
		${IMCONVERT} $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
		${IMCONVERT} $crop -resize $Tx% $crop						#Resize the image to fit on the Time Series
fi


# Define a new reference for the cross mark related to square (X-posX) the depending of the resize (X* resize ratio) (Size in pixels must be multiplicate by ratio)
NewX1=$(echo "scale=2;(($X1-$posX)*$TxR)" |bc)
NewX2=$(echo "scale=2;(($X2-$posX)*$TxR)" |bc)
NewY1=$(echo "scale=2;(($Y1-$posY)*$TxR)" |bc)
NewY2=$(echo "scale=2;(($Y2-$posY)*$TxR)" |bc)


NewX1=${NewX1%.*}
NewX2=${NewX2%.*}
NewY1=${NewY1%.*}
NewY2=${NewY2%.*}

 	X11=$((NewX1-XX))
	X12=$((NewX1+XX))
	X21=$((NewX2-XX))
	X22=$((NewX2+XX))
	Y11=$((NewY1-XX))
	Y12=$((NewY1+XX))
	Y21=$((NewY2-XX))
	Y22=$((NewY2+XX))

echo " Cross = ${XX}"	
echo " NeuX1 = $NewX1"
echo " NeuX2 = $NewX2"
echo " NeuY1 = $NewY1"
echo " NeuY2 = $NewY2"

echo " _X1 - _X2 - _Y1 - _Y2 -_X11 - _X12 - _X21 - _X22 -_Y11 - _Y12 - _Y21 - _Y22"
echo " $X1 - $X2 - $Y1 - $Y2 - $X11 - $X12 - $X21 - $X22 - $Y11 - $Y12 - $Y21 - $Y22"

#crop=$(echo "${TimeLine//.jpg/_crop.jpg}")  #Define the name of the crop file
#touch $crop
echo "*************$crop**************"
${IMCONVERT} $crop -draw "fill black stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
${IMCONVERT} $crop -draw "fill White stroke White stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
${IMCONVERT} $crop -draw "fill White stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
${IMCONVERT} $crop -draw "fill White stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop


##########################################################
###            Create crop on Satview files            ###
##########################################################

SaveDefoGeom		# NdO Aug 04 2026: see above, the block below overwrites all of it

# NdO Aug 04 2026: Rate can now be deduced from the actual size of satview.jpg (see below), so 
# a missing 3rd argument no longer has to skip the crop. The braces make the intent explicit: 
# satview.jpg is always required, Rate OR a tif workflow is enough for the rest. 
#if [[ ${AmpliCohDefo} == *"_LOS"* ]] && [ -e ${SatView} ];
 if [ -e "${SatView}" ] && { [ "${Rate}" != "" ] || [ "${EXTIMG}" = "tif" ] ; } ;
    then
            echo "Create crop on Satellite view as we are on Line Of Sight"

            # NdO Aug 04 2026: RateResoSatView is hard coded in TS_parameters.txt and gets stale 
            # as soon as satview.jpg is regenerated at another resolution. Compare it with the 
            # rate deduced from the actual sizes and trust the deduced one when they disagree. 
            SIZESAT=$(GetImgSize "${SatView}")
            SatW=$(echo ${SIZESAT} | cut -d ' ' -f 1)
            SatH=$(echo ${SIZESAT} | cut -d ' ' -f 2)
            echo " satview.jpg is ${SatW}x${SatH} px"

            if [ -n "${SatW}" ] && [ -n "${Crop_L}" ]
                then
                    RateAuto=$(echo "scale=4; ${SatW}/(${Crop_L}+1)" | bc -l)
                    if [ "${Rate}" = "" ]
                        then
                            echo " // No Rate given as 3rd argument --> deduced from the sizes: ${RateAuto}"
                            Rate=${RateAuto}
                    fi
                    Ratio=$(echo "scale=4; ${Rate}/${RateAuto}" | bc -l)
                    TooBig=$(echo "${Ratio} > 1.05" | bc -l)
                    TooSmall=$(echo "${Ratio} < 0.95" | bc -l)
                    if [ "${TooBig}" = "1" ] || [ "${TooSmall}" = "1" ]
                        then
                            echo " // WARNING: RateResoSatView = ${Rate} in TS_parameters.txt,"
                            echo " //          but satview.jpg / msbas grid gives ${RateAuto}"
                            echo " //          --> using ${RateAuto} instead"
                            Rate=${RateAuto}
                    fi
            fi

            if [ "${Rate}" = "" ]
                then
                    echo " // WARNING: neither RateResoSatView nor the image sizes give a usable rate"
                    echo " //          --> assuming 1, the satview crop will most probably be wrong"
                    Rate=1
            fi

            for i in `seq 1 4`
                do
                    array[$i]=$(echo $XXYY | cut -d '_' -f $i)		#Extract each coordinate in an array
                    array[$i]=$(echo "scale=2; ${array[$i]}*${Rate}" | bc -l)
                    array[$i]=${array[$i]%.*}
                done


            Crop_X=0    # We work on the entire image and not the crop (satview.jpg)
            Crop_Y=0    # We work on the entire image and not the crop (satview.jpg)


            X1=$((${array[1]} - ${Crop_X}))	# Origin image is cropped at 1000 pixels from left and top
            Y1=$((${array[2]} - ${Crop_Y}))
            X2=$((${array[3]} - ${Crop_X}))
            Y2=$((${array[4]} - ${Crop_Y}))
            echo "array = ${array[*]}"
            echo "$X1 $X2 $Y1 $Y2"

            #Define the size of the crop LxH + posX + posY (posX and posY are the distance from the top left of the original image)

            L=$((($X2-$X1)*2))	# Define the lengt of the crop
            L=${L#-}			# Keep absolute value

            H=$((($Y2-$Y1)*2))	# Define the lengt of the crop
            H=${H#-}			# Keep absolute value

            if [ $H -gt $L ]; then L=$H ; fi	#To have a standart square for each combination of points a and b
                                                # We will continue only with L value (size of the square side)
            #Force a minimum size for this Square to avoid extra zoom for points very close to each other
            XTresh=$((${CrossTresh}/2))
            XTresh=$(echo "scale=2; ${XTresh}*${Rate}" | bc -l)
            XTresh=${XTresh%.*}

            if [ $L -lt ${XTresh} ] 
                then 
                echo " Crop is limited to a square of ${XTresh} for satview"
                L=${XTresh}
                XX=${CrossSmall}
                else
                XX=${CrossBig}
                fi

            posX=$(((($X1+$X2)/2)-($L/2)))	# Define  X position from top left
            if [ $posX -le 0 ]
                then 
                    posX=0
            fi
            posY=$(((($Y1+$Y2)/2)-($L/2)))	# Define  Y position from top left
            if [ $posY -le 0 ]
                then 
                    posY=0
            fi

            # NdO Aug 04 2026: keep the square inside satview.jpg. An out of bounds geometry made 
            # convert fail with "geometry does not contain image", so crop2 was never created and 
            # the 4 -draw calls below failed as well. 
            WINSAT=$(ClampWin "${SatW}" "${SatH}" ${posX} ${posY} ${L})
            posX=$(echo ${WINSAT} | cut -d ' ' -f 1)
            posY=$(echo ${WINSAT} | cut -d ' ' -f 2)
            L=$(echo ${WINSAT} | cut -d ' ' -f 3)

            # Crop the image to the calculate value
            echo " L = $L ++ H= $H  ++ posX = $posX ++ posY = $posY "

            # Define the resize rate depending on the size of the square. We want a constant square of 350 pixels.
            Tx=$(echo "scale=2;(36000/$L)" |bc)
            echo " Taux = $Tx"
            TxR=$(echo "scale=3;($Tx/100)" | bc)
            #TxR=`echo "scale=2;(Tx/100)" | bc`
            echo " Taux en % = "$TxR


            crop2=$(echo "${TimeLine//.eps/_crop2.jpg}")  #Define the name of the crop file
            ${IMCONVERT} $SatView -crop ${L}x${L}+${posX}+${posY} $crop2	#Crop the image
            ${IMCONVERT} $crop2 -resize $Tx% $crop2						#Resize the image to fit on the Time Series


            # Define a new reference for the cross mark related to square (X-posX) the depending of the resize (X* resize ratio) (Size in pixels must be multiplicate by ratio)
            NewX1=$(echo "scale=2;(($X1-$posX)*$TxR)" |bc)
            NewX2=$(echo "scale=2;(($X2-$posX)*$TxR)" |bc)
            NewY1=$(echo "scale=2;(($Y1-$posY)*$TxR)" |bc)
            NewY2=$(echo "scale=2;(($Y2-$posY)*$TxR)" |bc)


            NewX1=${NewX1%.*}
            NewX2=${NewX2%.*}
            NewY1=${NewY1%.*}
            NewY2=${NewY2%.*}

                X11=$((NewX1-XX))
                X12=$((NewX1+XX))
                X21=$((NewX2-XX))
                X22=$((NewX2+XX))
                Y11=$((NewY1-XX))
                Y12=$((NewY1+XX))
                Y21=$((NewY2-XX))
                Y22=$((NewY2+XX))

            echo " Cross = ${XX}"	
            echo " NeuX1 = $NewX1"
            echo " NeuX2 = $NewX2"
            echo " NeuY1 = $NewY1"
            echo " NeuY2 = $NewY2"

            echo " _X1 - _X2 - _Y1 - _Y2 -_X11 - _X12 - _X21 - _X22 -_Y11 - _Y12 - _Y21 - _Y22"
            echo " $X1 - $X2 - $Y1 - $Y2 - $X11 - $X12 - $X21 - $X22 - $Y11 - $Y12 - $Y21 - $Y22"

            #crop=$(echo "${TimeLine//.jpg/_crop.jpg}")  #Define the name of the crop file
            #touch $crop2
            echo "*************$crop2**************"
            ${IMCONVERT} $crop2 -draw "fill black stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop2   #Build cross on a duplicate images $crop2
            ${IMCONVERT} $crop2 -draw "fill White stroke White stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop2	#Build cross on a duplicate images $crop2
            ${IMCONVERT} $crop2 -draw "fill White stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop2	#Build cross on a duplicate images $crop2
            ${IMCONVERT} $crop2 -draw "fill White stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop2	#Build cross on a duplicate images
		else

			echo "Do not create a crop on satview.jpg because:"
			if [ ! -e "${SatView}" ]
				then 
					echo "     --> ${SatView} does not exist"
					echo "         (is satview.jpg present in the Region _CombiFiles dir ?)"
			fi
			if [ "${Rate}" = "" ] && [ "${EXTIMG}" != "tif" ]
				then 
					echo "     --> no Rate was given as 3rd argument and this is not a tif workflow"
					echo "         (is RateResoSatView present in _CombiFiles/TS_parameters.txt ?)"
			fi
    fi


####################################################################################################################
###                   Create final jpeg file including time series, crops and legend                             ###
####################################################################################################################

echo "--------- CREATE FINAL COMBINE PICTURE -------------"

combi=$(echo "${TimeLine//.eps/_Combi.jpg}")		# Add extension _Combi to the name of final file
echo $combi

touch $combi
${IMCONVERT} -size 3300x2100 xc:white -type TrueColor $combi
${IMCONVERT} -density 300 -rotate 90 ${TimeLine} ${TimeLine}.jpg

#convert $combi ${TimeLine}.jpg -gravity northwest -geometry +330+0 -composite $combi
do_composite "$combi" "${TimeLine}.jpg" northwest +330+0
# tag for web site
#convert $combi -fill grey -pointsize 60 -font ${font} -draw "text 670,250 'WebSite: http://terra3.ecgs.lu/${WebPage}" $combi
TimeSeriesInfoHPWebTag

#convert $combi $crop -gravity northwest -geometry +30+150 -composite $combi
do_composite "$combi" "$crop" northwest +30+150

# Add logo to timestamp 
logo=${WorkDir}/AMSTer.png
AddOverlay "$combi" ${logo} 125x125 southwest +525+7
#convert $combi Temp -gravity southwest -geometry +525+7 -composite $combi

# Add Legend to the Time serie image
Legend=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE/Legend}")	# Create the name of the real file "legend"
					
# NdO Aug 04 2026: REDRAWBAR=YES rebuilds the bar from the same ramp as the thumbnails, because the
# Fiji step can produce a uniformly red bar (see the note on WriteTiff in the header). ${Legend}
# itself is left untouched: the branches below identify the component from its NAME.
LegendToDraw="${Legend}"
if [ "${REDRAWBAR}" = "YES" ] && [ -n "${USEDLO}" ] && [ -n "${USEDHI}" ]
	then
		LEGWID=$(GetImgSize "${Legend}" | cut -d ' ' -f 1)
		if BuildColourBar "${USEDLO}" "${USEDHI}" "${LEGWID}" "${TMPD}/bar.jpg"
			then
				LegendToDraw="${TMPD}/bar.jpg"
				echo " // Colour bar redrawn from the same ramp, ${USEDLO} to ${USEDHI} (m/yr), labelled in cm/yr"
			else
				echo " // WARNING: could not redraw the colour bar, using ${Legend} as is"
		fi
fi

# Add to the combi file the legend after having rescaled the legend to the size of the thumb (350 px = )
AddOverlay "$combi" ${LegendToDraw} 400x60 northwest +10+520
#convert $combi Temp -gravity northwest -geometry +10+520 -composite $combi

if [ $(basename ${Legend}) = 'Legend_EW.jpg' ]	# 'EW" because the last loop in previous script 'TS_AddLegend_EW_UD.sh'
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'East-West deformation'" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'East-West deformation'" $combi
	
	REMARKDIR=$(echo ${TimeLine} | sed -E 's/^.*timeLines?_([0-9]{2,4}_){4}//' | sed -E 's/.eps//')	# extract REMARKDIR string from eps filename
	echo "!!!!!!!!!! pwd =  $(pwd)"
	echo "TimeLine =  ${TimeLine} "
	echo "REMARKDIR = ${REMARKDIR}"
	
	SetDisplArtwork "zz_NS_${REMARKDIR}"
	AddOverlay "$combi" ${DisplPos} 400x400 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	AddOverlay "$combi" ${DisplNeg} 400x400 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	# NdO Aug 04 2026: the +30+1530 slot of this all components figure now holds the Google Earth 
	# crop, as it already did in every single component figure, instead of the UD velocity map. 
	# The UD component stays visible in the plot itself. The UD colour bar that used to sit at 
	# +10+1900 goes with it: it described that map and there is no map left to describe (the EW bar 
	# at +10+520 still documents the map at +30+150). 
	# If there is no satview crop at all (satview.jpg missing, or ENVI run with no rate given), 
	# fall back on the historical UD map so that the slot is never left empty. 
	if [ -e "${crop2}" ]
		then
			${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,1510 'Satellite view' decorate UnderLine" $combi
			do_composite "$combi" "$crop2" northwest +30+1530
		else
			echo " // no satview crop available --> keep the historical UD map at +30+1530"

			AmpliCohDefo=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE_EW/AMPLI_COH_MSBAS_LINEAR_RATE_UD}")
			Legend=$(echo "${Legend//_EW.jpg/_UD.jpg}")

			# this second thumbnail is the UD map on the DEFORMATION MAP geometry, which the 
			# satview block may have overwritten --> restore it first. 
			RestoreDefoGeom

			RATETIFUD=$(FindRateTif "${AmpliCohDefo}")
			if [ "${EXTIMG}" = "tif" ] && [ -n "${RATETIFUD}" ] && [ -e "${RATETIFUD}" ]
				then
					echo " // UD thumbnail rebuilt from ${RATETIFUD}"
					if ! CropFromTif "${RATETIFUD}" ${posX} ${posY} ${L} ${Tx} "${crop}"
						then
							echo " // --> failed, fall back on cropping ${AmpliCohDefo}"
							${IMCONVERT} $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop
							${IMCONVERT} $crop -resize $Tx% $crop
					fi
				else
					${IMCONVERT} $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
					${IMCONVERT} $crop -resize $Tx% $crop
			fi
			${IMCONVERT} $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
			${IMCONVERT} $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
			${IMCONVERT} $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
			${IMCONVERT} $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop

			${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,1510 'Up-down deformation' decorate UnderLine" $combi
			do_composite "$combi" "$crop" northwest +30+1530

			LegendToDraw="${Legend}"
			if [ "${REDRAWBAR}" = "YES" ] && [ -n "${USEDLO}" ] && [ -n "${USEDHI}" ]
				then
					LEGWID=$(GetImgSize "${Legend}" | cut -d ' ' -f 1)
					if BuildColourBar "${USEDLO}" "${USEDHI}" "${LEGWID}" "${TMPD}/bar_ud.jpg"
						then LegendToDraw="${TMPD}/bar_ud.jpg"
					fi
			fi
			AddOverlay "$combi" ${LegendToDraw} 400x60 northwest +10+1900
	fi
	
# NdO 20 Jan 2021
#elif [[ $(basename ${Legend}) = "Legend_LOS_"*"Asc.jpg" ]] || [[ $(basename ${Legend}) = "Legend_LOS_"*"asc.jpg" ]] 
elif [[ $(basename ${Legend}) = "Legend_"*"Asc"*".jpg" ]] || [[ $(basename ${Legend}) = "Legend_"*"asc"*".jpg" ]] 

then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'LOS-Ascending deformation' decorate UnderLine" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'LOS-Ascending deformation' decorate UnderLine" $combi

	Legend2=${WorkDir}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	Legend2=${WorkDir}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	if [ -e ${SatView} ];
	    then
            #convert $combi $crop2 -gravity northwest -geometry +30+1530 -composite $combi
            do_composite "$combi" "$crop2" northwest +30+1530
        fi

# NdO 20 Jan 2021
#elif [[ $(basename ${Legend}) = "Legend_LOS_"*"Desc.jpg" ]] || [[ $(basename ${Legend}) = "Legend_LOS_"*"desc.jpg" ]]
elif [[ $(basename ${Legend}) = "Legend_"*"Desc"*".jpg" ]] || [[ $(basename ${Legend}) = "Legend_"*"desc"*".jpg" ]]
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'LOS-Descending deformation' decorate UnderLine" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'LOS-Descending deformation' decorate UnderLine" $combi

	Legend2=${WorkDir}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	Legend2=${WorkDir}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	if [ -e ${SatView} ];
	    then
            #convert $combi $crop2 -gravity northwest -geometry +30+1530 -composite $combi
            do_composite "$combi" "$crop2" northwest +30+1530
        else
            echo "!!! ${SatView}  --> not available"
        fi

# NdO 20 Jan 2021 vv
elif [[ $(basename ${Legend}) = "Legend_GEOM_UD.jpg" ]] 
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'Up-Down deformation'" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'Up-Down deformation'" $combi
	
		
	SetDisplArtwork "${NSCompanionDir}"
	AddOverlay "$combi" ${DisplPos} 400x400 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	AddOverlay "$combi" ${DisplNeg} 400x400 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	# NdO Aug 04 2026: the EW --> UD substitution and the rebuilding of ${crop} that used to 
	# sit here came from the two-components workflow of TS_AddLegend_EW_UD.sh. In a single 
	# component figure the name contains _GEOM_ so the substitutions match nothing, and 
	# ${crop} is never composited again afterwards --> 6 useless convert calls, removed. 
	if [ -e "${crop2}" ]
		then do_composite "$combi" "$crop2" northwest +30+1530
		else echo "!!! no satview crop available"
	fi

elif [[ $(basename ${Legend}) = "Legend_GEOM_EW.jpg" ]] 
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'East-West deformation'" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'East-West deformation'" $combi
		
	SetDisplArtwork "${NSCompanionDir}"
	AddOverlay "$combi" ${DisplPos} 400x400 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	AddOverlay "$combi" ${DisplNeg} 400x400 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	# NdO Aug 04 2026: the EW --> UD substitution and the rebuilding of ${crop} that used to 
	# sit here came from the two-components workflow of TS_AddLegend_EW_UD.sh. In a single 
	# component figure the name contains _GEOM_ so the substitutions match nothing, and 
	# ${crop} is never composited again afterwards --> 6 useless convert calls, removed. 
	if [ -e "${crop2}" ]
		then do_composite "$combi" "$crop2" northwest +30+1530
		else echo "!!! no satview crop available"
	fi
# NdO 20 Jan 2021 ^^
# NdO 23 Mar 2026 vv
elif [[ $(basename ${Legend}) = "Legend_GEOM_NS.jpg" ]] 
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'East-West deformation'" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'North-South deformation'" $combi
		
	SetDisplArtwork "${NSCompanionDir}"
	AddOverlay "$combi" ${DisplPos} 400x400 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	AddOverlay "$combi" ${DisplNeg} 400x400 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	# NdO Aug 04 2026: same dead EW-->NS leftover as removed from the GEOM_UD and GEOM_EW 
	# branches: the substitutions can not match a _GEOM_ name and ${crop} is never 
	# composited again afterwards --> 6 useless convert calls, removed. 
	if [ -e "${crop2}" ]
		then do_composite "$combi" "$crop2" northwest +30+1530
		else echo "!!! no satview crop available"
	fi
elif [[ $(basename ${Legend}) = "Legend_GEOM_LineOfSight.jpg" ]] 
then
	#convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'LOS-Descending deformation' decorate UnderLine" $combi
	${IMCONVERT} $combi -pointsize 30 ${FONT_OPT} -draw "text 45,140 'LOS deformation' decorate UnderLine" $combi

	Legend2=${WorkDir}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+650
	#convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
	
	Legend2=${WorkDir}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	AddOverlay "$combi" ${Legend2} 350x350 northwest +15+1080
	#convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	if [ -e ${SatView} ];
	    then
            #convert $combi $crop2 -gravity northwest -geometry +30+1530 -composite $combi
            do_composite "$combi" "$crop2" northwest +30+1530
        else
            echo "!!! ${SatView}  --> not available"
        fi
# NdO 23 Mar 2026 ^^
else
	echo "Legend = ${Legend} --> not recognized"
fi
rm -f Temp
rm -f ${TimeLine}
rm -f ${TimeLine}.jpg
rm -f $crop
rm -f $crop2
# need a short nap in Linux to close $combi file before moving it
sleep 5
mv -f $combi ${RUNDIR}