#!/bin/bash

#Author: Jitse Amelink, jitse.amelink@donders.ru.nl
#Last updated 20210422

TEMPLATE_DIR=$1
LOG_DIR=${TEMPLATE_DIR}/logs
CODE_PATH = "/project/3022026.02/POM/code/QSM"
mkdir -p ${LOG_DIR}
TEMPLATE_LIST = ${TEMPLATE_DIR}/id_list.txt

cd $TEMPLATE_DIR

for input in $(cat ../${TEMPLATE_LIST}); do
  final_input_file="${TEMPLATE_DIR}/template/${input}_qsm_offset_aff"
  if [ $(imtest ${output_r2s}) -eq "0" ]; then
    echo "${CODE_PATH}/qsm_templ_preprocess_sub.sh $TEMPLATE_DIR ${input}" | qsub -l 'walltime=01:00:00,mem=8Gb' -N '${input}_qsm_template_preprocessing' -e ${LOG_DIR} -o ${LOG_DIR} 
  else
	echo "Subject $input already preprocessed"
  fi

done
