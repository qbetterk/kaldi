#!/bin/bash
# Copyright 2017  David Snyder
# TODO other authors
# Apache 2.0.
#
# This is still a work in progress, but implements something similar to
# Greg Sell's and Daniel Garcia-Romero's iVector-based diarization system
# in https://www.dropbox.com/s/bj5bc6brtzt52u4/slt_gks_dgr.pdf?dl=0 .
# The main difference is that we haven't implemented the VB resegmentation
# yet.

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
num_components=2048
ivector_dim=128

stat_scale=1
min_dur=16
pca_dim=128
loop_prob=0.95

mic=sdm1
mfcc_conf=conf/david_wideband_mfcc.conf

stage=1

. parse_options.sh || exit 1;

ns=$(cat data/compare_vandam/wav.scp | wc -l)

if [ $stage -le 1 ]; then
  for name in compare_vandam ; do
    steps/make_mfcc.sh --mfcc-config $mfcc_conf --nj $(($ns<40?$ns:40)) --cmd "$train_cmd" \
                data/$name exp/make_mfcc $mfccdir
    steps/compute_cmvn_stats.sh data/$name
    utils/fix_data_dir.sh data/$name
  done
fi


if [ $stage -le 2 ]; then
  for name in compare_vandam ; do
     sid/compute_vad_decision.sh --cmd "$train_cmd" --nj $(($ns<40?$ns:40)) \
                                 data/$name exp/make_vad $vaddir
    utils/fix_data_dir.sh data/$name
  done
fi


if [ $stage -le 3 ]; then

    # Extract iVectors for the two partitions of vandam.
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" --nj $(($ns<40?$ns:40)) \
                                    --use-vad false --use-cmvn true --chunk-size 150 --period 75 \
                                    --min-chunk-size 5 davids_models/extractor \
                                    data/compare_vandam exp/ivectors_compare_vandam
fi




if [ $stage -le 5 ]; then
    diarization/score_plda_modify.sh --cmd "$train_cmd --mem 4G" --nj 1 \
                                     exp/ivectors_dev_david exp/ivectors_compare_vandam \
                                     exp/ivectors_compare_vandam/plda_scores

fi


