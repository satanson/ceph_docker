#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/env.sh
source ${basedir}/functions.sh

${basedir}/add_libraries.sh

test -f /etc/ceph/ceph.conf
cluster=$(perl -ne 'print $1 if /^\s*cluster\s*=\s*(\w+)\s*$/' /etc/ceph/ceph.conf)
cluster=${cluster:-"ceph"}
host=$(hostname)
id=${host}
ip=$(perl -aF/\\s+/ -ne "print \$F[0] if /\b$host\b/" /etc/hosts)
test -d /home/ceph/mgr
mgr_data=/home/ceph/mgr/${cluster}-${id}
test -d ${mgr_data}
keyring=${mgr_data}/${cluster}-${id}.keyring
test -f ${keyring}

green_print "Start ceph-mgr@${id}"
ceph-mgr -i ${id}
