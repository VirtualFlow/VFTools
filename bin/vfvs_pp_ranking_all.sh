#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_pp_ranking_all.sh <input root folder> <parallel runs> <library_format>


Creates the full ranking of all docking compounds for each docking scenario.

All pathnames have to be relative to the working directory.

Options:
    <input root folder>: The folder containing the docking scenario output fodlers, normally the output-folder/complete folder.
    <parallel runs>: Integer
    <library format>: Possible values:
                           * tar
                           * meta_tranche
                           * meta_collection"

if [ "${1}" == "-h" ]; then
   echo -e "\n${usage}\n\n"
   exit 0 
fi

if [[ "$#" -ne "3" ]]; then
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
    pkill 0 
    exit 1
}
#trap 'error_response_nonstd $LINENO' ERR


# Exit cleanup
cleanup_exit() {


    # Terminating all remaining processes
    # Getting our process group id
    pgid=$(ps -o pgid= $$ | grep -o [0-9]*)
    # The pgid is supposed to be the pid since we are supposed to be the session leader, but due to the error we can't be sure

    # Terminating everything which was started by this script
    pkill -SIGTERM -P $$ || true
    sleep 1 || true
}
trap "cleanup_exit $LINENO" EXIT


# Variables
input_folder="$1"
parallel_runs="$2"
library_format="$3"

# Body
for folder in $(ls ${input_folder}); do
    while true; do
        job_count="$(jobs | grep -v " Done " | wc -l)"
        jobs
        if [ "${job_count}" -lt "${parallel_runs}" ]; then
            echo " * Starting to prepare the firstposes of docking-scenario $folder"
            vfvs_pp_ranking_single.sh $input_folder/$folder ${library_format} &
            break
        else
            echo " * Maximum number of parallel runs reached. Waiting..."
        fi
        sleep 1
    done
done

wait

echo -e "\n * The first-poses of all docking runs have been prepared\n\n"
