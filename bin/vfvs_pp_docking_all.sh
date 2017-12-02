#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_pp_docking_all.sh <input root folder> <pdbqt_folder> <no of highest ranking compounds> <parallel runs> <compute_min_values>

For each docking the rankings are and the structure files are prepared.

The <input root folder> is the output-folder/complete folder of the original workflow.
The command has to be run in the desired output folder.
All path names have to be relative to the working directory.
<parallel runs>: Integer
<compute_min_values>: possible values: yes or no. Useful for VFVS versions below 11.5 where the value was not computed automatically correctly. If set to now the fourth column is used to get the minimum value. Otherwise the minimum is comuted from the colums sixth column to the last column of the summary files."

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "5" ]]; then
   echo -e "\nWrong number of arguments. Exiting.\n"
   echo -e "${usage}\n\n"
   exit 1
fi
set -x

# Standard error response 
error_response_nonstd() {
    echo "Error was trapped which is a nonstandard error."
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})"
    echo "Error on line $1"
    echo
    pkill 0 
    exit 1
}
#trap 'error_response_nonstd $LINENO' ERR

clean_exit() {    
    pkill -P $$ || true
    sleep 3
    pkill -9 -P $$ || true

    # Get our process group id
    PGID=$(ps -o pgid= $$ | grep -o [0-9]*)
    # Terminating it in a new process group
    setsid bash -c "kill -- -$PGID; sleep 5; kill -9 -$PGID";
}
trap 'clean_exit' EXIT

# Variables
input_folder="$1"
pdbqt_folder="$2"
no_highest_ranking_compounds=$3
parallel_runs="$4"
compute_min_values="$5"

# Body
for folder in $(ls ${input_folder}); do
    while true; do
        job_count="$(jobs | grep -v " Done " | wc -l)"
        jobs
        if [ "${job_count}" -lt "${parallel_runs}" ]; then
            echo " * Starting to prepare the firstposes of docking-scenario $folder"
            vfvs_pp_docking_single.sh $input_folder/$folder $pdbqt_folder $no_highest_ranking_compounds $compute_min_values &
            break
        else
            echo " * Maximum number of parallel runs reached. Waiting..."
            sleep 1
        fi
    done
done

wait


# Joining all the scores
mkdir -p scores
for folder in $(ls ${input_folder}); do
    awk '{print $2","$1","$NF}' $folder/firstposes.all.sorted | sed "1s/^/Compound,Collection,$folder\n/" > scores/${folder}.scores;
done

paste -d " " scores/*scores | awk -F '[, ]+' '{printf $1" "$2 " "; for (i=3;i<=NF;i+=3) {printf $i" "} printf "\n" }' | tr " " "," | sed "s/,$//g" > scores/all.ov.csv

echo -e "\n * The first-poses of all docking runs have been prepared\n\n"
