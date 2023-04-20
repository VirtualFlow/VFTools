#!/usr/bin/env bash

# Usage information
usage="Usage: vflp_prepare_inputdb_splitting.sh <input file regex> <input file format> <splitting size> <remove first line> <library format> <compress>

Summary:
    Splits files with many molecules inside into smaller files (collections) of size <splitting size>.
    For each input file a subfolder is created, and the splitted files stored there.

Requirements:
    Has to be run in the root (database) folder which contains the input files.
    The input SMILES collections need to have the extension .smi or .txt, and have to be located in folders.

Arguments:
    -h: Display this help
    '<input file regex>': All files which match the regex will be used as input files. Has to be enclosed with single quotes ''
    <input file format>: Supported formats:
      * smi
      * txt
    <splitting size>: Number of molecules per output collection.
    <remove first line>: Possible values:
      * false
      * true
    <library format>: Specify output library format
      * tranche_collection
      * metatranche_tranche_collection
    <compress>: State whether files should be compressed with gzip.
      * zip
      * none
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
if [ "$#" -ne "6" ]; then

    # Printing some information
    echo
    echo -e "Error in script $(basename ${BASH_SOURCE[0]})"
    echo "Reason: The wrong number of arguments was provided when calling the script."
    echo "Number of expected arguments: 4"
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
inputfiles="$(eval echo ${1})"
inputfile_format="${2}"
splitting_size="${3}"
remove_first_line="${4}"
library_format="${5}"
compress="${6}"
database_name="$(pwd | awk -F '/' '{print $(NF)'})"

# Checking format
if [ "${inputfile_format}" == "smi" ] || [ "${inputfile_format}" == "txt" ] ; then

    # Loop for each input file
    for file in ${inputfiles}; do

        # Printing some information
        echo -e "\n\n * Starting to prepare file ${file}\n"

        # Variables
        filename_extension="${file/*.}"
        file_basename="${file/.*}"

        # Checking filename extension
        if [ -z ${filename_extension} ]; then
            echo "   * Warning: File ${file} has no filename extension, skipping..."
            continue
        fi

        # Removing empty lines
        echo "   * Removing empty lines"
        sed -i "/^[[:space:]]*$/d" ${file}

        # Converting tabs to spaces
        #echo "   * Converting tabs to spaces"
        #sed -i "s/\t/ /g" ${file}

        # Removing first line if needed
        if [ "${remove_first_line}" == "true" ]; then
            echo "   * Removing the first line of file ${file}"
            sed -i "1d" ${file}
        elif [ "${remove_first_line}" != "false" ]; then
            echo "   * Error: The argument <remove first line> has an incorrect value (${remove_first_line}). Exiting..."
            false
        fi

        # Checking if file is not empty
        if [ ! -s ${file} ]; then
            echo "   * Warning: File ${file} is empty, deleting this file..."
            rm ${file}
            continue
        fi

        # Preparing directory
        echo "   * Creating directory ${file_basename}"

	      if [ "${library_format}" == "tranche_collection" ]; then
    	      mkdir ${file_basename}
            cd ${file_basename}
	      elif [ "${library_format}" == "metatranche_tranche_collection" ]; then
	          mkdir ${file_basename:0:2}
	          cd ${file_basename:0:2}
            mkdir ${file_basename:2:4}
            cd ${file_basename:2:4}
        fi

        # Splitting the files
        if [ "${library_format}" == "tranche_collection" ]; then
            echo "   * Splitting the file ../${file}"
            split -l ${splitting_size} --additional-suffix=.${filename_extension} -a 5 -d ../${file} ""
            echo "   * The file was splitted into $(ls | wc -l) collections"
            echo "   * Removing the original file ../${file}"
            rm ../${file}
        elif  [ "${library_format}" == "metatranche_tranche_collection" ]; then
	          echo "   * Splitting the file ../../${file}"
	          split -l ${splitting_size} --additional-suffix=.${filename_extension} -a 5 -d ../../${file} ""
            echo "   * The file was splitted into $(ls | wc -l) collections"
            echo "   * Removing the original file ../${file}"
            rm ../../${file}
        fi

        # Determining the length of the collections
        echo "   * Determining the length of each collection"
        for file in *; do
            length="$(wc -l ${file} | awk '{print $1}')"
            if [ "${library_format}" == "tranche_collection" ]; then
	              echo "${file_basename}"_"${file/.*}" "${length}" >> ../${file_basename}.length
	          elif  [ "${library_format}" == "metatranche_tranche_collection" ]; then
		            echo "${file_basename:0:2}"_"${file_basename:2:4}"_"${file/.*}" "${length}" >> ../../${file_basename}.length
	          fi
        done

	      # Compress files (optional)
        if [ ${compress} == "zip" ]; then
	          echo "   * Compressing the files"
		        for f in *.${filename_extension}; do
	    	        gzip $f
		        done
	          echo "   * Files were compressed"
	      fi

        # Returning to original folder
        if [ "${library_format}" == "tranche_collection" ]; then
            cd ..
        elif [ "${library_format}" == "metatranche_tranche_collection" ]; then
            cd ../..
        fi
    done

    # Generating todo file
    for length_file in *.length; do
        cat ${length_file} >> ${database_name}.todo
    done
fi

echo -e "\n * The preparation of the files was completed.\n\n"
