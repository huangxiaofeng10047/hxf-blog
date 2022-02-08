---
title: 'docker.socket: Failed with result ‘service-start-limit-hit‘.'
date: 2021-09-14 11:25:29
tags:
- devops
categories: 
- devops
---

docker启动出问题：
docker.socket: Failed with result ‘service-start-limit-hit’.
解决方法：如下，把/etc/docker/daemon.json改名为/etc/docker/daemon.conf即可

—————————分界线———————
配完之后我下镜像的时候就发现不对劲了，于是把文件改了回来，然后把上一次的改动删掉再启动，于是成功运行，故此报错是因为daemon.json文件配置有问题，检查并修改应该就可以解决了。
具体归结下来原因，就是因为配置文件的问题。

