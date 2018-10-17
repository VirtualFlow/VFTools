#!/bin/bash

shopt -s nullglob

for file in *txt; do
  tranch=${file/.txt}
  mkdir -p ${tranch}
  grep -v smiles ${file} | tr "\t" " " > ${file}.tmp
  mv ${file}.tmp ${file}
  cd ${tranch}
  split -l 1000 -d -a 5 ../${file} ""
  for collection in *; do  
    length="$(wc -l $collection | awk '{print $1}')"
    echo "${tranch}_${collection} ${length}" >> ../all.length
  done
  cd ..
done

