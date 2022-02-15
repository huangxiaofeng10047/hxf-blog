---
title: docker命令升级镜像
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-11 14:53:53
tags:
---
升级命令为：
```
docker stop $(docker ps -a | grep "eipwork/kuboard" | awk '{print $1 }')
docker rm $(docker ps -a | grep "eipwork/kuboard" | awk '{print $1 }')
```
