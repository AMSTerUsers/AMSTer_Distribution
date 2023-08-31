#!/bin/bash
# -----------------------------------------------------------------------------------------
# This script is aiming at removing broken links from MSBAS/Site/MODEi and cleaning 
#   corresponding MODEi.txt files. Also remove corresponding raster in subdir.
#      
#
# Parameters : - path to dir with the links to check, i.e. MSBAS/Site/MODEi
#
# Dependencies:	- readlink
#
# New in Distro V 1.1:	- source bashrc
# New in Distro V 1.2:	- path to GNU grep
# New in Distro V 1.3:	- change naming _Full as _Inclunding_Broken_Links to avoid clash with other processes
#						- add random nr to CleanedLinks.txt to avoid clashes when launched in background
#						- also clean possible ${PATHMODE}_Full.txt, which can be created when resticting pairs based on coh threshold 
# New in Distro V 1.4:	- find -type l fails in Linux
#						- force mv Modei.txt in _Full.txt etc.. And test if _Full exists before atempting doing soething with it
# New in Distro V 1.5:	- sort and uniq files with broken links 
# New in Distro V 2.0:	- more robust for Linux 
# New in Distro V 2.1:	- happen / before original target path
#						- remove broken links from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt (if any) as well
# New in Distro V 2.2:	- revised and also clean list of files from coherence cleaning thresold and Out of Range filtering
# New in Distro V 2.3:	- prefer readlink to get original target of link
# New in Distro V 2.4: 	- wrong path for OUTRANGEFILES
# New in Distro V 2.5: - replace if -s as -f -s && -f to be compatible with mac os if 
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2019/12/31 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.5 MasTer script utilities"
AUT="Nicolas d'Oreye, (c)2016-2019, Last modified on Jul 19, 2023"
echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

# vvv ----- Hard coded lines to check --- vvv 
#must be sourced for usage with Linux?
source /$HOME/.bashrc 
# ^^^ ----- Hard coded lines to check --- ^^^ 

PATHMODE=$1					# path to dir where links to check are stored, i.e. MSBAS/Site/MODEi

if [ $# -lt 1 ] ; then echo “Usage $0 path_to_MSBAS/Site/MODEi”; exit; fi

MODE=`basename ${PATHMODE}`
PATHSITE="$(dirname "$PATHMODE")"		

RNDM1=`echo $(( $RANDOM % 10000 ))`

cd ${PATHMODE}

#if [ -e ${PATHSITE}/CleanedLinks_${RNDM1}.txt ] ; then rm -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt ; fi

# Remove broken links
for LINKS in ` find . -maxdepth 1 -name "*deg"` # Do not type -l because it fails with Linux 
 	do
#        ORIGINALTARGET=`ls -l ${LINKS} | cut -d ">" -f 2- | cut -d "/" -f 2-` # get  the path and name of file pointed to by the broken link i.e. file tolocate in  TARGETDIR
#		ORIGINALTARGET="/${ORIGINALTARGET}"
		ORIGINALTARGET=`readlink ${LINKS}`
		
		if [ ! -s ${ORIGINALTARGET} ] 
			then 
				echo "${LINKS} is broken --> cleaning"
				echo "${LINKS}" >> ${PATHSITE}/CleanedLinks_${RNDM1}_tmp.txt
            	rm -f ${LINKS}
			else
				echo "${LINKS} not broken"		
		fi
       # if [ -L ${LINKS} ] && [ ! -e ${LINKS} ] ; then 
       #     echo ${LINKS} >> "${PATHSITE}"/CleanedLinks_"${RNDM1}".txt
       #     rm -f ${LINKS}
       # fi
 		#find -L "${LINKS}" -type l ! -exec test -e {} \; -exec echo {} >> "${PATHSITE}"/CleanedLinks_"${RNDM1}".txt \;  -exec rm {} \; 	# first part stays silent if link is ok (or is not a link but a file or dir); answer the name of the link if the link is broken. Second part store the info and removes link if broken 
 		#find -L ${LINKS} -type l ! -exec test -e {} \; -exec echo {} >> ${PATHSITE}/CleanedLinks.txt \;  					# test without rm
done

if [ -f "${PATHSITE}/CleanedLinks_${RNDM1}_tmp.txt" ] && [ -s "${PATHSITE}/CleanedLinks_${RNDM1}_tmp.txt" ] ; then  

	# Just to be sure
	sort ${PATHSITE}/CleanedLinks_${RNDM1}_tmp.txt | uniq > ${PATHSITE}/CleanedLinks_${RNDM1}.txt
	rm -f ${PATHSITE}/CleanedLinks_${RNDM1}_tmp.txt

	echo "  // Shell clean:" 
	cat  ${PATHSITE}/CleanedLinks_${RNDM1}.txt

	# Remove defo map link
 		cd ${PATHMODE}
 		while read -r CLEANEDLINK
 		do	
 			echo "  // Clean ${CLEANEDLINK}"
 			rm -f ${CLEANEDLINK}
 		done < ${PATHSITE}/CleanedLinks_${RNDM1}.txt
	
	# Remove rasters
		cd ${PATHMODE}/Rasters
		while read -r CLEANEDLINK
		do	
			echo "  // Clean ${CLEANEDLINK}.ras"
			rm -f ${CLEANEDLINK}.ras
		done < ${PATHSITE}/CleanedLinks_${RNDM1}.txt

	# Clean text file
		cd ${PATHSITE}
		mv -f ${PATHMODE}.txt ${PATHMODE}_Inclunding_Broken_Links_tmp.txt
		sort ${PATHMODE}_Inclunding_Broken_Links_tmp.txt | uniq > ${PATHMODE}_Inclunding_Broken_Links.txt
		rm -f ${PATHMODE}_Inclunding_Broken_Links_tmp.txt
		${PATHGNU}/grep -Fv -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt ${PATHMODE}_Inclunding_Broken_Links.txt > ${PATHMODE}.txt  # remove from ${PATHMODE}_Inclunding_Broken_Links.txt each line that contains what is in lines of CleanedLinks.txt

	# Clean possisble _Full text file which would result from restiction of msbas to coh threshol 
	# Run that here even if one rune also the present script on _Full dir because here it cleans the right _Full.txt
		cd ${PATHSITE}
		if [ -d ${PATHMODE}_Full ] && [ -s ${PATHMODE}_Full/${MODE}_Full.txt ] ; then
			mv -f ${PATHMODE}_Full/${MODE}_Full.txt ${PATHMODE}_Full/${MODE}_Full_Inclunding_Broken_Links_tmp.txt
			sort ${PATHMODE}_Full/${MODE}_Full_Inclunding_Broken_Links_tmp.txt | uniq > ${PATHMODE}_Full/${MODE}_Full_Inclunding_Broken_Links.txt
			rm -f ${PATHMODE}_Full/${MODE}_Full_Inclunding_Broken_Links_tmp.txt
			${PATHGNU}/grep -Fv -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt ${PATHMODE}_Full/${MODE}_Full_Inclunding_Broken_Links.txt > ${PATHMODE}_Full/${MODE}_Full.txt  # remove from ${PATHMODE}_Inclunding_Broken_Links.txt each line that contains what is in lines of CleanedLinks.txt
		fi
  
  	# remove the cleaned links from Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt if any
		cd ${PATHSITE}
		COHIGNORE=Checked_For_CohThreshold_To_Be_Ignored_At_Next_Rebuild_msbas_Header.txt
		if [ -f "${PATHMODE}/${COHIGNORE}" ] && [ -s "${PATHMODE}/${COHIGNORE}" ] ; then
			mv -f ${PATHMODE}/${COHIGNORE} ${PATHMODE}/${COHIGNORE}_Inclunding_Broken_Links_tmp.txt
			sort ${PATHMODE}/${COHIGNORE}_Inclunding_Broken_Links_tmp.txt | uniq > ${PATHMODE}/${COHIGNORE}_Inclunding_Broken_Links.txt
			rm -f ${PATHMODE}/${COHIGNORE}_Inclunding_Broken_Links_tmp.txt
			${PATHGNU}/grep -Fv -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt ${PATHMODE}/${COHIGNORE}_Inclunding_Broken_Links.txt > ${COHIGNORE}  # remove from ${COHIGNORE}_Inclunding_Broken_Links.txt each line that contains what is in lines of CleanedLinks.txt
		fi
  
  	# remove the cleaned links from all Out or Range files (e.g. Out_Of_Range_20m_400days.txt) if any
		if [ `ls ${PATHMODE}/Out_Of_Range_*.txt 2>/dev/null | wc -l` -ge 1 ] 
			then 
				for OUTRANGEFILES in `ls ${PATHMODE}/Out_Of_Range_*.txt`
					do 
						if [ -f "${OUTRANGEFILES}" ] && [ -s "${OUTRANGEFILES}" ] ; then
							mv -f ${OUTRANGEFILES} ${OUTRANGEFILES}_Inclunding_Broken_Links_tmp.txt
							sort ${OUTRANGEFILES}_Inclunding_Broken_Links_tmp.txt | uniq > ${OUTRANGEFILES}_Inclunding_Broken_Links.txt
							rm -f ${OUTRANGEFILES}_Inclunding_Broken_Links_tmp.txt
							${PATHGNU}/grep -Fv -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt ${OUTRANGEFILES}_Inclunding_Broken_Links.txt > ${OUTRANGEFILES}  # remove from ${COHIGNORE}_Inclunding_Broken_Links.txt each line that contains what is in lines of CleanedLinks.txt
							rm -f ${OUTRANGEFILES}_Inclunding_Broken_Links.txt
						fi   	
				done
		fi

    rm -f ${PATHSITE}/CleanedLinks_${RNDM1}.txt
fi

