#!/bin/bash
# Script to run 3 cronjob for processing Piton de la Fournaise, mode SM. 
# To be launched e.g. by crontab on Pro-Silver
#
# For an up to date and detailed list of dependencies (and sub-dependencies), 
#    run the following command (add option -v to also list the commands and calls):
#  		Search_Dependencies /Path/to/This/script 
# 	 (Results are displayed at the Terminal; redirect them to a file with > file.txt if wished)
#
# New in Distro V 1.1 20261013:	- Recommend using Search_Dependencies.sh for 
#								  an updated list of dependencies
#									  
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V1.1 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on oct 13, 2026"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo "Processing launched on $(date) " 
echo " " 

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/PF_S1_Step1_Read_SMCoreg_Pairs_SM_DEMGeoid.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/PF_S1_Step2_MassProc_SM_DEMGeoid.sh \
    /${PATH_3610}/SAR_MASSPROCESS

# note that in this specific case, the path to flag files is not /${PATH_3610}/SAR_MASSPROCESS/S1 but
# /${PATH_3610}/SAR_MASSPROCESS. This is because there are two processings for PF and each has its own
# flag file withe the same name, hence in two different dirs

# cron 3 PF_S1_Step3_MSBAS_DEMGeoid.sh is launched on dellRack

# only for PF because both IW and SM:
mv -f /${PATH_3610}/SAR_MASSPROCESS/Last_Sucessful_Crons_PF.txt /${PATH_3610}/SAR_MASSPROCESS/Last_Sucessful_Crons_PF_SM.txt 