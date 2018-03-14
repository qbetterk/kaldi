#!/bin/bash


cmd="run.pl"
if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

data_in=$1
data_out=$2
log=$3

mkdir -p $log $data_out

[ ! -f $data_in/vad.scp ] && echo "No such file $data_in/vad.scp" && exit 1;

$cmd $log/vad2segments.log \
     copy-vector scp:$data_in/vad.scp ark,t:- \| \
    sed -e 's@\]@ @' -e 's@\[@ @' -e 's@ 1@ 2@g'  \| \
    utils/segmentation.pl --hard-max-segment-length 400 --max-segment-length 90 \> $data_out/segments

awk '{ print $1,$2}' $data_out/segments > $data_out/utt2spk

utils/utt2spk_to_spk2utt.pl $data_out/utt2spk > $data_out/spk2utt

cp $data_in/wav.scp $data_out
cp $data_in/reco2num $data_out

