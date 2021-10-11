#!/bin/bash

#Author: Niels Bergsland, npbergsland@bnac.net
#Last update: 20180424
#Version 0.2
#adapted for the Donders Centre for Cognitive Neuroscience by Jitse Amelink, jitse.amelink@donders.ru.nl
#this version includes R2*-maps.
#Last update: 20210422


#BEGIN CONFIG
FSLDIR="/opt/fsl/6.0.3"
ANTSPATH="/opt/ANTs/20150225/build/bin/" #should be 2.1.0 - release dates miss by a month (2015/01 vs. 2015/02)
TEMPLATE_TARGET="${FSLDIR}/data/standard/MNI152_T1_1mm_brain"
C3D_AFFINE_TOOL="/opt/c3d/1.0.0/bin/c3d_affine_tool"
TEMPLATE_DIR=$1
CODE_PATH="/project/3022026.02/POM/code/QSM"
QSUB_OPTION=4 #(or 2)
NUM_CORES=32 #only relevant when QSUB == 2
#END CONFIG

cd ${TEMPLATE_DIR}
export FSLDIR=${FSLDIR}
export ANTSPATH=${ANTSPATH}
export PATH="${FSLDIR}/bin:${PATH}"
export PATH="${ANTSPATH}:${PATH}"

TEMPLATE_LIST=id_list.txt

echo "Generating linear templates"

qsm_affine_template="${TEMPLATE_DIR}/template/qsm_affine_template.nii.gz"
fsladd ${qsm_affine_template} -m *qsm_offset_aff.nii.gz

t1_affine_template="${TEMPLATE_DIR}/template/t1_affine_template.nii.gz"
fsladd ${t1_affine_template} -m *t1_aff.nii.gz

r2s_affine_template="${TEMPLATE_DIR}/template/r2s_affine_template.nii.gz"
fsladd ${r2s_affine_template} -m *r2s_aff.nii.gz

echo "Generating nonlinear templates"
rm -f files.csv
for input in $(cat ../${TEMPLATE_LIST}); do
  echo ${TEMPLATE_DIR}/bet/${input}_t1_brain.nii.gz,${TEMPLATE_DIR}/qsm_to_t1_reg/${input}_qsm_offset.nii.gz,${TEMPLATE_DIR}/bet/${input}_r2s_brain.nii.gz >> files.csv
done

#depending on which option it runs a different version on the cluster
if  [ $QSUB_OPTION -eq 4 ]; then
	${CODE_PATH}/antsMultivariateTemplateConstruction2.sh -d 3 -k 3 -w 1x1x1 -n 0 -f 8x4x2x1 -s 3x2x1x0 -q 100x70x50x10 -n 0 -l 1 -m CC -c 4 -y 0 -o ${TEMPLATE_DIR}/template/multivariate_ -z ${t1_affine_template} -z ${qsm_affine_template} -z ${r2s_affine_template} files.csv
else
	antsMultivariateTemplateConstruction2.sh -d 3 -k 3 -w 1x1x1 -n 0 -f 8x4x2x1 -s 3x2x1x0 -q 100x70x50x10 -n 0 -l 1 -m CC -c 2 -j ${NUM_CORES} -y 0 -o multivariate_ -z ${t1_affine_template} -z ${qsm_affine_template} -z ${r2s_affine_template} files.csv
fi


`ln -sf multivariate_template0.nii.gz  ants_multivariate_t1_template.nii.gz`
`ln -sf multivariate_template1.nii.gz  ants_multivariate_qsm_template.nii.gz`
`ln -sf multivariate_template2.nii.gz  ants_multivariate_r2s_template.nii.gz`

#Now we warp the QSM images (pre-offset) to generate the "final" QSM template
#TODO: Note that this method does not then account for the shapeupdatetotemplate() procedure that is done in the ANTs scripts
#This was not done in Jannis' scripts either though. For more information, please see:
#https://sourceforge.net/p/advants/discussion/840261/thread/8651c760/?limit=25
#TODO: Could consider other interpolations here, but using Linear for now for consistency with ANTs template scripts
for input in $(cat ../${TEMPLATE_LIST}); do
  ${C3D_AFFINE_TOOL} -ref ../bet/${input}_t1_brain.nii.gz  -src ../reoriented/${input}_qsm_offset.nii.gz ../qsm_to_t1_reg/${input}_qsm_offset.mat -fsl2ras -oitk ${input}_qsm_to_t1_antsAffine.txt
  antsApplyTransforms -d 3 --float -i ../reoriented/${input}_qsm.nii.gz -r multivariate_template0.nii.gz -t $(ls multivariate_${input}_t1_brain*Warp.nii.gz | grep -v Inverse) -t multivariate_${input}_t1_brain*GenericAffine.mat -t ${input}_qsm_to_t1_antsAffine.txt -o ${input}_multivariate_qsmWarpedToTemplate.nii.gz
done
final_qsm_template="multivariate_qsm_template.nii.gz"
fsladd ${final_qsm_template} -m *_multivariate_qsmWarpedToTemplate.nii.gz

#create r2s template
for input in $(cat ../${TEMPLATE_LIST}); do
  ${C3D_AFFINE_TOOL} -ref ../bet/${input}_t1_brain.nii.gz  -src ../bet/${input}_r2s_brain.nii.gz ../qsm_to_t1_reg/${input}_r2s.mat -fsl2ras -oitk ${input}_r2s_to_t1_antsAffine.txt
  antsApplyTransforms -d 3 --float -i ../bet/${input}_r2s_brain.nii.gz -r multivariate_template0.nii.gz -t $(ls multivariate_${input}_t1_brain*Warp.nii.gz | grep -v Inverse) -t multivariate_${input}_t1_brain*GenericAffine.mat -t ${input}_r2s_to_t1_antsAffine.txt -o ${input}_multivariate_r2sWarpedToTemplate.nii.gz
done
final_r2s_template="multivariate_r2s_template.nii.gz"
fsladd ${final_r2s_template} -m *_multivariate_r2sWarpedToTemplate.nii.gz

echo "Done."
