#!/usr/bin/env bash

usage="vfvs_pp_firstposes_prepare_vina.sh <filter summary file> <ranking structures folder> <output folder> <number of compounds>"

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
if [ "$#" -ne "4" ]; then
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
ranking_file=${1}
structures_folder=${2}
output_folder=${3}
number_of_compounds=${4}

# Preparing required folders and files
if [ -d ${output_folder} ]; then
    echo " * The output folder ${output_folder} does already exist. Removing..."
    rm -r ${output_folder}
fi
mkdir -p ${output_folder}/pdb_h/first-poses
mkdir -p ${output_folder}/pdbqt/first-poses
mkdir -p ${output_folder}/pdbqt/all-poses
cat /dev/null > ${output_folder}/pdbqt/first-poses/all.pdbqt

# Loop for each winning structure
counter=0
while read -r line; do
    read -r -a array <<< "$line"
    echo $line
    collection="${array[0]}"
    molecule=${array[1]}
    echo -e "\n * Prepraring structure ${molecule}"
    vina_output_file=${output_folder}/pdbqt/all-poses/${collection}_${molecule}.vina.results.pdbqt
    cp ${structures_folder}/${collection}_${molecule}/*vina* ${vina_output_file}
    counter=$((counter + 1))
    if [ "${counter}" -eq "${number_of_compounds}" ]; then
        break
    fi
    # vina.all file
    grep -h -m 1 -B 100000 ENDMDL ${vina_output_file} | sed "s/MODEL 1/MODEL $((counter + 1))/" >> ${output_folder}/pdbqt/first-poses/all.pdbqt
    grep -h -m 1 -B 100000 ENDMDL ${vina_output_file} >> ${output_folder}/pdbqt/first-poses/${collection}_${molecule}.pdbqt
    obabel -p 7 -ipdbqt ${output_folder}/pdbqt/first-poses/${collection}_${molecule}.pdbqt -opdb -O ${output_folder}/pdb_h/first-poses/${collection}_${molecule}.pdb
    counter=$((counter+1))
done < ${ranking_file} 


echo -e "\n * The vina results files have all been copied.\n\n"

