#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/env.sh
source ${basedir}/functions.sh

id=ceph_mds0
dataDir=/home/ceph/mds
keyring=/etc/ceph/ceph-${id}.keyring
test -d ${dataDir}
mkdir -p ${dataDir}/ceph-${id}
ceph-authtool --create-keyring ${keyring} --gen-key -n mds.${id}
ceph auth add mds.${id} osd "allow rwx" mds "allow" mon "allow profile mds" -i ${keyring}
ceph-mds -f  --cluster ceph  -i ${id} 
