#!/bin/bash
#
# Apache 2.0.

. cmd.sh
. path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc


# The 8kHz version
#python local/make_voxceleb_8khz.py /export/corpora/VoxCeleb data/voxceleb

# The 16kHz version
python local/make_voxceleb_16khz.py /export/corpora/VoxCeleb data/voxceleb
utils/fix_data_dir.sh data/voxceleb

# Note that we need to utt2num_frames file when computing the frame-level vad.
# If we didn't do this, there could small mistmatches between the length of the
# vad.scp and the feats.scp.
steps/make_mfcc.sh --write-utt2num-frames true \
  --mfcc-config conf/mfcc.conf --nj 40 --cmd "$train_cmd --max-jobs-run 15" \
  data/voxceleb exp/make_mfcc $mfccdir
utils/fix_data_dir.sh data/voxceleb

# We need to use the segments provided by VoxCeleb to create the frame-level VAD.
# IMPORTANT: don't use the energy VAD here!
python local/make_voxceleb_vad.py /export/corpora/VoxCeleb data/voxceleb/
copy-vector ark:data/voxceleb/vad.txt ark,scp:$vaddir/vad_voxceleb.ark,$vaddir/vad_voxceleb.scp
cp mfcc/vad_voxceleb.scp data/voxceleb/vad.scp

utils/fix_data_dir.sh data/voxceleb/



