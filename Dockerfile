FROM centos:7
MAINTAINER Julian Wang <traceflight@outlook.com>

ENV DAQ_VERSION 2.2.2
ENV SNORT_VERSION 3.0.0
ENV SNORT_EXTRA_VERSION 1.0.0
ENV OPENAPPID_VERSION 8373

ENV PKG_CONFIG /usr/bin/pkg-config
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib64/pkgconfig:/usr/local/snort/lib/pkgconfig:/usr/local/snort/lib64/pkgconfig
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib:/usr/local/lib
ENV LUA_PATH /usr/local/snort/include/snort/lua/\?.lua\;\;
ENV SNORT_LUA_PATH /usr/local/snort/etc/
ENV PATH $PATH:/usr/local/snort/bin

ADD etc /usr/local/snort/etc
ADD rules /usr/local/snort/rules

# install epel-release
RUN yum -y update ca-certificates && \
    yum -y install epel-release wget gcc git automake autoconf libtool make gcc-c++ && \
    yum clean all && \
    yum makecache && \
    yum -y update
    
# install requirements
RUN yum -y install cmake3 libdnet-devel hwloc-devel luajit-devel openssl-devel zlib-devel libpcap-devel zlib-devel pcre-devel lzma xz-devel bison flex cmake3 && \
    ldconfig

# install nfq
RUN yum install -y libnetfilter_queue-devel
    
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
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/snort && \
    make clean && \
    make && \
    make install

# install snort_extra
RUN cd /home/snort/apps && \
    git clone git://github.com/snortadmin/snort3_extra.git && \
    cd snort3_extra && \
    cmake3 -DCMAKE_INSTALL_PREFIX=/usr/local/snort/extra && \
    make clean && \
    make && \
    make install

# update community rules
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O snort3-community-rules.tar.gz && \
    tar -xvf snort3-community-rules.tar.gz && \
    cp snort3-community-rules/snort3-community.rules /usr/local/snort/rules/rules/ && \
    cp snort3-community-rules/sid-msg.map /usr/local/snort/rules/rules/

# install openappid
RUN cd /home/snort/apps && \
    wget https://www.snort.org/downloads/openappid/${OPENAPPID_VERSION} -O snort-openappid.tar.gz && \
    tar -zxvf snort-openappid.tar.gz && \
    mkdir -p /usr/local/snort/appid/ && \
    cp -R odp /usr/local/snort/appid/

# Cleanup.
RUN yum clean all && \
    cd / && \
    rm -rf /var/log/* || true && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/*

RUN snort -V
