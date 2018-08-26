FROM centos:7
MAINTAINER Julian Wang <traceflight@outlook.com>

ENV DAQ_VERSION 2.2.2
ENV SNORT_VERSION 3.0.0
ENV SNORT_EXTRA_VERSION 1.0.0
ENV OPENAPPID_VERSION 8373
ENV PKG_CONFIG_VERSION 0.29.2

ENV PKG_CONFIG /usr/local/bin/pkg-config
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib64/pkgconfig
ENV LD_LIBRARY_PATH /usr/local/lib
ENV LUA_PATH /usr/local/include/snort/lua/\?.lua\;\;
ENV SNORT_LUA_PATH /usr/local/etc/snort

# install epel-release
RUN yum -y install epel-release wget gcc automake autoconf libtool make gcc-c++ && \
    yum clean all && \
    yum makecache && \
    yum -y update

# install pkgconfig
RUN mkdir /tmp/snort && \
    cd /tmp/snort && \
    wget http://pkgconfig.freedesktop.org/releases/pkg-config-${PKG_CONFIG_VERSION}.tar.gz -O pkg-config-${PKG_CONFIG_VERSION}.tar.gz && \
    tar -zxvf pkg-config-${PKG_CONFIG_VERSION}.tar.gz && \
    cd pkg-config-${PKG_CONFIG_VERSION} && \
    ./configure --with-internal-glib && \
    make && \
    make install

# install requirements
RUN yum install -y libdnet libdnet-devel hwloc hwloc-devel luajit luajit-devel openssl openssl-devel libpcap libpcap-devel pcre pcre-devel flex bison cmake3 lzma xz-devel && \
    ldconfig

# install nfq
RUN yum install -y libnetfilter_queue libnetfilter_queue-devel

# install daq
RUN cd /tmp/snort && \
    wget https://www.snort.org/downloads/snortplus/daq-${DAQ_VERSION}.tar.gz -O daq-${DAQ_VERSION}.tar.gz && \
    tar -zxvf daq-${DAQ_VERSION}.tar.gz && \
    cd daq-${DAQ_VERSION} && \
    ./configure && \
    make && \
    make install && \
    ldconfig

# install snort3
RUN cd /tmp/snort && \
    wget https://www.snort.org/downloads/snortplus/snort-${SNORT_VERSION}-243-cmake.tar.gz -O snort-${SNORT_VERSION}-243-cmake.tar.gz && \
    tar -zxvf snort-${SNORT_VERSION}-243-cmake.tar.gz && \
    cd snort-${SNORT_VERSION}-/ && \
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make clean && \
    make && \
    make install

# install snort_extra
RUN cd /tmp/snort && \
    wget https://www.snort.org/downloads/snortplus/snort_extra-${SNORT_EXTRA_VERSION}-243-cmake.tar.gz -O snort_extra-${SNORT_EXTRA_VERSION}-243-cmake.tar.gz && \
    tar -zxvf snort_extra-${SNORT_EXTRA_VERSION}-243-cmake.tar.gz && \
    cd snort_extra-${SNORT_EXTRA_VERSION}-a4 && \
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make clean && \
    make && \
    make install

# add rules
RUN cd /tmp/snort && \
    wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O snort3-community-rules.tar.gz && \
    tar -xvf snort3-community-rules.tar.gz && \
    mkdir /usr/local/etc/snort/rules/ && \
    cp snort3-community-rules/snort3-community.rules /usr/local/etc/snort/rules/ && \
    cp snort3-community-rules/sid-msg.map /usr/local/etc/snort/rules/ && \
    cp /usr/local/include/snort/lua/snort_config.lua /usr/local/etc/snort/

# install openappid
RUN cd /tmp/snort && \
    wget https://www.snort.org/downloads/openappid/${OPENAPPID_VERSION} -O snort-openappid.tar.gz && \
    tar -zxvf snort-openappid.tar.gz && \
    mkdir -p /usr/local/cisco/apps && \
    cp -R odp /usr/local/cisco/apps && \
    sed -i "s/--app_detector_dir = 'directory to load appid detectors from'/app_detector_dir = '\/usr\/local\/cisco\/apps',/g" /usr/local/etc/snort/snort.lua

# Cleanup.
RUN yum clean all && \
    cd / && \
    rm -rf /var/log/* || true && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

RUN snort -V
