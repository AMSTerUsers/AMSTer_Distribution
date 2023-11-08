#!/bin/bash
# allows deleting a dir that contains a .smbdelete.... file by getting rid of the problematic ghost file
#
# must be launched in dir that you can't delete because of the presence of the .smb ghost file 
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

mkdir -p /ToKill

TODEL=`ls .smbdelete*`

sudo mv -f ${TODEL} /ToKill

echo "Now you can delete the present dir; Your ghost file was moved in /ToKill"
