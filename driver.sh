#!/bin/bash -l

for i in {1..14}; do
  formatted_number=$(printf "%03d" $i)
  ./batch-grid-gen.sh $formatted_number
done
