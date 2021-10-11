#!/bin/bash

QSM_path=/project/3022026.02/POM/bids/derivatives/R2QSM_Analysis
cd $QSM_path

#get names of files
ls $QSM_path/sub-*/ses-Visit1/R2QSM/Data_arlo_r2s.nii.gz > r2star_maps.txt
ls $QSM_path/sub-*/ses-Visit1/R2QSM/QSM_ResidualWeights/FANSI/Data_QSM.nii.gz > fansi_maps.txt
ls $QSM_path/sub-*/ses-Visit1/R2QSM/QSM_ResidualWeights/MEDI/Data_QSM.nii.gz > medi_maps.txt
ls $QSM_path/sub-*/ses-Visit1/R2QSM/QSM_ResidualWeights/NDI/Data_QSM.nii.gz > ndi_maps.txt
ls $QSM_path/sub-*/ses-Visit1/R2QSM/SMWI/Data_smwi-paramagnetic.nii.gz > smwi_maps.txt

#create webpages with slicesdir
slicesdir -e 0 $(cat $QSM_path/r2star_maps.txt)
mv slicesdir slicesdir_r2star
slicesdir -e 0 $(cat $QSM_path/fansi_maps.txt)
mv slicesdir slicesdir_fansi
slicesdir -e 0 $(cat $QSM_path/medi_maps.txt)
mv slicesdir slicesdir_medi
slicesdir -e 0 $(cat $QSM_path/ndi_maps.txt)
mv slicesdir slicesdir_ndi
slicesdir -e 0 $(cat $QSM_path/smwi_maps.txt)
mv slicesdir slicesdir_smwi
