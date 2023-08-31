#!/bin/bash
# 
# BEWARE : script to quickly delete the whole content of a dir... 
#

DIRTOKILL=$1

cd ${DIRTOKILL}

# Check OS
OS=`uname -a | cut -d " " -f 1 `

case ${OS} in 
	"Linux") 
		espeak "Are you sure you want to kill all this ? " ;;
	"Darwin")
		say "Are you sure you want to kill all this ? " 	;;
	*)
		echo "Are you sure you want to kill all this ? " 	;;
esac			

echo "***************"
ls
echo "***************"

RNDM1=`echo $(( $RANDOM % 10000 ))`

while true; do
	read -p "Are you sure you want to kill all this [Y/N]? "  yn
	case $yn in
		[Y]* ) 
 				cd ..
				mkdir emptydir_${RNDM1}
				rsync -a --delete emptydir_${RNDM1}/ ${DIRTOKILL}
				rm -fR emptydir_${RNDM1} 
				rm -fR ${DIRTOKILL}
				exit 0 ;;
		[N]* ) 
			 echo "OK I quit" 
			 exit 0 ;;
		* ) 
			echo "Please answer Y or N." ;;
	esac
done




