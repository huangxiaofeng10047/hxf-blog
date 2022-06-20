---
title: 'net/http: HTTP large file upload fails with bufio: buffer full'
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-16 14:47:14
tags:
---

当go出现这个问题，很可能就是tmp目录问题，挂载tmp目录即可。

本文出现这个问题是因为，通过go直接运行没有这个错误，但是通过打包成镜像，出现如此问题。

参考文档：

https://github.com/golang/go/issues/26707
