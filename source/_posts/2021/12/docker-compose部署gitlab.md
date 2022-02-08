---
title: docker-compose部署gitlab
date: 2021-12-20 14:01:32
tags:
---

Docker Compose 部署 GitLab
创建如下目录
/usr/local/docker/nexus
1
创建docker-compose.yml文件
vim docker-compose.yml
1
docker-compose.yml配置如下
version: '2.0'
services:
  web:
    image: 'twang2218/gitlab-ce-zh'
    restart: always
    hostname: '192.168.20.44'
    environment:
      TZ: 'Asia/Shanghai'
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://192.168.20.44'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        unicorn['port'] = 8888
        nginx['listen_port'] = 80
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - ./config:/etc/gitlab
      - ./data:/var/opt/gitlab
      - ./logs:/vat/log/gitlab     
docker-compose up -d 启动即可
