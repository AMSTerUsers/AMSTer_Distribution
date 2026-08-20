#!/bin/bash
# Script to run 3 cronjob for processing Piton de la Fournaise, mode IW. 
# To be launched e.g. by crontab on Pro-Silver
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/PF_S1_Step1_Read_SMCoreg_Pairs_DEMGeoid.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/PF_S1_Step2_MassProc_DEMGeoid.sh \
    /${PATH_3610}/SAR_MASSPROCESS/S1 


# cron 3 PF_S1_Step3_MSBAS_DEMGeoid.sh is launched on dellRack

# only for PF because both IW and SM:
mv -f /${PATH_3610}/SAR_MASSPROCESS/S1/Last_Sucessful_Crons_PF.txt /${PATH_3610}/SAR_MASSPROCESS/S1/Last_Sucessful_Crons_PF_IW.txt 