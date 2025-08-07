#!/bin/bash
# Script intends to run a comparison of MSBAS results based on several tables of pairs
# 
# NOTE: - 
#
# WARNING: 	can only compare table from a single set and both tables are supposed to be stored in the same dir
#
# Parameters: 
#			  - PathtoDir where the results will be stored 
#			  - List of PathtoMSBASDIR 
#			  - List of StringCommentforNaming  
# Hardcoded: 
#
# Dependencies:	- 

# New in Distro V 1.0:  - 
# New in 1.1 (20250319 - DS): - Change to compare more than 2 dir + ajout plot events
#
# MasTer: InSAR Suite automated Mass processing Toolbox. 
# NdO (c) 2016/03/07 - could make better with more functions... when time.
# -----------------------------------------------------------------------------------------
PRG=`basename "$0"`
VER="Distro V2.8 MasTer script utilities"
AUT="Delphine Smittarello, (c)2016-2019, Last modified on Feb 04, 2025 by DS"

echo " "
echo "${PRG} ${VER}, ${AUT}"
echo " "

source $HOME/.bashrc

Current_dir=$(pwd)


RESULTS=$1
MSBAS_DIR=$2
Label=$3
nom_fichier=$4  
EVENTS=$5

echo $nom_fichier
mkdir -p ${RESULTS}
cd ${RESULTS}
echo "Compare Times Series from MSBAS processings " > logfile.txt


## Functions 
lire_fichier() {
    if [[ ! -f "$1" ]]; then
        echo "Error: Le file '$1' not found."
        return 1
    fi
    cat "$1"
}

transformer_lignes() {
    while read -r ligne; do
        set -- $ligne
        if [[ $# -ge 5 ]]; then
            echo "${5}_timeLines_"
        fi
    done
}

# Exemple d'utilisation
contenu=$(lire_fichier "$nom_fichier")
# For each line in the file, process it and call Plot_compareTS.py
echo "$contenu" | transformer_lignes | while read -r POINTSDIF; do
    echo "Processing point: $POINTSDIF"
    echo Plot_compareTS.py ${MSBAS_DIR} ${Label} ${POINTSDIF} -events ${EVENTS} >> logfile.txt
    Plot_compareTS.py ${MSBAS_DIR} ${Label} ${POINTSDIF}  -events ${EVENTS}
done

cd ${Current_dir}