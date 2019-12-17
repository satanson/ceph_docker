#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/scripts/functions.sh

poolimage=${1?:"missing 'poolimage'"};shift
set $(perl -e "print qq#${poolimage}#=~y#/# #r")
if [ $# -eq 1 ];then
  pool=rbd
  image=$1
elif [ $# -eq 2 ];then
  pool=$1
  image=$2
else
  echo "ERROR: Illegal format\n\t$(basename ${BASH_SOURCE:-$0}) [pool/]image" >&2
  exit 1
fi

device=$(docker exec -it ceph_mon0 rbd device list|perl -lne "print \$1 if /\\b${pool}\\b\\s*\\b${image}\\b.*?(\\S+)\\s*$/")
if [ -z "${device}" ];then
  echo "${device} not exists!"
  if df -hl |grep "${device}";then
    sudo umount ${device}
  fi
else
  docker exec -it ceph_mon0 /home/ceph/scripts/rm_rbd.sh ${pool} ${image}
fi


