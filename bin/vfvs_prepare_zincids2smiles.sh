#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_prepare_zincids2smiles.sh <input_list> <smiles_collection_folder> <smile_collection_folder_format> <output_filename>

The <input_list> has to contain the collection in the first column and the ZINC-ID in the second column.
The colums have to be separated by single spaces.
All path names have to be relative to the working directory.
<smiles_collection_folder_format>
    * tranch: smiles_collection_folder/<tranch>/<collection>.smi
    * metatrach: smiles_collection_folder/<metatranch>/tranch.smi"

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "4" ]]; then
   echo -e "\nWrong number of arguments. Exiting.\n"
   echo -e "${usage}\n\n"
   exit 1
fi
set -x
# Standard error response 
error_response_nonstd() {
    echo
    echo
    echo "Error was trapped which is a nonstandard error."
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})"
    echo "Error on line $1"
    echo
    exit 1
}
trap 'error_response_nonstd $LINENO' ERR

clean_exit() {
    echo
}
trap 'clean_exit' EXIT

# Variables
input_file="$1"
smiles_folder="$2"
output_file="$3"
smiles_folder_format="$4"

# Body
while read -r line; do 
    tranch=$(echo -n "$line" | awk -F '[_]' '{print $1}')
    collection=$(echo -n "$line" | awk -F '[_ ]' '{print $2}')
    compound_id=$(echo -n "$line" | awk -F '[ ]' '{print $2}')
    compound_id2=$(echo -n $compound_id | awk -F '[_]' '{print $1"_"$2}')
    metatranch=${tranch:0:2}
    trap '' ERR
    if [ "${smiles_folder_format}" == "tranch" ]; then
        smiles=$(grep -w "${compound_id2}" "${smiles_folder}/${tranch}/${collection}.smi" | awk '{print $1}')
        exit_code="$?"
    elif [ "${smiles_folder_format}" == "metatranch" ]; then
        smiles=$(grep -w "${compound_id2}" "${smiles_folder}/${metatranch}/${tranch}.smi" | awk '{print $1}')
        exit_code="$?"
    fi
    if [ ${exit_code} == 0 ]; then
        echo "${smiles} ${compound_id}" >> ${output_file}
        echo "Compound ${compound_id2} of collection ${collection} successfully extracted"
    else 
        echo ${compound_id2} ${collection} >> ${output_file}.failed
        echo "Compound ${compound_id2} of collection ${collection} failed to extract"
    fi
    trap 'error_response_nonstd $LINENO' ERR
done < "${input_file}"

echo -e "\n * The SMILES of the compounds have been prepared\n\n"
