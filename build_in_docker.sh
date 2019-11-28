#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}
parentdir=$(cd ${basedir}/../;pwd)
CCACHE=${parentdir}/ccache
PIP_CACHE=${parentdir}/pip_cache
docker run -it --rm --name ceph_build --hostname ceph_build -u ceph -w /home/ceph/ceph --net host  \
  -v ${CCACHE}:/home/ceph/.ccache \
  -v ${PWD}:/home/ceph/ceph \
  -v ${PIP_CACHE}:/home/ceph/.cache/pip \
  ceph_build:v15.0.0 \
  /bin/bash
