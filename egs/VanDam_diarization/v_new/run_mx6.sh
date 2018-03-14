#!/bin/bash
#

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc

# prepare data
local/make_mx6.sh
utils/fix_data_dir.sh data/mx6_mic

# make mfcc
steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd --max-jobs-run 15" \
                           data/mx6_mic exp/make_mfcc $mfccdir
utils/fix_data_dir.sh data/mx6_mic

# do vad
sid/compute_vad_decision.sh --nj 40 --cmd "$train_cmd" \
                                    data/mx6_mic exp/make_vad $vaddir
utils/fix_data_dir.sh data/mx6_mic
