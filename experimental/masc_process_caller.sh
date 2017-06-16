#!/bin/bash
CACHED_PATHS="/home/disk/ivanova2/spencerwork/MATLAB/cp3g_masclab/cache/cached_paths_1/"

RESUME=$(echo "1" | bc)
FILE="$CACHED_PATHS""f$RESUME"".txt"

while [ -f "$FILE" ]; do
  matlab16a -nojvm -r "cd /home/disk/ivanova2/spencerwork/MATLAB/cp3g_masclab; addpath ./utils; scan_crop_resume_processing;"
  
  RESUME=$(echo "$RESUME + 20" | bc)
  FILE="$CACHED_PATHS""f$RESUME"".txt"
done