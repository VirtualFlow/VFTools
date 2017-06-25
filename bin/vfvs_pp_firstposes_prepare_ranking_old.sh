#!/usr/bin/env bash
set -x
usage="vfvs_pp_firstposes_prepare_ranking_structures.sh <pdbqt folder> <results folder> <folder_format> <ranking file> <output folder>

Possible folder formats:
    sub for VFVS version < 8.0
    tar: vfvs version >= 8.0
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
pdbqt_input_folder=${1}
results_folder=${2}
format=${3}
ranking_file=${4}
output_folder=${5}

# Preparing required folders and files
if [ -d ${output_folder} ]; then
    echo " * The output folder ${output_folder} does already exist. Removing..."
    rm -r ${output_folder}
fi
mkdir -p ${output_folder}
echo " * If the file $(basename ${ranking_file} list).energies exists already it will be cleared."
echo -n "" > "$(basename ${ranking_file} list).energies"
echo " *** Preparing the tmp folder ***"
mkdir -p tmp

# Loop for each winning structure
while read -r line; do
    read -r -a array <<< "$line"
    collection="${array[0]}"
    molecule=${array[1]}
    tranch=${collection/_*}
    collection_no=${collection/*_}
#    name2_padded=$(printf "%05.f" ${collection:5})
    echo -e "\n *** Preparing structure ${molecule} ***"
    mkdir -p ${output_folder}/${tranch}/${collection}/${molecule}
    cd tmp
    tar -xvf ../${results_folder}/${tranch}.tar --wildcards ${tranch}/${collection_no}*
    tar -xvf ${collection}.pdbqt.gz.tar --wildcards ${molecule}.* || true
    tar -xvf ../${pdbqt_input_folder}/${tranch}.tar --wildcards ${collection}*tar -C tmp
    tar -xvf ${tranch}/${collection}.gz.tar --wildcards ${molecule}* -C tmp
    gunzip tmp/*.gz 
    mv * ../ ${output_folder}/${tranch}/${collection}/${molecule}/  || true
    cd ../ ${output_folder}/${tranch}/${collection}/${molecule}/ 
#obabel -m -ipdbqt vina.out.results.pdbqt -opdb -O "${molecule}.rank-.pdb"
#    obabel -ipdbqt ${molecule}.original.pdbqt -opdb -O ${molecule}.original.pdb
#    obenergy ${molecule}.rank-1.pdb
#    energy=$(obenergy "${molecule}.rank-1.pdb" | tail -n 1 | awk '{print $4}')
    echo "${tranch}_${collection} ${molecule} ${energy}" >> "${molecule}.rank-1.energy"
    for file in *; do 
        mv $file ${name1}_${name2}_${molecule}.{file}
    done
    cd ../../../../
    printf "%-10s %-10s %-15s\n" "${name1}_${name2}" "${molecule}" "${energy}" >> "$(basename ${ranking_file} list).energies"
done < ${ranking_file}

echo -e " *** Deleting the tmp folder *** "
rm -r tmp
