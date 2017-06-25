#!/bin/bash

usage="Usage: vflp_pp_length.sh <source_foldername> <output filename>"
        

# Checking the input arguments
if [ "${1}" == "-h" ]; then
    echo -e "\n${usage}\n\n"
    exit 0
fi

if [ "$#" -ne "2" ]; then
    echo -e "\nWrong number of input arguments. Exiting...\n"
    echo -e "${usage}\n\n"
    exit 1
fi


# Standard error response 
error_response_std() {
    echo
    echo "Error was trapped" 1>&2
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "Error on line $1" 1>&2
    echo -e "Exiting.\n\n"
    exit 0
}
trap 'error_response_std $LINENO' ERR


# Printing some information
echo
echo
echo "************************************************************"
echo "           Computing the length of the collections          "
echo "************************************************************"
echo

# Variables
source_folder=${1%/}
output_filename=${2%/}

# Copying the files
for folder in $(ls ${source_folder}/); do
    name1=${folder:0:4}
    name2=${folder:5}
    echo
    if [ -z ${name2} ]; then
        echo " * Collection $folder has no collection sub_id. Assigning it sub_id 1."
        name2=1
    fi
    filename=$(ls ${source_folder}/${folder})
    filename_ending="${filename/all.}"
    if [ -z ${filename} ]; then
        echo  " * No file in folder ${source_folder}/${folder}. Skipping this folder."
        continue
    fi
    length=$(tar -tvf ${source_folder}/${folder}/${filename} | wc -l )
    if [[ "${length}" -eq "${length}" ]]; then
        echo " * Adding the length of the collection ${source_folder}/${folder}/${filename} to the file ${output_filename}" 
        echo "${folder} ${length}" >> ${output_filename}
    else 
        echo " Error: Could not get the length (length=${length}) of the collection ${folder}. Skipping..."|  tee ${output_filename}.err
    fi
done

echo -e "\n * The restructuring of the folder ${source_folder} has been completed."

