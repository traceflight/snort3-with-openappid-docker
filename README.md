# snort3-with-openappid-docker
Dockerfile of snort3 with openappid

## 使用方法

* 直接下载镜像

```
$ docker pull traceflight/snort3-with-openappid-docker
```

* 挂载本地路径分析pcap文件

```
$ docker run -it --rm -v path/to/pcapdir:/data traceflight/snort3-with-openappid-docker /bin/bash
```

* 分析数据
```
$ snort -c /usr/local/etc/snort/snort.lua -r /data/pcapfile.pcap 
```

## 注意事项

使用中可能出现错误提示：`ERROR: Cannot decode data link type 113`

原因：为Wireshark在对Linux进行抓包时，若对any接口进行抓包，使用的格式为[Linux cooked-mode capture (SLL)](https://wiki.wireshark.org/SLL)，snort不支持该格式。

解决方法：不对any接口进行抓包，对指定接口如eth0抓包即可。
