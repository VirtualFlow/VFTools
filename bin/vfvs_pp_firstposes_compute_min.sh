#!/usr/bin/env bash
usage="vfvs_pp_firstposes_compute_min.sh <input file> <first_input_column_ID> <last_input_column_ID> <output file>

The of the column IDs starts at 1 (all columns are counted, even non-numerical ones). Columns are separates by whitespaces."

# Standard error response 
error_response_std() {
    echo "Error was trapped" 1>&2
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "Error on line $1" 1>&2
    echo "Exiting."
    exit 1
}
trap 'error_response_std $LINENO' ERR
set -x
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
echo "                       Computing the min values                      "
echo "*********************************************************************"
echo


# Variables
input_filename=${1}
first_input_column_id=${2}
last_input_column_id=${3}
output_filename="${4}"
#input_column_count="$((last_input_column_id - first_input_column_id + 1))"

while IFS= read -r line; do
    read -a line_array <<< "$line"
    max_value=$(echo "${line_array[@]}" | awk -v a=${first_input_column_id} -v b="${last_input_column_id}" '{m=$1;for(i=a;i<=b;i++)if($i<m)m=$i; print m }')
    echo "$line $max_value" >> "$output_filename.tmp"
done < $input_filename

column -t ${output_filename}.tmp > ${output_filename}
rm ${output_filename}.tmp

echo -e "\n * Computation completed.\n\n"
