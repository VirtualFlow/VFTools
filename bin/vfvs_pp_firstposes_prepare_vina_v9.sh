#!/usr/bin/env bash

usage="vfvs_pp_first_poses_prepare_vina.sh <filter summary file> <ranking structures folder> <output folder> <number of compounds>"

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
ligand_residue_name=LIG

# Preparing required folders and files
if [ -d ${output_folder} ]; then
    echo " * The output folder ${output_folder} does already exist. Removing..."
    rm -r ${output_folder}
fi

mkdir -p ${output_folder}/pdb_h/first_poses
mkdir -p ${output_folder}/pdbqt/all_poses
mkdir -p ${output_folder}/pdbqt/first_poses
mkdir -p ${output_folder}/sdf_h/first_poses
cat /dev/null > ${output_folder}/pdbqt/first_poses/all.${number_of_compounds}.pdbqt
set +x
# Loop for each winning structure
counter=0
while read -r line; do
    read -r -a array <<< "$line"
    collection="${array[0]}"
    tranch=${collection/_*}
    collection_no=${collection/*_}
    molecule=${array[1]}
    echo -e "\n * Prepraring structure ${molecule}"
    for replica in $(ls -d ${structures_folder}/${tranch}/${collection_no}/${molecule}/replica* | awk -F '/' '{print $NF}'); do
        vina_output_file_basename=${collection}_${molecule}_${replica}
        cp ${structures_folder}/${tranch}/${collection_no}/${molecule}/${replica}/docking.out.pdbqt ${output_folder}/pdbqt/all_poses/${vina_output_file_basename}.pdbqt
        # Correting the pdbqt file
        sed -i "s/${ligand_residue_name} ...../${ligand_residue_name} L   1/g" ${output_folder}/pdbqt/all_poses/${vina_output_file_basename}.pdbqt
        sed -i "s/HSE/HIS/g" ${output_folder}/pdbqt/all_poses/${vina_output_file_basename}.pdbqt
        sed -i "s/CD  ILE/CD1 ILE/g" ${output_folder}/pdbqt/all_poses/${vina_output_file_basename}.pdbqt
        # Getting the first pose only
        grep -h -m 1 -B 100000 ENDMDL ${structures_folder}/${tranch}/${collection_no}/${molecule}/${replica}/docking.out.pdbqt > ${output_folder}/pdbqt/first_poses/${vina_output_file_basename}.pdbqt
                
        # vina.all file
        echo "REMARK The compound below is ${molecule} of collection ${collection}" >> ${output_folder}/pdbqt/first_poses/all.${number_of_compounds}.pdbqt
        grep -h -m 1 -B 100000 ENDMDL  ${output_folder}/pdbqt/all_poses/${vina_output_file_basename}.pdbqt | sed "s/MODEL 1/MODEL   $((counter + 1))/" >> ${output_folder}/pdbqt/first_poses/all.${number_of_compounds}.pdbqt
        if ! obabel -p 7 -ipdbqt ${output_folder}/pdbqt/first_poses/${vina_output_file_basename}.pdbqt -opdb -O ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb; then
            echo " * Error during obabel conversion of the file ${vina_output_file_basename}.pdbqt to ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb"
        fi
        if !  obabel -p 7 -ipdbqt ${output_folder}/pdbqt/first_poses/${vina_output_file_basename}.pdbqt -osdf -O ${output_folder}/sdf_h/first_poses/${vina_output_file_basename}.sdf; then
            echo " * Error during obabel conversion of the file ${vina_output_file_basename}.pdbqt to ${output_folder}/sdf_h/first_poses/${vina_output_file_basename}.sdf"
        fi
        grep ATOM ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb | sed 's/LIG../LIG L/g' > ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb.tmp # just for trying a bit, later scripts will do it better
        mv ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb.tmp ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb
        echo "END" >> ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb
        cat ${output_folder}/pdb_h/first_poses/${vina_output_file_basename}.pdb >> ${output_folder}/pdb_h/first_poses/all.${number_of_compounds}.pdb
        echo "REMARK The compound below is ${molecule} of collection ${collection}" >> ${output_folder}/pdbqt/first_poses/all.${number_of_compounds}.pdb
    done
    counter=$((counter + 1))
    if [ "${counter}" -eq "${number_of_compounds}" ]; then
        break
    fi
done < ${ranking_file} 


echo -e "\n * The vina results files have all been prepared.\n\n"

