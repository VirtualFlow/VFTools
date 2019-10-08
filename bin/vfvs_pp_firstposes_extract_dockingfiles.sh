#!/usr/bin/env bash

usage="vfvs_pp_firstposes_extract_dockingfiles.sh <input compound file> <results folder> <output folder>


In the compound file, the first column has to be the collection, the second column has to be the compound ID"

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
    echo -e "\n $usage\n\n"
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
echo "                      Extracting the structures                      "
echo "*********************************************************************"
echo

# Variables
input_file=${1}
results_folder=${2}
output_folder=${3}

# Preparing required folders and files
mkdir -p ${output_folder}

# Loop for each winning structure
while read -r line; do
    read -r -a array <<< "$line"
    collection="${array[0]}"
    molecule=${array[1]} # removing replicas
    tranch=${collection/_*}
    collection_no=${collection/*_}

    echo -e "\n *** Preparing structure ${molecule} ***"
    if [ -d ${output_folder}/${tranch}/${collection_no}/${molecule} ]; then
        echo " * The directory for this ligand already exists. Skipping this ligand."
        continue
    fi
    mkdir -p ${output_folder}/${tranch}/${collection_no}/${molecule}
    cd ${output_folder}/${tranch}/${collection_no}/${molecule}
   
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
        energy=$(obenergy "${molecule}.rank-1.pdb" | tail -n 1 | awk '{print $4}')
        echo "${tranch}_${collection} ${molecule} ${replica_folder} ${energy}" >> "${molecule}.rank-1.energy"
        ad_pp_vina_curate-one-pose-RFL.sh receptor.rigidres.pdbqt docking.out.pdbqt vina.out.firstpose         
        cd ..
    done
    cd ../../../../
done < ${input_file}

echo -e " *** The extraction of the docking files has been completed ***"

