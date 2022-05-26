---
title: drone坑记
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-31 14:00:20
tags:
---

在gitlab配置Apps的时候，关注下这个地方的设置，有个token过期的机制最好退出一下，不然8小时后webhook就会失效，只能重新登录drone才会正常。
