#!/bin/bash

usage="Usage: vfvs_v6tov7_restructure_inputcollections <source_foldername>\nHas to be run in the folder in which the source folder is located."

# Checking the input arguments
if [ "${1}" == "-h" ]; then
    echo -e $usage
    exit 0
fi

if [ "$#" -ne "1" ]; then
    echo -e $usage
    exit 1
fi


# Standard error response 
error_response_std() {
    echo "Error was trapped" 1>&2
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "Error on line $1" 1>&2
    echo "Exiting."
    exit 0
}
trap 'error_response_std $LINENO' ERR


# Variables
source_folder=${1/\/}


# Folders
if [ -d ${source_folder}_sub/ ]; then
    rm -r ${source_folder}_sub/ 
fi

# Copying the files
for filename in $(ls ${source_folder}/); do
    file_basename=${filename/.*}
    name1=${file_basename/_*}
    name2=${file_basename/*_}
    # Checking if there is no number at all (a few collections had that)
    if [ "${name1}" == "${name2}" ]; then
        name2="000000"
        ending=${filename/${name1}}
    else
#        name3=$(printf "%05d\n" $name2)
        name3=$name2

        ending=${filename/${name1}_${name2}}
    fi
    if [ ! -d "${source_folder}_sub/${name1}/" ]; then
        echo "Creating directory ${source_folder}_sub/${name1}/"
        mkdir -p "${source_folder}_sub/${name1}/"
    fi
    echo "Copying the file ${source_folder}/${filename} to ${source_folder}_sub/${name1}/${name3}${ending}"
    cp ${source_folder}/${filename} ${source_folder}_sub/${name1}/${name3}${ending}
done


