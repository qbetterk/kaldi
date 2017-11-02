#!/bin/bash


for period in 150; do
   ./run.sh --chunk_size 450 --min_chunk_size 100 --period $period --stage 8 --result_dir ./result_new
done



