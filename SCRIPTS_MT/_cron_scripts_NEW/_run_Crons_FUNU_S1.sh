#!/bin/bash
# Script to run 2 cronjob for processing Funu. To be launched e.g. by crontab on Studio
# Third cron to be launched on DellRack
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/Funu_S1_Step1_Read_SMCoreg_Pairs.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts_NEW/Funu_S1_Step2_MassProc_shortest.sh \
    /${PATH_1660}/SAR_MASSPROCESS/S1 


# cron 3 Funu_S1_Step3_MSBAS_shortest_2D.sh  and Funu_S1_Step3_MSBAS_shortest_3D.sh launched on hp385