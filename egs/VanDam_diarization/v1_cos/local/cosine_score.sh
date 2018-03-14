#!/bin/bash
#
. ./path.sh

set -e

for name in vandam1 vandam2; do
	copy-matrix --binary=false scp:exp/ivectors_${name}/ivector.scp ark,t:exp/ivectors_${name}/ivector

	python ./local/cosine_score.py exp/ivectors_${name}/ivector exp/ivectors_${name}/plda_scores/cos_score.ark  

	copy-matrix --binary=true ark,t:exp/ivectors_${name}/plda_scores/cos_score.ark \
							  ark:exp/ivectors_${name}/plda_scores/score_binary.ark

	copy-matrix ark,t:exp/ivectors_${name}/plda_scores/cos_score.ark \
				ark,scp:exp/ivectors_${name}/plda_scores/score_binary.ark,exp/ivectors_${name}/plda_scores/score_binary.scp
done
