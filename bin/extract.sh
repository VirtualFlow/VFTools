# Usage: extract compounds_file structure_dir output_dir

index=0
while IFS= read -r line; do
    index=$((index+1))
   read -r -a array <<< "$line"
   collection=${array[0]}
   tranch=${array/_*}
   collection_id=${array/*_}
   zinc_id="${array[1]}"
   minindex="${array[2]}"
   echo "Extracting $tranch, $collection_id, $zinc_id, $minindex"
   cp $2/${tranch}/${collection_id}/${zinc_id}/replica-${minindex}/${zinc_id}.rank-1.pdb $3/${index}_${zinc_id}.pdb
   echo
done < $1
