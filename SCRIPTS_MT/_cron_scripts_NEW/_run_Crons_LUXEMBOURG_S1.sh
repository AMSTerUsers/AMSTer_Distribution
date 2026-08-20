#!/bin/bash
# Script to run 3 cronjob for processing Luxembourg. To be launched e.g. by crontab on 384
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/LUX_S1_Step1_Read_SMCoreg_Pairs.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/LUX_S1_Step2_MassProc.sh \
    /${PATH_3610}/SAR_MASSPROCESS/S1 


# cron 3 LUX_S1_Step3_MSBAS_Split.sh launched on hp385 only once per week (Saturday)