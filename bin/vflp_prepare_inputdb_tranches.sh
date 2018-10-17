#!/usr/bin/env bash

# Usage information
usage="Usage: vflp_prepare_inputdb_splitting.sh <input files> <create meta-tranch folders>

Summary:
    Sortes the compounds in a file with many molecules into separate files corresponding to the tranches. 
    For each tranch an individual file is created, located in a folder with the meta-tranch (first two letters).

Requirements:
    Has to be run in the root (database) folder which contains the input file.
    The first column contains the SMILES, the second column the compound name, and the third column the tranch name. Columns have to be separated by single spaces. 

Arguments:
    -h: Display this help
    '<input files>': The input files with the compounds (SMILES, name, tranch), separated by a colon ":"
    -<create meta-tranch folders>: true or false. If false, the folders have to exist already.
"

# Checking the input parameters
if [ "${1}" == "-h" ]; then

    # Printing some information
    echo
    echo -e "$usage"
    echo
    echo
    exit 0
fi
if [ "$#" -ne "2" ]; then

    # Printing some information
    echo
    echo -e "Error in script $(basename ${BASH_SOURCE[0]})"
    echo "Reason: The wrong number of arguments was provided when calling the script."
    echo "Number of expected arguments: 2"
    echo "Number of provided arguments: ${#}"
    echo "Provided arguments: $@"
    echo
    echo -e "$usage"
    echo
    echo
    exit 1
fi

# Standard error response 
error_response_std() {

    # Printing some information
    echo
    echo "An error was trapped" 1>&2
    echo "The error occurred in bash script $(basename ${BASH_SOURCE[0]})" 1>&2
    echo "The error occurred on line $1" 1>&2
    echo "Working directory: $PWD"
    echo "Exiting..."
    echo
    echo

    # Exiting
    exit 1
}
trap 'error_response_std $LINENO' ERR

trap "pkill -9 -P $$" EXIT


# Variables
input_files="$(eval echo ${1})"
create_meta_tranch_folders="${2}"


# Printing some information
echo -e "\n\n * Starting to prepare file ${file}\n"

# Reading the input file line by line
counter=0
for input_file in ${input_files//:/ }; do 
    while IFS='' read -r line || [[ -n "$line" ]]; do

        # Removing first line if needed
        if [[ "${counter}" == "0" ]] && [[ "${skip_first_line^^}" == "TRUE" ]]; then

            # Printing some information
            echo "   * Skipping the first line of file ${file}"

            # Updating the counter
            counter=$((counter+1))

            continue
        fi

        # Variables
        line=$(echo ${line} | tr -d "\r")
        read -a line_array <<< ${line}
        smiles=${line_array[0]}
        name=${line_array[1]}
        tranch=${line_array[2]}
        meta_tranch=${tranch:0:2}

        # Creating the required folder
        if [ "${create_meta_tranch_folders^^}" == "TRUE" ]; then 
            mkdir -p ${meta_tranch}
        fi
        
        # Adding the compound to its tranch file
        echo "Adding compound ${name} to tranch ${tranch}"
        echo "${smiles} ${name}" >> ${meta_tranch}/${tranch}.txt    

        # Updating the counter
        counter=$((counter+1))
    done < "${input_file}" &
done

wait

echo -e "\n * The preparation of the files was completed.\n\n"
