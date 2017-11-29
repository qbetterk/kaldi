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

 #   local/make_sre.sh data

 #   # Prepare SWB for UBM and iVector extractor training.
 #   local/make_swbd2_phase2.pl /export/corpora5/LDC/LDC99S79 \
 #                              data/swbd2_phase2_train
 #   local/make_swbd2_phase3.pl /export/corpora5/LDC/LDC2002S06 \
 #                              data/swbd2_phase3_train
 #   local/make_swbd_cellular1.pl /export/corpora5/LDC/LDC2001S13 \
 #       			 data/swbd_cellular1_train
 #   local/make_swbd_cellular2.pl /export/corpora5/LDC/LDC2004S07 \
 #       			 data/swbd_cellular2_train

 #   # NOTE: For now, this is not a propery data prep script.  It assumes that the
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
	rm data/callhome/$name 
	cp exp/segmentation_1a/tdnn_lstm_asr_sad_1a/callhome_seg/$name data/callhome/	  
    done


    local/split_callhome.sh data/callhome data/


#    utils/combine_data.sh data/train \
#			  data/swbd_cellular1_train data/swbd_cellular2_train \
#			  data/swbd2_phase2_train data/swbd2_phase3_train data/sre
#
    # The script local/make_callhome.sh splits callhome into two parts, called
    # callhome1 and callhome2.  Each partition is treated like a held-out
    # dataset, and used to estimate various quantities needed to perform
    # diarization on the other part (and vice versa).

fi



if [ $stage -le 1 ];then

    for name in callhome1 callhome2; do
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd" \
			   data/$name exp/make_mfcc $mfccdir
	utils/fix_data_dir.sh data/$name
    done
fi



if [ $stage -le 7 ];then


    # Extract iVectors for the two partitions of callhome.
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" \
				    --nj 40 --use-vad false --chunk-size 150 --period 75 \
				    --min-chunk-size 50 exp/extractor_c${num_components}_i${ivector_dim} \
				    data/callhome1 exp/ivectors_callhome1

    
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" \
				    --nj 40 --use-vad false --chunk-size 150 --period 75 \
				    --min-chunk-size 50 exp/extractor_c${num_components}_i${ivector_dim} \
				    data/callhome2 exp/ivectors_callhome2

fi


if [ $stage -le 7 ];then
    
    # Train a PLDA model on SRE, using callhome1 to whiten.
    # We will later use this to score iVectors in callhome2.
    run.pl exp/ivectors_callhome1/log/plda.log \
	   ivector-compute-plda ark:exp/ivectors_sre/spk2utt \
	   "ark:ivector-subtract-global-mean scp:exp/ivectors_sre/ivector.scp ark:- | transform-vec exp/ivectors_callhome1/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
	   exp/ivectors_callhome1/plda || exit 1;
    
    # Train a PLDA model on SRE, using callhome2 to whiten.
    # We will later use this to score iVectors in callhome1.
    run.pl exp/ivectors_callhome2/log/plda.log \
	   ivector-compute-plda ark:exp/ivectors_sre/spk2utt \
	   "ark:ivector-subtract-global-mean scp:exp/ivectors_sre/ivector.scp ark:- | transform-vec exp/ivectors_callhome2/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
	   exp/ivectors_callhome2/plda || exit 1;
fi
    

if [ $stage -le 8 ];then
    # Perform PLDA scoring on all pairs of segments for each recording.
    # The first directory contains the PLDA model that used callhome2
    # to perform whitening (recall that we're treating callhome2 as a
    # heldout dataset).  The second directory contains the iVectors
    # for callhome1.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
			      --nj 20 exp/ivectors_callhome2 exp/ivectors_callhome1 \
			      exp/ivectors_callhome1/plda_scores

    # Do the same thing for callhome2.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
			      --nj 20 exp/ivectors_callhome1 exp/ivectors_callhome2 \
			      exp/ivectors_callhome2/plda_scores
fi


if [ $stage -le 9 ];then
    # This performs unsupervised calibration using K-Means (K=2)
    # clustering on the scores.  The average of the centroids
    # is used as the estimated threshold.  Each partition is used
    # as a held-out dataset to compute the stopping criteria used
    # to cluster the other partition.
    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
					    --nj 20 exp/ivectors_callhome1 exp/ivectors_callhome2 exp/ivectors_callhome2/plda_scores

    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
					    --nj 20 exp/ivectors_callhome2 exp/ivectors_callhome1 exp/ivectors_callhome1/plda_scores

fi


if [ $stage -le 10 ];then
    # Cluster the PLDA scores using agglomerative hierarchical clustering,
    # using the thresholds discovered in the previous step.
    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
			   --nj 20 --threshold `cat exp/ivectors_callhome2/plda_scores/threshold.txt` \
			   exp/ivectors_callhome1/plda_scores exp/ivectors_callhome1/plda_scores

    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
			   --nj 20 --threshold `cat exp/ivectors_callhome1/plda_scores/threshold.txt` \
			   exp/ivectors_callhome2/plda_scores exp/ivectors_callhome2/plda_scores

    # Result using using unsupervised calibration
    # OVERALL SPEAKER DIARIZATION ERROR = 17.44 percent of scored speaker time  `(ALL)
    cat exp/ivectors_callhome1/plda_scores/rttm exp/ivectors_callhome2/plda_scores/rttm \
	| perl local/md-eval.pl -1 -c 0.25 -r local/fullref.rttm -s - 2> /dev/null | tee

    cat exp/ivectors_callhome1/plda_scores/rttm exp/ivectors_callhome2/plda_scores/rttm \
        | perl local/md-eval.pl -1 -c 0.25 -r local/fullref.rttm -s - 2> /dev/null | tee > result/result-sil-${sil_scale}-`date +%Y-%m-%d`

fi
