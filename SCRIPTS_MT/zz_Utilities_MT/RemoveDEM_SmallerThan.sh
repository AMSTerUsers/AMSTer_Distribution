#!/bin/bash
# Remove externalSlantRangeDEM in subdir if smaller than a given size

SIZE=$1 	# size in b

echo "List dates of missing files from prensent dir/subdirs: "

for dem in `find . -name externalSlantRangeDEM`
   do
 		demsize=$(stat -c%s "$dem")
 		if [ -f "${dem}" ] && [ ${demsize} -lt ${SIZE} ]
			then 
				echo "${dem} is ${demsize} => del"
				rm -f ${dem}
			else 
				echo "${dem} is ${demsize} => ok"
		fi

done

echo +++++++++++++++++++++++++++++++++++++++++++++++
echo "ALL FILES CHECKED - HOPE IT WORKED"
echo +++++++++++++++++++++++++++++++++++++++++++++++


