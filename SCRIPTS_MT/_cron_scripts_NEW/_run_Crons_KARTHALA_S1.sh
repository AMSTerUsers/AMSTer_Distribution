#!/bin/bash
# Script to run 3 cronjob for processing Karthala. To be launched e.g. by crontab on Pro-Black
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/KARTHALA_S1_Step1_Read_SMCoreg_Pairs_SM.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/KARTHALA_S1_Step2_MassProc_SM.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/KARTHALA_S1_Step3_MSBAS.sh \
    /${PATH_3601}/SAR_MASSPROCESS/S1 
    