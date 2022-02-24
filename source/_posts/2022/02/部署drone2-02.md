---
title: 部署drone2.02
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-16 15:32:45
tags:
---





drone安装：

docker-compose.yml如下

```
### 參考文章 ###
### (https://chunkai.me/2018/06/18/setting-up-drone-for-gitlab-integration/) ###
version: '2'

services:
  ### Drone Setting
  drone-server:
    image: drone/drone:1
    container_name: drone-server
    ports:
      - 8090:80
    extra_hosts:
     - "drone.local.com:192.168.20.31"
    volumes:
      - ./:/data
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
    environment:
      - DRONE_SERVER_HOST=${DRONE_SERVER_HOST}                       # Drone URL
      - DRONE_SERVER_PROTO=${DRONE_SERVER_PROTO}                     # http 或者 https 連線設定
      - DRONE_TLS_AUTOCERT=false                                     # 自動生成 ssl 證書，並接受 https 連線，末認為false
      - DRONE_RUNNER_CAPACITY=3                                      # 表示一次可執行 n 個 job
      - DRONE_GIT_ALWAYS_AUTH=false                                  # Drone clone 時，是否每次都驗證
      - DRONE_USER_CREATE=username:root,admin:true                         # 这个关系到是否显示trusted按钮。
      # GitLab Config
      - DRONE_GITLAB_CLIENT_ID=${DRONE_GITLAB_CLIENT_ID}             # OAuth 的 Application ID
      - DRONE_GITLAB_CLIENT_SECRET=${DRONE_GITLAB_CLIENT_SECRET}     # OAuth 的 Secret
      - DRONE_GITLAB_SERVER=http://${GITLAB_SERVER}            # Gitlab Server
      - DRONE_LOGS_DEBUG=true                                        # 選擇是否開啟 debug 模式
      # - DRONE_LOGS_PRETTY=true                                     # Log 是否以json方式呈現
      - DRONE_LOGS_COLOR=true                                        # Log 啟用顏色辨識
      - DRONE_LOGS_TRACE=true
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
  drone-agent:
    image: drone/drone-runner-docker:1
    container_name: drone-agent
    restart: always
    depends_on:
      - drone-server
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_RPC_HOST=${DRONE_SERVER_HOST}
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
      - DRONE_RUNNER_CAPACITY=3
      - DRONE_LOGS_DEBUG=true
      - DRONE_LOGS_TRACE=true

```

创建.env

```
DRONE_SERVER_HOST=192.168.20.31:8090
DRONE_SERVER_PROTO=http
DRONE_GITLAB_CLIENT_ID=086182a642e9c51f0be366f5f1c50fcd8d5051661e2130700de38a31f305ff37
DRONE_GITLAB_CLIENT_SECRET=0ff642d3576c5bf9b1629cba13ad1820e20a1ff3b17c97b79d8c2a5d6fba9d66
GITLAB_SERVER=192.168.20.44
DRONE_RPC_SECRET=secret

```

启动之后，创建demo，看是否正常消费。

遇到问题：

# Drone SETTINGS 页面没有 Trusted

原因:drone-server缺少 `- DRONE_USER_CREATE=username:root,admin:true`
