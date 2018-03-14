#!/bin/bash

set -e

src_dir=$1
data_dir=$2

mkdir -p $data_dir/callhome

for name in callhome ; do
  cp $src_dir/wav.scp $data_dir/$name
  cp $src_dir/segments $data_dir/$name
  cp $src_dir/utt2spk $data_dir/$name
  cp $src_dir/spk2utt $data_dir/$name
  cp $src_dir/reco2num $data_dir/$name
done

utils/validate_data_dir.sh --no-text --no-feats $data_dir/callhome
utils/fix_data_dir.sh $data_dir/callhome

cp $src_dir/fullref.rttm local/fullref.rttm
