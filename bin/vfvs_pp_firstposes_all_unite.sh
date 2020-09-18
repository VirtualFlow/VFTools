#!/usr/bin/env bash
usage="vfvs_pp_firstposes_all_unite <input folder> <type> <output filename>

Possible types:
    sub: first poses in sub folders, uncompressed (version 6, 7)
    tar: first poses in tar files (one per tranche, version >= 8)
    meta_tranche_: first poses in tar files (one per tranche, in meta-tranche folders)
    meta_collection: first poses gz files (one per collection)
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
if [ "$#" -ne "3" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Exit cleanup
cleanup_exit() {
    # Terminating all remaining processes
    # Getting our process group id
    pgid=$(ps -o pgid= $$ | grep -o [0-9]*)
    # The pgid is supposed to be the pid since we are supposed to be the session leader, but due to the error we can't be sure

    # Terminating everything which was started by this script
    pkill -SIGTERM -P $$ || true
    sleep 1 || true

    # Terminating it in a new process group
}
trap "cleanup_exit $LINENO" EXIT

# Printing some information
echo
echo
echo "*********************************************************************"
echo "             Creating a single file with all first poses             "
echo "*********************************************************************"
echo 

# Variables
input_folder=${1%/}
type=$2
output_filename=${3}
temp_folder=/dev/shm/cgorgulla/vfvs_pp_firstposes_all_unite_$(date +%s%N)

# Directories
mkdir -p ${temp_folder}  

# Main
if [ "${type}" = "sub" ]; then
    for collection in $(ls ${input_folder}); do
        for file in $(ls ${input_folder}/${collection}); do
            echo " * Adding file ${input_folder}/${collection}/${file} to ${output_filename}"
            cat ${input_folder}/${collection}/${file} | grep -v "average\-score" | sed "s/^/${collection}_${file/.txt} /g"  >> ${output_filename}
            echo 
        done
    done
elif [ "${type}" = "tar" ]; then
    cd ${temp_folder}
    for tranche in $(ls ../${input_folder}); do
        echo " * Extracting ${input_folder}/${tranche} to ${temp_folder}"
        tar -xf ../${input_folder}/${tranche} || true
    done
    cd ..
    for tranche in $(ls ${temp_folder}); do
        for file in $(ls ${temp_folder}/${tranche}); do
            echo " * Adding file ${temp_folder}/${tranche}/${file} to ${output_filename}"
            zcat ${temp_folder}/${tranche}/${file} | grep -v "average\-score" | sed "s/^/${tranche}_${file/.txt.gz} /g"  >> ${output_filename}
        done
    done
elif [ "${type}" = "meta_tranche" ]; then
    for metatranche in $(ls ${input_folder}); do
        for tranche in $(ls ${input_folder}/${metatranche}); do
            echo " * Extracting ${metatranche}/${tranche} to ${temp_folder}"
            tar -xf ${input_folder}/${metatranche}/${tranche} -C ${temp_folder} || true
            for file in $(ls ${temp_folder}/${tranche/.*}); do
                echo " * Adding file ${temp_folder}/${tranche/.*}/${file} to ${output_filename}"
                zcat ${temp_folder}/${tranche/.tar}/${file} | grep -v "average\-score" >> ${output_filename} || true
            done
            rm -r ${temp_folder}/${tranche/.*}/ || true
        done
    done
elif [ "${type}" = "meta_collection" ]; then
    for metatranche in $(ls ${input_folder}); do
        for tranche in $(ls ${input_folder}/${metatranche}); do
            echo " * Extracting ${metatranche}/${tranche} to ${temp_folder}"
            for file in ${input_folder}/${metatranche}/${tranche}/*; do
                echo " * Adding file ${file} to ${output_filename}"
                zcat ${file} | grep -v "average\-score" >> ${output_filename} || true
            done
        done
    done
fi

echo -e "\n * Cleaning the temporary files *"
rm -r ${temp_folder}

echo -e "\n * All first poses have been united in the file ${output_filename}"


