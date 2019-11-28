#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/scripts/functions.sh
source ${basedir}/ceph_ops.sh


op_cluster(){
  op=$(selectOption "bootstrap_start" "restart" "bootstrap" "start" "stop")
  green_print "exec: ${op}_ceph_cluster"
  confirm
  ${op}_ceph_cluster
}
op_service(){
  green_print "service: "
  service=$(selectOption "ceph_mon" "ceph_osd" "ceph_mgr" "ceph_client")

  if isIn ${service} "ceph_mon|ceph_osd|ceph_mgr";then
    green_print "cmd: "
    cmd=$(selectOption "bootstrap" "bootstrap_all" "mkfs" "mkfs_all" "start" "start_all" "stop" "stop_all" "restart" "restart_all")
    if isIn ${cmd} "mkfs_all|bootstrap_all|bootstrap_and_mkfs_all|start_all|stop_all|restart_all";then
      green_print "exec: ${cmd}_${service}"
      confirm
      ${cmd}_${service}
    elif isIn ${cmd} "bootstrap|start|stop|restart";then
      if isIn ${service} "ceph_mon";then
        node=$(selectOption $(eval "green_print ceph_mon{0..$((${ceph_mon_num}-1))}"))
      elif isIn ${service} "ceph_osd";then
        node=$(selectOption $(eval "green_print ceph_osd{0..$((${ceph_osd_num}-1))}"))
      elif isIn ${service} "ceph_mgr";then
        node=$(selectOption $(eval "green_print ceph_mgr{0..$((${ceph_mgr_num}-1))}"))
      fi
      green_print "exec: ${cmd}_${service} ${node}"
      confirm
      ${cmd}_${service} ${node}
    else
      :
    fi
  elif isIn ${service} "ceph_client";then
    green_print "cmd: "
    cmd=$(selectOption "start" "stop" "restart")
    green_print "node: "
    node=$(selectOption $(eval "green_print ceph_client{0..$((${ceph_client_num}-1))}"))
    green_print "exec: ${cmd}_${service} ${node}"
    confirm
    ${cmd}_${service} ${node}
  else
    :
  fi
}


op(){
  green_print "choose target:"
  target=$(selectOption "cluster" "service")
  if isIn ${target} "cluster";then
    op_cluster
  elif isIn ${target} "service";then
    op_service
  fi 
}

op
