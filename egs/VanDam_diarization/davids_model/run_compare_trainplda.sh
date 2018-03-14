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


if [ $stage -le 1 ]; then
  for name in ami vandam_trainplda ; do
    ns=$(cat data//$name/wav.scp | wc -l)
    steps/make_mfcc.sh --mfcc-config $mfcc_conf --nj $(($ns<40?$ns:40)) --cmd "$train_cmd" \
                data/$name exp/make_mfcc $mfccdir
    steps/compute_cmvn_stats.sh data/$name
    utils/fix_data_dir.sh data/$name
  done
fi


if [ $stage -le 2 ]; then
  for name in ami vandam_trainplda ; do
     ns=$(cat data//$name/wav.scp | wc -l)
     sid/compute_vad_decision.sh --nj $(($ns<40?$ns:40)) --cmd "$train_cmd" \
                                 data/$name exp/make_vad $vaddir
    utils/fix_data_dir.sh data/$name
  done
fi


if [ $stage -le 3 ]; then

    # Extract iVectors for the two partitions of vandam.
    ns=$(cat data/vandam_trainplda/wav.scp | wc -l)
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" --nj $(($ns<40?$ns:40)) \
				   --use-vad false --use-cmvn true --chunk-size 150 --period 75 \
                                   --min-chunk-size 5 davids_models/extractor \
                                   data/vandam_trainplda exp/ivectors_vandam_trainplda
    ns=$(cat data/ami/wav.scp | wc -l)
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 25G" --nj $(($ns<40?$ns:40)) \
                                   --use-vad false --use-cmvn true --chunk-size 300 --period 300 \
                                   --min-chunk-size 5 davids_models/extractor \
                                   data/ami exp/ivectors_ami

fi

#######################33
exit 0
########################3
#unfinished

if [ $stage -le 4 ]; then
    # Train a PLDA model on vandam_trainplda, using vandam1 to whiten.
    # We will later use this to score iVectors in vandam2.
    run.pl exp/ivectors_vandam1/log/plda.log \
           ivector-compute-plda ark:exp/ivectors_vandam_trainplda/spk2utt \
           "ark:ivector-subtract-global-mean scp:exp/ivectors_vandam_trainplda/ivector.scp ark:- | transform-vec exp/ivectors_vandam1/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
           exp/ivectors_vandam1/plda || exit 1;

    # Train a PLDA model on vandam_trainplda, using vandam2 to whiten.
    # We will later use this to score iVectors in vandam1.
    run.pl exp/ivectors_vandam2/log/plda.log \
           ivector-compute-plda ark:exp/ivectors_vandam_trainplda/spk2utt \
           "ark:ivector-subtract-global-mean scp:exp/ivectors_vandam_trainplda/ivector.scp ark:- | transform-vec exp/ivectors_vandam2/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
           exp/ivectors_vandam2/plda || exit 1;

fi


if [ $stage -le 5 ]; then
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
                              --nj 20 exp/ivectors_vandam2 exp/ivectors_vandam1 \
                              exp/ivectors_vandam1/plda_scores

    # Do the same thing for vandam2.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
                              --nj 20 exp/ivectors_vandam1 exp/ivectors_vandam2 \
                              exp/ivectors_vandam2/plda_scores
fi


