from centos:7.4.1708

RUN rm -fr /etc/yum.repo.d/*
COPY Centos-7.repo /etc/yum.repo.d/
RUN yum clean all && yum makecache && yum install -y epel-release && yum clean all && yum makecache && yum -y update

RUN yum install -y  \
  sudo \
  inetutils-ping\
  wget \
  curl \
  net-tools \
  netcat \
  vim \
  python \
  ccache \
  lvm2 \
  udev \
  dmraid \
  tree \
  gdb \
  silversearcher-ag \
  && yum clean packages

RUN useradd -u 1000 -s /bin/bash -m ceph
RUN usermod -a -G wheel ceph
RUN echo "%ceph ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ceph


RUN python --version
COPY get-pip.py /tmp/
RUN python /tmp/get-pip.py
RUN mkdir -p /root/.pip
COPY pip.conf /root/.pip/
RUN python -m pip install --upgrade pip setuptools wheel
RUN pip install cryptography pyOpenSSL pecan virtualenv
RUN pip install Werkzeug
RUN yum clean all
RUN pip install PrettyTable

RUN yum install -y  \
  bc \
  && yum clean packages

COPY epel.repo /etc/yum.repos.d/
RUN yum makecache

COPY ceph-15.0.0 /tmp/ceph
RUN perl -i.bak -lpe 's{dl.fedoraproject.org/pub}{mirrors.tuna.tsinghua.edu.cn}g' /tmp/ceph/install-deps.sh
RUN yum install -y libselinux-utils
#RUN setenforce 0 
RUN yum install -y git
RUN cd /tmp/ceph && bash -x ./install-deps.sh
RUN pip install bcrypt jwt==0.3.2
RUN yum install -y the_silver_searcher bzip2 rpm-build rpmdevtools devtoolset-7-gcc-c++ python3-devel python36-Cython
RUN yum clean packages
