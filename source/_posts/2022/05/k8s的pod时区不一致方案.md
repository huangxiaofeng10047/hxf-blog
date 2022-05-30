---
title: k8s的pod时区不一致方案
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-30 11:25:02
tags:
---

## 1、背景介绍

> 我们知道，使用 [docker](https://so.csdn.net/so/search?q=docker&spm=1001.2101.3001.7020) 容器启动服务后，如果使用默认 Centos 系统作为基础镜像，就会出现系统时区不一致的问题，因为默认 Centos 系统时间为 UTC 协调世界时 (Universal Time Coordinated)，一般本地所属时区为 CST（＋8 时区，上海时间），时间上刚好相差 8 个小时。这就导致了，我们服务启动后，获取系统时间来进行相关操作，例如存入数据库、时间换算、日志记录等，都会出现时间不一致的问题，所以很有必要解决掉容器内时区不统一的问题。

问题显示如下：

```
# 查看本地时间
$ date
Wed Mar  6 16:41:08 CST 2019

# 查看容器内 centos 系统默认时区
$ docker run -it centos /bin/sh
sh-4.2# date
Wed Mar  6 08:41:45 UTC 2019
```

## 2、环境、软件准备

本次演示环境，我是在虚拟机上安装 Linux 系统来执行操作，通过虚拟机完成 Kubernetes 集群的搭建，以下是安装的软件及版本：

-   **Oracle VirtualBox**: 5.1.20 r114628 (Qt5.6.2)
-   **System**: CentOS Linux release 7.3.1611 (Core)
-   **kubernetes**: 1.12.1
-   **docker**: 18.06.1-ce

注意：本次操作基于 Linux Centos7 系统操作，若系统为 Ubuntu 或其他 Linux 系统，亦可参考方案对应处理，都大同小异。

## 3、Dockerfile 中处理

可以直接修改 `Dockerfile`，在构建系统基础镜像或者基于基础镜像再次构建业务镜像时，添加时区修改配置即可。

```
$ cat Dockerfile.date
FROM centos

RUN rm -f /etc/localtime \
&& ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone

# 构建容器镜像
$ docker build -t centos7-date:test -f Dockerfile.date .
Sending build context to Docker daemon  4.426GB
Step 1/2 : FROM centos
 ---> 1e1148e4cc2c
Step 2/2 : RUN rm -f /etc/localtime && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone
 ---> Running in fe2e931c3cf2
'/etc/localtime' -> '/usr/share/zoneinfo/Asia/Shanghai'
Removing intermediate container fe2e931c3cf2
 ---> 2120143141c8
Successfully built 2120143141c8
Successfully tagged centos7-date:test

$ docker run -it centos7-date:test /bin/sh
sh-4.2# date
Wed Mar  6 16:40:01 CST 2019
```

可以看到，系统时间正常了，个人比较推荐这种方式，一劳永逸，只需要一次配置即可，后续在基于此基础镜像制作的镜像就可以直接使用了，不需要担心时区问题。

## 4、容器启动时处理

除了在 Dockerfile 中修改配置方式外，我们还可以在容器启动时通过挂载主机时区配置到容器内，前提是主机时区配置文件正常。

```
# 挂载本地 /etc/localtime 到容器内覆盖配置
$ docker run -it -v /etc/localtime:/etc/localtime centos /bin/sh
sh-4.2# date
Wed Mar  6 16:42:38 CST 2019

# 或者挂载本地 /usr/share/zoneinfo/Asia/Shanghai 到容器内覆盖配置
$ docker run -it -v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime centos /bin/sh
sh-4.2# date
Wed Mar  6 16:42:52 CST 2019
```

以上两种方式，其实原理都一样，在 Centos 系统中，`/usr/share/zoneinfo/Asia/Shanghai` 和 `/etc/localtime` 二者是一致的，我们一般会将二者软连接或者直接 cp 覆盖。

## 5、进入容器内处理

还有一种方式，就是进入到容器内处理，但是此方式有个不好的地方就是，如果容器删除后重新启动新的容器，还需要我们进入到容器内配置，非常不方便，所以个人不建议此方式。

```
# 进入到容器内部配置
$ docker run -it centos /bin/sh
sh-4.2# date
Wed Mar  6 08:43:29 UTC 2019
sh-4.2# rm -f /etc/localtime && ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
'/etc/localtime' -> '/usr/share/zoneinfo/Asia/Shanghai'
sh-4.2# date
Wed Mar  6 16:43:54 CST 2019
```

## 6、k8s 解决容器时间不一致

在 K8s 集群里，也会存在因为时区不一致导致的问题，还记得我之前文章中挖出来的坑 [配置 Ceph Object Gateway Management Frontend](https://blog.csdn.net/aixiaoyang168/article/details/86467931#6_Ceph_Object_Gateway_Management_Frontend_647) 中，因为容器时间不一致，导致的报错。那么在 k8s 集群里，如何解决容器时间不统一的问题呢？方式有很多，最一劳永逸的方式还是上边，在基础镜像或者服务镜像里面直接配置好。其次我们还可以通过挂载主机时间配置的方式解决，针对此方式，我举个栗子。

```
$ cat busy-box-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busy-box-test
  namespace: default
spec:
  restartPolicy: OnFailure
  containers:
  - name: busy-box-test
    image: busybox
    imagePullPolicy: IfNotPresent
    volumeMounts:
    - name: date-config
      mountPath: /etc/localtime
    command: ["sleep", "60000"]
  volumes:
  - name: date-config
    hostPath:
      path: /etc/localtime
               
```

注意：如果主机 `/etc/localtime` 已存在且时区正确的话，可以直接挂载，如果本地 `/etc/localtime` 不存在或时区不正确的话，那么可以直接挂载 `/usr/share/zoneinfo/Asia/Shanghai` 到容器内 `/etc/localtime`，都是可行的。
