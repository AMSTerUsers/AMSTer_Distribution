#!/bin/bash
# This script contains a series of hard coded lines required for several scripts of the
# AMSTer toolbox. 
#
# They are written here as functions to be called from the scripts using the following line:
# source ${PATH_SCRIPTS}/SCRIPTS_MT/__HardCodedLines.sh   
#
# Note that several other scripts or templates contain hard coded lines to define plot style
# or define the name of the institute where computations are performed , e.g.:
#  - PlotTS.sh (NEEDS HARD CODED LINES WHEN USED FROM QGIS PYTHON CONSOLE !)
#  - all the templates .gnu (e.g. plotTS_template.gnu) 
#
# Other files contains specific parameters for specific targets, e.g.:
#  - all the cron scripts 
#
#
# New in Distro V 2.0 20230830:	- Rename SCRIPTS_OK directory as SCRIPTS_MT 
#								- Replace CIS by MT in names 
#								- Renamed FUNCTIONS_FOR_MT.sh
# New in Distro V 3.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
# New in Distro V 3.1 20240116:	- allows MSBAS 3D. Note that the inversion of the this third NS component only makes sense if/where the 
# 								displacement is expected to occur along the steepest slope of the topography (e.g. in 
# 								case of land slide). That is why it is sometimes referred as 3D SPF (Surface Parallel Flow)
# New in Distro V 3.2 20240308:	- Split Session in AS sub dirs instead of MT
# New in Distro V 3.3 20241220:	- add disk 3611 at ECGS
#								- update address to terra4 
# New in Distro V 3.4 20250321:	- allows HOMEDATA for Mac as well 
# New in Distro V 3.5 20250707:	- 3610 was wrongly named as 3611 in line 73; one 3611 not defined in RenameVolNameToVariable
#								- add ENVISAT Nepal
#
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2023/06/22 - could make better... when time.
# -----------------------------------------------------------------------------------------

# List of scripts sourcing bashrc: 
##################################
#	- ALL2GIF.sh
#	- AllProd2GIF.sh
#	- AmpAmpAmp.sh
#	- AmpAmpCoh.sh
#	- AmpDefo_map.sh
#	- build_header_msbas_criteria_From_nvi_name_WithoutAcqTime.sh
#	- build_header_msbas_criteria.sh
#	- Check_Installation.sh
#	- MultiLaunch_Ampli_Coh.sh
#	- MultiLaunch_ForMask.sh
#	- MultiLaunch.sh
#	- Read_All_Img_Rebuild.sh
#	- Read_All_Img.sh

# See in there if needed

	
#__SplitCoreg.sh and __SplitSession.sh
######################################
	# definition of path to disks where multiple sessions of Splitxxx can be run.
	function SplitDiskDef()
		{
		OS=`uname -a | cut -d " " -f 1 `
		echo "Running on ${OS}"
		echo

		# Common disks
		PATH1650=${PATH_1650} 
		PATH3600=${PATH_3600}
		PATH3601=${PATH_3601}
		PATH3602=${PATH_3602}

		# More disks at ECGS
		PATH1660=${PATH_1660} 
		PATH3610=${PATH_3610}				
		PATH3611=${PATH_3611}
				
		PATHSYNODATA=${PATH_SynoData}
		
		case ${OS} in 
			"Linux") 
				PATHSYNOCONGO="/mnt/syno_congo"
				PATHSYNOSAR="/mnt/syno_sar" 
				PATHHOMEDATA=${PATH_HOMEDATA}
				;;
			"Darwin")
				PATHSYNOCONGO="/Volumes/DataRDC"
				PATHSYNOSAR="/Volumes/DataSAR" 
				PATHHOMEDATA=${PATH_HOMEDATA}
				;;
		esac			
		}
	
	# list of disks names and number attribution to disks where sessions of Splitxxx will be run. 
	# To be displayed before opeartor select the disks by their number.
	# Must be consistent with SplitDiskDef

	function SplitDiskList()
		{
		echo "  1) = hp-1600"
		echo "  2) = hp-D3600"
		echo "  3) = hp-D3601"
		echo "  4) = hp-D3602"
		echo "  5) = Doris_10T"
		echo "  6) = SAR_20T_N1"
		echo "  7) = syno_data"
		echo "  8) = syno_sar"
		echo "  9) = syno_congo (do not use !)"
		echo "  10) = HOMEDATA (Linux)"
		echo "  11) = HOME"
		echo "  12) = hp-1660"
		echo "  13) = hp-D3610"
		echo "  14) = hp-D3611"		
		}
	
	# Selection of disk where sessions of Splitxxx will be run. 
	# Must be consistent with SplitDiskList and SplitDiskDef
	function SplitDiskSelection()
		{
		case $DISK in
			"1") 
				DISKPATH=/${PATH1650}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"2") 
				DISKPATH=/${PATH3600}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"3") 
				DISKPATH=/${PATH3601}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"4") 
				DISKPATH=/${PATH3602}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"5") 
				mkdir -p /Volumes/Lacie10TB/PROCESS/AS 								# Hookled on Mac Pro only
				DISKPATH=/Volumes/Lacie10TB/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"6") 
				mkdir -p /Volumes/SAR_20T_N1/PROCESS/AS								# Hookled on Mac Pro only
				DISKPATH=/Volumes/SAR_20T_N1/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"7") 
				mkdir -p /${PATHSYNODATA}/PROCESS/AS
				DISKPATH=/${PATHSYNODATA}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"8") 
				mkdir -p /${PATHSYNOSAR}/PROCESS/AS
				DISKPATH=/${PATHSYNOSAR}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;				
			"9") 
				mkdir -p /${PATHSYNOCONGO}/PROCESS/AS
				DISKPATH=/${PATHSYNOCONGO}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;				
			"10") 
				mkdir -p ${PATHHOMEDATA}/PROCESS/AS
				DISKPATH=${PATHHOMEDATA}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"11") 
				mkdir -p ${HOME}/PROCESS/AS
				DISKPATH=${HOME}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"12") 
				DISKPATH=/${PATH1660}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"13") 
				DISKPATH=/${PATH3610}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;
			"14") 
				DISKPATH=/${PATH3611}/PROCESS/AS/${SATDIR}_${TRKDIR}_Part_${i}
				 ;;


			* ) 
				echo "Unknown; try again"
				;;
		esac
		}
		
# ALL2GIF.sh
############
	# Define path to where to store the computed amplitudes 
	function ALL2GIFWhereAreAmpli()
		{
		# Setup disk paths for processing in Luxembourg. Adjust accordingly if you run several 
		ROOTTARGETDIR=${PATH_1650}/SAR_SM/AMPLITUDES
		}	

	# Define crop region in amplitude images depending on the sat, mode and target
	function ALL2GIFCrop()
		{
		case "${SAT}_${TRK}_${REGION}" in 
			"S1_DRC_NyigoCrater_A_174_Nyigo_crater_originalForm")  
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 270x270+4175+130 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif  
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"S1_DRC_NyigoCrater_D_21_Nyigo_Nyam_crater_originalForm")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 200x200+3580+950 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif 
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"S1_DRC_NyamCrater_A_174_Nyam_crater_originalForm")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 260x280+4030+560 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;

			"RADARSAT_RS2_F2F_Desc_Nyam")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 260x280+4030+560 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"RADARSAT_RS2_UF_Asc_Nyam")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x550+480+1130 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;

			"CSK_Virunga_Asc_Nyigo2")
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 500x500+770+2020 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Nyigo.gif
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x550+785+1570 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Nyigo.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"CSK_Virunga_Desc_NyigoCrater2")
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 1000x750+900+780 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 570x500+550+440 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 850x500+300+420 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyigoCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"CSK_Virunga_Asc_NyamCrater2")
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 400x320+630+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 450x250+1080+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"NyamCrater2_FullCrater_though_jumps")
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 400x320+630+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 450x250+1080+0 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"CSK_Virunga_Desc_NyamCrater2")
		#		convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 400x420+1590+1350 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 450x450+1435+1010 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_NyamCrater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;

			"S1_Hawaii_LL_A_124_Hawaii_LL_Crater_originalForm")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 550x380+4800+1 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Crater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"S1_Hawaii_LL_D_87_Hawaii_LL_Crater_originalForm")
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 350x400+450+80 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_Crater.gif
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
				
			"S1_PF_SM_A_144_PitonFournaise")  
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2400x1600+1800+1800 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
			"S1_PF_SM_D_151_tstampli_PitonFournaise")  
				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2500x1600+1800+1400 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;

#			"ENVISAT_A427_CentralNepal")  
#				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2500x1600+1800+1400 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
#				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
#			"ENVISAT_D33_CentralNepal")  
#				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2500x1600+1800+1400 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
#				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;
#			"ENVISAT_D305_CentralNepal")  
#				convert _movie_${SAT}_${TRK}_${REGION}.gif -coalesce -crop 2500x1600+1800+1400 +repage _movie_${SAT}_${TRK}_${REGION}_Crop_PDF.gif  
#				rm -f  _movie_${SAT}_${TRK}_${REGION}.gif ;;


			*)
				echo "No predefined crop for gif. Please do manually if required." ;;
		esac
		}	
		
# FUNCTIONS_FOR_MT.sh - should be obsolate
######################
	# For tracking the version of AMSTer Engine
	function FunctionsForAEPathSources()
		{
		eval PATHAMSTERENGINE=${HOME}/SAR/AMSTer/AMSTerEngine
		eval PATHSOURCES=${PATHAMSTERENGINE}/_Sources_AE/Older/
		}	

# Geocode_from_ALL2GIF.sh, RenamePath_Volumes.sh, RenamePathAfterMove_in_SAR_MASSPROC.sh,
# RenamePathAfterMove_in_SAR_SM_AMPLITUDES.sh
########################################################################################
	# Rename all path in param files just in case DIR were moved
	function RenameVolNameToVariable()
		{
		ORIGINAL=$1
		CHANGED=$2
		${PATHGNU}/gsed -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/\$PATH_1650%g 
							 s%\/Volumes\/hp-D3600-Data_Share1%\/\$PATH_3600%g 
							 s%\/Volumes\/hp-D3601-Data_RAID6%\/\$PATH_3601%g 
							 s%\/Volumes\/hp-D3602-Data_RAID5%\/\$PATH_3602%g
							 s%\/Volumes\/hp1660%\/\$PATH_1660%g 
							 s%\/Volumes\/D3610%\/\$PATH_3610%g 
							 s%\/Volumes\/D3611%\/\$PATH_3611%g 
							 s%\/mnt\/1650%\/\$PATH_1650%g 
							 s%\/mnt\/3600%\/\$PATH_3600%g 
							 s%\/mnt\/3601%\/\$PATH_3601%g 
							 s%\/mnt\/3602%\/\$PATH_3602%g
							 s%\/mnt\/1660%\/\$PATH_1660%g 
							 s%\/mnt\/3611%\/\$PATH_3611%g
							 s%\/mnt\/3610%\/\$PATH_3610%g " ${ORIGINAL} > ${CHANGED}
		}

# PlotTS.sh
###########
	# Do not define state variable from this sourced file because it does not work from python console when used with QGIS !
	# Define the INSTITUTE and the gnu TEMPLATES though as below

# PlotTS.sh, Plot_All_EW_UP_ts_inDir.sh, Plot_All_LOS_ts_inDir.sh, Plot_Diff_TS.sh
##########################################################################################
	# Define name of the institue where computations are performed
	function Institue()
		{
		INSTITUTE="ECGS"
		}
	function TemplatesGnuForPlotWOfit()
		{
		GNUTEMPLATENOFIT="/${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/plotTS_template.gnu"
		GNUTEMPLATEFIT="/${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/plotTS_template_fit.gnu" 
		}
	function TemplatesGnuForPlotMultiWOfit()
		{
		GNUTEMPLATENOFIT="/${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/plotTS_template_multi.gnu"
		GNUTEMPLATEFIT="/${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/plotTS_template_multi_fit.gnu" 
		GNUTEMPLATEFIT3D="/${PATH_SCRIPTS}/SCRIPTS_MT/TemplatesForPlots/plotTS_template_multi_fit3D.gnu" 
		}

# RenamePath_Volumes_MNTtoVOL.sh
################################
	# Rename Linux mounting point by Mac volume name 
	function RenameMntToVol()
		{
		ORIGINAL=$1
		CHANGED=$2
		${PATHGNU}/gsed -e 	"s%\/mnt\/1650%\/Volumes\/hp-1650-Data_Share1%g  
							 s%\/mnt\/3600%\/Volumes\/hp-D3600-Data_Share1%g 
							 s%\/mnt\/3601%\/Volumes\/hp-D3601-Data_RAID6%g  
							 s%\/mnt\/3602%\/Volumes\/hp-D3602-Data_RAID5%g
							 s%\/mnt\/1660%\/Volumes\/hp1660%g  
							 s%\/mnt\/3611%\/Volumes\/D3611%g
							 s%\/mnt\/3610%\/Volumes\/D3610%g" ${ORIGINAL} > ${CHANGED}
		}


# RenamePath_Volumes_VARtoMNT.sh
################################
	# Rename PATH variable name by Linux mounting point
	function RenamePathToMnt()
		{
		ORIGINAL=$1
		CHANGED=$2
		${PATHGNU}/gsed -e 	"s%\/\$PATH_1650%\/mnt\/1650%g  
							 s%\/\$PATH_3600%\/mnt\/3600%g  
							 s%\/\$PATH_3601%\/mnt\/3601%g  
							 s%\/\$PATH_3602%\/mnt\/3602%g
							 s%\/\$PATH_1660%\/mnt\/1660%g  
							 s%\/\$PATH_3611%\/mnt\/3611%g
							 s%\/\$PATH_3610%\/mnt\/3610%g" ${ORIGINAL} > ${CHANGED}
		}
		
		
# RenamePath_Volumes_VARtoVol.sh
################################
	# Rename PATH variable name by Mac volume name 
	function RenamePathToVol()
		{
		ORIGINAL=$1
		CHANGED=$2
		${PATHGNU}/gsed -e 	"s%\/\$PATH_1650%\/Volumes\/hp-1650-Data_Share1%g  
							 s%\/\$PATH_3600%\/Volumes\/hp-D3600-Data_Share1%g 
							 s%\/\$PATH_3601%\/Volumes\/hp-D3601-Data_RAID6%g  
							 s%\/\$PATH_3602%\/Volumes\/hp-D3602-Data_RAID5%g
							 s%\/\$PATH_1660%\/Volumes\/hp1660%g  
							 s%\/\$PATH_3611%\/Volumes\/D3611%g
							 s%\/\$PATH_3610%\/Volumes\/D3610%g" ${ORIGINAL} > ${CHANGED}
		}


# RenamePathInPlace_Volumes_VOLtoMNT.sh
#######################################
	# Rename in palce Mac volume name by Linux volume mounting name 
	function RenameInPlaceVotToMnt()
		{
		INPUTFILE=$1
		${PATHGNU}/gsed -i -e 	"s%\/Volumes\/hp-1650-Data_Share1%\/mnt\/1650%g  
								s%\/Volumes\/hp-D3600-Data_Share1%\/mnt\/3600%g 
						 		s%\/Volumes\/hp-D3601-Data_RAID6%\/mnt\/3601%g  
						 		s%\/Volumes\/hp-D3602-Data_RAID5%\/mnt\/3602%g
						 		s%\/Volumes\/hp1660%\/mnt\/1660%g  
								s%\/Volumes\/D3611%\/mnt\/3611%g
								s%\/Volumes\/D3610%\/mnt\/3610%g" ${INPUTFILE}
		}
	

# SinglePairNoUnwrap.sh
#######################
	# Define the type of Cell where the date is print on the plots
	function SinglePairNoUnwrapDATECELL()
		{
		   case ${TRKDIR} in
		       "RS2_UF_Asc") 
		    		DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
		       "RS2_F2F_Desc") 
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
		       "Virunga_Asc")  # for CSK
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
		       "Virunga_Desc")  # for CSK
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 30 -fill black -annotate" ;;
		       "PF_SM_A_144")  # for S1 Pdf
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 2400 -fill black -annotate" ;;
		       "PF_SM_D_151")  # for S1 Pdf
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 2400 -fill black -annotate" ;;	 
		       *) 
		        	DATECELL=" -gravity SouthWest -undercolor white -font Helvetica -pointsize 12 -fill black -annotate" ;;
		    esac
		}

# TimeSeriesInfo_HP.sh
#######################
	# Tag for web page 
	function TimeSeriesInfoHPWebTag()
		{
		convert $combi -fill grey -pointsize 60 -font ${font} -draw "text 670,250 'WebSite: http://terra4.ecgs.lu/${WebPage}" $combi
		}

# UpdateAMSTerEngine.sh
#######################
	# Define path to AMSTerEngine and its sources
	function PathSourcesAE()
		{
		PATHAMSTERENGINE=${HOME}/SAR/AMSTer/AMSTerEngine
		PATHSOURCES=${PATHAMSTERENGINE}/_Sources_AE/Older
		}
