#!/bin/bash
sudo mkdir -p /usr/local/lib/ceph/erasure-code/
sudo mkdir -p /usr/local/lib/ceph/compressor/
sudo ln -sf /home/ceph/ceph/build/lib/libceph_snappy.so /usr/local/lib/ceph/compressor/libceph_snappy.so
sudo ln -sf /home/ceph/ceph/build/lib/libec_clay.so /usr/local/lib/ceph/erasure-code/libec_clay.so
sudo ln -sf /home/ceph/ceph/build/lib/libec_isa.so /usr/local/lib/ceph/erasure-code/libec_isa.so
sudo ln -sf /home/ceph/ceph/build/lib/libec_jerasure_generic.so /usr/local/lib/ceph/erasure-code/libec_jerasure_generic.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_jerasure.so /usr/local/lib/ceph/erasure-code/libec_jerasure.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_jerasure_sse3.so /usr/local/lib/ceph/erasure-code/libec_jerasure_sse3.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_jerasure_sse4.so /usr/local/lib/ceph/erasure-code/libec_jerasure_sse4.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_lrc.so /usr/local/lib/ceph/erasure-code/libec_lrc.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_shec_generic.so /usr/local/lib/ceph/erasure-code/libec_shec_generic.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_shec.so /usr/local/lib/ceph/erasure-code/libec_shec.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_shec_sse3.so /usr/local/lib/ceph/erasure-code/libec_shec_sse3.so 
sudo ln -sf /home/ceph/ceph/build/lib/libec_shec_sse4.so /usr/local/lib/ceph/erasure-code/libec_shec_sse4.so
