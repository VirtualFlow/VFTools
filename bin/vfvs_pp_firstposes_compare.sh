#!/usr/bin/env bash

usage="vfvs_pp_firstposes_compare.sh <ranking file> <output filename> <file to join 1>:<file to compare 2>:...

The ranking file needs to have in:
    column 1: the collection name
    column 2: the ligand name
    column 3: the score
    
The files to join need to have in:
    column 3: the energy
   
If the files to compare contains multiple entries for one ligand, only the first entry is used.
<files to join> should dont have to be first-poses.all files, they are to big usually. one can use a ranking.10000 file or similar. If a compound there is missing, the entry in the compare file for that score will be missing, so one knows the score will be relatively low.
"

# Standard error response 
error_response_std() {
    echo "Error was trapped" 1>&2
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "Error on line $1" 1>&2
    echo "Exiting."
    exit 1
}
trap 'error_response_std $LINENO' ERR

clean_up() {
    rm .winner.temp 1>/dev/null 2>&1 || true
}
trap 'clean_up' EXIT

# Checking the input paras
if [ "${1}" == "-h" ]; then
    echo -e "\n${usage}\n\n"
    exit 0
fi
if [ "$#" -ne "3" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Printing some information
echo
echo
echo "*********************************************************************"
echo "                       Ranking the first poses                       "
echo "*********************************************************************"
echo


# Variables
ranking_filename=${1}
output_filename=${2}
IFS=':' read -r -a files_to_compare <<< ${3}
# Main
if [ -f ${output_filename} ]; then
    echo " * The outputfile ${output_filename} does already exist. Overwriting..."
    echo "" > ${output_filename}
fi

# Applying the collection regular expression

echo " * Combining the poses based on the provided energies."
printf "%20s %20s %10s" "Collection" "Molecule" "score-1" > ${output_filename}
counter=2
for file_to_compare in ${files_to_compare[@]}; do 
    printf "%10s" "score-${counter}" >> ${output_filename}
    counter=$((counter+1))
done
echo >> ${output_filename}

while read -r line; do
    read -r -a array <<< "$line"
    if ! grep ZINC <<< "${line}" &>/dev/null; then
        continue
    fi
    collection=${array[0]}
    molecule=${array[1]}
    score=${array[2]}
    echo -e "\n * Processing ligand ${molecule}"
    printf "%20s %20s %10s" "${collection}" "${molecule}" "${score}" >> ${output_filename}
    for file_to_compare in ${files_to_compare[@]}; do 
        score=$(grep -m 1 ${molecule} ${file_to_compare} | awk '{print $3}')
        printf "%10s" "${score}" >> ${output_filename}
    done
    echo >> ${output_filename}   
done < ${ranking_filename}

echo -e "\n * The scores of the molecules has been completed.\n\n"

