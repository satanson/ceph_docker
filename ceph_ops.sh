#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
test  ${basedir} == ${PWD}
source ${basedir}/scripts/functions.sh

cephLocalRoot=$(cd ${basedir}/../ceph_all;pwd)
cephDockerRoot=/home/ceph/ceph

ceph_mon_num=$(perl -ne 'print if /^\s*\d+(\.\d+){3}\s+ceph_mon\d+\s*$/' ${PWD}/hosts |wc -l);
ceph_osd_num=$(perl -ne 'print if /^\s*\d+(\.\d+){3}\s+ceph_osd\d+\s*$/' ${PWD}/hosts |wc -l);
ceph_mgr_num=$(perl -ne 'print if /^\s*\d+(\.\d+){3}\s+ceph_mgr\d+\s*$/' ${PWD}/hosts |wc -l);
ceph_mds_num=$(perl -ne 'print if /^\s*\d+(\.\d+){3}\s+ceph_mds\d+\s*$/' ${PWD}/hosts |wc -l);
ceph_client_num=$(perl -ne 'print if /^\s*\d+(\.\d+){3}\s+ceph_client\d+\s*$/' ${PWD}/hosts |wc -l);

dockerFlags="--rm -u ceph -w /home/ceph --privileged --net static_net0 \
  -e PATH=/home/ceph/ceph/build/ceph-volume-virtualenv/bin:/home/ceph/ceph/build/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  -v ${PWD}/hosts:/etc/hosts \
  -v ${PWD}/ceph_conf:/etc/ceph \
  -v ${cephLocalRoot}:${cephDockerRoot} \
  -v ${PWD}/scripts:/home/ceph/scripts" 

dockerImage="ceph_build:v15.0.0"

stop_node(){
  local name=$1;shift
  set +e +o pipefail
  docker kill ${name}
  docker rm ${name}
  set -e -o pipefail
}

ceph_cmd(){
  local node=${1:?"undefined 'node'"};shift
  local detach=${1:?"undefined 'detach'"};shift
  local hup=${1:?"undefined 'hup'"};shift
  checkArgument detach ${detach} "attach|detach"
  checkArgument hup ${hup} "hup|nohup"
  local role=$(perl -e "print \$1 if qq/${node}/=~/ceph_(\\w+?)\\d+$/")

  local mode="-it"
  if isIn ${detach} "detach";then
    local mode="-dit"
  fi

  local cmd="$*"
  if isIn ${hup} "hup";then
    local cmd="$* && sleep 100000000"
  fi

	local ip=$(perl -aF/\\s+/ -ne "print \$F[0] if /\b$node\b/" hosts)

  local dataDir=$(cd $(readlink -f ${PWD}/data/${node}_data);pwd)
  local extraDockerFlags="--hostname ${node} --name ${node} --ip ${ip} \
    -v ${PWD}/data/${node}_logs:/var/log/ceph \
    -v ${PWD}/data/${node}_run:/var/run/ceph \
    -v ${dataDir}:/home/ceph/${role}"

  docker run ${mode} ${dockerFlags} ${extraDockerFlags} ${dockerImage} /bin/bash -c "${cmd}"
}

bootstrap_ceph_mon(){
  ceph_cmd ${1:?"undefined 'node'"} attach nohup /home/ceph/scripts/bootstrap_ceph_mon.sh
}

mkfs_ceph_mon(){
  local node=$1;shift
  ceph_cmd ${node} attach nohup /home/ceph/scripts/mkfs_ceph_mon.sh
}

mkfs_all_ceph_mon(){
  for node in $(eval "echo ceph_mon{0..$((${ceph_mon_num}-1))}") ;do
    mkfs_ceph_mon ${node}
  done
}

bootstrap_all_ceph_mon(){
  stop_all_ceph_mon
  bootstrap_ceph_mon ceph_mon0
  mkfs_all_ceph_mon
}

start_ceph_mon(){
  local node=$1;shift
  ceph_cmd ${node} detach hup /home/ceph/scripts/start_ceph_mon.sh
}

start_all_ceph_mon(){
  for node in $(eval "echo ceph_mon{0..$((${ceph_mon_num}-1))}") ;do
    start_ceph_mon ${node}
  done
}

stop_ceph_mon(){
  stop_node ${1:?"missing 'node'"}
}

stop_all_ceph_mon(){
  for node in $(eval "echo ceph_mon{0..$((${ceph_mon_num}-1))}") ;do
    stop_ceph_mon ${node}
  done
}

restart_ceph_mon(){
  stop_ceph_mon  ${1:?"missing 'node'"}
  start_ceph_mon $1
}

restart_all_ceph_mon(){
  for node in $(eval "echo ceph_mon{0..$((${ceph_mon_num}-1))}") ;do
    restart_ceph_mon ${node}
  done
}

start_ceph_client(){
  ceph_cmd ${1:?"missing 'node'"} attach nohup /bin/bash
}

stop_ceph_clent(){
  stop_node ${1:?"missing 'node'"}
}

restart_ceph_client(){
  stop_ceph_client ${1:?"missing 'node'"}
  start_ceph_client $1
}

#################################################################
## ceph-osd

bootstrap_ceph_osd(){
  local node=$1;shift
  stop_node ${node}
  ceph_cmd ${node} attach nohup /home/ceph/scripts/bootstrap_ceph_osd.sh
}

bootstrap_all_ceph_osd(){
  for node in $(eval "echo ceph_osd{0..$((${ceph_osd_num}-1))}") ;do
    bootstrap_ceph_osd ${node}
  done
}

stop_ceph_osd(){
  local node=$1;shift
  stop_node ${name}
}

stop_all_ceph_osd(){
  for node in $(eval "echo ceph_osd{0..$((${ceph_osd_num}-1))}") ;do
    stop_node ${node}
  done
}

start_ceph_osd(){
  local node=$1;shift
  stop_node ${node}
  #ceph_cmd ${node} attach nohup /bin/bash
  ceph_cmd ${node} detach hup /home/ceph/scripts/start_ceph_osd.sh
}

start_all_ceph_osd(){
  for node in $(eval "echo ceph_osd{0..$((${ceph_osd_num}-1))}") ;do
    start_ceph_osd ${node}
  done
}

restart_ceph_osd(){
  local node=$1;shift
  stop_node ${node}
  start_ceph_osd ${node}
}

restart_all_ceph_osd(){
  for node in $(eval "echo ceph_osd{0..$((${ceph_osd_num}-1))}") ;do
    restart_ceph_osd ${node}
  done
}

###############################################################################
# ceph-mgr

bootstrap_ceph_mgr(){
  ceph_cmd ${1:?"undefined node"} attach nohup /home/ceph/scripts/bootstrap_ceph_mgr.sh
}

bootstrap_all_ceph_mgr(){
  for node in $(eval "echo ceph_mgr{0..$((${ceph_mgr_num}-1))}") ;do
    bootstrap_ceph_mgr ${node}
  done
}

start_ceph_mgr(){
  ceph_cmd ${1:?"undefined node"} detach hup /home/ceph/scripts/start_ceph_mgr.sh
}

start_all_ceph_mgr(){
  for node in $(eval "echo ceph_mgr{0..$((${ceph_mgr_num}-1))}") ;do
    start_ceph_mgr ${node}
  done
}

stop_ceph_mgr(){
  stop_node ${1:?"undefined node"}
}

stop_all_ceph_mgr(){
  for node in $(eval "echo ceph_mgr{0..$((${ceph_mgr_num}-1))}") ;do
    start_ceph_mgr ${node}
  done
}

restart_ceph_mgr(){
  stop_ceph_mgr ${1:?"undefined node"}
  start_ceph_mgr $1
}

restart_all_ceph_mgr(){
  for node in $(eval "echo ceph_mgr{0..$((${ceph_mgr_num}-1))}") ;do
    restart_ceph_mgr ${node}
  done
}

bootstrap_ceph_cluster(){
  bootstrap_all_ceph_mon
  bootstrap_all_ceph_osd
  bootstrap_all_ceph_mgr
}

start_ceph_cluster(){
  start_all_ceph_mon
  start_all_ceph_osd
  start_all_ceph_mgr
}

bootstrap_start_ceph_cluster(){
  bootstrap_ceph_cluster
  start_ceph_cluster
}

stop_ceph_cluster(){
  stop_all_ceph_mgr
  stop_all_ceph_osd
  stop_all_ceph_mon
}

restart_ceph_cluster(){
  restart_all_ceph_mon
  restart_all_ceph_osd
  restart_all_ceph_mgr
}
