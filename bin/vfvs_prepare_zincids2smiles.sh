#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_prepare_zincids2smiles.sh <input_lists> <smiles_collection_folder> <output_filename>

The <input_list> has to contain the collection in the first column and the ZINC-ID in the second column.
The colums have to be separated by single spaces.
All path names have to be relative to the working directory."

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "3" ]]; then
   echo -e "\nWrong number of arguments. Exiting.\n"
   echo -e "${usage}\n\n"
   exit 1
fi

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
set -x

# Variables
input_file="$1"
smiles_folder="$2"
output_file="$3"

# Body
while read -r line; do 
    tranch=$(echo -n "$line" | awk -F '[ _]' '{print $1}')
    collection=$(echo -n "$line" | awk -F '[ _]' '{print $2}')
    zincid=$(echo -n "$line" | awk -F '[ _]' '{print $3}')    
    grep "${zincid}" "${smiles_folder}/${tranch}/${collection}.smi"  >> "${output_file}"
done < "${input_file}"

echo -e "\n * The smiles of the compounds have been prepared\n\n"
