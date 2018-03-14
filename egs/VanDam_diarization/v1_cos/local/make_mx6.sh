#!/bin/bash
# Copyright 2017   David Snyder
# Apache 2.0.
#
# See README.txt for more info on data required.

set -e

echo "$0: preparing mic speech (excluding 01, 03, and 13)"
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 02 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 04 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 05 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 06 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 07 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 08 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 09 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 10 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 11 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 12 data/
local/make_mx6_mic.pl  /export/corpora5/LDC/LDC2013S03 14 data/

utils/combine_data.sh data/mx6_mic_04_to_14_16khz data/mx6_mic_{04,05,06,07,08,09,10,11,12,14}_16khz

echo "$0: selecting subset of 04 through 14 mic speech and combining it with 02"
utils/subset_data_dir.sh data/mx6_mic_04_to_14_16khz 8000 data/mx6_mic_04_to_14_16khz_2k
utils/combine_data.sh data/mx6_mic data/mx6_mic_02_16khz data/mx6_mic_04_to_14_16khz_2k
