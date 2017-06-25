
#!/usr/bin/env bash

usage="vfvs_v6tov7_restructure_firstposes.sh <input folder> <output folder>"

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
if [ "$#" -ne "2" ]; then
    echo -e "\nWrong number of arguments. Exiting.\n"
    echo -e "${usage}\n\n"
    exit 1
fi

# Printing some information
echo
echo
echo "*********************************************************************"
echo "   Restructuring the first-poses folder from VFVS v6 to v7  format   "
echo "*********************************************************************"
echo 

# Variables
input_folder=${1%/}
output_folder=${2%/}

# Body
for file in $(ls ${input_folder}); do
    name1=${file:0:4}
    name2=${file:5}
    if [[ "$name2" = "txt" ]]; then
        name2=1
        mv ${input_folder}/${file} ${input_folder}/${name1}_${name2}.txt
        file=${name1}_${name2}.txt
    fi
    if [ ! -d "${output_folder}/${name1}/" ]; then
        echo " * Creating directory ${output_folder}/${name1}"
        mkdir -p "${output_folder}/${name1}/"
    fi
    echo " * Copying ${input_folder}/${file} to ${output_folder}/${name1}/${name2}"
    cp ${input_folder}/${file} ${output_folder}/${name1}/${name2}
done

echo -e "\n * Restructuring completed"
