#!/bin/bash


for sil_scale in 0.0001 0.001 0.01 0.1; do 
	./try_run.sh --sil_scale ${sil_scale}
#	mv data/callhome/segments data/callhome/segments_${sil_scale}

done

