#!/usr/bin/env bash

usage="vfvs_pp_prepare_docking_poses.sh <results folder> <folder_format> <ranking file> <output folder> <mode>

Possible folder formats (for the results as well as pdbqt folders):
    sub: for VFVS version < 8.0
    tar: vfvs version >= 8.0
    meta_tranche: Use this format if the output files are stored on the tranche level. This is the case when the setting 'outputfiles_level' was set to 'tranche' in the control file during the workflow.
    meta_collection: Use this format if the output files are stored on the collection level. This is the case when the setting 'outputfiles_level' was set to 'collection' in the control file during the workflow.

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
results_folder=${1}
format=${2}
ranking_file=${3}
output_folder=${4}
mode=${5}

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
    tranche=${collection/_*}
    collection_no=${collection/*_}
#    name2_padded=$(printf "%05.f" ${collection:5})
    echo -e "\n *** Preparing structure ${molecule} ***"
    if [ -d ${output_folder}/${tranche}/${collection_no}/${molecule} ]; then
        echo " * The directory for this ligand already exists. Skipping this ligand."
        continue
    fi
    mkdir -p ${output_folder}/${tranche}/${collection_no}/${molecule}
    cd ${output_folder}/${tranche}/${collection_no}/${molecule}

    if [ "${format}" == "tar" ]; then
        if ! tar -xvf ../../../../${results_folder}/${tranche}.tar --wildcards "${tranche}/${collection_no}*tar"; then
            if ! tar -xvf ../../../../${results_folder/complete/incomplete}/${tranche}.tar --wildcards "${tranche}/${collection_no}*tar"; then
                echo " * Error, skipping this ligand"
                cd ../../../../
                continue
            fi
        fi
        if ! tar -xvf ${tranche}/${collection_no}.gz.tar --wildcards "${molecule}*"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
    elif [ "${format}" == "sub" ]; then
        if ! tar -xvf ../../../../${results_folder}/${tranche}/${collection_no}.gz.tar --wildcards "${molecule}_replica*"; then
            if ! tar -xvf ../../../../${results_folder/complete/incomplete}/${tranche}/${collection_no}.gz.tar --wildcards "${molecule}_replica*"; then
                echo " * Error, skipping this ligand"
                cd ../../../../
                continue
            fi
        fi
    elif [ "${format}" == "meta_tranche" ]; then
        metatranche=${tranche:0:2}
        if ! tar -xvf ../../../../${results_folder}/${metatranche}/${tranche}.tar --wildcards "${tranche}/${collection_no}.tar.gz"; then
            if ! tar -xvf ../../../../${results_folder/complete/incomplete}/${metatranche}/${tranche}.tar --wildcards "${tranche}/${collection_no}.tar.gz"; then
                echo " * Error, skipping this ligand"
                cd ../../../../
                continue
            fi
        fi
        if ! tar -xvf ${tranche}/${collection_no}.tar.gz --wildcards "${collection_no}/${molecule}_replica*"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
        mv ${collection_no}/*pdbqt ./
    elif [ "${format}" == "meta_collection" ]; then
        metatranche=${tranche:0:2}
        if ! cp ../../../../${results_folder}/${metatranche}/${tranche}/${collection_no}.tar.gz ./; then
            if ! cp ../../../..${results_folder/complete/incomplete}/${metatranche}/${tranche}/${collection_no}.tar.gz ./; then
                echo " * Error, skipping this ligand"
                cd ../../../../
                continue
            fi
        fi
        mkdir ${tranche}/
        mv ${collection_no}.tar.gz ${tranche}/
        if ! tar -xvf ${tranche}/${collection_no}.tar.gz --wildcards "${collection_no}/${molecule}_replica*"; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
        mv ${collection_no}/*pdbqt ./
    fi

    if [[ ! "${format}" == "meta"* ]]; then
        if ! gunzip *gz; then
            echo " * Error, skipping this ligand"
            cd ../../../../
            continue
        fi
    fi
    for file in $(ls *replica*pdbqt); do
        replica=${file/*_}
        replica=${replica/.*}
        mkdir -p ${replica}
        mv $file ${replica}/${tranche}_${collection_no}_${file}
    done
    if [[ "${format}" == "tar" ]] || [[ "${format}" == "sub" ]]; then
        rm *tar || true        
    fi

    rm -r ${tranche}*
    for replica_folder in $(ls -d replica*); do
        cd ${replica_folder}
        mv *pdbqt docking.out.pdbqt
        obabel -m -ipdbqt docking.out.pdbqt -opdb -O "${molecule}.rank-.pdb"
        energy=$(obenergy "${molecule}.rank-1.pdb" | tail -n 1 | awk '{print $4}')
        obabel -m -ipdbqt docking.out.pdbqt -osdf -O "${molecule}.rank-.sdf"
        obabel -ipdbqt docking.out.pdbqt -osdf -O "${molecule}.rank-all.sdf"
        echo "${tranche}_${collection} ${molecule} ${replica_folder} ${energy}" >> "${molecule}.rank-1.energy"
        echo "${molecule} ${energy} ${replica_folder}" >> ../../../../../${ranking_file}.energies
        cd ..
    done
    cd ../../../../
done < ${ranking_file}

# Creating a CSV file of the energy file
awk '{print $1","$2}' ${ranking_file}.energies | sort -u -k 1,1 -t "," | sed "1s/^/compoundid,energy\n/g" >  ${ranking_file}.energies.uniq.csv


# Extracting the plain docking poses
vfvs_pp_extract_best_poses.sh ${ranking_file} ${output_folder} ${output_folder}.plain

echo -e " *** The preparation of the structures has been completed ***"

