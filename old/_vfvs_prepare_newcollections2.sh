#!/usr/bin/env bash

usage="vfvs_prepare_newcollections.sh <ligand file> <pdbqt_input_folder> <ligands_per_collection> <collections_per_tranch> <output folder>

Requires a ligand file with the first column the collection name and the second column the ligand name"

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
if [ "$#" -ne "5" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Printing some information
echo
echo
echo "*********************************************************************"
echo "                  Extracting the winning structrures                 "
echo "*********************************************************************"
echo

# Variables
ligand_file=${1}
pdbqt_input_folder=${2}
ligands_per_collection=${3}
collections_per_tranch=${4}
output_folder=${5}

# Preparing required folders and files
if [ -d ${output_folder} ]; then
    echo " * The output folder ${output_folder} does already exist. Removing..."
    rm -r ${output_folder}
fi
mkdir ${output_folder}
echo " * If the file ${output_folder}.length.all exists already it will be cleared."
echo -n "" > "$(basename ${output_folder}.length.all)"


# Loop for each winning structure
molecule_counter=1
collection_counter=1
tranch_counter=1
while read -r line; do
    read -r -a array <<< "$line"
    collection_original="${array[0]}"
    tranch_original="${collection_original/_*}"
    collection_no_original=${collection_original/*_}
    collection_no_padded_original="$(printf "%05.f" "${collection_no_original}")"
    tranch="T$(printf "%04.f" "${tranch_counter}")"
    molecule=${array[1]}
    collection_no=${collection/*_}
    collection_no="$(printf "%05.f" ${collection_counter})"
    collection="${tranch}_${collection_no}"
    echo -e "\n *** Adding the structure ${molecule} to collection ${collection} ***"
    if [ ! -d  "${output_folder}/${collection}/" ]; then
        mkdir ${output_folder}/${collection}
    fi
    tar -xOf ${pdbqt_input_folder}/${tranch_original}/${collection_no_padded_original}.pdbqt.gz.tar ${molecule}.pdbqt.gz > ${output_folder}/${collection}/${molecule}.pdbqt.gz || true
    molecule_counter=$((molecule_counter+1))
    if [ "${molecule_counter}" -gt "${ligands_per_collection}" ]; then
        collection_counter=$((collection_counter+1))
        molecule_counter=1
    fi
    if [ "${collection_counter}" -gt "${collections_per_tranch}" ]; then
        collection_counter=$((collection_counter+1))
        molecule_counter=1
        collection_counter=1
        tranch_counter=$((tranch_counter+1))
    fi
done < ${ligand_file}
echo -e "\n *** The preparation of the intermediate folders has been completed ***"

echo -e "\n *** Starting the preparation of the length.all file ***"
for folder in $(ls ${output_folder}); do
    echo -e "\n *** Adding the collection ${folder} to the length.all file ***"
    cd ${output_folder}/${folder}
    length=$(ls -A | wc -l)
    echo "${folder} ${length}" >> ../../${output_folder}.length.all
    cd ../..
done
echo -e "\n *** The preparation of the length.all file has been completed ***"

echo -e "\n *** Starting the preparation of the tar archives ***"
for folder in $(ls ${output_folder}); do
    cd ${output_folder}/${folder}
    tranch=${folder/_*}
    collection_no=${folder/*_}
    echo -e "\n *** Creating the tar archive for collection ${folder} ***"
    tar -cf ${collection_no}.pdbqt.gz.tar --wildcards *
    echo -e "*** Adding the tar archive of collection ${folder} to the tranch-archive ${tranch}.tar ***"
    tar -rf ../${tranch}.tar ${collection_no}.pdbqt.gz.tar
    cd ../../
    #rm -r ${output_folder}/${folder}
done
echo -e "\n *** The preparation of the tranch-archives has been completed ***"

echo -e "\n *** The preparation of the new collections has been completed ***"
