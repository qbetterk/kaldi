#!/bin/bash

for ((i=1;i<=40;i++));
do
   echo "for extract_ivector.${i}.log" >> logrecord.log
   tail ./exp/ivectors_dev/log/extract_ivector.${i}.log >> logrecord.log 
   echo " "
done
