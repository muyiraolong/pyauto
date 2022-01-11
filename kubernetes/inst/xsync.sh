#!/bin/bash
# HEADER
#================================================================
#% SYNOPSIS
#%    ${prog}  file1
#%
#% DESCRIPTION
#%    xsync
#%
#% ARGUMENTS
#%     file1 file2 file3
#%
#% EXAMPLES
#%    ${prog} file1
#%
#================================================================
#  HISTORY
#     20220104  innod motingxia@163.com
#================================================================
#  NOTES
#================================================================
# END_OF_HEADER
#================================================================

#================================================================
#  IMPORT COMMON FUNCTIONS AND VARIABLES
#================================================================
RUNDIR="$(cd "$(dirname "${0}")" && pwd)"
if [ -z "${FUNCTIONS_IMPORTED}" ]; then
  . ${RUNDIR}/functions.ksh
fi

#================================================================
#  FUNCTIONS
#================================================================
if [ $# -lt 1 ]
then
  usage
  exit 8;
fi

source ~/.bash_profile
. ${RUNDIR}/master-slave.sh


scriptname=$(basename $0)
if ! [ -f ${LOG_FILE_DIR}/${scriptname}.log  ];then
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
else
  rm -rf ${LOG_FILE_DIR}/${scriptname}.log
  touch ${LOG_FILE_DIR}/${scriptname}.log
  LogFile=${LOG_FILE_DIR}/${scriptname}.log
fi
export LogFile=${LOG_FILE_DIR}/${scriptname}.log
echo ${LogFile}


#================================================================
# xsync
#================================================================
{

#2. 遍历集群所有机器
echo ${NODE_NAMES}
for host in in `seq 0 ${#NODE_NAMES[@]}`
do
  log_info "====================  ${NODE_NAMES[$host]}  ===================="
  #3. 遍历所有目录，挨个发送
  for file in $@
  do
    #4 判断文件是否存在
    if [ -e $file ]
    then
      #5. 获取父目录
      pdir=$(cd -P $(dirname $file); pwd)
      #6. 获取当前文件的名称
      fname=$(basename $file)
      ssh ${NODE_NAMES[$i]}  "mkdir -p $pdir"
      rsync -av $pdir/$fname ${NODE_NAMES[$host]}:$pdir
    else
      log_info $file does not exists!
    fi
  done
done
}