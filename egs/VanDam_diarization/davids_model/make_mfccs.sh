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

stage=1

. parse_options.sh || exit 1;


if [ $stage -le 1 ]; then
  for name in train_oraclespk dev eval; do
    steps/make_mfcc.sh --mfcc-config conf/mfcc_spkrid_16k.conf --nj 40 --cmd "$train_cmd" \
        data/$mic/$name exp/$mic/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/$mic/$name
  done
fi


if [ $stage -le 2 ]; then
  for name in train_oraclespk dev eval; do
    ns=$(cat data/$mic/$name/wav.scp | wc -l)
    sid/compute_vad_decision.sh --nj $(($ns<40?$ns:40)) --cmd "$train_cmd" \
        data/$mic/$name exp/$mic/make_vad $vaddir
    utils/fix_data_dir.sh data/$mic/$name
  done
fi
