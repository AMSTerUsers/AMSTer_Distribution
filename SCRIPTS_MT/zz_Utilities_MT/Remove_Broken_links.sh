#!/bin/bash
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
#

#dir where links are
LINKTOCSL=$1

# Remove possible broken links 
for LINKS in `ls -d ${LINKTOCSL}/*.csl 2> /dev/null`
	do
		find -L ${LINKS} -type l ! -exec test -e {} \; -exec rm {} \; # first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part removes link if broken 
done
