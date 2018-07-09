#!/bin/bash
PATH_TO_EA="<location of ea-masclab>"
SELECTED="<cached paths to process>" # e.g. SELECTED="1"
CACHED_PATHS="$PATH_TO_EA/cache/cached_paths_$SELECTED/"

RESUME=$(echo "1" | bc)
FILE="$CACHED_PATHS""f$RESUME"".txt"

while [ -f "$FILE" ]; do
  matlab16a -r "cd $PATH_TO_EA; addpath ./utils; CACHED_PATH_SELECTION = $SELECTED; scan_crop_resume_processing;"

  RESUME=$(echo "$RESUME + 20" | bc)
  FILE="$CACHED_PATHS""f$RESUME"".txt"
done