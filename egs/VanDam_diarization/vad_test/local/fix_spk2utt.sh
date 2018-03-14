#!/bin/bash
#
set -e -o pipefail -u

dir=$1

tmpdir=$(mktemp -d /tmp/kaldi.XXXX);
trap 'rm -rf "$tmpdir"' EXIT HUP INT PIPE TERM

export LC_ALL=C

function check_sorted {
  file=$1
  sort -k1,1 -u <$file >$file.tmp
  if ! cmp -s $file $file.tmp; then
    echo "$0: file $1 is not in sorted order or not unique, sorting it"
    mv $file.tmp $file
  else
    rm $file.tmp
  fi
}

sed -i 's/-[0-9]\{6\}//g' $1/utt2spk
sed -i 's/_[0-9]\{7\}_[0-9]\{7\}$//g' $1/utt2spk

mkdir -p $dir/.backup
cp $dir/utt2spk $dir/.backup/utt2spk
check_sorted $dir/utt2spk

cat $dir/utt2spk | awk '{print $1}' > $tmpdir/utts

if [ -f $dir/utt2spk ]; then
  new_nutts=$(cat $tmpdir/utts | wc -l)
  old_nutts=$(cat $dir/utt2spk | wc -l)
  if [ $new_nutts -ne $old_nutts ]; then
    echo "fix_data_dir.sh: kept $new_nutts utterances out of $old_nutts"
  else
    echo "fix_data_dir.sh: kept all $old_nutts utterances."
  fi
fi 

#cp $dir/utt2spk $dir/.backup/utt2spk

if ! cmp -s $dir/utt2spk <( utils/filter_scp.pl $tmpdir/utts $dir/utt2spk ) ; then
     utils/filter_scp.pl $tmpdir/utts $dir/.backup/utt2spk > $dir/utt2spk
fi

#cp $dir/utt2spk $dir/.backup/utt2spk
python local/split_speaker.py $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt

cp $dir/ivector.scp $dir/.backup/ivector.scp
sed -i 's/-[0-9]\{6\}-[0-9]\{6\}//g' $dir/ivector.scp
sort -u -k1,1 -o $dir/ivector.scp $dir/ivector.scp
python local/split_speaker.py $dir/ivector.scp

