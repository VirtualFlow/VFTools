#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_pp_ranking_single.sh <docking_scenario_output_folder> <library_format>

Creates the full ranking of all docking compounds for the specified docking scenario.

All pathnames have to be relative to the working directory.

Options:
    <docking_scenario_output_folder>: The <docking scenario output folder> is one of the folders in output-folder/complete.
    <library_format>: Possible values:
                           * tar
                           * meta
                           * meta_tranche
                           * meta_collection"

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "2" ]]; then
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
library_format=${2}
docking_name="$(basename $input_folder)"

# Body
if [ -d "$docking_name" ]; then
    echo -e " * The folder $docking_name exists already, exiting." 
    exit 0
fi

mkdir -p $docking_name
cd $docking_name/
vfvs_pp_firstposes_all_unite.sh ../${input_folder}/summaries ${library_format} firstposes.all
vfvs_pp_firstposes_all_unite.sh ../${input_folder/complete/incomplete}/summaries ${library_format} firstposes.all.incomplete
cat firstposes.all.incomplete >> firstposes.all
rm firstposes.all.incomplete
vfvs_pp_firstposes_prepare_ranking.sh firstposes.all 4 firstposes.all.minindex.sorted.clean


cd ..

echo -e "\n * The first-poses of the docking scenario $docking_name has been prepared\n\n"
