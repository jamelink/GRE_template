#!/bin/bash

#set up stuff
input=$1
main_dir=/project/3022026.02/POM/bids/derivatives/QSM_template_NDI
template_dir=$main_dir/template
T1_TEMPLATE=$template_dir/ants_multivariate_t1_template.nii.gz
R2s_TEMPLATE=$template_dir/multivariate_r2s_template.nii.gz
QSM_TEMPLATE=$template_dir/multivariate_qsm_template.nii.gz
SMWI_TEMPLATE=$template_dir/multivariate_smwi_template.nii.gz

C3D_AFFINE_TOOL="/opt/c3d/1.0.0/bin/c3d_affine_tool"
ANTSPATH="/opt/ANTs/20150225/build/bin/"
FSLDIR="/opt/fsl/6.0.3"

export FSLDIR=${FSLDIR}
export ANTSPATH=${ANTSPATH}
export PATH="${FSLDIR}/bin:${PATH}"
export PATH="${ANTSPATH}:${PATH}"

cd $main_dir
mkdir -p align

#align T1 to R2s
echo "Linear alignment..."
align_flirt=align/${input}_t1_brain_to_r2s.nii.gz
 if [ $(imtest ${align_flirt}) -eq "0" ]; then
flirt -in bet/${input}_t1_brain.nii.gz -ref bet/${input}_r2s_brain.nii.gz -dof 6 -out ${align_flirt} -omat align/${input}_t1_brain_to_r2s.mat -interp spline
fi

#mask R2s with T1
r2s_masked=align/${input}_r2s_t1_masked.nii.gz
 if [ $(imtest ${r2s_masked}) -eq "0" ]; then
fslmaths  bet/${input}_r2s_brain.nii.gz -mas  align/${input}_t1_brain_to_r2s.nii.gz ${r2s_masked}
fi

#apply align to R2s
iotk_mat=align/${input}_t1_brain_to_r2s_ITK.mat
 if [ $(imtest ${iotk_mat}) -eq "0" ]; then
${C3D_AFFINE_TOOL} -ref bet/${input}_r2s_brain.nii.gz -src bet/${input}_t1_brain.nii.gz align/${input}_t1_brain_to_r2s.mat -fsl2ras -oitk ${iotk_mat}
fi

#ANTS_registration
mkdir -p template_reg
echo "ANTs registration..."
output1=template_reg/${input}_multiVar
 if [ $(imtest ${output1}) -eq "0" ]; then
antsRegistration --dimensionality 3 --float 0 --output [${output1},template_reg/${input}_multiVarWarped.nii.gz,template_reg/${input}_multiVarWarped_Inv.nii.gz]  --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [${T1_TEMPLATE},align/${input}_t1_brain_to_r2s.nii.gz,1] --transform Rigid[0.1] --metric MI[${T1_TEMPLATE},align/${input}_t1_brain_to_r2s.nii.gz,0.5,32,Regular,0.25] --metric MI[${R2s_TEMPLATE},align/${input}_r2s_t1_masked.nii.gz,0.5,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform Affine[0.1] --metric MI[${T1_TEMPLATE},align/${input}_t1_brain_to_r2s.nii.gz,0.5,32,Regular,0.25] --metric MI[${R2s_TEMPLATE},align/${input}_r2s_t1_masked.nii.gz,0.5,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --transform SyN[0.1,3,0] --metric CC[${T1_TEMPLATE},align/${input}_t1_brain_to_r2s.nii.gz,0.5,4] --metric CC[${R2s_TEMPLATE},align/${input}_r2s_t1_masked.nii.gz,0.5,4] --convergence [100x70x50x20,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox
fi

#apply registration to original
echo "Applying registration..."
output_qsm=template_reg/${input}_qsm_warped.nii.gz
output_r2s=template_reg/${input}_r2s_warped.nii.gz
output_t1=template_reg/${input}_t1_warped.nii.gz
output_smwi=template_reg/${input}_smwi_warped.nii.gz

if [ $(imtest ${output_qsm}) -eq "0" ]; then
antsApplyTransforms -d 3 -i reoriented/${input}_qsm.nii.gz -t template_reg/${input}_multiVar1Warp.nii.gz -t template_reg/${input}_multiVar0GenericAffine.mat -o ${output_qsm} -r ${QSM_TEMPLATE}
fi

if [ $(imtest ${output_r2s}) -eq "0" ]; then
antsApplyTransforms -d 3 -i bet/${input}_r2s_brain.nii.gz -t template_reg/${input}_multiVar1Warp.nii.gz -t template_reg/${input}_multiVar0GenericAffine.mat -o ${output_r2s} -r ${R2s_TEMPLATE}
fi

if [ $(imtest ${output_smwi}) -eq "0" ]; then
antsApplyTransforms -d 3 -i bet/${input}_smwi_brain.nii.gz -t template_reg/${input}_multiVar1Warp.nii.gz -t template_reg/${input}_multiVar0GenericAffine.mat -o ${output_smwi} -r ${SMWI_TEMPLATE}
fi

if [ $(imtest ${output_t1}) -eq "0" ]; then
antsApplyTransforms -d 3 -i bet/${input}_t1_brain.nii.gz -t template_reg/${input}_multiVar1Warp.nii.gz -t template_reg/${input}_multiVar0GenericAffine.mat -t align/${input}_t1_brain_to_r2s_ITK.mat -o ${output_t1} -r ${T1_TEMPLATE}
fi
echo "Done."


