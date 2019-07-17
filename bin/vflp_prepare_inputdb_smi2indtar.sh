#!/usr/bin/env bash

# Usage information
usage="Usage: vflp_prepare_inputdb_smi2indtar.sh <folder regex> <SMILES column> <Name column>

Summary:
    Converts files with multiple SMILES (collections) into files with individual SMILES.
    For each input SMILES collection a subfolder is created, and the individual SMILES stored inside that subfolders.
    The subfolders are then archived in the tar.gz, and the subfolders removed.

Requirements:
    Has to be run in the root (database) folder which contains the folders with the SMILES collections.
    The input SMILES collections need to have the extension .smi or .txt, and have to be located in folders.
    Each input SMILES collection needs to store the name as well as the SMILES of the molecule separated by a tab or space.

Arguments:
    -h: Display this help
    '<Folder regex>':  All folders which match the regex will be used as input folders. Has to be enclosed with single quotes ''. 
    <SMILES column>: The column of the files which contain the SMILES of the molecules.. The first column has index 0
    <Name column>:   The column of the files which contains the names of the molecules. The first column has index 0.
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
if [ "$#" -ne "3" ]; then

    # Printing some information
    echo
    echo -e "Error in script $(basename ${BASH_SOURCE[0]})"
    echo "Reason: The wrong number of arguments was provided when calling the script."
    echo "Number of expected arguments: 3"
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

# Settings
shopt -s nullglob


# Variables
folder_regex="$1"
smiles_column_index="$2"
name_column_index="$3"

# Loop for each folder
for folder in $(eval echo ${folder_regex}); do
  
  # Printing some information
  echo -e "\n\n * Preparing folder ${folder}"

  # Checking if the folder is indeed a folder
  if [ ! -d ${folder} ]; then
    echo "   * Warning: ${folder}" is not a directory, skipping this file...
    continue
  fi
  cd ${folder}

  # Loop for each file in folder
  for file in *.{smi,txt}; do

    # Printing informatoin
    echo -e "\n   * Starting processing of file ${folder}/${file}"

    # Subfolder
    subfolder="${file/.*}"
    echo "     * Creating folder ${subfolder}"
    mkdir -p ${subfolder}
    
    # Creating the individual files
    echo "     * Creating the individual SMILES files" 
    while IFS='' read -r line || [[ -n "$line" ]]; do
      IFS='\t ' read -a line_array <<< ${line}
      echo "${line_array[${smiles_column_index}]}" > "${subfolder}/${line_array[${name_column_index}]}.smi"
    done < ${file}
    collection_size=$(ls ${subfolder} | wc -l)
    echo "     * From the file ${file} ${collection_size} individual SMILES files were created"
    #echo "${folder}_${subfolder} ${collection_size}" >> length.all

    # Packing the files into a compressed archive
    echo "     * Creating compressed tar archive"
    tar -czf ${subfolder}.tar.gz ${subfolder}

    # Removing files
    echo "     * Removing subfolder ${subfolder} and original file ${file}"
    rm -r ${subfolder}
    rm ${file}
  done

  # Printint some information
  echo -e "\n   * All the files in the tranch $folder have been splitted and archived"

  # Returning to root folder
  cd ..

  # Creating archive for current tranch
  echo "   * Creating archive for tranch ${folder}"
  mkdir -p ${folder:0:2}
  tar -cf ${folder:0:2}/${folder/\/}.tar ${folder}

  # Removing tranch folder
  echo "   * Removing tranch folder ${folder}"
  rm -r ${folder}
done

echo -e "\n * All the tranches have been prepared.\n\n"
