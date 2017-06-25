#!/bin/bash

usage="Usage: vfvs_v8tov7_restructure_inputcollections <source_foldername> <output foldername>"

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


# Copying the files
mkdir -p ${output_folder}
cd ${output_folder}
for tranch_archive in $(ls ../${source_folder}); do
    tranch=${tranch_archive/.tar}
    mkdir -p $tranch
    cd $tranch
    tar -xvf ../../${source_folder}/$tranch_archive
    cd ..
done
cd ..
echo -e "\n * The restructuring of the folder ${source_folder} has been completed."

