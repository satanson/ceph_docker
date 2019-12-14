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

sudo modprobe rbd
docker exec -it ceph_mon0 /home/ceph/scripts/map_ceph_image.sh ${pool} ${image}
mnt=${pool}_${image}_mnt
mkdir -p ${mnt}
device=$(docker exec -it ceph_mon0 rbd device list|perl -lne "print \$1 if /\\b${pool}\\b\\s*\\b${image}\\b.*?(\\S+)\\s*$/")

if df -hl|grep "${mnt}";then
  green_print "${device} already mounted on ${mnt}"
  exit 0
fi

green_print "sudo mkfs.ext4 ${device}"
confirm
sudo mkfs.ext4 ${device:?"undefined"}

green_print "sudo mount -t ext4 ${device} ${mnt}"
sudo mount -t ext4 ${device} ${mnt}
sudo chown -R ${USER}:${USER} ${mnt}
