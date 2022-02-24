---
title: dnsmasq配置dns和dhcp
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-24 11:26:28
tags:
---

安装dns服务

```
yum  -y  install  dnsmasq
```

vim /etc/sysconfig/network-scripts/ifcfg-ens33修改网络配置

```
添加如下：

ONBOOT="yes"
IPADDR=192.168.20.39 #静态IP
GATEWAY=192.168.20.1 #默认网关
NETMASK=255.255.255.0 #子网掩码
DNS1=192.168.20.39

```

systemctl restart network重启网络

vim /etc/dnsmasq.conf  修改dnsmasq配置文件

```
#指定上游dns服务器
resolv-file=/etc/resolv.dnsmasq.conf
#表示严格按照 resolv-file 文件中的顺序从上到下进行 DNS 解析, 直到第一个成功解析成功为止
strict-order
# 开启后会寻找本地的hosts文件在去寻找缓存的域名，最后到上游dns查找
#no-resolv
listen-address=192.168.37.1 #设置为当前服务器的ip
conf-dir=/etc/dnsmasq.d # 我们的解析记录都写到这个目录下
addn-hosts=/etc/dnsmasq.hosts  #自定义的dns记录文件
```

