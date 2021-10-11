#!/bin/bash

modalities="MEDI FANSI NDI"
qsm_dir=/project/3022026.02/POM/bids/derivatives/QSM
#qsm_dir = $1

cd $qsm_dir

#QSM slicesdir
for mod in $modalities; do
ls $qsm_dir/*/ses-POMVisit1/R2QSM/QSM_ResidualWeights/$mod/Data_QSM.nii.gz > list_$mod.txt

/home/mrstats/jitame/Software/slicesdir_qsm -e 0 $(cat list_$mod.txt)
mv slicesdir slicesdir_$mod
done

#R2star slicesdir

ls $qsm_dir/*/ses-POMVisit1/R2QSM/Data_arlo_r2s.nii.gz > list_r2s.txt
/home/mrstats/jitame/Software/slicesdir_r2star -e 0 $(cat list_r2s.txt)
mv slicesdir slicesdir_r2s


