---
title: docker配置代理下载
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-26 15:21:22
tags:
---

```
cd /etc/systemd/system/docker.service.d
vi http-proxy.conf
##添加如下内容
[Service]
Environment="HTTP_PROXY=http://172.27.64.1:10809"
Environment="HTTPS_PROXY=http://172.27.64.1:10809"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.37.153,qua.io"



保存退出
systemctl daemon-reload 
systemctl restart docker
接下来可以下载google镜像试试。

```

