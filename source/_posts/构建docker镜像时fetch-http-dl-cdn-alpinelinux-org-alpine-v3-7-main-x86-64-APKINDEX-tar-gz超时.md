---
title: >-
  构建docker镜像时fetch
  http://dl-cdn.alpinelinux.org/alpine/v3.7/main/x86_64/APKINDEX.tar.gz超时
date: 2021-09-01 15:22:16
tags:
- k8s
- drone
categories: 
- devops
---

## 1、超时原因

外部网站，国内访问时可能会超时

```
fetch http://dl-cdn.alpinelinux.org/alpine/v3.7/main/x86_64/APKINDEX.tar.gz
```

修改Dockerfile，使用国内的alpine源

<!--more-->

## 2.1、正确的做法

正确的做法是使用国内源完全覆盖 /etc/apk/repositories  
在Dockerfile中增加下面的第二行

```
FROM alpine:3.7
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ > /etc/apk/repositories
```

## 2.2、可能有问题的做法

追加国内源（echo后面双大于号），此时可能依然超时，因为默认的/etc/apk/repositories里面就有国外的源

追加方法

```
FROM alpine:3.7

RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ >> /etc/apk/repositories
```

调试一下可以看到默认的国外源  
在Dockerfile中增加一条命令

```
RUN cat /etc/apk/repositories
```

执行时可以看到全部的源

```
Step 4/7 : RUN cat /etc/apk/repositories
 ---> Running in 03382d07061a
http://dl-cdn.alpinelinux.org/alpine/v3.7/main
http://dl-cdn.alpinelinux.org/alpine/v3.7/community
http://mirrors.ustc.edu.cn/alpine/v3.7/main/
```
