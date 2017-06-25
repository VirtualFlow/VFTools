#!/usr/bin/env bash
usage="vfvs_pp_firstposes_all_unite <input folder> <type> <output filename>

Possible types:
    sub: first poses in sub folders, uncompressed (version 6, 7)
    tar: first poses in tar files (one per tranch, version >= 8)
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
if [ "$#" -ne "3" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Printing some information
echo
echo
echo "*********************************************************************"
echo "             Creating a single file with all first poses             "
echo "*********************************************************************"
echo 

# Variables
input_folder=${1%/}
type=$2
output_filename=${3}
temp_folder=${output_filename}.tmp

# Directories
mkdir -p ${temp_folder}  

# Main
if [ "${type}" = "sub" ]; then
    for collection in $(ls ${input_folder}); do
        for file in $(ls ${input_folder}/${collection}); do
            echo " * Adding file ${input_folder}/${collection}/${file} to ${output_filename}"
            cat ${input_folder}/${collection}/${file} | grep -v "ZINC\-ID" | sed "s/^/${collection}_${file/.txt} /g"  >> ${output_filename}
            echo 
        done
    done
elif [ "${type}" = "tar" ]; then
    cd ${temp_folder}
    for tranch in $(ls ../${input_folder}); do
        echo " * Extracting ${input_folder}/${trach} to ${temp_folder}"
        tar -xvf ../${input_folder}/${tranch} || true
    done
    cd ..
    for tranch in $(ls ${temp_folder}); do
        for file in $(ls ${temp_folder}/${tranch}); do
            echo " * Adding file ${temp_folder}/${tranch}/${file} to ${output_filename}"
            zcat ${temp_folder}/${tranch}/${file} | grep -v "ZINC\-ID" | sed "s/^/${tranch}_${file/.txt.gz} /g"  >> ${output_filename}
        done
    done
fi           

echo -e "\n * Cleaning the temporary files *"
rm -r ${temp_folder}

echo -e "\n * All first poses have been united in the file ${output_filename}"


