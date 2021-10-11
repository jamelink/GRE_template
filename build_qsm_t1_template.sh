#!/bin/bash

#Author: Niels Bergsland, npbergsland@bnac.net
#Last update: 20180424
#Version 0.1
#adapted for the Donders Centre for Cognitive Neuroscience by Jitse Amelink, jitse.amelink@donders.ru.nl
#Last update: 20210322
#  Initial release

#BEGIN CONFIG
FSLDIR="/opt/fsl/5.0.9/"
ANTSPATH="/opt/ANTs/20150225/build/bin/" #should be 2.1.0 - release dates miss by a month (2015/01 vs. 2015/02)
TEMPLATE_TARGET="${FSLDIR}/data/standard/MNI152_T1_1mm_brain"
NUM_CORES=$1
C3D_AFFINE_TOOL="/opt/c3d/1.0.0/bin/c3d_affine_tool"
TEMPLATE_DIR=$2
#END CONFIG

cd ${TEMPLATE_DIR}
export FSLDIR=${FSLDIR}
export ANTSPATH=${ANTSPATH}
export PATH="${FSLDIR}/bin:${PATH}"
export PATH="${ANTSPATH}:${PATH}"
#export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS}

#if [ $# -eq 0 ]; then
#  echo "Usage: ${0} TEMPLATE-LIST-FILE"
#  exit 1
#fi

TEMPLATE_LIST=id_list.txt

if [ ! -e $TEMPLATE_LIST ]; then
  echo "${TEMPLATE_LIST} does not exist!"
  exit 1
fi

#We check for the required inputs. 
echo "Checking for all required inputs..."
for input in $(cat ${TEMPLATE_LIST}); do
  im_types="qsm mask t1"
  for im_type in $(echo ${im_types}); do
    input_im_type="orig/${input}_${im_type}"
    if [ $(imtest ${input_im_type}) -eq "0" ]; then
      echo "${input_im_type} does not exit!"
      exit 1
    fi
  done
done

#We reorient all of the images to the standard MNI brain
#orientation. This is done to aid the linear registration step.
#Not strictly necessary if all inputs and target are oriented the same
#way but this ensures consistency
echo "Reorient to standard orientation..."
mkdir -p reoriented
for input in $(cat ${TEMPLATE_LIST}); do
  im_types="qsm mask t1"
  for im_type in $(echo ${im_types}); do
    input_im_type="orig/${input}_${im_type}"
    output_im_type="reoriented/${input}_${im_type}"
    if [ $(imtest ${output_im_type}) -eq "0" ]; then
      fslreorient2std ${input_im_type} ${output_im_type}
    fi
  done
done

#We add a constant value to ensure that all values are greater than 0
#so that we don't run into problems with negative values during the warping step.
echo "Adding constant offset of 1.5 to all QSM images..."
for input in $(cat ${TEMPLATE_LIST}); do
  input_qsm="reoriented/${input}_qsm"
  input_mask="reoriented/${input}_mask"
  output_qsm="reoriented/${input}_qsm_offset"
  if [ $(imtest ${output_qsm}) -eq "0" ]; then
    fslmaths ${input_qsm} -nan -add 1.5 -mas ${input_mask} ${output_qsm}
  fi
done

#We N4 the T1s
echo "Running N4 on the T1 images..."
mkdir -p n4
for input in $(cat ${TEMPLATE_LIST}); do
  input_t1="reoriented/${input}_t1.nii.gz"
  output_n4="n4/${input}_t1.nii.gz"
  if [ $(imtest ${output_n4}) -eq "0" ]; then
    N4BiasFieldCorrection -d 3 -i ${input_t1} -o ${output_n4} --shrink-factor 4 --convergence [50x50x50x50,0.0000001] --bspline-fitting [200]
  fi
done

#We need to brain extract the T1 since QSM is brain only
echo "Brain extracting the T1 images..."
mkdir -p bet
for input in $(cat ${TEMPLATE_LIST}); do
  input_t1="n4/${input}_t1"
  output_brain="bet/${input}_t1_brain"
  if [ $(imtest ${output_brain}) -eq "0" ]; then
    bet ${input_t1} ${output_brain} -B -f 0.2
  fi
done

#Input modalities need to be prealigned for template construction
echo "Registering QSM to T1..."
mkdir -p qsm_to_t1_reg

for input in $(cat ${TEMPLATE_LIST}); do
  input_qsm="reoriented/${input}_qsm_offset"
  output_qsm_reg="qsm_to_t1_reg/${input}_qsm_offset"
  if [ $(imtest ${output_qsm_reg}) -eq "0" ]; then
    flirt -in ${input_qsm} -ref bet/${input}_t1_brain -dof 6 -cost normmi -searchcost normmi -interp spline -out ${output_qsm_reg} -omat ${output_qsm_reg}.mat
  fi
done

#We run an affine registration of the T1s to the chosen reference (default is the MNI T1 1mm brain).
#The result is used as the target for generating the actual template.
#TODO: Parallelize this step. Done as a simple for loop for clarity.
mkdir -p template
echo "Generating initial affine template"
cd template
for input in $(cat ../${TEMPLATE_LIST}); do
  
  output_t1="${input}_t1_aff"
  if [ $(imtest ${output_t1}) -eq "0" ]; then
    input_t1="../bet/${input}_t1_brain"
    fsl_reg ${input_t1} ${TEMPLATE_TARGET} ${output_t1}  -a -flirt " -interp sinc"
  fi

  output_qsm="${input}_qsm_offset_aff"
  if [ $(imtest ${output_qsm}) -eq "0" ]; then
    input_qsm="../reoriented/${input}_qsm_offset"
    convert_xfm -omat ${input}_qsm_offset_aff.mat -concat ${input}_t1_aff.mat ../qsm_to_t1_reg/${input}_qsm_offset.mat
    flirt -in ${input_qsm} -ref ${TEMPLATE_TARGET} -init ${input}_qsm_offset_aff.mat -applyxfm -out ${output_qsm} -interp sinc
  fi
done

qsm_affine_template="qsm_affine_template.nii.gz"
fsladd ${qsm_affine_template} -m *qsm_offset_aff.nii.gz

t1_affine_template="t1_affine_template.nii.gz"
fsladd ${t1_affine_template} -m *t1_aff.nii.gz

echo "Generating nonlinear template"
rm -f files.csv
for input in $(cat ../${TEMPLATE_LIST}); do
  echo ../bet/${input}_t1_brain.nii.gz,../qsm_to_t1_reg/${input}_qsm_offset.nii.gz >> files.csv
done
antsMultivariateTemplateConstruction2.sh -d 3 -k 2 -w 1x1 -n 0 -f 8x4x2x1 -s 3x2x1x0 -q 100x70x50x10 -n 0 -l 1 -m CC -c 2 -j ${NUM_CORES} -y 0 -o multivariate_ -z ${t1_affine_template} -z ${qsm_affine_template} files.csv

`ln -sf multivariate_template0.nii.gz  ants_multivariate_t1_template.nii.gz`
`ln -sf multivariate_template1.nii.gz  ants_multivariate_qsm_template.nii.gz`

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

#echo "Finished building template. ants_template corresponds to the ANTs template built "
#echo "from the QSM images with an offset of 1.5 (and shape update). qsm_template corresponds to the original "
#echo "QSM images after having been warped and the simple average computed."
