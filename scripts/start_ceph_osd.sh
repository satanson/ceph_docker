#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/env.sh
source ${basedir}/functions.sh

green_print "Phase 1: Check environment"
${basedir}/add_libraries.sh

host=$(hostname)
ok=$(perl -e "print qq/ok/ if qq/${host}/=~m/^ceph_osd\\d+$/")
test "x${ok}x" = "xokx"
ip=$(perl -aF/\\s+/ -ne "print \$F[0] if /\b$host\b/" /etc/hosts)
id=${host##ceph_osd}
keyring=/etc/ceph/ceph.osd.${id}.keyring
dataFile=/home/ceph/osd/datablkdev
journalFile=/home/ceph/osd/journalblkdev
dataBlkdev=/dev/datablkdev
journalBlkdev=/dev/journalblkdev
dataMinorId=$((40+${id}*2+0))
journalMinorId=$((40+${id}*2+1))
dataDir=/home/ceph/osd/data-${host}
journalDir=/home/ceph/osd/journal-${host}

test -d /home/ceph/osd
test -f ${dataFile}
test -f ${journalFile} 
test -f ${keyring}
#test -f ${dataDir}/fsid

cat<<DONE
host=${host}
ip=${ip}
id=${id}
uuid=${dataFile}
$(cat ${dataFile}/fsid)
keyring=${keyring}
$(cat ${keyring})
osd_secret=${osd_secret}
DONE
echo "Done!"
hrule

green_print "Phase 2: Mount block device for data and journal"

# umount first
df -hl |perl -lne "print \$1 if m{(/dev/loop${dataMinorId}|/dev/loop${journalMinorId}|${dataBlkdev}|${journalBlkdev})}" \
  | xargs -i{} sudo umount '{}'
# losetup detach
losetup --list |perl -lne "print \$1 if m{(/dev/loop${dataMinorId}|/dev/loop${journalMinorId}|${dataBlkdev}|${journalBlkdev})}" \
  | xargs -i{} sudo losetup -d '{}'
# rm blkdev
for blkdev in /dev/loop${dataMinorId} /dev/loop${journalMinorId} ${dataBlkdev} ${journalBlkdev};do
  set +e +o pipefail
  sudo losetup -d ${blkdev}
  [ -b ${blkdev} ] && sudo rm ${blkdev:?"undefined"}
  set -e -o pipefail
done

sudo mknod ${dataBlkdev} b 7 ${dataMinorId}
sudo mknod ${journalBlkdev} b 7 ${journalMinorId}
sudo losetup ${dataBlkdev} ${dataFile}
sudo losetup ${journalBlkdev} ${journalFile}
#sudo mkfs.xfs -f ${dataBlkdev:?"undefined"}
#sudo mkfs.xfs -f ${journalBlkdev:?"undefined"}

test -d ${dataDir}
test -d ${journalDir}
sudo mount -t xfs ${dataBlkdev} ${dataDir}
sudo mount -t xfs ${journalBlkdev} ${journalDir}
#ln -sf ${dataBlkdev} ${dataDir}/block
sudo chown -R ceph:ceph ${dataBlkdev}
sudo chown -R ceph:ceph ${journalBlkdev}
sudo chown -R ceph:ceph ${dataDir}
sudo chown -R ceph:ceph ${journalDir}
echo "Done"
hrule
green_print "Phase 3: Start ceph-osd"
ceph-osd -f --conf /etc/ceph/ceph.conf -i ${id}
sleep 2

if ps -ef |grep ceph-osd >/dev/null 2>&1;then
  green_print "ceph-osd.${id}@${host} ACTIVE"
else
  red_print "ceph-osd.${id}@${host} INACTIVE"
fi

echo "Done"
hrule
