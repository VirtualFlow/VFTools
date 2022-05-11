#!/bin/bash

#Checking the input arguments
usage="Usage: vfvs_pp_prepare_dwar.sh <smiles_collection_folder> <smiles_collection_folder_format> <database_type>

The script should be run in the dwar root folder, and contain a subfolder called 'docking_scores'.
The folder 'docking_scores' should contain the files containing the compounds,collection, and docking scores.
These files need to be in text-format (space separated), have the filename ending 'original', and contain the following columns:
    * column 1: Collection
    * column 2: Compound ID
    * column 3: Docking score

<smiles_collection_folder>:
    * Relative path to the SMILES collection folder

<smiles_collection_folder_format>:
    * tranche: smiles_collection_folder/<tranch>/<collection>.smi
    * meta_tranche: smiles_collection_folder/<metatranch>/tranch.smi

<database_type>:
    * ZINC15: Prepares also the vendor availability according to the ZINC library
    * Other: No preparation of vendor availability"

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
    echo
    echo
    echo "Error was trapped which is a nonstandard error."
    echo "Error in bash script $(basename ${BASH_SOURCE[0]})"
    echo "Error on line $1"
    echo
    exit 1
}
trap 'error_response_nonstd $LINENO' ERR

clean_exit() {
    echo
}
trap 'clean_exit' EXIT

# Variables
smiles_collection_folder="$1"
smiles_collection_folder_format="$2"
database_type="$3"

# Preparing the docking scores
cd docking_scores
for file in *original; do
    awk '{print $2, $4}' $file | grep -e "-[0-9]*.[0-9]*" > $file.scores
done
for file in *scores; do
    sort -k 1,1 -u $file | sort -k 2,2 -n > $file.sorted.unique
done
for file in *unique; do
    sed "1s/^/Compound_ID Score_${file/.*}\n/" $file | column -t |  sed "s/ \+/,/g" > $file.heading.csv
done
awk '{print $1, $2}' *original | sort | uniq > compounds.all.collections+compoundids.unique
awk '{print $1","$2}' *original | sort -k 2,2 -t',' -u > compounds.all.collections_full+compoundids.unique.csv
sed -i  "1s/^/Collection,Compound_ID\n/g" compounds.all.collections_full+compoundids.unique.csv
cd ..


# new smiles way
mkdir -p smiles-original
cd smiles-original
vfvs_prepare_compoundids2smiles.sh ../docking_scores/compounds.all.collections+compoundids.unique ../../../../../../../vflp/collections/compound15-20161102-splitted_sub compounds.all.smile
# Adjusting the file vfvs_prepare_compoundid2smiles accordingly: reading any file ending (txt instead of smi), removing the tautomers from the compound filenames). We should do: Prepare a new smiles library with the tautomers of Compound15_2018 - we prepared it, just need to extract it and prepare it. And adjust the vfvs_prepare_compoundid2smiles file accordingly.
vfvs_prepare_compoundids2smiles.sh ../docking_scores/compounds.all.collections+compoundids.unique ../${smiles_collection_folder} ${smiles_collection_folder_format} compounds.all.smiles
sort compounds.all.smiles | uniq | tr " " "," > compounds.all.smiles.csv
sed -i "1s/^/SMILES,Compound-ID\n/" compounds.all.smiles.csv
cd ..


# Preparing the compound IDs
mkdir -p compound_ids
awk '{print $1}'  docking_scores/*sorted.unique | sort | uniq  > compound_ids/compounds.all.compound_ids.unique
sed "1s/^/Compound_ID\n/g" compound_ids/compounds.all.compound_ids.unique > compound_ids/compounds.all.compound_ids.unique.heading.csv
awk -F '[_ ]' '{print $0","$1}' compound_ids/compounds.all.compound_ids.unique | sed "1s/^/CompoundID,CompoundBaseID\n/g" > compound_ids/compounds.all.compound_ids+base_ids.unique.csv
awk -F '[_ ]' '{print $3}' docking_scores/compounds.all.collections+compoundids.unique > compound_ids/compounds.all.base_ids
rm compound_ids/*unique

# Vendors for ZINC15
if [ "${database_type}" == "ZINC15" ]; then

    # Splitting the compounds
    splitting_size=100
    cd compound_ids
    mkdir -p split_${splitting_size}
    cd split_${splitting_size}
    split -l ${splitting_size} ../compounds.all.base_ids compounds.all.compound_ids.part-
    cd ../..

    # Getting the vendor availability
    splitting_size=100
    cd compound_ids/split_${splitting_size}
    mkdir -p ../../vendors/split_${splitting_size}
    while [ $i -le 10 ]; do
        grep -i "doctype" ../../vendors/split_${splitting_size}/* | awk -F ":" '{print $1}' | uniq | xargs rm -v || true
        wc -l ../../vendors/split_${splitting_size}/* | grep " 0 " | awk '{print $2}' | xargs rm -v || true
        wc -l ../../vendors/split_${splitting_size}/* | grep " [0-8][0-9] "  | awk '{print $2}' | xargs rm -v || true
        for file in *; do
            while true; do
                if [ "$(jobs | wc -l)" -lt "10" ]; then
                    break;
                else
                    echo -e "\nWaiting for free slot\n"; sleep 1
                fi
            done
            if [ ! -f ../../vendors/split_${splitting_size}/${file/compound_ids/vendors} ]; then
                echo -e "\n\nprocessing file $file\n"
                timeout 1m curl http://compound15.docking.org/catitems.txt -F compound_id-in=@$file -F count=all > ../../vendors/split_${splitting_size}/${file/compound_ids/vendors} & sleep 0.5
            else
                echo "The file ${file/compound_ids/vendors} already exists, skipping"
            fi
            sleep 0.01
        done
        wait
    done
    #for file in *; do while true; do if [ "$(jobs | wc -l)" -lt "10" ]; then break; else echo -e "\nWaiting for free slot\n"; sleep 1; fi; done; if [ ! -f ../../vendors/split_${splitting_size}/${file/compound_ids/vendors} ]; then echo -e "\n\nprocessing file $file\n"; timeout 1m curl http://compound15.docking.org/catitems.txt -F compound_id-in=@$file -F count=all > ../../vendors/split_${splitting_size}/${file/compound_ids/vendors} & sleep 0.5; else echo "The file ${file/compound_ids/vendors} already exists, skipping"; fi; sleep 0.01; done;
    grep -i "doctype" ../../vendors/split_${splitting_size}/* | awk -F ":" '{print $1}' | uniq | xargs rm -v || true; wc -l ../../vendors/split_${splitting_size}/* | grep " 0 " | awk '{print $2}' | xargs rm -v || true
    # this comes without headinds -> nice
    cd ../../

    # Adding the vendor to the vendor id
    cd vendors/
    cat split_${splitting_size}/* > compounds.all.vendors
    awk -F "\t" '{print $1","$2","$3","$3":"$1}' compounds.all.vendors  > compounds.all.vendors.extended
    # Converting into csv and naming it the first file compounds.all.vendors.nonunique-Compound-keys.0.csv
    sed "s/ \+/,/g" compounds.all.vendors.extended  | grep Compound > compounds.all.vendors.extended.nonunique-Compound-keys.0.csv
    # Making the files unique
    for i in {0..101}; do
        awk -F "," '!seen[$2]++' compounds.all.vendors.extended.nonunique-Compound-keys.${i}.csv > compounds.all.vendors.extended.unique-Compound-keys.${i}.csv
        awk -F "," 'seen[$2]++' compounds.all.vendors.extended.nonunique-Compound-keys.${i}.csv > compounds.all.vendors.extended.nonunique-Compound-keys.$((i+1)).csv
    done
    mkdir unique
    mkdir nonunique
    mv *nonunique-Compound* nonunique/
    mv *unique-Compound* unique/
    # Adding the headings
    cd unique
    sed -i "1s/^/VendorID,CompoundID,Vendor,Vendor:VendorID\n/" compounds.all.vendors.extended.unique-Compound-keys.*
    cd ../..

fi
