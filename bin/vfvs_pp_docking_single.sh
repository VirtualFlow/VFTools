#!/bin/bash
set -x
#Checking the input arguments
usage="Usage: vfvs_pp_firstposes_all_dockings.sh <input root folder> <pdbqt_folder> <no of highest ranking compounds> <compute_min_values> [<first_column_id> <last_column_id>]

For each docking the rankings are and the structure files are prepared.

The <input root folder> is normally one of the folders in output-folder/complete.
The command has to be run in the desired output folder.
All path names have to be relative to the working directory.
<compute_min_values>: possible values: yes or no. Useful for VFVS versions below 11.7 where the value was not computed automatically correctly. If set to no the fourth column is used to get the minimum value. Otherwise the minimum is comuted from the colums sixth to the final column of the summary files."

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "4" ]]; then
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


clean_exit() {
    pkill -P $$ || true
    sleep 3
    pkill -9 -P $$ || true
}
trap 'clean_exit' EXIT

# Variables
input_folder="$1"
pdbqt_folder="$2"
no_highest_ranking_compounds=$3
compute_min_value=$4
docking_name="$(basename $input_folder)"

# Body
if [ -d "$docking_name" ]; then
    echo -e " * The folder $docking_name exists already, exiting." 
    exit 0
fi
mkdir -p $docking_name
cd $docking_name/
vfvs_pp_firstposes_all_unite.sh ../${input_folder}/summaries/first-poses/ tar firstposes.all
if [ "${compute_min_value}" == yes ]; then
    first_column_id=6
    last_column_id=$(head -n 1 firstposes.all | wc -w)
    vfvs_pp_firstposes_compute_min.sh firstposes.all $first_column_id $last_column_id firstposes.all.new
    vfvs_pp_firstposes_prepare_ranking_v11.sh firstposes.all.new $((last_column_id + 1)) firstposes.all.new.ranking.${no_highest_ranking_compounds} ${no_highest_ranking_compounds}
else
    vfvs_pp_firstposes_prepare_ranking_v11.sh firstposes.all 4 firstposes.all.new.ranking.${no_highest_ranking_compounds} ${no_highest_ranking_compounds}
fi
vfvs_pp_firstposes_prepare_ranking_structures_v10.sh ../${pdbqt_folder} ../${input_folder}/results/ tar firstposes.all.new.ranking.${no_highest_ranking_compounds} firstposes.all.new.ranking.${no_highest_ranking_compounds}.structures continue
cd ..

echo -e "\n * The first-poses of the docking scenario $docking_namer has been prepared\n\n"
