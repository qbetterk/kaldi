#!/bin/bash

. ./cmd.sh
. ./path.sh


# You may set 'mic' to:
#  ihm [individual headset mic- the default which gives best results]
#  sdm1 [single distant microphone- the current script allows you only to select
#        the 1st of 8 microphones]
#  mdm8 [multiple distant microphones-- currently we only support averaging over
#       the 8 source microphones].
# ... by calling this script as, for example,
# ./run.sh --mic sdm1
# ./run.sh --mic mdm8
mic=mdm8

# Train systems,
nj=30 # number of parallel jobs,

mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
num_components=2048
ivector_dim=128

stat_scale=1
min_dur=16
pca_dim=128
loop_prob=0.95
result_dir='pwd'/result

chunk_size=500
min_chunk_size=5
period=100


stage=-1
. utils/parse_options.sh

base_mic=$(echo $mic | sed 's/[0-9]//g') # sdm, ihm or mdm
nmics=$(echo $mic | sed 's/[a-z]//g') # e.g. 8 for mdm8.

set -euo pipefail

# Path where AMI gets downloaded (or where locally available):
AMI_DIR=$PWD/wav_db # Default,
case $(hostname -d) in
  fit.vutbr.cz) AMI_DIR=/mnt/scratch05/iveselyk/KALDI_AMI_WAV ;; # BUT,
  clsp.jhu.edu) AMI_DIR=/export/corpora4/ami/amicorpus ;; # JHU,
  cstr.ed.ac.uk) AMI_DIR= ;; # Edinburgh,
esac

#[ ! -r data/local/lm/final_lm ] && echo "Please, run 'run_prepare_shared.sh' first!" && exit 1
#final_lm=`cat data/local/lm/final_lm`
#LM=$final_lm.pr1-7


if [ $stage -le -1 ]; then
  local/ami_text_prep.sh data/local/downloads
fi



## Download AMI corpus, You need around 130GB of free space to get whole data ihm+mdm,
#if [ $stage -le 0 ]; then
#  if [ -d $AMI_DIR ] && ! touch $AMI_DIR/.foo 2>/dev/null; then
#    echo "$0: directory $AMI_DIR seems to exist and not be owned by you."
#    echo " ... Assuming the data does not need to be downloaded.  Please use --stage 1 or more."
#    exit 1
#  fi
#  if [ -e data/local/downloads/wget_$mic.sh ]; then
#    echo "data/local/downloads/wget_$mic.sh already exists, better quit than re-download... (use --stage N)"
#    exit 1
#  fi
#  local/ami_download.sh $mic $AMI_DIR
#fi



if [ "$base_mic" == "mdm" ]; then
  PROCESSED_AMI_DIR=$AMI_DIR/beamformed
  if [ $stage -le 1 ]; then
    # for MDM data, do beamforming
    #! hash BeamformIt && echo "Missing BeamformIt, run 'cd ../../../tools/; make beamformit;'" && exit 1
    local/ami_beamform.sh --cmd "$train_cmd" --nj 20 $nmics $AMI_DIR $PROCESSED_AMI_DIR
  fi
else
  PROCESSED_AMI_DIR=$AMI_DIR
fi

# Prepare original data directories data/ihm/train_orig, etc.
if [ $stage -le 2 ]; then
  local/ami_${base_mic}_data_prep.sh $PROCESSED_AMI_DIR $mic
  local/ami_${base_mic}_scoring_data_prep.sh $PROCESSED_AMI_DIR $mic dev
  local/ami_${base_mic}_scoring_data_prep.sh $PROCESSED_AMI_DIR $mic eval

  

  local/ami_ihm_data_prep.sh $AMI_DIR ihm
  local/ami_ihm_scoring_data_prep.sh $AMI_DIR ihm dev
  local/ami_ihm_scoring_data_prep.sh $AMI_DIR ihm eval
  

  if [ "$mic" != "ihm" ]; then
    local/prepare_oraclespk_datadir.sh --dataset train --mic $mic
#    cp -r data/mdm8/train_orig data/mdm8/train_oraclespk
    local/prepare_oraclespk_datadir.sh --dataset dev --mic $mic
    local/prepare_oraclespk_datadir.sh --dataset eval --mic $mic
  fi


   local/make_sre.sh data
   local/make_swbd2_phase2.pl /export/corpora5/LDC/LDC99S79 \
                               data/swbd2_phase2_train
   local/make_swbd2_phase3.pl /export/corpora5/LDC/LDC2002S06 \
                               data/swbd2_phase3_train
   local/make_swbd_cellular1.pl /export/corpora5/LDC/LDC2001S13 \
                               data/swbd_cellular1_train
   local/make_swbd_cellular2.pl /export/corpora5/LDC/LDC2004S07 \
                               data/swbd_cellular2_train
   utils/combine_data.sh data/$mic/train_oraclespk \
                          data/swbd_cellular1_train data/swbd_cellular2_train \
                          data/swbd2_phase2_train data/swbd2_phase3_train data/sre

fi

#if [ $stage -le 3 ]; then
#  for dset in train dev eval; do
#    # this splits up the speakers (which for sdm and mdm just correspond
#    # to recordings) into 30-second chunks.  It's like a very brain-dead form
#    # of diarization; we can later replace it with 'real' diarization.
#    seconds_per_spk_max=30
#    [ "$mic" == "ihm" ] && seconds_per_spk_max=120  # speaker info for ihm is real,
#                                                    # so organize into much bigger chunks.
#    utils/data/modify_speaker_info.sh --seconds-per-spk-max 30 \
#      data/$mic/${dset}_orig data/$mic/$dset
#  done
#fi
#



###################################################################################################################
###################################################################################################################





if [ $stage -le 4 ];then
    steps/make_mfcc.sh --mfcc-config conf/mfcc_call.conf --nj 40 --cmd "$train_cmd" \
			data/$mic/train_oraclespk exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/$mic/train_oraclespk

    for name in dev_oraclespk eval_oraclespk; do
        steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd" \
                           data/$mic/$name exp/make_mfcc $mfccdir
        utils/fix_data_dir.sh data/$mic/$name

#    read -p "finished partly"
    done
fi

if [ $stage -le 5 ];then
    for name in train_oraclespk dev_oraclespk eval_oraclespk; do
        sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
                                    data/$mic/$name exp/make_vad $vaddir
    done
fi


if [ $stage -le 6 ];then
    # Reduce the amount of training data for the UBM.
    utils/subset_data_dir.sh data/$mic/train_oraclespk 16000 data/$mic/train_16k
    utils/subset_data_dir.sh data/$mic/train_oraclespk 32000 data/$mic/train_32k

    # Train UBM and i-vector extractor.
    diarization/train_diag_ubm.sh --cmd "$train_cmd -l mem_free=20G,ram_free=20G" \
                                  --nj 40 --num-threads 8 --delta-order 1 data/$mic/train_16k $num_components \
                                  exp/diag_ubm_$num_components

    diarization/train_full_ubm.sh --nj 40 --remove-low-count-gaussians false \
                                  --cmd "$train_cmd -l mem_free=25G,ram_free=25G" data/$mic/train_32k \
                                  exp/diag_ubm_$num_components exp/full_ubm_$num_components
fi

if [ $stage -le 7 ];then
    diarization/train_ivector_extractor.sh \
        --cmd "$train_cmd -l mem_free=35G,ram_free=35G" \
        --ivector-dim $ivector_dim --num-iters 5 \
        exp/full_ubm_$num_components/final.ubm data/$mic/train_oraclespk \
        exp/extractor_c${num_components}_i${ivector_dim}
fi


if [ $stage -le 8 ];then

    # Extract iVectors for the train, which is our PLDA training
    # data.  A long period is used here so that we don't compute too
    # many iVectors for each recording.
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 50G" \
                                    --nj 40 --use-vad true --chunk-size $chunk_size --period 4500 \
                                    --min-chunk-size $min_chunk_size exp/extractor_c${num_components}_i${ivector_dim} \
                                    data/$mic/train_oraclespk exp/ivectors_train

    #diarization/extract_ivectors_nondense.sh --cmd "$train_cmd --mem 25G" \
    #                                --nj 40 --use-vad true exp/extractor_c${num_components}_i${ivector_dim} \
    #                                data/$mic/train_oraclespk exp/ivectors_train
fi


##################################################################################################################################
#################################################   for testing   ################################################################
##################################################################################################################################


if [ $stage -le 9 ];then
    # Extract iVectors for the dev and eval.
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 50G" \
                                    --nj 40 --use-vad false --chunk-size $chunk_size --period $period \
                                    --min-chunk-size 5 exp/extractor_c${num_components}_i${ivector_dim} \
                                    data/$mic/dev_oraclespk exp/ivectors_dev
    diarization/extract_ivectors.sh --cmd "$train_cmd --mem 50G" \
                                    --nj 40 --use-vad false --chunk-size $chunk_size --period $period \
                                    --min-chunk-size 5 exp/extractor_c${num_components}_i${ivector_dim} \
                                    data/$mic/eval_oraclespk exp/ivectors_eval

fi




if [ $stage -le 10 ];then

    # Train a PLDA model on train, using dev to whiten.
    # We will later use this to score iVectors in eval.
    run.pl exp/ivectors_dev/log/plda.log \
           ivector-compute-plda ark:exp/ivectors_train/spk2utt \
           "ark:ivector-subtract-global-mean scp:exp/ivectors_train/ivector.scp ark:- | transform-vec exp/ivectors_dev/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
           exp/ivectors_dev/plda || exit 1;

    # Train a PLDA model on train, using eval to whiten.
    # We will later use this to score iVectors in dev.
    run.pl exp/ivectors_eval/log/plda.log \
           ivector-compute-plda ark:exp/ivectors_train/spk2utt \
           "ark:ivector-subtract-global-mean scp:exp/ivectors_train/ivector.scp ark:- | transform-vec exp/ivectors_eval/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
           exp/ivectors_eval/plda || exit 1;
fi


if [ $stage -le 11 ];then
    # Perform PLDA scoring on all pairs of segments for each recording.
    # The first directory contains the PLDA model that used eval
    # to perform whitening (recall that we're treating eval as a
    # heldout dataset).  The second directory contains the iVectors
    # for dev.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
                              --nj 10 exp/ivectors_eval exp/ivectors_dev \
                              exp/ivectors_dev/plda_scores

    # Do the same thing for eval.
    diarization/score_plda.sh --cmd "$train_cmd --mem 4G" \
                              --nj 10 exp/ivectors_dev exp/ivectors_eval \
                              exp/ivectors_eval/plda_scores
fi


if [ $stage -le 12 ];then
    # This performs unsupervised calibration using K-Means (K=2)
    # clustering on the scores.  The average of the centroids
    # is used as the estimated threshold.  Each partition is used
    # as a held-out dataset to compute the stopping criteria used
    # to cluster the other partition.
    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
                                            --nj 10 exp/ivectors_dev exp/ivectors_eval exp/ivectors_eval/plda_scores

    diarization/compute_plda_calibration.sh --cmd "$train_cmd --mem 4G" \
                                            --nj 10 exp/ivectors_eval exp/ivectors_dev exp/ivectors_dev/plda_scores

fi



if [ $stage -le 13 ];then
    # Cluster the PLDA scores using agglomerative hierarchical clustering,
    # using the thresholds discovered in the previous step.
    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
                           --nj 10 --threshold `cat exp/ivectors_eval/plda_scores/threshold.txt` \
                           exp/ivectors_dev/plda_scores exp/ivectors_dev/plda_scores

    diarization/cluster.sh --cmd "$train_cmd --mem 4G" \
                           --nj 10 --threshold `cat exp/ivectors_dev/plda_scores/threshold.txt` \
                           exp/ivectors_eval/plda_scores exp/ivectors_eval/plda_scores

fi


#if [ $stage -le 123 ];then
   grep '[-]' exp/ivectors_dev/plda_scores/rttm |wc -l

   sed -i '/[-][0-9]/d' exp/ivectors_dev/plda_scores/rttm 
#fi


if [ $stage -le 14 ];then
    # Result using using unsupervised calibration
    # OVERALL SPEAKER DIARIZATION ERROR = 10.33 percent of scored speaker time  `(ALL)
    echo $(date) >>${result_dir}/$chunk_size'_'$period'.txt'
    echo chunk size: $chunk_size , min chunk size: $min_chunk_size , period: $period >> ${result_dir}/$chunk_size'_'$period'.txt'
    local/md-eval.pl -1 -c 0.25 -r local/rttm -s exp/ivectors_dev/plda_scores/rttm >> ${result_dir}/$chunk_size'_'$period'.txt'
fi

