#!/bin/bash

# Copyright  2017 Jesus Villalba
# Apache 2.0.

# This script performs VB resegmentation
# Using the labels of the AHC as starting point

# Begin configuration section.
cmd="run.pl"
stage=0

echo "$0 $@"  # Print the command line for logging

stat_scale=1
pca_dim=30
loop_prob=0.9
min_dur=1

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;


if [ $# != 5 ]; then
  echo "Usage: $0 <ivector-dir> <plda-dir> <init-label-dir> <output-dir> <log-dir>"
  echo " e.g.: $0 exp/ivectors_callhome1 exp/ivectors_callhome2 exp/ivectors_callhome1/plda_scores exp/ivectors_callhome1/vb_resegm"
fi

ivector_dir=$1
plda_dir=$2
init_label_dir=$3
output_dir=$4
log_dir=$5

mkdir -p $output_dir $log_dir

export PHYTHONPATH=.:$PYTHONPATH

ivector_scp=$ivector_dir/ivector.scp
ivector_h5=$ivector_dir/ivector.h5

awk '{ sub(/-.*/,""); print $1,"unk" }' $ivector_scp | sort -u > $output_dir/utt2spk

if [ $stage -le 0 ];then
    # Convert ivector format
    $cmd -V $log_dir/iv2h5.log \
	 py_diarization/bin/ark2hyp.py \
	 --input-file $ivector_scp \
	 --output-file $ivector_h5 --squeeze
fi


centering=$plda_dir/mean.vec 
whitening=$plda_dir/transform.mat
plda=$plda_dir/plda

if [ $stage -le 1 ];then
    #Convert models format to be easy to read from python
    #Centering
    sed -e 's@\[@@' -e 's@\]@@' $centering > $centering.txt
    copy-matrix --binary=false $whitening - | \
	sed -e 's@\[@@' -e 's@\]@@'  > $whitening.txt
    ivector-copy-plda --binary=false --normalize-length=false $plda - | \
	sed -e 's@\[@@' -e 's@\]@@' -e 's@<.*>@@g' > $plda.txt
    
fi


if [ $stage -le 2 ];then
    # Do VB resegmentation
    echo "$0: resegmentation with loop_prob:$loop_prob min_dur:$min_dur pca_dim:$pca_dim stat_scale:$stat_scale"

    $cmd -V $log_dir/vb_resegm.log \
	 py_diarization/bin/vb-resegm.py \
	 --iv-file $ivector_h5 \
	 --file-list $output_dir/utt2spk \
	 --init-label-file $init_label_dir/labels \
	 --model-path $plda_dir \
	 --output-path $output_dir \
	 --loop-prob $loop_prob --stat-scale $stat_scale --min-dur $min_dur --pca-dim $pca_dim
    
    
fi

if [ $stage -le 3 ];then
    #from labels to RTTM
    cp $init_label_dir/segments $output_dir
    python2 diarization/make_rttm.py $output_dir/segments $output_dir/labels > $output_dir/rttm || exit 1;
fi

