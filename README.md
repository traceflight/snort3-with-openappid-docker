# snort3-with-openappid-docker
Dockerfile of snort3 with openappid

## 组件及版本

|组件|版本|
|:---|:--|
|snort|3.0.0|
|daq|2.2.2|
|snort extra|1.0.0|
|openappid|8373|
|rules|community|

## 使用方法

### 获取镜像

```
$ docker pull traceflight/snort3-with-openappid-docker
```

### 监听主机网卡

首先获取待监听网卡名称：

```
$ ip a
```

使用docker的host模式监听指定网卡（假设为eth0），挂载本地路径（`/var/log/snort`）存放日志信息：

```
$ docker run -it --name snort --net=host \
    --cap-add=NET_ADMIN \
    -v /var/log/snort/:/var/log/snort/ \
    traceflight/snort3-with-openappid-docker \
    snort -c /usr/local/etc/snort/snort.lua \
    -A fast \
    -l /var/log/snort \
    -i eth0
```

### 分析Pcap数据

运行snort并挂载待分析文件

```
$ docker run -it --rm -v path/to/pcapdir:/data \
    traceflight/snort3-with-openappid-docker /bin/bash
```

分析数据
```
$ snort -c /usr/local/etc/snort/snort.lua -r /data/pcapfile.pcap 
```

## 修改配置和规则

### 自定义应用检测器

将自定义检测脚本放置在`custom/lua`文件夹中，然后重新build容器或挂载`custom`文件夹到`/usr/local/etc/snort/appid/`文件夹中。

### 使用自定义规则

配置文件和规则文件分别放置在项目中`etc`和`rules/rules`文件夹内。如需要进行修改，可clone本项目，然后对相应文件修改后重新build容器，将文件夹`etc`中的文件和`rules`分别挂载到容器内的`/usr/local/etc/snort/`和`/usr/local/etc/snort/rules/`路径下。

步骤如下：

* 下载镜像

```
$ docker pull traceflight/snort3-with-openappid-docker
```

* clone本项目

```
$ git clone https://github.com/traceflight/snort3-with-openappid-docker.git
```

* 创建规则

在`rules/rules`文件夹内创建规则文件`local.rules`，需要在`etc/snort.lua`配置文件中第6个部分（6. configure detection）中的`rules`变量内添加一行`include $RULE_PATH/local.rules`。

* 挂载文件 

运行时挂载

```
$ docker run -it -v `pwd`/etc/snort.lua:/usr/local/snort/etc/snort.lua \
    -v `pwd`/rules/:/usr/local/snort/rules/ \
    traceflight/snort3-with-openappid-docker /bin/bash
```

或创建Dockerfile生成新的镜像

```
FROM traceflight/snort3-with-openappid-docker:latest
MAINTAINER yourname

ADD etc/snort.lua /usr/local/snort/etc/
ADD rules /usr/local/snort/rules

RUN snort -V
```

### 使用snort注册版规则

在snort官方注册后，可下载注册版规则。将规则文件解压缩后，放在本项目对应文件夹中，然后修改`etc/snort.lua`文件中的`appid`变量值，指定appid路径。最后将文件夹挂载到路径下即可。

```
appid =
{
    -- appid requires this to use appids in rules
    app_detector_dir = '/usr/local/etc/snort/appid',
}
```

## 使用中可能出现错误提示

**ERROR: Cannot decode data link type 113**

原因：libpcap在对Linux进行抓包时，若对any接口进行抓包，使用的格式为[Linux cooked-mode capture (SLL)](https://wiki.wireshark.org/SLL)，snort不支持该格式。

解决方法：不对any接口进行抓包，对指定接口如eth0抓包即可。

**SIOETHTOOL(ETHTOOL_GUFO) ioctl failed: Operation not permitted**

原因：容器对监听本地网卡的权限不足。

解决方法：在docker运行时，添加参数`--cap-add=NET_ADMIN`。
