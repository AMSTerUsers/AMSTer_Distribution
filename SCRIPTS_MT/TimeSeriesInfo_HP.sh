#!/bin/bash
#
#	Dependencies:
#	- ImageJ
#	- ghostscript (to avoid ImageJ issue)
#   - Parameters file must be present in "MSBAS/Region/_CombiFiles" to extract several parameters from it.
#   - 'satview.jpg' must be present in "MSBAS/Region/_CombiFiles" = Google earth image cropped using headers parameters of deformation file
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
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2017/12/29 - could make better... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V4.0 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Aug 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
source ${HOME}/.bashrc

source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh
	# See below: 
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
echo "Rate between pixel number on eps file and image to crop = ${Rate}"
ParamFile=${WorkDir}/TS_parameters.txt
bn=$(basename ${TimeLine})
echo "test max"
echo "cp ${TimeLine} ${WorkDir}/${bn}"
#cp ${TimeLine} ${WorkDir}/${bn}
cp ${TimeLine} ${WorkDir}
TimeLine=${WorkDir}/${bn}
SatView=${WorkDir}/satview.jpg

# Check OS
OS=`uname -a | cut -d " " -f 1 `
echo "Running on ${OS}"

case ${OS} in 
	"Linux") 
		font="FreeSans";;
	"Darwin")
		font="Helvetica";;	
	*)
		;;
esac	

echo "font = ${font}"

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
CrossTresh=$(GetParam CrossTresh)
CrossBig=$(GetParam CrossBig)
CrossSmall=$(GetParam CrossSmall)
WebPage=$(GetParam WebPage)


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
convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
convert $crop -resize $Tx% $crop						#Resize the image to fit on the Time Series


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
convert $crop -draw "fill black stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
convert $crop -draw "fill White stroke White stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
convert $crop -draw "fill White stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
convert $crop -draw "fill White stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop


##########################################################
###            Create crop on Satview files            ###
##########################################################



if [[ ${AmpliCohDefo} == *"LOS"* ]] && [ -e ${SatView} ];
    then
            echo "Create crop on Satellite view as we are on Line Of Sight"
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
    
            # Crop the image to the calculate value
            echo " L = $L ++ H= $H  ++ posX = $posX ++ posY = $posY "

            # Define the resize rate depending on the size of the square. We want a constant square of 350 pixels.
            Tx=$(echo "scale=2;(36000/$L)" |bc)
            echo " Taux = $Tx"
            TxR=$(echo "scale=3;($Tx/100)" | bc)
            #TxR=`echo "scale=2;(Tx/100)" | bc`
            echo " Taux en % = "$TxR


            crop2=$(echo "${TimeLine//.eps/_crop2.jpg}")  #Define the name of the crop file
            convert $SatView -crop ${L}x${L}+${posX}+${posY} $crop2	#Crop the image
            convert $crop2 -resize $Tx% $crop2						#Resize the image to fit on the Time Series


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
            convert $crop2 -draw "fill black stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop2   #Build cross on a duplicate images $crop2
            convert $crop2 -draw "fill White stroke White stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop2	#Build cross on a duplicate images $crop2
            convert $crop2 -draw "fill White stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop2	#Build cross on a duplicate images $crop2
            convert $crop2 -draw "fill White stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop2	#Build cross on a duplicate images
    fi


####################################################################################################################
###                   Create final jpeg file including time series, crops and legend                             ###
####################################################################################################################

echo "--------- CREATE FINAL COMBINE PICTURE -------------"

combi=$(echo "${TimeLine//.eps/_Combi.jpg}")		# Add extension _Combi to the name of final file
echo $combi

touch $combi
convert -size 3300x2100 xc:white -type TrueColor $combi
convert -density 300 -rotate 90 ${TimeLine} ${TimeLine}.jpg
convert $combi ${TimeLine}.jpg -gravity northwest -geometry +330+0 -composite $combi

# tag for web site
#convert $combi -fill grey -pointsize 60 -font ${font} -draw "text 670,250 'WebSite: http://terra3.ecgs.lu/${WebPage}" $combi
TimeSeriesInfoHPWebTag

convert $combi $crop -gravity northwest -geometry +30+150 -composite $combi



# Add Legend to the Time serie image
Legend=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE/Legend}")	# Create the name of the real file "legend"
					
# Add to the combi file the legend after having rescaled the legend to the size of the thumb (350 px = )
convert ${Legend} -resize 400x60 Temp
convert $combi Temp -gravity northwest -geometry +10+520 -composite $combi


if [ $(basename ${Legend}) = 'Legend_EW.jpg' ]
then
	convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'East-West deformation'" $combi
	
		
 	Legend2=${WorkDir}/TS_Displ_Pos.png #Image to explain the sens of displacement between cross
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	Legend2=${WorkDir}/TS_Displ_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	
	AmpliCohDefo=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE_EW/AMPLI_COH_MSBAS_LINEAR_RATE_UD}")
	Legend=$(echo "${Legend//_EW.jpg/_UD.jpg}")
	convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
	convert $crop -resize $Tx% $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop

	convert $combi -pointsize 30 -font ${font} -draw "text 45,1510 'Up-down deformation' decorate UnderLine" $combi
	convert $combi $crop -gravity northwest -geometry +30+1530 -composite $combi
	convert ${Legend} -resize 400x60 Temp
	convert $combi Temp -gravity northwest -geometry +10+1900 -composite $combi

# NdO 20 Jan 2021
#elif [[ $(basename ${Legend}) = "Legend_LOS_"*"Asc.jpg" ]] || [[ $(basename ${Legend}) = "Legend_LOS_"*"asc.jpg" ]] 
elif [[ $(basename ${Legend}) = "Legend_"*"Asc"*".jpg" ]] || [[ $(basename ${Legend}) = "Legend_"*"asc"*".jpg" ]] 

then
	convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'LOS-Ascending deformation' decorate UnderLine" $combi

	Legend2=${WorkDir}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 350x350 Temp
	convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	Legend2=${WorkDir}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 350x350 Temp
	convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	if [ -e ${SatView} ];
	    then
            convert $combi $crop2 -gravity northwest -geometry +30+1530 -composite $combi
        fi

# NdO 20 Jan 2021
#elif [[ $(basename ${Legend}) = "Legend_LOS_"*"Desc.jpg" ]] || [[ $(basename ${Legend}) = "Legend_LOS_"*"desc.jpg" ]]
elif [[ $(basename ${Legend}) = "Legend_"*"Desc"*".jpg" ]] || [[ $(basename ${Legend}) = "Legend_"*"desc"*".jpg" ]]
then
	convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'LOS-Descending deformation' decorate UnderLine" $combi

	Legend2=${WorkDir}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 350x350 Temp
	convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	Legend2=${WorkDir}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 350x350 Temp
	convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	if [ -e ${SatView} ];
	    then
            convert $combi $crop2 -gravity northwest -geometry +30+1530 -composite $combi
        else
            echo "!!! ${SatView}  --> not available"
        fi

# NdO 20 Jan 2021 vv
elif [[ $(basename ${Legend}) = "Legend_GEOM_UD.jpg" ]] 
then
	convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'Up-Down deformation'" $combi
	
		
 	Legend2=${WorkDir}/TS_Displ_Pos_UD.png #Image to explain the sens of displacement between cross
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	Legend2=${WorkDir}/TS_Displ_Neg_UD.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	
	AmpliCohDefo=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE_EW/AMPLI_COH_MSBAS_LINEAR_RATE_UD}")
	Legend=$(echo "${Legend//_EW.jpg/_UD.jpg}")
	convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
	convert $crop -resize $Tx% $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop


elif [[ $(basename ${Legend}) = "Legend_GEOM_EW.jpg" ]] 
then
	convert $combi -pointsize 30 -font ${font} -draw "text 45,140 'East-West deformation'" $combi
	
		
 	Legend2=${WorkDir}/TS_Displ_Pos_EW.png #Image to explain the sens of displacement between cross
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+650 -composite $combi
		
	
	Legend2=${WorkDir}/TS_Displ_Neg_EW.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 400x400 Temp
	convert $combi Temp -gravity northwest -geometry +15+1080 -composite $combi
	
	
	AmpliCohDefo=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE_EW/AMPLI_COH_MSBAS_LINEAR_RATE_UD}")
	Legend=$(echo "${Legend//_EW.jpg/_UD.jpg}")
	convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
	convert $crop -resize $Tx% $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop
# NdO 20 Jan 2021 ^^
else
	echo "Legend = ${Legend} --> not recognized"
fi
rm Temp
rm -f ${TimeLine}
rm -f ${TimeLine}.jpg
rm -f $crop
rm -f $crop2
# need a short nap in Linux to close $combi file before moving it
sleep 5
mv -f $combi ${RUNDIR}

