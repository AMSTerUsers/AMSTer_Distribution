#!/bin/bash
# Script to run 2 cronjob for processing DOMUYO + ETAD. To be launched e.g. by crontab on Studio
# Third cron to be launched on DellRack
# 
# New in V1.1 20260420:	- write teh flag file in the same dir as process without ETAD to avoid 
#						  possible prblms (e.g. holes in defo maps when masks links are broken by change in OS) 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------

source $HOME/.bashrc

/$HOME/SAR/AMSTer/SCRIPTS_MT/zz_Utilities_MT/Crons_1_2_3.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts/Domuyo_S1_Step1_Read_SMCoreg_Pairs_DEMGeoid_ETAD.sh \
    /$HOME/SAR/AMSTer/SCRIPTS_MT/_cron_scripts/Domuyo_S1_Step2_MassProc_DEMGeoid_ETAD.sh \
    /${PATH_3602}/SAR_MASSPROCESS_2/S1 
# Because this run was for ETAD, add that info in FLAG file Last_Sucessful_Crons_Domuyo.txt
echo "*** This porcess was with ETAD ***" >> /${PATH_3602}/SAR_MASSPROCESS/S1/Last_Sucessful_Crons_Domuyo.txt

# Beware, the flag file is the same on 3602 as the one for Domuyo without ETAD, and MUST be like 

# cron 3 Domuyo_S1_Step3_MSBAS_DEMGeoid_ETAD.sh launched on dellrack