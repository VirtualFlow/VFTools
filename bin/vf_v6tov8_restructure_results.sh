#!/bin/bash

usage="Usage: vf_v6tov8_restructure_results <source_foldername> <output foldername>\nHas to be run in the folder in which the source folder is located."

# Checking the input arguments
if [ "${1}" == "-h" ]; then
    echo -e "\n${usage}\n\n"
    exit 0
fi

if [ "$#" -ne "2" ]; then
    echo -e "Wrong number of input arguments. Exiting...\n"
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
echo "               Restructuring the results folder             "
echo "************************************************************"
echo

# Variables
source_folder=${1%/}
output_folder=${2%/}

# Folders
mkdir -p ${output_folder}

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
    echo " * Adding the file ${source_folder}/${folder}/${filename} to the archive ${output_folder}/${name1}.tar"
    tar -rf ${output_folder}/${name1}.tar -C ${source_folder}/${folder} --wildcards --transform="flags=r;s|all|${name2}|" ${filename}
done

echo -e "\n * The restructuring of the folder ${source_folder} has been completed."

