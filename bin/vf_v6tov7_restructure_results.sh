#!/bin/bash

usage="Usage: vf_v6tov7_restructure_results <source_foldername> <output foldername>\nHas to be run in the folder in which the source folder is located."

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
echo "               Restructuring the results folder             "
echo "************************************************************"
echo

# Variables
source_folder=${1%/}
output_folder=${2%/}

# Copying the files
for folder in $(ls ${source_folder}/); do
    name1=${folder:0:4}
    name2=${folder:5}
    name2=${name2/.txt}
    echo
    if [ -z ${name2} ]; then
        echo " * Collection $folder has no collection sub_id. Assigning it sub_id 1."
        name2=1
    fi
    filename=$(ls ${source_folder}/${folder})
    if [ -z ${filename} ]; then
        echo  " * No file in folder ${source_folder}/${folder}. Skipping this folder."
        continue
    fi
    #if [ -d "${output_folder}/${name1}/" ]; then
    #    echo " * Directory ${output_folder}/${name1}/ already exists. Removing..."
    #fi
    echo " * Creating the directory ${output_folder}/${name1} if not yet existent."
    mkdir -p "${output_folder}/${name1}/"
    echo " * Copying the file ${source_folder}/${folder}/${filename} to ${output_folder}/${name1}/${name2}.gz.tar"
    cp ${source_folder}/${folder}/* ${output_folder}/${name1}/${name2}.gz.tar
done

echo -e "\n * The restructuring of the folder ${source_folder} has been completed."

