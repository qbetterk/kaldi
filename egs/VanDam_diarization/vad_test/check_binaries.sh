#!/bin/bash

for name in add-deltas select-voiced-frames subsample-feats gmm-global-init-from-feats gmm-gselect gmm-global-acc-stats gmm-global-sum-accs gmm-global-est gmm-global-to-fgmm fgmm-global-acc-stats fgmm-global-est fgmm-global-sum-accs ivector-extractor-init fgmm-global-gselect-to-post scale-post ivector-extractor-acc-stats ivector-extractor-sum-accs ivector-extractor-est fgmm-global-to-gmm ivector-mean est-pca ivector-compute-plda ivector-subtract-global-mean transform-vec ivector-normalize-length; do
  path1=$(whereis $name | awk '{print $2}')
  path2=$(echo "$path1" | sed -e 's/diarization/kaldi-jsalt-test/g')
  if [ "$(diff $path1 $path2 | wc -l)" -ne "0" ]; then
    echo "$name"
  fi
done
