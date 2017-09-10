#!/usr/bin/env bash

usage="vfvs_prepare_newcollections.sh <ligand file> <pdbqt_input_folder> <pdbqt_folder_format> <ligands_per_collection> <output folder>

Requires a ligand file with the first column the collection name and the second column the ligand name.

pdbqt_folder_format: Possible values: tar_tar and sub_tar
sub_sub is supported by vfvs_prepare_newcollections2.sh
This script is not yet ready to continue started procedures."

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
pdbqt_folder_format=${3}
ligands_per_collection=${4}
output_folder=${5}
temp_folder=${output_folder}.tmp

# Preparing required folders and files
if [ -d ${output_folder} ]; then
    echo " * The output folder ${output_folder} does already exist. Removing..."
    rm -r ${output_folder}
fi
mkdir ${output_folder}
if [ -d ${temp_folder} ]; then
    echo " * The temp folder ${temp_folder} does already exist. Removing..."
    rm -r ${temp_folder}
fi
mkdir ${temp_folder}
echo " * If the file ${output_folder}.length.all exists already it will be cleared."
echo -n "" > "$(basename ${output_folder}.length.all)"


# Loop for each winning structure
molecule_counter=1
collection_counter=1
tranch_counter=1
while read -r line; do
    read -r -a array <<< "$line"
    collection="${array[0]}"
    tranch="${collection/_*}"
    collection_no=${collection/*_}
    collection_no="$(printf "%05.f" "${collection_no}")"
    molecule=${array[1]}
    collection_subno="1"
    collection_subno_padded="001"
    collection_no_new=${collection_no}-${collection_subno_padded}
    collection_new="${tranch}_${collection_no_new}"
    # Determining the collection_* variables
    while true; do
        if [ ! -d  "${output_folder}/${collection_new}/" ]; then
            mkdir ${output_folder}/${collection_new}
            break
        else
            no_of_files=$(ls ${output_folder}/${collection_new} | wc -l)
            if [ "${no_of_files}" -lt "${ligands_per_collection}" ]; then
                break
            else
                if [ "${collection_subno}" -eq "999" ]; then
                    echo "Reached maximum supported collection number 999. Exiting..."
                    exit 1
                else
                    collection_subno=$((collection_subno + 1))
                    collection_subno_padded="$(printf "%03.f" "${collection_subno}")"
                    collection_no_new=${collection_no}-${collection_subno_padded}
                    collection_new="${tranch}_${collection_no_new}"
                fi
            fi
        fi
    done
    echo -e "\n *** Adding the molecule ${molecule} to the new collection ${collection_new} ***"
    if [ "${pdbqt_folder_format}" == "tar_tar" ]; then
        mkdir ${temp_folder}/${tranch}
        cd ${temp_folder}/${tranch}
        tar -xvf ../../${pdbqt_input_folder}/${tranch}.tar ${collection_no}.pdbqt.gz.tar || true
        cd ../..
        tar -xOf ${temp_folder}/${tranch}/${collection_no}.pdbqt.gz.tar ${molecule}.pdbqt.gz > ${output_folder}/${collection_new}/${molecule}.pdbqt.gz || true
        rm -r ${temp_folder}/${tranch}
    elif [ "${pdbqt_folder_format}" == "sub_tar" ]; then
        tar -xOf ${pdbqt_input_folder}/${tranch}/${collection_no}.pdbqt.gz.tar ${molecule}.pdbqt.gz > ${output_folder}/${collection_new}/${molecule}.pdbqt.gz || true
    else 
        echo -e "Error: The argument pdbqt_folder_format has an unsupported value: ${pdbqt_folder_format}. Supported are sub_tar and tar_tar"
    fi
done < ${ligand_file}
echo -e "\n *** The preparation of the intermediate folders has been completed ***"

echo -e "\n *** Starting the preparation of the length.all file ***"
for folder in $(ls ${output_folder}); do
    if [ -f ${output_folder}.length.all ] ; then
        echo " The file ${output_folder}.length.all does exist already. Skipping the preparation of this file"
        break
    fi
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
    tar -cf ${collection_no}.pdbqt.gz.tar --wildcards * || true
    echo -e " *** Adding the tar archive of collection ${folder} to the tranch-archive ${tranch}.tar ***"
    tar -rf ../${tranch}.tar ${collection_no}.pdbqt.gz.tar || true
    cd ../../
    #rm -r ${output_folder}/${folder}
done
echo -e "\n *** The preparation of the tranch-archives has been completed ***"

echo -e "\n *** The preparation of the new collections has been completed ***"

