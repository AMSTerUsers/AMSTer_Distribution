#!/bin/bash
# Script dedicated to launch the required processes for a full SuperMaster processing, 
#   that is SuperMasterCoreg.sh then SuperMaster_MassProc.sh
#
# Parameters : - file with the compatible pairs (incl path; named as table_MinBp_MaxBp_MinBt_MaxBt.txt)    
#              - file with the processing parameters (incl path) 
#			   - For S1: add FORCE to recompute DEM for each image at coregistration
#
# Dependencies:
#    	- SuperMasterCoreg.sh
#		- SuperMaster_MassProc.sh
#
# New in Distro V 1.0:	- Based on developpement version and Beta V1.0
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

PAIRFILE=$1
PARAMFILE=$2
FORCES1DEM=$3				# For S1 processing : if FORCE, then recompute DEM for each S1 image 

if [ $# -lt 2 ] ; then echo "Usage $0 PAIRFILE PARAM_FILE "; exit; fi

SuperMasterCoreg.sh ${PARAMFILE} ${FORCES1DEM}
SuperMaster_MassProc.sh ${PAIRFILE} ${PARAMFILE}

