#!/bin/bash
set -e -o pipefail
basedir=$(cd $(dirname $(readlink -f ${BASH_SOURCE:-$0}));pwd)
cd ${basedir}

source ${basedir}/env.sh
source ${basedir}/functions.sh

green_print "Phase 1: Generate uuid,osd_secret,id for ceph-osd"

host=$(hostname)
ok=$(perl -e "print qq/ok/ if qq/${host}/=~m/^ceph_osd\\d+$/")
test "x${ok}x" = "xokx"
ip=$(perl -aF/\\s+/ -ne "print \$F[0] if /\b$host\b/" /etc/hosts)
id=${host##ceph_osd}
uuid=$(uuidgen)
osd_secret=$(ceph-authtool --gen-print-key)
cat<<DONE
host=${host}
ip=${ip}
id=${id}
uuid=${uuid}
osd_secret=${osd_secret}
DONE

hrule

green_print "Phase 2: Decommission old osd.${id}"
${basedir}/decommission_osd.sh ${id}
echo "Done"
hrule

#id=$(echo "{\"cephx_secret\": \"$OSD_SECRET\"}" | \
#	   ceph osd new $UUID -i - \
#	      -n client.bootstrap-osd -k /var/lib/ceph/bootstrap-osd/ceph.keyring)

green_print "Phase 3: Register new osd.${id}"
ceph osd new ${uuid} ${id}
echo "Done"
hrule

green_print "Phase 4: Generate block device for data and journal"
test -d /home/ceph/osd
dataFile=/home/ceph/osd/datablkdev
journalFile=/home/ceph/osd/journalblkdev
dataBlkdev=/dev/datablkdev
journalBlkdev=/dev/journalblkdev
dataMinorId=$((40+${id}*2+0))
journalMinorId=$((40+${id}*2+1))

[ ! -f ${dataFile} ] && dd if=/dev/zero of=${dataFile} bs=1M count=10K
[ ! -f ${journalFile} ] && dd if=/dev/zero of=${journalFile} bs=1M count=10K

# mount first
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
sudo mkfs.xfs -f ${dataBlkdev:?"undefined"}
sudo mkfs.xfs -f ${journalBlkdev:?"undefined"}

dataDir=/home/ceph/osd/data-${host}
journalDir=/home/ceph/osd/journal-${host}
mkdir -p ${dataDir}
mkdir -p ${journalDir}
sudo mount -t xfs ${dataBlkdev} ${dataDir}
sudo mount -t xfs ${journalBlkdev} ${journalDir}
#ln -sf ${dataBlkdev} ${dataDir}/block
sudo chown -R ceph:ceph ${dataBlkdev}
sudo chown -R ceph:ceph ${journalBlkdev}
sudo chown -R ceph:ceph ${dataDir}
sudo chown -R ceph:ceph ${journalDir}
echo "Done"
hrule

green_print "Phase 5: Generate keyring for osd.${id}"
keyring=/etc/ceph/ceph.osd.${id}.keyring
ceph-authtool --create-keyring ${keyring} --name osd.${id} --add-key ${osd_secret}
ceph auth add osd.${id} osd 'allow *' mon 'allow rwx' -i ${keyring}
cat ${keyring}
hrule

#ceph-osd --mkfs --conf /etc/ceph/ceph.conf  --monmap /etc/ceph/monmap --osd-data ${dataDir} --osd-journal ${journalDir}  --keyring ${keyring} --osd-uuid ${uuid} -i ${id}
#ceph-osd --mkjournal --conf /etc/ceph/ceph.conf  --monmap /etc/ceph/monmap --osd-data ${dataDir} --osd-journal ${journalDir}  --keyring ${keyring} --osd-uuid ${uuid} -i ${id}
${basedir}/add_libraries.sh
green_print "Phase 6: format dataDir ${dataDir} for osd.${id}"
ceph-osd --mkfs --mkkey --conf /etc/ceph/ceph.conf --osd-uuid ${uuid} -i ${id}
#ceph-osd --mkfs --conf /etc/ceph/ceph.conf  --monmap /etc/ceph/monmap --osd-data ${dataDir} --osd-journal ${journalDir}  --keyring ${keyring} --osd-uuid ${uuid} -i ${id}
tree ${dataDir}
hrule

#green_print "Phase 7: format journalDir ${journalDir} for osd.${id}"
#ceph-osd --mkjournal --conf /etc/ceph/ceph.conf --osd-uuid ${uuid} -i ${id}
#tree ${journalDir}
#hrule

green_print "All done!!!"
#ceph-osd -f --conf /etc/ceph/ceph.conf
