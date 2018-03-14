#!/bin/bash


#for period in 50 100 150; do
#   ./run.sh --chunk_size 450 --min_chunk_size 100 --period $period --stage 7 --result_dir ./result
#done
#
#
#for min_chunk_size in 5 50 200; do
#   ./run.sh --chunk_size 450 --min_chunk_size $min_chunk_size --period 75 --stage 8 --result_dir ./result
#done

for chunk_size in 100 200 600; do
   ./run.sh --chunk_size $chunk_size --min_chunk_size 5 --period 75 --stage 8 --result_dir ./result
done

