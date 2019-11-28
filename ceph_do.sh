#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/scripts/functions.sh
source ${basedir}/ceph_ops.sh

echo "service: "
service=$(selectOption "ceph_mon" "ceph_osd" "ceph_mgr" "ceph_client")

if isIn ${service} "ceph_mon|ceph_osd|ceph_mgr";then
  echo "cmd: "
  cmd=$(selectOption "bootstrap" "bootstrap_all" "mkfs" "mkfs_all" "start" "start_all" "stop" "stop_all" "restart" "restart_all")
  if isIn ${cmd} "mkfs_all|bootstrap_all|bootstrap_and_mkfs_all|start_all|stop_all|restart_all";then
    echo "exec: ${cmd}_${service}"
    confirm
    ${cmd}_${service}
  elif isIn ${cmd} "bootstrap|start|stop|restart";then
    if isIn ${service} "ceph_mon";then
      node=$(selectOption $(eval "echo ceph_mon{0..$((${ceph_mon_num}-1))}"))
    elif isIn ${service} "ceph_osd";then
      node=$(selectOption $(eval "echo ceph_osd{0..$((${ceph_osd_num}-1))}"))
    elif isIn ${service} "ceph_mgr";then
      node=$(selectOption $(eval "echo ceph_mgr{0..$((${ceph_mgr_num}-1))}"))
    fi
    echo "exec: ${cmd}_${service} ${node}"
    confirm
    ${cmd}_${service} ${node}
  else
    :
  fi
elif isIn ${service} "ceph_client";then
  echo "cmd: "
  cmd=$(selectOption "start" "stop" "restart")
  echo "node: "
  node=$(selectOption $(eval "echo ceph_client{0..$((${ceph_client_num}-1))}"))
  echo "exec: ${cmd}_${service} ${node}"
  confirm
  ${cmd}_${service} ${node}
else
  :
fi
