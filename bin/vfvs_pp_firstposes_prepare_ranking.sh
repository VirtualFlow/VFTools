#!/usr/bin/env bash
usage="vfvs_pp_firstposes_prepare_ranking.sh <first poses all file> <ranked_column_id> <output filename> <number of highest ranked compounds>

Arguments:
    ranked_column_id: contains the column id which is used for ranking the compounds (index starts at 1)
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

# Checking the input paras
if [ "${1}" == "-h" ]; then
    echo -e "\n${usage}\n\n"
    exit 0
fi
if [ "$#" -ne "4" ]; then
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
input_filename=${1}
column_id=${2}
output_filename=${3}
no_of_winners=${4}

# Main
if [ ! -f ${input_filename}.sorted ]; then
    echo " * Sorting the first poses"
    nice -n 20 ionice -c2 -n7 cat ${input_filename} | LC_ALL=C sort -k${column_id} -n | column -t > ${input_filename}.sorted
else
    echo " * Found the file ${input_filename}.sorted. Using it in the further processing"
fi


echo " * Preparing the file ${output_filename} containing the winners"
#head -n "${no_of_winners}" ${input_filename}.sorted | awk -F ' ' '{$3 = sprintf("%5.1f", $3); print $2": "  $3 "  (" $1")"}' > ${output_filename}
head -n "${no_of_winners}" ${input_filename}.sorted | awk -F ' ' '{$3 = sprintf("%5.1f", $3); printf "%-10s %s %5s\n", $1,  $2, $3}' > ${output_filename}
echo -e "\n * The preparation of the rankings has been completed.\n\n"
