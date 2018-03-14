#!/bin/bash

set -e

#./make_mfccs.sh --mic mdm8
#./make_mfccs.sh --mic hms

#./run_plda_cross_mean_frac.sh --mic mdm8 --sec 120 --spk-frac 0.8
#./run_plda_cross_mean_frac.sh --mic hms --sec 120 --spk-frac 0.8
./run_davids_models_plda_cross_mean.sh --mic hms --stage 3 --sec 60 --spk-frac 0.5
./run_davids_models_plda_cross_mean.sh --mic hms --stage 3 --sec 90 --spk-frac 0.5


exit

for secs in 60 90 120 150 180 210; do
  for frac in 0.2 0.3 0.4 0.5 0.8 1.0; do
    ./run_davids_models_plda_cross_mean.sh --mic mdm8 --stage 3 --sec $secs --spk-frac $frac
  done
done

#for mic in mdm8 sdm1; do
#  ./run_fixed_plda.sh --stage 6 --mic $mic
#done

#./run_davids_models.sh --mic sdm_se
#./run_davids_models.sh --mic mdm_se
#./run_davids_models.sh --mic hms_se

#for mult in 200; do
#  ./run_fixed_plda_multispk.sh --stage 6 --spk-mult $mult
#done



exit

for secs in 30; do
  for frac in 0.2 0.3 0.4 0.5 0.6 0.8 1.0; do
    ./run_davids_models_plda_sitemean_trianmean.sh --stage 3 --sec $secs --spk-frac $frac
  done
done
exit


for secs in 180 210; do
  for frac in 0.2 0.3 0.4 0.5 0.8 1.0; do
#    ./run_plda_cross_site_mean_testmean.sh --stage 6 --sec $secs --spk-frac $frac
    ./run_plda_cross_site_mean_trainmean.sh --stage 6 --sec $secs --spk-frac $frac
#    echo "sec $secs frac $frac"
#    grep -e DIARIZATION diarization_results_sdm1_test_sitemean_plda_spk${secs}s_sub${frac}p.txt
  done
done
