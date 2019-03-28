#!/usr/bin/env bash

usage="vfvs_pp_firstposes_prepare_ranking_structures.sh <pdbqt folder> <results folder> <folder_format> <ranking file> <output folder> <mode>

Possible folder formats (for the results as well as pdbqt folders):
    sub: for VFVS version < 8.0
    tar: vfvs version >= 8.0

The <ranking file> needs to contain the collection in the first column and the compound name in the second column.

Modes:
    continue: continues previous runs (e.g. after an error)
    overwrite: deletes existing output files and folders
"

#Example usage: vfvs_pp_firstposes_prepare_ranking_structures_v10.sh ../${pdbqt_folder} ../${input_folder}/results/ tar firstposes.all.new.ranking.${no_highest_ranking_compounds} firstposes.all.new.ranking.${no_highest_ranking_compounds}.structures continue

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
if [ "$#" -ne "6" ]; then
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
pdbqt_input_folder=${1}
results_folder=${2}
format=${3}
ranking_file=${4}
output_folder=${5}
mode=${6}

# Preparing required folders and files
if [ "${mode}" = "overwrite" ]; then
    if [ -d ${output_folder} ]; then
        echo " * The output folder ${output_folder} does already exist. Removing..."
        rm -r ${output_folder}
    fi

    if [ -f ${ranking_file}.energies ]; then
        echo " * The file ${ranking_file}.energies does already exist. Deleting..."
        echo -n "" > "${ranking_file}.energies"
    fi
fi
mkdir -p ${output_folder}

# Loop for each winning structure
while read -r line; do
    read -r -a array <<< "$line"
    collection="${array[0]}"
    #molecule=${array[1]/_*} # removing replicas
    molecule=${array[1]}
    tranch=${collection/_*}
    collection_no=${collection/*_}
#    name2_padded=$(printf "%05.f" ${collection:5})
    echo -e "\n *** Preparing structure ${molecule} ***"
    if [ -d ${output_folder}/${tranch}/${collection_no}/${molecule} ]; then
        echo " * The directory for this ligand already exists. Skipping this ligand."
        continue
    fi
    mkdir -p ${output_folder}/${tranch}/${collection_no}/${molecule}
    cd ${output_folder}/${tranch}/${collection_no}/${molecule}
    if [ "${format}" == "tar" ]; then
        tar -xvf ../../../../${pdbqt_input_folder}/${tranch}.tar --wildcards "${collection_no}*tar"
        tar -xvf ${collection_no}.pdbqt.gz.tar --wildcards "${molecule}*"
    elif [ "${format}" == "sub" ]; then
        collection_no_padded=$(printf "%05d" ${collection_no})
        tar -xvf ../../../../${pdbqt_input_folder}/${tranch}/${collection_no_padded}.pdbqt.gz.tar --wildcards "${molecule}*"
    fi
    gunzip *.gz
    mv ${molecule}.pdbqt ${molecule}.original.pdbqt

    obabel -ipdbqt ${molecule}.original.pdbqt -opdb -O ${molecule}.original.pdb
    if [ "${format}" == "tar" ]; then
        if ! tar -xvf ../../../../${results_folder}/${tranch}.tar --wildcards "${tranch}/${collection_no}*tar"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
        if ! tar -xvf ${tranch}/${collection_no}.gz.tar --wildcards "${molecule}*"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
    elif [ "${format}" == "sub" ]; then
        if ! tar -xvf ../../../../${results_folder}/${tranch}/${collection_no}.gz.tar --wildcards "${molecule}*"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
    fi
    if ! gunzip *gz; then
        echo " * Error, skipping this ligand"
        cd ../../../../
        continue
    fi
    for file in $(ls *replica*pdbqt); do
        replica=${file/*_}
        replica=${replica/.*}
        mkdir -p ${replica}
        mv $file ${replica}/${tranch}_${collection_no}_${file}
    done
    rm *tar
    rm -r ${tranch}
    for replica_folder in $(ls -d replica*); do
        cd ${replica_folder}
        mv *pdbqt docking.out.pdbqt
        obabel -m -ipdbqt docking.out.pdbqt -opdb -O "${molecule}.rank-.pdb"
        energy=$(obenergy "${molecule}.rank-1.pdb" | tail -n 1 | awk '{print $4}')
        obabel -m -ipdbqt docking.out.pdbqt -osdf -O "${molecule}.rank-.sdf"
        obabel -ipdbqt docking.out.pdbqt -osdf -O "${molecule}.rank-all.sdf"
        echo "${tranch}_${collection} ${molecule} ${replica_folder} ${energy}" >> "${molecule}.rank-1.energy"
        printf "%s  %s %10s  %s\n" "${tranch}_${collection_no}" "${molecule}" "${energy}" "${replica_folder}" >> ../../../../../${ranking_file}.energies
        cd ..
    done
    cd ../../../../
done < ${ranking_file}

echo -e " *** The preparation of the structures has been completed ***"

