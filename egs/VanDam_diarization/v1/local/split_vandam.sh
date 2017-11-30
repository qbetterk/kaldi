#!/bin/bash
# Copyright 2017   David Snyder, Kun Qian
# Apache 2.0.
#
# TODO, this is a temporary data prep script for Callhome.

set -e

src_dir=$1
data_dir=$2

if [ -d $data_dir/vandam_plda ];then
        rm -r $data_dir/vandam_trainplda
        rm -r $data_dir/vandam_calib
fi

mkdir -p $data_dir/vandam_trainplda
mkdir -p $data_dir/vandam_calib

for name in vandam_trainplda vandam_calib; do
  cp $src_dir/wav.scp $data_dir/$name
  cp $src_dir/segments $data_dir/$name
  cp $src_dir/utt2spk $data_dir/$name
  cp $src_dir/spk2utt $data_dir/$name
  cp $src_dir/stm $data_dir/$name
  cp $src_dir/rec2num $data_dir/$name
done

utils/validate_data_dir.sh --no-text --no-feats $data_dir/vandam
utils/fix_data_dir.sh $data_dir/vandam

shuf $data_dir/vandam/wav.scp | head -n 80 | utils/filter_scp.pl - $data_dir/vandam/wav.scp > $data_dir/vandam_trainplda/wav.scp
utils/fix_data_dir.sh $data_dir/vandam_trainplda
utils/filter_scp.pl --exclude $data_dir/vandam_trainplda/wav.scp $data_dir/vandam/wav.scp > $data_dir/vandam_calib/wav.scp
utils/fix_data_dir.sh $data_dir/vandam_calib
utils/filter_scp.pl $data_dir/vandam_trainplda/wav.scp $data_dir/vandam/stm > $data_dir/vandam_trainplda/stm
#utils/filter_scp.pl $data_dir/vandam_trainplda/wav.scp $data_dir/vandam/rttm > $data_dir/vandam_trainplda/rttm
utils/filter_scp.pl $data_dir/vandam_calib/wav.scp $data_dir/vandam/stm > $data_dir/vandam_calib/stm

utils/filter_scp.pl $data_dir/vandam_trainplda/wav.scp $data_dir/vandam/rec2num > $data_dir/vandam_trainplda/rec2num
utils/filter_scp.pl $data_dir/vandam_calib/wav.scp $data_dir/vandam/rec2num > $data_dir/vandam_calib/rec2num



if [ -d $data_dir/vandam1 ];then
	rm -r $data_dir/vandam1
	rm -r $data_dir/vandam2
fi

mkdir -p $data_dir/vandam1
mkdir -p $data_dir/vandam2

for name in vandam1 vandam2; do
  cp $data_dir/vandam_calib/wav.scp $data_dir/$name
  cp $data_dir/vandam_calib/segments $data_dir/$name
  cp $data_dir/vandam_calib/utt2spk $data_dir/$name
  cp $data_dir/vandam_calib/spk2utt $data_dir/$name
  cp $data_dir/vandam_calib/stm $data_dir/$name
  cp $data_dir/vandam_calib/rec2num $data_dir/$name
done

utils/validate_data_dir.sh --no-text --no-feats $data_dir/vandam_calib
utils/fix_data_dir.sh $data_dir/vandam_calib

shuf $data_dir/vandam_calib/wav.scp | head -n 40 | utils/filter_scp.pl - $data_dir/vandam_calib/wav.scp > $data_dir/vandam1/wav.scp
utils/fix_data_dir.sh $data_dir/vandam1
utils/filter_scp.pl --exclude $data_dir/vandam1/wav.scp $data_dir/vandam_calib/wav.scp > $data_dir/vandam2/wav.scp
utils/fix_data_dir.sh $data_dir/vandam2
utils/filter_scp.pl $data_dir/vandam1/wav.scp $data_dir/vandam_calib/stm > $data_dir/vandam1/stm
utils/filter_scp.pl $data_dir/vandam2/wav.scp $data_dir/vandam_calib/stm > $data_dir/vandam2/stm

utils/filter_scp.pl $data_dir/vandam1/wav.scp $data_dir/vandam_calib/rec2num > $data_dir/vandam1/rec2num
utils/filter_scp.pl $data_dir/vandam2/wav.scp $data_dir/vandam_calib/rec2num > $data_dir/vandam2/rec2num

rm -r data/vandam_calib
