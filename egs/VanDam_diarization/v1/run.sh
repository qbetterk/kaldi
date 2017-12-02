#!/bin/bash

. cmd.sh
. path.sh

set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
num_components=2048
ivector_dim=600

stat_scale=1
min_dur=16
pca_dim=128
loop_prob=0.95

sil_scale=0.1

stage=-1

chunk_size=400
min_chunk_size=5
period=50
result_dir=./result/
threshold=0.5

. parse_options.sh || exit 1;




if [ $stage -le 0 ];then
    # preparing training data

    run_voxceleb.sh

    #local/make_mx6.sh
    run_mx6.sh

    cp -r data/voxceleb data/train
    #utils/combine_data.sh data/train data/mx6_mic data/voxceleb
fi

if [ $stage -le 1 ];then

    # the data is in /export/a16/mmaciej2/data/CITI/vandam

    local/make_vandam.sh
   
#    steps/segmentation/detect_speech_activity.sh \
#                --extra-left-context 70 --extra-right-context 0 --frames-per-chunk 150 \
#                --extra-left-context-initial 0 --extra-right-context-final 0 \
#                --nj 32 --acwt 0.3 --stage $test_stage -10 \
#		--sil-scale $sil_scale \
#		data/vandam \
#                exp/segmentation_1a/tdnn_lstm_asr_sad_1a \
#                mfcc_hires_bp \
#                exp/segmentation_1a/tdnn_lstm_asr_sad_1a/{,vandam}
#    
#    for name in segments spk2utt utt2spk; do
#	rm data/vandam/$name 
#	cp exp/segmentation_1a/tdnn_lstm_asr_sad_1a/vandam_seg/$name data/vandam/	  
#    done
#
#
    local/split_vandam.sh data/vandam data/
    local/make_vandam_test.sh

    # The script local/make_vandam.sh splits vandam into two parts, called
    # vandam1 and vandam2.  Each partition is treated like a held-out
    # dataset, and used to estimate various quantities needed to perform
    # diarization on the other part (and vice versa).

fi



if [ $stage -le 2 ];then

    for name in vandam_trainplda vandam1_test vandam2_test; do
	steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd" \
			   data/$name exp/make_mfcc $mfccdir
	utils/fix_data_dir.sh data/$name
    done
fi


if [ $stage -le 3 ];then    
    for name in vandam_trainplda vandam1_test vandam2_test; do
    	sid/compute_vad_decision.sh --nj 20 --cmd "$train_cmd" \
    				    data/$name exp/make_vad $vaddir
    	utils/fix_data_dir.sh data/$name
    done

fi

if [ $stage -le 5 ];then
    # Reduce the amount of training data for the UBM.
    utils/subset_data_dir.sh data/train 16000 data/train_16k
    #utils/subset_data_dir.sh data/train 32000 data/train_32k

    # Train UBM and i-vector extractor.
    diarization/train_diag_ubm.sh --cmd "$train_cmd -l mem_free=20G,ram_free=20G" \
				  --nj 40 --num-threads 8 --delta-order 1 data/train_16k $num_components \
				  exp/diag_ubm_$num_components

    diarization/train_full_ubm.sh --nj 40 --remove-low-count-gaussians false \
				  --cmd "$train_cmd -l mem_free=25G,ram_free=25G" data/train \
				  exp/diag_ubm_$num_components exp/full_ubm_$num_components
fi

if [ $stage -le 6 ];then
    diarization/train_ivector_extractor.sh \
	--cmd "$train_cmd -l mem_free=35G,ram_free=35G" \
	--ivector-dim $ivector_dim --num-iters 5 \
	exp/full_ubm_$num_components/final.ubm data/train \
	exp/extractor_c${num_components}_i${ivector_dim}
fi



if [ $stage -le 7 ];then

   # Extract iVectors for the voxceleb, which is our PLDA training
    # data.  A long period is used here so that we don't compute too
    # many iVectors for each recording.
#    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 25G" \
#    				    --nj 40 --use-vad true --chunk-size 300 --period 150 \
#    				    --min-chunk-size 5 exp/extractor_c${num_components}_i${ivector_dim} \
#    				    data/voxceleb exp/ivectors_voxceleb
#

    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 25G" \
                                   --nj 40 --use-vad true --chunk-size $chunk_size --period $period \
                                   --min-chunk-size 5 exp/extractor_c${num_components}_i${ivector_dim} \
                                   data/vandam_trainplda exp/ivectors_vandam_trainplda


fi

if [ $stage -le 8 ];then

    # Extract iVectors for the two partitions of vandam.
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" \
				    --nj 40 --use-vad false --chunk-size $chunk_size --period $period \
				    --min-chunk-size $min_chunk_size exp/extractor_c${num_components}_i${ivector_dim} \
				    data/vandam1_test exp/ivectors_vandam1

    
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 20G" \
				    --nj 32 --use-vad false --chunk-size $chunk_size --period $period \
				    --min-chunk-size $min_chunk_size exp/extractor_c${num_components}_i${ivector_dim} \
				    data/vandam2_test exp/ivectors_vandam2

fi


if [ $stage -le 9 ];then
    
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
    

if [ $stage -le 10 ];then
    # Perform PLDA scoring on all pairs of segments for each recording.
    # The first directory contains the PLDA model that used vandam2
    # to perform whitening (recall that we're treating vandam2 as a
    # heldout dataset).  The second directory contains the iVectors
    # for vandam1.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
			      --nj 20 exp/ivectors_vandam2 exp/ivectors_vandam1 \
			      exp/ivectors_vandam1/plda_scores

    # Do the same thing for vandam2.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
			      --nj 20 exp/ivectors_vandam1 exp/ivectors_vandam2 \
			      exp/ivectors_vandam2/plda_scores
fi


if [ $stage -le 11 ];then
    # This performs unsupervised calibration using K-Means (K=2)
    # clustering on the scores.  The average of the centroids
    # is used as the estimated threshold.  Each partition is used
    # as a held-out dataset to compute the stopping criteria used
    # to cluster the other partition.
    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
					    --nj 20 exp/ivectors_vandam1 exp/ivectors_vandam2 exp/ivectors_vandam2/plda_scores

    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
					    --nj 20 exp/ivectors_vandam2 exp/ivectors_vandam1 exp/ivectors_vandam1/plda_scores

fi


if [ $stage -le 12 ];then
    # Cluster the PLDA scores using agglomerative hierarchical clustering,
    # using the thresholds discovered in the previous step.
#    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
#			   --nj 20 --threshold `cat exp/ivectors_vandam2/plda_scores/threshold.txt` \
#			   exp/ivectors_vandam1/plda_scores exp/ivectors_vandam1/plda_scores
#
#    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
#			   --nj 20 --threshold `cat exp/ivectors_vandam1/plda_scores/threshold.txt` \
#			   exp/ivectors_vandam2/plda_scores exp/ivectors_vandam2/plda_scores

#   # tuning threshold value
#    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
#                           --nj 20 --threshold $threshold \
#                           exp/ivectors_vandam1/plda_scores exp/ivectors_vandam1/plda_scores
#
#    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
#                           --nj 20 --threshold $threshold \
#                           exp/ivectors_vandam2/plda_scores exp/ivectors_vandam2/plda_scores
#    
    # using oracle speaker number
    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
                           --nj 20 --utt2num data/vandam/rec2num \
                           exp/ivectors_vandam1/plda_scores exp/ivectors_vandam1/plda_scores

    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
                           --nj 20 --utt2num data/vandam/rec2num \
                           exp/ivectors_vandam2/plda_scores exp/ivectors_vandam2/plda_scores


fi

if [ $stage -le 13 ];then
  #  for name in vandam1 vandam2; do
  #      sed -i '/[-][0-9]/d' exp/ivectors_${name}/plda_scores/rttm
  #  done

    # Result using using unsupervised calibration 
    # OVERALL SPEAKER DIARIZATION ERROR =  percent of scored speaker time  `(ALL)
    cat exp/ivectors_vandam1/plda_scores/rttm exp/ivectors_vandam2/plda_scores/rttm \
	| perl local/md-eval.pl -1 -c 0.25 -r data/vandam/rttm -s - 2> /dev/null | tee

    cat exp/ivectors_vandam1/plda_scores/rttm exp/ivectors_vandam2/plda_scores/rttm \
        | perl local/md-eval.pl -1 -c 0.25 -r data/vandam/rttm -s - 2> /dev/null | tee > result/result-`date +%Y-%m-%d`

fi
