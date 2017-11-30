wget http://dl.kaldi-asr.org/models/0001_aspire_chain_model.tar.gz
mkdir -p aspire
(cd aspire; tar xzf ../0001_aspire_chain_model.tar.gz)
cp ~/cha2stm.targzip cha2stm.tar
mkdir tools
(
  cd tools; 
  tar xf ../cha2stm.tar.gz; 
  chmod a+x cha2stm/parse_cha_xml.py
  sed -i'' 's:#!/usr/bin/python:#!/bin/env python:g' parse_cha_xml.py
  sed -i'' 's/python parse_cha_xml.py/parse_cha_xml.py/g' cha2stm.sh
)
PATH=$PATH:tools/cha2stm

TALKBANK=/data/MM1/corpora/HomeBank/VanDam/
DATA=data/vandam
mkdir -p $DATA
find $TALKBANK -name "*.cha" | \
	xargs -n 1 tools/cha2stm/cha2stm.sh > $DATA/stm

LAME=$(which lame)
SOX=$(which sox)

find "${TALKBANK}" -name "*.cha" > $DATA/cha.list
find "${TALKBANK}" -name "*.mp3" > $DATA/mp3.list


perl -ne 'chomp;  $b=`basename $_`; chomp $b; $b =~ s/\.mp3$//; print "$b '$LAME' --decode --quiet $_ - | sox - -t wav -r 8000 - |\n"' $DATA/mp3.list > $DATA/wav.scp

cat data/vandam/stm | \
  perl -ne 'chomp; 
            @F = split / /, $_, 7; 
            $s = $F[3]; 
            $e = $F[4]; 
	    $spk = sprintf("%016s_%06s", $F[0], $F[1]);"
            $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);  
            if (scalar @F > 5) {print "$u $F[6]\n"} else {print "$u SIL\n"}' > $DATA/text

cat data/vandam/stm | \
  perl -ne 'chomp; 
            @F = split / /, $_, 7; 
            $s = $F[3]; 
            $e = $F[4]; 
	    $spk = sprintf("%016s_%06s", $F[0], $F[1]);"
            $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);  
            print "$u $F[0] $s $e \n"' > $DATA/segments

cat data/vandam/stm | \
  perl -ne 'chomp; 
            @F = split / /, $_, 7; 
            $s = $F[3]; 
            $e = $F[4]; 
	    $spk = sprintf("%016s_%06s", $F[0], $F[1]);"
            $u = sprintf("%s_%07d_%07d", $spk,  $s*1000, $e *1000);  
            print "$u $spk \n"' > $DATA/utt2spk

utils/fix_data_dir.sh $DATA

utils/mkgraph.sh --self-loop-scale 1.0 \
	aspire/data/lang_pp_test aspire/exp/tdnn_7b_chain_online \
	aspire/exp/tdnn_7b_chain_online//graph_pp

steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf\
	aspire/data/lang_chain aspire/exp/nnet3/extractor \
	aspire/exp/chain/tdnn_7b aspire/exp/tdnn_7b_chain_online

steps/online/nnet3/decode.sh --cmd "$decode_cmd" \
	--nj 32 --acwt 1.0 --post-decode-acwt 10.0 \
	aspire/exp/tdnn_7b_chain_online/graph_pp \
	data/vandam/ aspire/exp/tdnn_7b_chain_online//decode_vandam
