---
title: mm-wiki搭建记录
date: 2021-09-02 14:45:54
tags:
- shell
categories: 
- devops
---

第一步创建目录：



```
mkdir  -p /data/mm-wiki/conf/
mkdir -p /data/mm-wiki/data
mkdir /data/mm-wiki/docs/search

```

<!--more-->

第二步创建服务

```
docker run -d -p 8080:8081 -v /data/mm-wiki/conf/:/opt/mm-wiki/conf/ -v /data/mm-wiki/data:/data/mm-wiki/data/  -v /data/mm-wiki/docs/search_dict/:/opt/mm-wiki/docs/search_dict/ --name mm-wiki huangxiaofenglogin/mm-wiki-image:v1.0.3
```

遇到问题：

构建自己的镜像，因为官方镜像会报错，提示dictionary.txt不存在

Dockerfile(解决时区问题)

```
FROM alpine/git

ENV TZ=Asia/Shanghai

WORKDIR /app

RUN git clone https://github.com/phachon/mm-wiki.git


FROM golang:1.14.1-alpine

COPY --from=0 /app/mm-wiki /app/mm-wiki

WORKDIR /app/mm-wiki
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ > /etc/apk/repositories
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone
ENV TZ Asia/Shanghai
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ > /etc/apk/repositories
# 如果国内网络不好，可添加以下环境
RUN go env -w GO111MODULE=on
RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN export GO111MODULE=on
RUN export GOPROXY=https://goproxy.cn

RUN mkdir /opt/mm-wiki && ls /app/mm-wiki
RUN go build -o /opt/mm-wiki/mm-wiki ./ \
    && cp -r ./conf/ /opt/mm-wiki \
    && cp -r ./install/ /opt/mm-wiki\
    && cp ./scripts/run.sh /opt/mm-wiki\
    && cp -r ./static/ /opt/mm-wiki\
    && cp -r ./views/ /opt/mm-wiki\
    && cp -r ./logs/ /opt/mm-wiki\
    && cp -r ./docs/ /opt/mm-wiki
CMD ["/opt/mm-wiki/mm-wiki", "--conf", "/opt/mm-wiki/conf/mm-wiki.conf"]
```







docker-compose.yml

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  mm-wiki:                            # 可以隨意命名，通常以有意義的字串命名
    image: huangxiaofenglogin/mm-wiki-image:v1.0.3    # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
    volumes:                        # 掛載的撰寫方式，如果有多組不同路徑掛載，只需要在新增幾行條件即可。
      - /data/mm-wiki/conf/:/opt/mm-wiki/conf/
      - /data/mm-wiki/data:/data/mm-wiki/data/
      - /data/mm-wiki/docs/search_dict/:/opt/mm-wiki/docs/search_dict/
    ports:
      - "8080:8081"
    container_name: mm-wiki
    environment:
       - TZ=Asia/Shanghai
```

问题：

解决fetch http://dl-cdn.alpinelinux.org/alpine/v3.11/main/x86_64/APKINDEX.tar.gz下载太慢：

解决办法：

```
RUN echo -e http://mirrors.ustc.edu.cn/alpine/v3.7/main/ > /etc/apk/repositories
```

