#!/bin/bash

#Author: Jitse Amelink, jitse.amelink@donders.ru.nl
#Last updated 20210422

TEMPLATE_DIR=$1
#LOG_DIR="${TEMPLATE_DIR}/logs"
CODE_PATH="/project/3022026.02/POM/code/QSM"
#mkdir -p ${LOG_DIR}
TEMPLATE_LIST=${TEMPLATE_DIR}/id_list.txt

cd $TEMPLATE_DIR

for input in $(cat ${TEMPLATE_LIST}); do
  input_qsm="${TEMPLATE_DIR}/template/${input}_qsm_offset_aff"
  input_t1="${TEMPLATE_DIR}/template/${input}_t1_aff"
  input_smwi="${TEMPLATE_DIR}/template/${input}_smwi_aff"
  if [[ $(imtest ${input_qsm}) -eq "0" ]] || [[ $(imtest ${input_t1}) -eq "0" ]] || [[ $(imtest ${input_smwi}) -eq "0" ]]; then
    echo "${CODE_PATH}/qsm_templ_preproces_sub_smwi.sh $TEMPLATE_DIR ${input}" | qsub -l 'walltime=01:00:00,mem=4Gb' -N '${input}_qsm_template_preprocessing'
  else
	echo "Subject $input already preprocessed"
  fi

done
