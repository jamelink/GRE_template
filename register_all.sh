#!/bin/bash

TEMPLATE_DIR=$1
#LOG_DIR="${TEMPLATE_DIR}/logs"
CODE_PATH="/project/3022026.02/POM/code/QSM"
#mkdir -p ${LOG_DIR}
TEMPLATE_LIST=${TEMPLATE_DIR}/id_list.txt

cd $TEMPLATE_DIR

for input in $(cat ${TEMPLATE_LIST}); do
output_qsm=$TEMPLATE_DIR/template_reg/${input}_qsm_warped.nii.gz
output_r2s=$TEMPLATE_DIR/template_reg/${input}_r2s_warped.nii.gz
output_t1=$TEMPLATE_DIR/template_reg/${input}_t1_warped.nii.gz
  if [[ $(imtest ${output_qsm}) -eq "0" ]] || [[ $(imtest ${output_t1}) -eq "0" ]] ||  [[ $(imtest ${output_r2s}) -eq "0" ]]; then
    echo "${CODE_PATH}/register_sub.sh ${input}" | qsub -l 'walltime=12:00:00,mem=12Gb' -N "${input}_registration"
  else
	echo "Subject $input already preprocessed"
  fi

done
