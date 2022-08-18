#!/usr/bin/env bash

usage="vfvs_prepare_newcollections.sh <ligand file> <pdbqt_input_folder> <pdbqt_folder_format> <ligands_per_collection> <output folder>

Requires a ligand file with the first column the collection name and the second column the ligand name.

pdbqt_folder_format. Possible values: tar_tar, meta, sub_tar, hash_metatranche
sub_tar is supported by vfvs_prepare_newcollections2.sh
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
#if [ -d ${output_folder}.tmp2 ]; then
#    echo " * The output folder ${output_folder}.tmp2 does already exist. Removing..."
#    rm -r ${output_folder}.tmp2
#fi
#mkdir -p ${output_folder}.tmp2
#if [ -d ${temp_folder} ]; then
#    echo " * The temp folder ${temp_folder} does already exist. Removing..."
#    rm -r ${temp_folder}
#fi
mkdir -p ${temp_folder}


# Loop for each winning structure
ligand_counter=1
collection_counter=1
tranche_counter=1
cd ${temp_folder}
#while false; do
while read -r line; do
    line="${line//,/ }"
    read -r -a array <<< "$line"
    old_collection=${collection}
    old_tranche=${tranche}

    collection_subno="1"
    collection_subno_padded="0001"

    if [ "${pdbqt_folder_format}" == "hash_metatranche" ]; then
        collection_ligand="${array[0]}"
        ligand=$(basename ${collection_ligand})
        ligand=$(basename ${collection_ligand/.*})
        collection=${collection_ligand%\/*}
        collection_no="$(echo $collection | awk -F '/' '{print $NF}')"
        tranche="$(echo $collection | awk -F '/' '{print $(NF-1)}')"
    else
        collection="${array[0]}"
        ligand="${array[1]}"
        metatranche="${tranche:0:2}"
        tranche="${collection/_*}"
        collection_no=${collection/*_}
        #collection_no="$(printf "%05.f" "${collection_no}")"
    fi

    collection_no_new=${collection_no}-${collection_subno_padded}
    collection_new="${tranche}_${collection_no_new}"

    # Checking if we have a new collection
    if [ ! "${old_collection}" == "${collection}" ]; then
        new_collection="true"
    else
        new_collection="false"
    fi

    # Determining the collection_* variables
    while true; do
        if [ ! -d  "../${output_folder}.tmp2/${collection_new}/" ]; then
            mkdir -p ../${output_folder}.tmp2/${collection_new}
            break
        else
            no_of_files=$(ls ../${output_folder}.tmp2/${collection_new} | wc -l)
            if [ "${no_of_files}" -lt "${ligands_per_collection}" ]; then
                break
            else
                if [ "${collection_subno}" -eq "9999" ]; then
                    echo "Reached maximum supported collection number 9999. Exiting..."
                    exit 1
                else
                    collection_subno=$((collection_subno + 1))
                    collection_subno_padded="$(printf "%04.f" "${collection_subno}")"
                    collection_no_new=${collection_no}-${collection_subno_padded}
                    collection_new="${tranche}_${collection_no_new}"
                fi
            fi
        fi
    done
    echo -e "\n *** Adding the ligand ${ligand} to the collection ${collection_new} ***"
    if [ "${pdbqt_folder_format}" == "tar_tar" ]; then
        mkdir ${tranche}
        cd ${tranche}
        tar -xvf ../../${pdbqt_input_folder}/${tranche}.tar ${collection_no}.pdbqt.gz.tar || true
        cd ../
        tar -xOf ${tranche}/${collection_no}.pdbqt.gz.tar ${ligand}.pdbqt.gz > ../${output_folder}.tmp2/${collection_new}/${ligand}.pdbqt.gz || true
        rm -r ${tranche}
    elif [ "${pdbqt_folder_format}" == "sub_tar" ]; then
        tar -xOf ${pdbqt_input_folder}/${tranche}/${collection_no}.pdbqt.gz.tar ${ligand}.pdbqt.gz > ../${output_folder}.tmp2/${collection_new}/${ligand}.pdbqt.gz || true
    elif [ "${pdbqt_folder_format}" == "meta" ]; then
        if [ "${new_collection}" == "true" ]; then
            echo
            echo
            echo " * Extracting collection ${collection}"
            rm -r ${old_tranche} &>/dev/null || true
            tar -xf ../${pdbqt_input_folder}/${metatranche}/${tranche}.tar ${tranche}/${collection_no}.tar.gz || true
            cd ${tranche}
            tar -xzf ${collection_no}.tar.gz || true
            cd ..
        fi
        cp ${tranche}/${collection_no}/${ligand}.pdbqt ../${output_folder}.tmp2/${collection_new}/${ligand}.pdbqt || true
    elif [ "${pdbqt_folder_format}" == "hash_metatranche" ]; then
        if [ "${new_collection}" == "true" ]; then
            echo " * Extracting collection ${collection}"
            rm -r ${collection} &>/dev/null || true
            tar -xzf ../${pdbqt_input_folder}/${collection}.tar.gz || true
        fi
        cp ${collection_no}/${ligand}.pdbqt ../${output_folder}.tmp2/${collection_new}/${ligand}.pdbqt || true
    else
        echo -e "Error: The argument pdbqt_folder_format has an unsupported value: ${pdbqt_folder_format}. Supported are sub_tar and tar_tar"
    fi
done < "../${ligand_file}"
cd ..
rm -r ${output_folder}.tmp/ || true
echo -e "\n *** The preparation of the intermediate folders has been completed ***"

echo -e "\n *** Starting the preparation of the length.all file ***"
echo " * If the file ${output_folder}.length.all exists already it will be cleared."
echo -n "" >${output_folder}.length.all
for folder in $(ls ${output_folder}.tmp2); do
    echo -e "\n *** Adding the collection ${folder} to the length.all file ***"
    cd ${output_folder}.tmp2/${folder}
    length=$(ls -A | wc -l)
    echo "${folder} ${length}" >> ../../${output_folder}.length.all
    cd ../..
done
echo -e "\n *** The preparation of the length.all file has been completed ***"

echo -e "\n *** Starting the preparation of the tar archives ***"
cd ${output_folder}.tmp2
for folder in $(ls); do
    tranche=${folder/_*}
    collection_no=${folder/*_}
    if [[ ! -f ${folder}/${tranche}.tar.gz && ! "${folder}" == "${tranche}" ]]; then

        mv ${folder} ${tranche}
        cd ${tranche}
        mkdir ${collection_no}
        mv *pdbqt ${collection_no}
        echo -e "\n *** Creating the tar archive for collection ${folder} ***"
        tar -czf ${collection_no}.tar.gz ${collection_no} || true
        echo -e " *** Adding the tar archive of collection ${folder} to the tranche-archive ${tranche}.tar ***"
        mkdir -p ../../${output_folder}/${tranche:0:2}/
        tar -rf ../../${output_folder}/${tranche:0:2}/${tranche}.tar -C .. ${tranche}/${collection_no}.tar.gz || true
        cd ..
        rm -r ${tranche}
    else
        echo "* Already existing, skipping this collection"
    fi
done
cd ..
echo -e "\n *** The preparation of the tranche-archives has been completed ***"

# Finalization

echo -e "\n *** The preparation of the new collections has been completed ***"
