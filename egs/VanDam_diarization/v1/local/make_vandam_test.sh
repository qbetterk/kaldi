#!/bin/bash

for name in vandam1 vandam2; do
  mkdir -p data/${name}_test/
  for file in wav.scp utt2spk segments; do
    cp data/$name/$file data/${name}_test/
    sed -i 's/_[0-9,A-Z]\{6\}_/_/g' data/${name}_test/$file
    sed -i 's/_[0-9,A-Z]\{6\}$//g' data/${name}_test/$file
  done
  
  utils/fix_data_dir.sh data/${name}_test
  utils/validate_data_dir.sh --no-text --no-feats data/${name}_test

done


