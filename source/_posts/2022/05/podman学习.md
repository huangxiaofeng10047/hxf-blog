---
title: podman学习
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 09:26:46
tags:
---

Podman 默认注册表配置文件在 /etc/containers/registries.conf

修改为以下内容：

```shell
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "******.mirror.aliyuncs.com"
```

对应的值修改为你的阿里云容器加速镜像地址就可以了，现在拉取镜像就是用的阿里云加速
