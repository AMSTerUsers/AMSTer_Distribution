#!/bin/bash
######################################################################################
# This script set a color bullet to a file or a folder porvided as argument. 
#
# Parameters:	- color code:	0  No color
#								1  Orange
#								2  Red
#								3  Yellow
#								4  Blue
#								5  Purple
#								6  Green
#								7  Gray
#				- file or dir to tag
#
# Note: may actually tag more than one file if your cycle the parameters input 
#
# New in Distro V 2.0 20231030:	- Rename MasTer Toolbox as AMSTer Software
#								- rename Master and Slave as Primary and Secondary (though not possible in some variables and files)
#
# AMSTer: SAR & InSAR Automated Mass processing Software for Multidimensional Time series
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.0 AMSTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Oct 30, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# Check OS and exit of not Mac
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		espeak "Can't change color tag with Linux; this is a Mac feature only." 
		exit 0 ;;
	"Darwin")
		say "Let's change color tag..." 	;;
	*)
		echo "No sure about your OS. Can't change color tag with Linux; this is a Mac feature only." 	
		exit 0 ;;
esac			

COLORLABEL=$1
FILETOTAG=$2

# Set Finder label color
label(){
  if [ $# -lt 2 ]; then
    echo "USAGE: label [0-7] file1 [file2] ..."
    echo "Sets the Finder label (color) for files"
    echo "Default colors:"
    echo " 0  No color"
    echo " 1  Orange"
    echo " 2  Red"
    echo " 3  Yellow"
    echo " 4  Blue"
    echo " 5  Purple"
    echo " 6  Green"
    echo " 7  Gray"
  else
    osascript - "$@" << EOF 2> /dev/null
    on run argv
        set labelIndex to (item 1 of argv as number)
        repeat with i from 2 to (count of argv)
          tell application "Finder"
              set theFile to POSIX file (item i of argv) as alias
              set label index of theFile to labelIndex
          end tell
        end repeat
    end run
EOF
  fi
}

label ${COLORLABEL} ${FILETOTAG}

echo +++++++++++++++++++++++++++++++++
echo "COLOR CHANGED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++

