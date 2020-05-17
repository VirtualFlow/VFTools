#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_pp_all.sh <smiles_collection_folder> <smiles_collection_folder_format> <database_type> <dwar_compound_count> <poses_compound_count>

This script has to be run in the root folder of the VirtualFlow installtion directory.

This script post-processes the virtual screening data, and stores the post-processsed files in the folder pp (postprocessing). More specifically, it does the following:
    1) It prepares the full ranking of all docking compounds for each docking scenario, and stores it in the folder pp/firstposes.
    2) It exctracts and reformats the docking poses of the best <poses_compound_count> compounds, and stores it in the folder pp/docking_poses.
    3) It prepares the input files for DataWarrior for the best <dwar_compound_count> compounds, and stores it in the folder pp/dwar.

The preparation of the docking poses when the receptor was allowed to be flexible might not work perfectly yet.

Options:

    <smiles_collection_folder>:
      * Relative path to the SMILES collection folder

    <smiles_collection_folder_format>:
      * tranche: smiles_collection_folder/<tranch>/<collection>.smi
      * meta_tranche: smiles_collection_folder/<metatranch>/tranch.smi

    <database_type>:
      * ZINC15: Prepares also the vendor availability according to the ZINC library
      * Other: No preparation of vendor availability

    <dwar_compound_count>: Number of dwar compounds
    <poses_compound_count>: Number of compounds for which the docking poses should be prepared"

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0
fi

if [[ "$#" -ne "5" ]]; then
   echo -e "\nWrong number of arguments. Exiting.\n"
   echo -e "${usage}\n\n"
   exit 1
fi

if ! [[ -d "tools" ]]; then
   echo -e "\nThis script has to be run in the root folder of VirtualFlow Exiting.\n"
   exit 1
fi

# Standard error response
error_response_nonstd() {
    echo "Error was trapped which is a nonstandard error."
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})"
    echo "Error on line $1"
    echo
    pkill 0 &>/dev/null
    exit 1
}
#trap 'error_response_nonstd $LINENO' ERR

# Variables
smiles_collection_folder="$1"
smiles_collection_folder_format="$2"
database_type="$3"
dwar_compound_count="$4"
poses_compound_count="$5"

# First poses
mkdir -p pp/firstposes
cd pp/firstposes
vfvs_pp_ranking_all.sh ../../output-files/complete/ 1 meta_collection
cd ..

#dwar
mkdir -p dwar
cd dwar
for folder in $(ls ../firstposes/); do
    mkdir -p $folder/docking_scores/;
    head -n $dwar_compound_count ../firstposes/$folder/firstposes.all.minindex.sorted.clean > $folder/docking_scores/top$dwar_compound_count.original
    cd $folder
    vfvs_pp_prepare_dwar.sh ../../$smiles_collection_folder/ $smiles_collection_folder_format $database_type
    cd ..
done
cd ..

# docking_poses
mkdir -p docking_poses
cd docking_poses
for folder in $(ls ../firstposes); do
    head -n $poses_compound_count ../firstposes/$folder/firstposes.all.minindex.sorted.clean > $folder.top$poses_compound_count
    vfvs_pp_prepare_dockingposes.sh ../../output-files/complete/$folder/results meta_collection $folder.top$poses_compound_count $folder.top$poses_compound_count.poses overwrite
done
cd ..

# Finalization
cd ..