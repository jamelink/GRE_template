#!/bin/bash

#set variables
code_path = "SPECIFY" #specify path to GRE_template directory
export FSLDIR="/opt/fsl/6.0.3"
TEMPLATE_DIR=$1

#set up folders
mkdir $TEMPLATE_DIR/qc
cd TEMPLATE_DIR

#get names of files
ls $TEMPLATE_DIR/orig/*_r2s.nii.gz > $TEMPLATE_DIR/qc/r2star_maps.txt
ls $TEMPLATE_DIR/orig/*_qsm.nii.gz > $TEMPLATE_DIR/qc/qsm_maps.txt
ls $TEMPLATE_DIR/orig/*_smwi.nii.gz > $TEMPLATE_DIR/qc/smwi_maps.txt
ls $TEMPLATE_DIR/orig/*_t1.nii.gz > $TEMPLATE_DIR/qc/t1_maps.txt

#create webpages with slicesdir
$code_path/slicesdir_r2star -e 0 $(cat $QSM_path/r2star_maps.txt)
mv slicesdir $TEMPLATE_DIR/qc/r2star
$code_path/slicesdir_qsm -e 0 $(cat $QSM_path/qsm_maps.txt)
mv slicesdir $TEMPLATE_DIR/qc/qsm
$FSLDIR/slicesdir -e 0 $(cat $QSM_path/smwi_maps.txt)
mv slicesdir $TEMPLATE_DIR/qc/smwi
$FSLDIR/slicesdir -e 0 $(cat $QSM_path/t1_maps.txt)
mv slicesdir $TEMPLATE_DIR/qc/t1
