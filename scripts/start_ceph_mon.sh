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
fsid="$(perl -lne 'print $1 if/^\s*fsid\s*=\s*(.*?)\s*$/' /etc/ceph/ceph.conf|tail -1)"
mon_initial_members="$(perl -lne 'print $1 if/^\s*mon_initial_members\s*=\s*(.*?)\s*$/' /etc/ceph/ceph.conf|tail -1)"
host=$(hostname)
id=${host}

green_print "mon_initial_members=${mon_initial_members} host=${host}"

if ! isIn ${host} $(replace_before_remove_whitespace ${mon_initial_members} "," "|");then
  red_print "ERROR: ${host} is not in ${mon_initial_members}" 
  exit 1
fi

mon_data=/home/ceph/mon/${cluster}-${id}

test -d ${mon_data}

rm -fr /var/log/ceph/*
green_print "start ceph-mon"

ceph-mon -f --conf /etc/ceph/ceph.conf --id ${host} --mon-data ${mon_data} --pid-file /var/run/ceph/${cluster}-${id}.pid
