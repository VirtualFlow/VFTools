#!/usr/bin/env bash

usage="vfvs_prepare_newcollections.sh <ligand file> <pdbqt_input_folder> <tranch name> <ligands_per_collection> <output folder>

Creates new collections from pdbqt files stored in a single folder. In the output folder two files will be stored: the tranch-tar-archive <tranch name>.tar and the corresponding length file <tranch name>.all.length

ligand file: list with the ligand names with file name extension.
pdbqt input folder: all the ligands in files names <ligand name>.pdbqt
tranch name: No underscore or spaces in the name

The total number of molecules needs to be less than <ligands per collection> * 100000  because the maximum number of collections is 99999 because the collection number has 5 digits."

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
pdbqt_input_folder=${2%/}
tranch_name=${3}
ligands_per_collection=${4}
output_folder=${5%/}
temp_folder=/tmp/${output_folder}.${pdbqt_input_folder}

# Checking the tranch-name
if [[ "${tranch_name}" == *"_"* ]]; then
    echo -n "\n * ERROR: Tranchname contains an underscore, which is not allowed. Exiting...\n\n"
    exit 1
elif [[ "${tranch_name}" == *" "* ]]; then    
    echo -n "\n * ERROR: Tranchname contains a space, which is not allowed. Exiting...\n\n"
    exit 1
fi

# Preparing required folders and files
mkdir -p ${output_folder}
if [ -d ${temp_folder} ]; then
    echo " * The temp folder ${temp_folder} does already exist. Removing..."
    rm -r ${temp_folder}
fi
mkdir -p ${temp_folder}
echo " * If the file ${output_folder}.length.all exists already it will be cleared."
echo -n "" > "${output_folder}/${tranch_name}.length.all"

# Loop for each winning structure
molecule_counter=1
collection_counter=1
while read -r line; do
    read -r -a array <<< "$line"
    molecule_file=${line}
    collection_no="$(printf "%05.f" ${collection_counter})"
    collection="${tranch_name}_${collection_no}"
    echo -e "\n *** Adding the file ${molecule_file} to collection ${collection} ***"
    if [ ! -d  "${temp_folder}/${collection}/" ]; then
        mkdir -p ${temp_folder}/${collection}
    fi
    gzip < ${pdbqt_input_folder}/${molecule_file} > ${temp_folder}/${collection}/${molecule_file}.gz || true
    molecule_counter=$((molecule_counter+1))
    if [ "${molecule_counter}" -gt "${ligands_per_collection}" ]; then
        collection_counter=$((collection_counter+1))
        molecule_counter=1
    fi
done < ${ligand_file}
echo -e "\n *** The preparation of the intermediate folders has been completed ***"

echo -e "\n *** Starting the preparation of the length.all and length.todo files ***"
for folder in $(ls ${temp_folder}); do
    echo -e "\n *** Adding the collection ${folder} to the length.all file ***"
    length=$(ls -A ${temp_folder}/${folder} | wc -l)
    echo "${folder} ${length}" >> ${output_folder}/${tranch_name}.length.all
    echo "${folder}.pdbqt.gz.tar" >> ${output_folder}/${tranch_name}.todo.all
done
echo -e "\n *** The preparation of the length.all file has been completed ***"



echo -e "\n *** Starting the preparation of the tar archives ***"
for folder in $(ls ${temp_folder}); do
    cd ${temp_folder}/${folder}
    tranch=${folder/_*}
    collection_no=${folder/*_}
    echo -e "\n *** Creating the tar archive for collection ${folder} ***"
    tar -cf ${collection_no}.pdbqt.gz.tar --wildcards *
    echo -e " *** Adding the tar archive of collection ${folder} to the tranch-archive ${tranch}.tar ***"
    tar -rf ../${tranch}.tar ${collection_no}.pdbqt.gz.tar 
    cd ${OLDPWD}
done

mv ${temp_folder}/*tar ${output_folder}/
rm -r ${temp_folder}

echo -e "\n *** The preparation of the tranch-archives has been completed ***"

echo -e "\n *** The preparation of the new collections has been completed ***\n\n"

