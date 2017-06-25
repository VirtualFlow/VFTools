#!/bin/bash

#Checking the input arguments
usage="Usage: vf_pp_firstposes.sh <input root folder> <pdbqt_folder> <first_column_id> <last_column_id> <no of highest ranking compounds>

For each docking the rankings are and the structure files are prepared.

The <input root folder> is the output-folder/complete folder of the original workflow.
The command has to be run in the desired output folder.
All path names have to be relative to the working directory."

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "5" ]]; then
   echo -e "\nWrong number of arguments. Exiting.\n"
   echo -e "${usage}\n\n"
   exit 1
fi

# Standard error response 
error_response_nonstd() {
    echo "Error was trapped which is a nonstandard error."
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})"
    echo "Error on line $1"
    echo
    exit 1
}
trap 'error_response_nonstd $LINENO' ERR

# Variables
input_folder="$1"
pdbqt_folder="$2"
first_column_id=$3
last_column_id=$4
no_highest_ranking_compounds=$5
set -x

# Body
for folder in $(ls ${input_folder}); do
    mkdir -p $folder
    cd $folder/
    vfvs_pp_firstposes_all_unite.sh ../${input_folder}/$folder/summaries/first-poses/ tar firstposes.all
    vfvs_pp_firstposes_compute_min.sh firstposes.all $first_column_id $last_column_id firstposes.all.new
    vfvs_pp_firstposes_prepare_ranking_v11.sh firstposes.all.new $((last_column_id + 1)) firstposes.all.new.ranking.${no_highest_ranking_compounds} ${no_highest_ranking_compounds}
    vfvs_pp_firstposes_prepare_ranking_structures_v10.sh ../${pdbqt_folder} ../${input_folder}/$folder/results/ tar firstposes.all.new.ranking.${no_highest_ranking_compounds} firstposes.all.new.ranking.${no_highest_ranking_compounds}.structures continue
    cd ..
done

echo -e "\n * The first-poses of the results have been prepared\n\n"
