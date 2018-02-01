#!/bin/bash

TALKBANK=/export/a15/mmaciej2/data/CITI/VanDam/
DATA=data/vandam

mkdir -p $DATA/xml/

PATH=$PATH:/home/$USER/bin

echo "making stm file..."
find $TALKBANK -name "*.cha" | \
        xargs -n 1 -i ./local/cha2stm.sh {} ${DATA}/xml > $DATA/stm

LAME=$(which lame)
#LAME=/home/qkun/bin/lame
SOX=$(which sox)

find "${TALKBANK}" -name "*.cha" > $DATA/cha.list
find "${TALKBANK}" -name "*.mp3" > $DATA/mp3.list

#original one
perl -ne 'chomp;  $b=`basename $_`; chomp $b; $b =~ s/\.mp3$//; print "$b '$LAME' --decode --quiet $_ - | sox - -t wav -r 16000 - |\n"' $DATA/mp3.list > $DATA/wav.scp


cat $DATA/stm | \
  perl -ne 'chomp;
            @F = split / /, $_, 7;
            $s = $F[3];
            $e = $F[4];
            $spk = sprintf("%016s_%06s", $F[0], $F[1]);
            $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);
            if (scalar @F > 5) {print "$u $F[6]\n"} else {print "$u SIL\n"}' > $DATA/text.tmp

sort -k1,2 -k4,4 -t_ $DATA/text.tmp > $DATA/text
rm $DATA/text.tmp


cat $DATA/stm | \
  perl -ne 'chomp;
            @F = split / /, $_, 7;
            $s = $F[3];
            $e = $F[4];
            $spk = sprintf("%016s_%06s", $F[0], $F[1]);
	    $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);
            print "$u $F[0] $s $e \n"' > $DATA/segments.tmp

sort -k1,2 -k4,4 -t_ $DATA/segments.tmp > $DATA/segments
rm $DATA/segments.tmp


cat $DATA/stm | \
  perl -ne 'chomp;
            @F = split / /, $_, 7;
            $s = $F[3];
            $e = $F[4];
            $spk = sprintf("%016s_%06s", $F[0], $F[1]);
	    $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);
            print "$u $spk \n"' > $DATA/utt2spk.tmp

sort -k1,2 -k4,4 -t_ $DATA/utt2spk.tmp > $DATA/utt2spk
rm $DATA/utt2spk.tmp


cat $DATA/stm | \
  perl -ne 'chmop;
	    @F = split / /, $_, 7;
	    $d = sprintf("%.03f",$F[4]-$F[3]);
            print "SPEAKER $F[0] 0 $F[3] $d <NA> <NA> $F[1] <NA> <NA> \n"' > $DATA/rttm

python local/count_spk_num.py $DATA/stm > $DATA/rec2num

utils/fix_data_dir.sh $DATA

