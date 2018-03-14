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
sec=60
spk_frac=1.0

stage=3

. parse_options.sh || exit 1;


steps/make_mfcc.sh --mfcc-config conf/mfcc_spkrid_16k.conf --nj 40 --cmd "$train_cmd" \
    data/hms/train_oraclespk_spk180s exp/hms/make_mfcc $mfccdir

sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
    data/hms/train_oraclespk_spk180s exp/hms/make_vad $vaddir
utils/fix_data_dir.sh data/hms/train_oraclespk_spk180s
