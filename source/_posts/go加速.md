---
title: go加速
date: 2021-07-29 11:14:19
tags: go
---

使用七牛云 go module 镜像

golang1.13.x 可以直接执行：

```
go` `env -w GO111MODULE=on``go` `env -w GOPROXY=https:``//goproxy.cn,direct
```
<!--more-->

然后再次使用 go get 下载 gin 依赖就可以了。

