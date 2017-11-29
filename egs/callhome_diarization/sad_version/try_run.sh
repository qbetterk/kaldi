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

sil_scale=0.1

stage=-1

. parse_options.sh || exit 1;


if [ $stage -le 0 ];then
    # Prepare a collection of NIST SRE data. This will be used to train the UBM,
    # iVector extractor and PLDA model.


    # NOTE: For now, this is not a propery data prep script.  It assumes that the
    # data was already prepared elsewhere (e.g., in
    # /home/dsnyder/a16/a16/dsnyder/SCALE17/callhome), and copies the files to
    # the local directories here.

    local/make_callhome_only.sh /home/dsnyder/a16/a16/dsnyder/SCALE17/callhome data/
 
    steps/segmentation/detect_speech_activity.sh \
                --extra-left-context 70 --extra-right-context 0 --frames-per-chunk 150 \
                --extra-left-context-initial 0 --extra-right-context-final 0 \
                --nj 32 --acwt 0.3 --stage $test_stage -10 \
                --sil-scale $sil_scale \
                data/callhome \
                exp/segmentation_1a/tdnn_lstm_asr_sad_1a \
                mfcc_hires_bp \
                exp/segmentation_1a/tdnn_lstm_asr_sad_1a/{,callhome}

    for name in segments spk2utt utt2spk; do
        cp exp/segmentation_1a/tdnn_lstm_asr_sad_1a/callhome_seg/$name data/segments/callhome/
    done
fi


