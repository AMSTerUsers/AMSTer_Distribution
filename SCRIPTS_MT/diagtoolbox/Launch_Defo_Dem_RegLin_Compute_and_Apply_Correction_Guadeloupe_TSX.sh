#!/bin/bash
######################################################################################
# This script launch the computation of the linear regression between DEM and deformation maps of Guadeloupe TSX modes and 
# save plots in process directory directory. 
# DEM and DEFO must be of the same size.  
#
# Dependencies:	- python3.10 and modules below (see import)
#
# Parameters: hard coded below
# launch command : thisscript.sh
#
# New in Distro V 1.0 20250121
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# DS (c) 2022 - could make better with more functions... when time.
######################################################################################

CURRENTDIR=$(pwd)

#DEM="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/ENVI/Guadeloupe_SRTM_Lidar_extract_MSBASgrid_V2.r4" 
#DEM="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/ENVI/Guadeloupe_SRTM_Lidar_extract_MSBASgrid_V30m.r4" 
DEM="/Users/delphine/Documents/Guadeloupe/Data/DEM/Lidar/ENVI/Litto3D-SHOM-Guadeloupe-2016_Lidar_MNT1m_MSBASgrid_V2m.r4"

#DEFODIR_A104="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML5/Geocoded/DefoInterpolx2Detrend"
#DEFODIR_D20="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML5/Geocoded/DefoInterpolx2Detrend"

#DEFODIR_A104=/Users/delphine/Documents/Guadeloupe/Data/A_104/Geocoded/DefoInterpolx2Detrend
#DEFODIR_D20=/Users/delphine/Documents/Guadeloupe/Data/D_20/Geocoded/DefoInterpolx2Detrend
#Processdir_A104="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem2/A_104"
#Processdir_D20="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem2/D_20"

#DEFODIR_A104="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML24/Geocoded/DefoInterpolx2Detrend"
#DEFODIR_D20="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML24/Geocoded/DefoInterpolx2Detrend"
#Processdir_A104="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem30m/A_104"
#Processdir_D20="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem30m/D_20"

DEFODIR_A104="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_A104/SMNoCrop_SM_20240204_Zoom1_ML2/Geocoded/DefoInterpolx2Detrend"
#DEFODIR_D20="/Volumes/D3610/SAR_MASSPROCESS/TSX/GUADELOUPE_D20/SMNoCrop_SM_20240724_Zoom1_ML2/Geocoded/DefoInterpolx2Detrend"
Processdir_A104="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem2m/A_104"
#Processdir_D20="/Users/delphine/Documents/Guadeloupe/Comparaison_defo_dem2m/D_20"


#### Compute Linear Regression with DEM for ALl Maps in Defodir and store data in an output.txt file
mkdir -p ${Processdir_A104}
#mkdir -p ${Processdir_D20}

cd ${Processdir_A104}
RegLin_DEM_Defo_all_Maps_In_Geocoded.sh ${DEM} ${DEFODIR_A104}
Load_and_Plot_Output_DEMDefo.py "${Processdir_A104}/output.txt"
#cd ${Processdir_D20}
#RegLin_DEM_Defo_all_Maps_In_Geocoded.sh ${DEM} ${DEFODIR_D20}
#Load_and_Plot_Output_DEMDefo.py "${Processdir_D20}/output.txt"

cd ${CURRENTDIR}


### Apply model and write cordefomaps for all maps in dir

Compute_and_Substract_Defo_Dem_All_In_Dir.sh ${DEM} ${DEFODIR_A104} "${Processdir_A104}/resultats.csv"
#Compute_and_Substract_Defo_Dem_All_In_Dir.sh ${DEM} ${DEFODIR_D20} "${Processdir_D20}/resultats.csv"

# Move all png to GeocodedRaster
cd ${DEFODIR_A104}
cd ..
cd ..
mkdir -p GeocodedRasters/COR_Defo_Dem/
mv Geocoded/COR_Defo_Dem/*.png GeocodedRasters/COR_Defo_Dem/
#cd ${DEFODIR_D20}
#cd ..
#cd ..
#mkdir -p GeocodedRasters/COR_Defo_Dem/
#mv Geocoded/COR_Defo_Dem/*.png GeocodedRasters/COR_Defo_Dem/