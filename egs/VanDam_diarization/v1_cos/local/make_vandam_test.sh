#!/bin/bash

for name in "$@"; do
  mkdir -p ${name}_test/
  for file in wav.scp utt2spk segments; do
    cp $name/$file ${name}_test/
    sed -i 's/_[0-9,A-Z]\{6\}_/_/g' ${name}_test/$file
    sed -i 's/_[0-9,A-Z]\{6\}$//g' ${name}_test/$file
  done
  
  utils/fix_data_dir.sh ${name}_test
  utils/validate_data_dir.sh --no-text --no-feats ${name}_test

done


