#!/bin/bash

#Author: Niels Bergsland, npbergsland@bnac.net
#Last update: 20180424
#Version 0.2
#adapted for the Donders Centre for Cognitive Neuroscience by Jitse Amelink, jitse.amelink@donders.ru.nl
#this version includes R2*-maps.
#Last update: 20210422

#BEGIN CONFIG
FSLDIR="/opt/fsl/6.0.3"
TEMPLATE_TARGET="${FSLDIR}/data/standard/MNI152_T1_1mm_brain"
TEMPLATE_DIR=$1
input=$2 #SUB-ID
CODE_PATH="/project/3022026.02/POM/code/QSM"

cd ${TEMPLATE_DIR}
export FSLDIR=${FSLDIR}
export PATH="${FSLDIR}/bin:${PATH}"


#We check for the required inputs. 
echo "Checking for all required inputs..."

im_types="qsm mask t1 r2s"
for im_type in $(echo ${im_types}); do
  input_im_type="orig/${input}_${im_type}"
  if [ $(imtest ${input_im_type}) -eq "0" ]; then
    echo "${input_im_type} does not exit!"
    exit 1
  fi
done


#We reorient all of the images to the standard MNI brain
#orientation. This is done to aid the linear registration step.
#Not strictly necessary if all inputs and target are oriented the same
#way but this ensures consistency
echo "Reorient to standard orientation..."
mkdir -p reoriented
im_types="qsm mask t1 r2s"
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
input_qsm="reoriented/${input}_qsm"
input_mask="reoriented/${input}_mask"
output_qsm="reoriented/${input}_qsm_offset"
if [ $(imtest ${output_qsm}) -eq "0" ]; then
  fslmaths ${input_qsm} -nan -add 1.5 -mas ${input_mask} ${output_qsm}
fi

#We N4 the T1s
echo "Running N4 on the T1 images..."
mkdir -p n4
input_t1="reoriented/${input}_t1.nii.gz"
output_n4="n4/${input}_t1.nii.gz"
if [ $(imtest ${output_n4}) -eq "0" ]; then
  N4BiasFieldCorrection -d 3 -i ${input_t1} -o ${output_n4} --shrink-factor 4 --convergence [50x50x50x50,0.0000001] --bspline-fitting [200]
fi
done

#We need to brain extract the T1 since QSM is brain only
echo "Brain extracting the T1 images..."
mkdir -p bet
input_t1="n4/${input}_t1"
  output_brain="bet/${input}_t1_brain"
if [ $(imtest ${output_brain}) -eq "0" ]; then
  bet ${input_t1} ${output_brain} -B -f 0.2
fi

#Brain extract the R2star maps also
echo "Applying mask to R2* images..."
mask="reoriented/${input}_mask"
input_r2s="reoriented/${input}_r2s"
output_brain="bet/${input}_r2s_brain_uncorrected"
if [ $(imtest ${output_brain}) -eq "0" ]; then
  fslmaths ${input_r2s} -mas ${mask} ${output_brain}
fi

#Normalization step
echo "Thresholding R2* images..."
input_r2s="bet/${input}_r2s_brain_uncorrected"
output_brain="bet/${input}_r2s_brain"
if [ $(imtest ${output_brain}) -eq "0" ]; then
  fslmaths ${input_r2s} -uthr 100 ${output_brain}
fi

#Input modalities need to be prealigned for template construction
echo "Registering QSM to T1..."
mkdir -p qsm_to_t1_reg
input_qsm="reoriented/${input}_qsm_offset"
output_qsm_reg="qsm_to_t1_reg/${input}_qsm_offset"
if [ $(imtest ${output_qsm_reg}) -eq "0" ]; then
  flirt -in ${input_qsm} -ref bet/${input}_t1_brain -dof 6 -cost normmi -searchcost normmi -interp spline -out ${output_qsm_reg} -omat ${output_qsm_reg}.mat
fi

echo "Registering R2* to T1..."
input_r2s="bet/${input}_r2s_brain"
output_r2s_reg="qsm_to_t1_reg/${input}_r2s"
if [ $(imtest ${output_r2s_reg}) -eq "0" ]; then
  flirt -in ${input_r2s} -ref bet/${input}_t1_brain -dof 6 -cost normmi -searchcost normmi -interp spline -out ${output_r2s_reg} -omat ${output_r2s_reg}.mat
fi

#We run an affine registration of the T1s to the chosen reference (default is the MNI T1 1mm brain).
#The result is used as the target for generating the actual template.
#TODO: Parallelize this step. Done as a simple for loop for clarity.
mkdir -p template
echo "Generating initial affine template"
cd template
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

output_r2s="${input}_r2s_aff"
if [ $(imtest ${output_r2s}) -eq "0" ]; then
  input_r2s="../bet/${input}_r2s_brain"
  convert_xfm -omat ${input}_r2s_aff.mat -concat ${input}_t1_aff.mat ../qsm_to_t1_reg/${input}_r2s.mat
  flirt -in ${input_r2s} -ref ${TEMPLATE_TARGET} -init ${input}_r2s_aff.mat -applyxfm -out ${output_r2s} -interp sinc
fi

echo "Preprocessing done. Continue with running the main template script."
