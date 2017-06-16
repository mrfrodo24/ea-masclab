STARTDATE=$(echo "73600" | bc) # Make sure to use 8 decimal precision to be as accurate as possible
ENDDATE=$(echo "73608" | bc)

CURDATE=$STARTDATE
while (( $(bc <<< "$CURDATE <= $ENDDATE") == 1 )); do
  matlab16a -nojvm -r "cd /home/disk/ivanova2/spencerwork/MATLAB/cp3g_masclab_sbu; addpath(genpath('./modules')); module_resume_processing;"
  CURDATE=$(echo "$CURDATE + 1" | bc) # Always round up last decimal of offset
done
