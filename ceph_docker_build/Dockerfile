from ubuntu:18.04

COPY sources.list /etc/apt/sources.list
RUN apt-get update -y 
RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        sudo \
                        inetutils-ping\
                        wget \
                        curl \
                        net-tools \
                        netcat \
                        vim \
                        && rm -fr /var/cache/apt/archives/*

RUN useradd -u 1000 -s /bin/bash -m ceph
RUN usermod -a -G sudo ceph
RUN echo "ceph ALL=(ALL) NOPASSWD : ALL" > /etc/sudoers


RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        python \
                        && rm -fr /var/cache/apt/archives/*
RUN python --version
COPY get-pip.py /tmp/
RUN python /tmp/get-pip.py
RUN python -m pip install --upgrade pip setuptools wheel

COPY ceph-15.0.0 /tmp/ceph
RUN cd /tmp/ceph && ./install-deps.sh && rm -fr /var/cache/apt/archives/*
RUN pip install PrettyTable
RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        ccache \
                        && rm -fr /var/cache/apt/archives/*

RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        librocksdb-dev \
                        librocksdb5.8 \
                        && rm -fr /var/cache/apt/archives/*

RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        lvm2 \
                        udev \
                        dmraid \
                        && rm -fr /var/cache/apt/archives/*

RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        tree \
                        && rm -fr /var/cache/apt/archives/*

RUN env DEBIAN_FRONTEND=noninteractive \
                        apt-get install -y --no-install-recommends \
                        gdb \
                        silversearcher-ag \
                        && rm -fr /var/cache/apt/archives/*

RUN mkdir -p /root/.pip
COPY pip.conf /root/.pip/
RUN pip install cryptography pyOpenSSL pecan
RUN pip install Werkzeug
