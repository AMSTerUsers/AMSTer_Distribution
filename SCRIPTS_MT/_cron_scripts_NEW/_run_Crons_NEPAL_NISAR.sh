#!/bin/bash
# Script to run 3 cronjob for processing NEPAL NISAR. To be launched e.g. by crontab on 385
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/NEPAL_NISAR_Step1_Read_SMCoreg_Pairs.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/NEPAL_NISAR_Step2_MassProc.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/NEPAL_NISAR_Step3_MSBAS_128Threads.sh \
    /${PATH_3612}/SAR_MASSPROCESS/NISAR
    