FROM centos:7
MAINTAINER Julian Wang <traceflight@outlook.com>

ENV DAQ_VERSION 2.2.2
ENV SNORT_VERSION 3.0.0
ENV SNORT_EXTRA_VERSION 1.0.0
ENV OPENAPPID_VERSION 8373
ENV PKG_CONFIG_VERSION 0.29.2

ENV PKG_CONFIG /usr/local/bin/pkg-config
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib64/pkgconfig:/usr/local/snort/lib/pkgconfig:/usr/local/snort/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/lib:/usr/local/lib
ENV LUA_PATH /usr/local/snort/include/snort/lua/\?.lua\;\;
ENV SNORT_LUA_PATH /usr/local/snort/etc/snort

ADD snort /usr/local/snort/etc/snort

# install epel-release
RUN yum -y update ca-certificates && \
    yum -y install epel-release wget gcc git automake autoconf libtool make gcc-c++ && \
    yum clean all && \
    yum makecache && \
    yum -y update

# install pkgconfig
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz -O pkg-config-${PKG_CONFIG_VERSION}.tar.gz && \
    tar -zxvf pkg-config-${PKG_CONFIG_VERSION}.tar.gz && \
    cd pkg-config-${PKG_CONFIG_VERSION} && \
    ./configure --with-internal-glib && \
    make && \
    make install
    
# install requirements
RUN yum -y install libdnet-devel hwloc-devel luajit-devel openssl-devel zlib-devel libpcap-devel zlib-devel pcre-devel lzma xz-devel bison flex cmake3 && \
    ldconfig

# install nfq
RUN yum install -y libnetfilter_queue-devel

# install cmake
RUN cd /home/snort/apps && \
    wget https://cmake.org/files/v3.12/cmake-3.12.1.tar.gz && \
    tar xf cmake-3.12.1.tar.gz && \
    cd cmake-3.12.1/ && \
    ./configure && \
    make && \
    make install
    
# install daq
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/snortplus/daq-${DAQ_VERSION}.tar.gz -O daq-${DAQ_VERSION}.tar.gz && \
    tar -zxvf daq-${DAQ_VERSION}.tar.gz && \
    cd daq-${DAQ_VERSION} && \
    ./configure && \
    make && \
    make install && \
    ldconfig

# install snort3
RUN cd /home/snort/apps && \
    git clone https://github.com/snort3/snort3.git && \
    cd snort3/ && \
    ./configure_cmake.sh --prefix=/usr/local/snort && \
    cd build && \
    make && \
    make install && \
    ldconfig

# install snort_extra
RUN cd /home/snort/apps && \
    git clone git://github.com/snortadmin/snort3_extra.git && \
    cd snort_extra && \
    ./configure_cmake.sh --prefix=/usr/local/snort/extra && \
    cd build && \
    make && \
    make install

# update community rules
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O snort3-community-rules.tar.gz && \
    tar -xvf snort3-community-rules.tar.gz && \
    cp snort3-community-rules/snort3-community.rules /usr/local/snort/etc/snort/rules/ && \
    cp snort3-community-rules/sid-msg.map /usr/local/snort/etc/snort/rules/

# install openappid
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/openappid/${OPENAPPID_VERSION} -O snort-openappid.tar.gz && \
    tar -zxvf snort-openappid.tar.gz && \
    mkdir -p /usr/local/cisco/apps && \
    cp -R odp /usr/local/cisco/apps

# Cleanup.
RUN yum clean all && \
    cd / && \
    rm -rf /var/log/* || true && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

RUN snort -V
