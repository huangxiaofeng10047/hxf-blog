---
title: drone-dingding-message使用
date: 2021-09-01 17:08:48
tags:
- devops
categories: 
- devops
---

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/ad5fbf65ly1ge3ighqw3uj21hc120dpl.jpg" alt="post thumb" style="zoom:80%;" />

<!--more-->

通过钉钉的通知机器人，可以告知是否成功构建。

见样例，这次使用的demo-go服务：

.drone.yml

```
---
kind: pipeline
type: docker
name: demo-go

platform:
  os: linux
  arch: amd64

steps:
  - name: greeting
    image: golang:1.12
    commands:
      - export GO111MODULE=on 
      - export GOPROXY=https://goproxy.cn
      - go build

  - name: 钉钉通知
    image: lddsb/drone-dingtalk-message
    settings:
      token:
        from_secret: dingding
      secret: 
        from_secret: dingding_sec
      type: markdown
      message_color: true
      message_pic: true
      sha_link: true
    when:
      status: [failure, success]

trigger:
  branch:
    - master





```

![image-20210901171304368](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901171304368.png)

其中token为webhook后面的token，secret为加签的值，这样才能正常发送通知，如下图所示：

![image-20210901171359369](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901171359369.png)

