---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---

有些docker镜像的tar命令不识别-P参数，可以不填
例如

```
kubectl exec redis-6c98cb5b5f-nxb59 -- tar cf -  /data/dump_redis.rdb | sudo tar xf - -C .
```

出现这个报错，`tar: Removing leading`/' from member names` 可以忽略

**会在当前目录产生 data/dump_redis.rdb**,也就是把文件和目录从k8s 的pod中复制

## [kubectl cp 从k8s pod 中 拷贝 文件到本地 ](https://www.cnblogs.com/faberbeta/p/14510807.html)

[[K8S集群 NOT READY的解决办法 1.13 错误信息:cni config uninitialized](https://www.cnblogs.com/jinanxiaolaohu/p/10682455.html)](https://www.cnblogs.com/jinanxiaolaohu/p/10682455.html)