#!/bin/bash
# Copyright 2017   David Snyder
# Apache 2.0.
#
# TODO, this is a temporary data prep script for Callhome.

set -e

src_dir=$1
data_dir=$2

mkdir -p $data_dir/callhome
mkdir -p $data_dir/callhome1_0
mkdir -p $data_dir/callhome2_0

for name in callhome callhome1_0 callhome2_0; do
  cp $src_dir/wav.scp $data_dir/$name
  #cp $src_dir/segments $data_dir/$name
  rm -f $data_dir/$name/segments
  awk '{ print $1,$1}' $data_dir/$name/wav.scp | sort -u > $data_dir/$name/utt2spk
  cp $data_dir/$name/utt2spk $data_dir/$name/spk2utt
  cp $src_dir/reco2num $data_dir/$name
done

utils/validate_data_dir.sh --no-text --no-feats $data_dir/callhome
utils/fix_data_dir.sh $data_dir/callhome

head -n 250 $data_dir/callhome/wav.scp | utils/filter_scp.pl - $data_dir/callhome/wav.scp > $data_dir/callhome1_0/wav.scp
utils/fix_data_dir.sh $data_dir/callhome1_0
utils/filter_scp.pl --exclude $data_dir/callhome1_0/wav.scp $data_dir/callhome/wav.scp > $data_dir/callhome2_0/wav.scp
utils/fix_data_dir.sh $data_dir/callhome2_0
utils/filter_scp.pl $data_dir/callhome1_0/wav.scp $data_dir/callhome/reco2num > $data_dir/callhome1_0/reco2num
utils/filter_scp.pl $data_dir/callhome2_0/wav.scp $data_dir/callhome/reco2num > $data_dir/callhome2_0/reco2num

cp $src_dir/fullref.rttm local/fullref.rttm
