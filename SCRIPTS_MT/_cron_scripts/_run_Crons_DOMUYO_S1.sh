#!/bin/bash
# Script to run 3 cronjob for processing DOMUYO. To be launched e.g. by crontab on dellRack
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts/Domuyo_S1_Step1_Read_SMCoreg_Pairs_DEMGeoid.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts/Domuyo_S1_Step2_MassProc_DEMGeoid.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts/Domuyo_S1_Step3_MSBAS_DEMGeoid_Split.sh \
    /${PATH_3602}/SAR_MASSPROCESS_2/S1 
