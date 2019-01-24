FROM centos:7
MAINTAINER Julian Wang <traceflight@outlook.com>

ENV DAQ_VERSION 2.2.2
ENV SNORT_VERSION 3.0.0
ENV SNORT_EXTRA_VERSION 1.0.0
ENV OPENAPPID_VERSION 9552
ENV CMAKE_VERSION 3.12
ENV PCRE_VERSION 8.41
ENV HYPERSCAN_VERSION 5.0.0

ENV PKG_CONFIG /usr/bin/pkg-config
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/lib:/usr/local/lib
ENV LUA_PATH /usr/local/include/snort/lua/\?.lua\;\;
ENV SNORT_LUA_PATH /usr/local/etc/snort/
ENV PATH $PATH:/usr/local/bin

ADD rules /usr/local/etc/snort/rules
ADD custom /usr/local/etc/snort/appid/custom

# install requirements
RUN yum -y update ca-certificates && \
    yum remove cmake && \
    yum -y install epel-release wget gcc git automake autoconf libtool make gcc-c++ && \
    yum makecache && \
    yum -y update && \
    yum -y install libnetfilter_queue-devel libunwind-devel sqlite-devel libdnet-devel hwloc-devel luajit-devel openssl-devel zlib-devel libpcap-devel zlib-devel lzma xz-devel bison flex && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    ldconfig

# install cmake
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://cmake.org/files/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.0.tar.gz && \
    tar xf cmake-${CMAKE_VERSION}.0.tar.gz && cd cmake-${CMAKE_VERSION}.0 && \
    ./configure && \
    make && \
    make install && \
    rm -rf /home/snort/apps

# install pcre
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.gz && \
    tar xf pcre-${PCRE_VERSION}.tar.gz && cd pcre-${PCRE_VERSION} && \
    ./configure --libdir=/usr/lib64 --includedir=/usr/include && \
    make && \
    make install && \
    rm -rf /home/snort/apps
     
# install ragel boost hyperscan
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget http://www.colm.net/files/ragel/ragel-6.10.tar.gz && \
    tar xf ragel-6.10.tar.gz && cd ragel-6.10 && \
    ./configure && \
    make && \
    make install && \
    cd /home/snort/apps && \
    wget https://dl.bintray.com/boostorg/release/1.67.0/source/boost_1_67_0.tar.gz && \
    tar xf boost_1_67_0.tar.gz && \
    cd /home/snort/apps && \
    wget https://github.com/intel/hyperscan/archive/v${HYPERSCAN_VERSION}.tar.gz -O hyperscan-${HYPERSCAN_VERSION}.tar.gz && \
    tar xf hyperscan-${HYPERSCAN_VERSION}.tar.gz && \
    mkdir hs-build && cd hs-build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DBOOST_ROOT=../boost_1_67_0 ../hyperscan-${HYPERSCAN_VERSION} && \
    make && \
    make install && \
    cp /usr/local/lib64/pkgconfig/libhs.pc /usr/lib64/pkgconfig/ && \
    rm -rf /home/snort/apps

# install flatbuffers
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://github.com/google/flatbuffers/archive/v1.9.0.tar.gz -O flatbuffers-1.9.0.tar.gz && \
    tar xf flatbuffers-1.9.0.tar.gz && \
    mkdir fb-build && cd fb-build && \
    cmake ../flatbuffers-1.9.0 && \
    make && \
    make install && \
    rm -rf /home/snort/apps
   
# install tcmalloc
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz && \
    tar xf gperftools-2.7.tar.gz && \
    cd gperftools-2.7/ && \
    ./configure --libdir=/usr/lib64 --includedir=/usr/include && \
    make && \
    make install && \
    rm -rf /home/snort/apps
    
# install daq
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://www.snort.org/downloads/snortplus/daq-${DAQ_VERSION}.tar.gz -O daq-${DAQ_VERSION}.tar.gz && \
    tar xf daq-${DAQ_VERSION}.tar.gz && \
    cd daq-${DAQ_VERSION} && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    rm -rf /home/snort/apps
   
# install snort3
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    git clone https://github.com/snort3/snort3.git && \
    cd snort3/ && \
    ./configure_cmake.sh --prefix=/usr/local --enable-tcmalloc --enable-large-pcap && \
    cd build/ && \
    make && \
    make install && \
    rm -rf /home/snort/apps

# install snort_extra
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    git clone https://github.com/snort3/snort3_extra.git && \
    cd snort3_extra && \
    ./configure_cmake.sh --prefix=/usr/local && \
    cd build/ && \
    make && \
    make install && \
    rm -rf /home/snort/apps

ADD etc/snort.lua /usr/local/etc/snort/
ADD etc/snort_defaults.lua /usr/local/etc/snort/

# update community rules
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O snort3-community-rules.tar.gz && \
    tar -xvf snort3-community-rules.tar.gz && \
    cp snort3-community-rules/snort3-community.rules /usr/local/etc/snort/rules/rules/ && \
    cp snort3-community-rules/sid-msg.map /usr/local/etc/snort/rules/rules/ && \
    rm -rf /home/snort/apps

# install openappid
RUN mkdir -p /home/snort/apps && \
    cd /home/snort/apps && \
    wget https://www.snort.org/downloads/openappid/${OPENAPPID_VERSION} -O snort-openappid.tar.gz && \
    tar -zxvf snort-openappid.tar.gz && \
    cp -R odp /usr/local/etc/snort/appid/ && \
    rm -rf /home/snort/apps

RUN snort -V
