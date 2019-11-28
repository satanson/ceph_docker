#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/env.sh
source ${basedir}/functions.sh

test -f /etc/ceph/ceph.conf
cluster=$(perl -ne 'print $1 if /^\s*cluster\s*=\s*(\w+)\s*$/' /etc/ceph/ceph.conf)
cluster=${cluster:-"ceph"}
host=$(hostname)
id=${host}
ip=$(perl -aF/\\s+/ -ne "print \$F[0] if /\b$host\b/" /etc/hosts)
test -d /home/ceph/mgr
mgr_data=/home/ceph/mgr/${cluster}-${id}

green_print "Phase 1: Create mgr_data ${mgr_data}"
mkdir -p ${mgr_data}
cat <<DONE
cluster=${cluster}
id=${id}
ip=${ip}
mgr_data=${mgr_data}
DONE
echo "Done!"
hrule

keyring=${mgr_data}/${cluster}-${id}.keyring
green_print "Phase 2: Auth mgr.${id} and obtain keyring ${keyring}"
ceph auth get-or-create mgr.${id}  mon 'allow profile mgr' osd 'allow *' mds 'allow *' > ${keyring}
cat ${keyring}
echo "Done!"
hrule

green_print "All done!!!"
