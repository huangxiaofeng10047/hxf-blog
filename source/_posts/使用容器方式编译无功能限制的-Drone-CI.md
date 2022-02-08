---
title: 使用容器方式编译无功能限制的 Drone CI
date: 2021-08-25 14:39:49
tags:
- drone
- ci 
categories: 
- devops
---

因为默认版本的 Drone 包含构建次数限制，如果日常高频使用 Drone，不久之后，便会遇到需要“重新初始化”应用才能继续使用的问题，但其实，作为个人用户，我们其实可以不受此限制影响。

在使用Mysql时，创建表结构时可以通过关键字auto\_increment来指定主键是否自增。但在Postgresql数据库中，虽然可以实现字段的自增，但从本质上来说却并不支持Mysql那样的自增。

![image-20210825085148884](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210825085148884.png)

<!--more-->

所以本篇文章，就来分享下如何使用容器方式构建无使用限制的 Drone CI。

## 写在前面

之所以会有这篇文章出现呢？因为之前折腾群里的同学“公子”曾提到过“Drone 默认镜像是企业版，有 5000 次构建限制，需要重新编译”。考虑到软件的长期稳定使用，对[官方文档](https://docs.drone.io/enterprise/)进行翻阅，看到情况确实如此，文档中是如此描述的：“**存在两种版本的 Drone，分别是需要自行构建的社区开源版本，和官方提供的企业版本**”，然而官方并没有更多对于编译构建相关的文档或者说明。

### 关于 Drone CI

对于个人开发者或者团队来说，我们最关心的几个问题，莫过于代码是否安全、软件授权方式、以及授权费用了，官方文档中有提及：

-   软件全部开源，官方默认为所有人提供企业版的镜像试用，支持 5000 次构建调用。
-   如果需要使用开源版本，需要自行进行构建。
-   企业版对于个人使用是免费的。
-   如果你的团队、公司（包含非盈利组织）年收入低于100万美元的企业，或者融资少于 500 万美元，可以免费使用。
-   如果你的公司需要付费，最低门槛是每月 299 美元。

在官方[企业服务页面](https://www.drone.io/enterprise/)，我们可以看到不同版本的功能区别，主要在于是否支持：分布式方式运行多个 Runner；使用 K8S Runner；支持组织密钥功能；支持搭配 Vault 使用；支持定时任务；支持使用 postgres、mysql、s3 进行数据存储；支持自动扩容以及[“扩展功能”](https://docs.drone.io/extensions/overview/)。

如果你有上述需求，可以构建“企业版”、反之构建“开源版”即可。不过结合上面的使用限制，对于一般个人和团队来说，直接构建“企业版”会更省事一些，功能更加全面。

那么，就来看看如何采取类似“官方的方式”编译构建 Drone 的容器镜像吧。

## 收集 Drone 官方构建资料

[翻阅文档](https://docs.drone.io/enterprise/)，可以看到关于自行构建，只有两条（或者说一条）简单的命令：

```
# 构建开源版
$ go build -tags "oss nolimit" github.com/drone/drone/cmd/drone-server

# 构建企业版
$ go build -tags "nolimit" github.com/drone/drone/cmd/drone-server
```

为了构建出和官方基本一致的镜像，需要从官方仓库中梳理完整的“构建套路”。这里以 [v1.10.1](https://github.com/drone/drone/tree/v1.10.1) 代码为基础，进行构建方式梳理。

从仓库根目录的 `BUILDING` 和 `BUILDING_OSS` 文件，可以看到[记录了](https://github.com/drone/drone/blob/v1.10.1/BUILDING_OSS)两种发行版软件的安装和构建流程：

```
1. Clone the repository
2. Install go 1.11 or later with Go modules enabled
3. Install binaries to $GOPATH/bin

    go install -tags "oss nolimit" github.com/drone/drone/cmd/drone-server

4. Start the server at localhost:8080

    export DRONE_GITHUB_CLIENT_ID=...
    export DRONE_GITHUB_CLIENT_SECRET=...
    drone-server
```

继续翻阅项目的 `.drone.yml` [CI 文件](https://github.com/drone/drone/blob/v1.10.1/.drone.yml)，可以看到官方是如何通过 CI 构建和发布软件的：

```
...
- name: build
  image: golang:1.14.4
  commands:
  - sh scripts/build.sh
  environment:
    GOARCH: amd64
    GOOS: linux

- name: publish
  image: plugins/docker:18
  settings:
    auto_tag: true
    auto_tag_suffix: linux-amd64
    dockerfile: docker/Dockerfile.server.linux.amd64
    repo: drone/drone
    username:
      from_secret: docker_username
    password:
      from_secret: docker_password
  when:
    event:
    - push
    - tag
...
```

按图索骥，翻阅 CI 文件中提到的“[构建脚本](https://github.com/drone/drone/blob/v1.10.1/scripts/build.sh)”，内容如下：

```
#!/bin/sh

echo "building docker images for ${GOOS}/${GOARCH} ..."

REPO="github.com/drone/drone"

# compile the server using the cgo
go build -ldflags "-extldflags \"-static\"" -o release/linux/${GOARCH}/drone-server ${REPO}/cmd/drone-server

# compile the runners with gcc disabled
export CGO_ENABLED=0
go build -o release/linux/${GOARCH}/drone-agent      ${REPO}/cmd/drone-agent
go build -o release/linux/${GOARCH}/drone-controller ${REPO}/cmd/drone-controller
```

继续查看容器 Dockerfile [docker/Dockerfile.server.linux.amd64](https://github.com/drone/drone/blob/v1.10.1/docker/Dockerfile.server.linux.amd64) ，可以看到容器结构：

```
# docker build --rm -f docker/Dockerfile -t drone/drone .

FROM alpine:3.11 as alpine
RUN apk add -U --no-cache ca-certificates

FROM alpine:3.11
EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=true
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ADD release/linux/amd64/drone-server /bin/
ENTRYPOINT ["/bin/drone-server"]
```

线索差不多齐了，我们开始编写基础的容器镜像。

## 编写构建脚本

上一小节中，我们可以看到容器文件中使用的核心的软件 `drone-server` 是从“本地”拷贝至镜像中的，猜测是为了更高的编译效率，使用更短时间编译多平台使用的二进制文件，所以采取了这样的策略。

对于我们来说，只需要使用适用于某一种 CPU 架构和系统的软件，可以考虑将编译环境直接用容器来创建。除了能够更好的保存编译环境外，还能够让编译使用的机器系统环境更加“纯粹和干净”：

```
FROM golang:1.16.0-alpine3.13 AS Builder

ENV DRONE_VERSION 2.1.0

ENV CGO_CFLAGS="-g -O2 -Wno-return-local-addr"

RUN apk add build-base && go env -w GO111MODULE=on && \
    mkdir /src && cd /src && \
    apk add curl && curl -L https://github.com/drone/drone/archive/refs/tags/v${DRONE_VERSION}.tar.gz -o v${DRONE_VERSION}.tar.gz && \
    tar zxvf v${DRONE_VERSION}.tar.gz && rm v${DRONE_VERSION}.tar.gz && \
    cd /src/drone-${DRONE_VERSION} && \
    go mod download && \
    go build -ldflags "-extldflags \"-static\"" -tags="nolimit" github.com/drone/drone/cmd/drone-server
```

为了让构建速度加快，我们可以适当调整 Dockerfile ，添加一些国内的软件源：

```
FROM golang:1.16.0-alpine3.13 AS Builder

RUN sed -i 's/https:\/\/dl-cdn.alpinelinux.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/' /etc/apk/repositories && \
    echo "Asia/Shanghai" > /etc/timezone

RUN apk add build-base && \
    go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

ENV DRONE_VERSION 2.1.0

WORKDIR /src

# Build with online code
RUN apk add curl && curl -L https://github.com/drone/drone/archive/refs/tags/v${DRONE_VERSION}.tar.gz -o v${DRONE_VERSION}.tar.gz && \
    tar zxvf v${DRONE_VERSION}.tar.gz && rm v${DRONE_VERSION}.tar.gz
# OR with offline tarball
# ADD drone-2.1.0.tar.gz /src/

WORKDIR /src/drone-${DRONE_VERSION}

RUN go mod download

ENV CGO_CFLAGS="-g -O2 -Wno-return-local-addr"

RUN go build -ldflags "-extldflags \"-static\"" -tags="nolimit" github.com/drone/drone/cmd/drone-server
```

将上面的内容保存为 `Dockerfile`，然后执行 `docker build -t drone:2.1.0 .` ，稍等片刻“全功能”的 Drone 就在镜像内构建完毕了，但是镜像尺寸非常大，足足有 1.28GB 之大，所以我们要继续编写一个多阶段构建的镜像，来减少容器尺寸。

### 多阶段镜像构建

在上面的容器声明文件下方继续添加一些内容，结合前文找到的官方构建脚本，我们可以对构建脚本进行一些调整：

```
FROM golang:1.16.0-alpine3.13 AS Builder

RUN sed -i 's/https:\/\/dl-cdn.alpinelinux.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/' /etc/apk/repositories && \
    echo "Asia/Shanghai" > /etc/timezone

RUN apk add build-base git && \
    go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct

ENV DRONE_VERSION 2.1.0

WORKDIR /src

# Build with online code
RUN apk add curl && curl -L https://github.com/drone/drone/archive/refs/tags/v${DRONE_VERSION}.tar.gz -o v${DRONE_VERSION}.tar.gz && \
    tar zxvf v${DRONE_VERSION}.tar.gz && rm v${DRONE_VERSION}.tar.gz
# OR with offline tarball
# ADD drone-1.10.1.tar.gz /src/

WORKDIR /src/drone-${DRONE_VERSION}

RUN go mod download

ENV CGO_CFLAGS="-g -O2 -Wno-return-local-addr"

RUN go build -ldflags "-extldflags \"-static\"" -tags="nolimit" github.com/drone/drone/cmd/drone-server



FROM alpine:3.13 AS Certs
RUN sed -i 's/https:\/\/dl-cdn.alpinelinux.org/http:\/\/mirrors.tuna.tsinghua.edu.cn/' /etc/apk/repositories && \
    echo "Asia/Shanghai" > /etc/timezone
RUN apk add -U --no-cache ca-certificates



FROM alpine:3.13
EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=true
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=Certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=Builder /src/drone-2.1.0/drone-server /bin/drone-server
ENTRYPOINT ["/bin/drone-server"]
```

再次执行 `docker build -t drone:1.10.1 .`，能够看到镜像尺寸减少到了 `61.7MB` ，和官方提供的 67.3MB 镜像差不多大了。

## 其他

今年早些时候，曾写过一篇关于 Drone 的内容：[《容器方式下的轻量仓库与CI 使用方案：Gitea + Drone 基础篇》](https://soulteary.com/2021/02/25/lightweight-code-warehouse-and-ci-usage-plan-in-docker-with-gitea-and-drone-part-1.html)，前些天在[《站点优化日志（2021.04.12）》](https://soulteary.com/2021/04/12/site-optimization-log.html) 中，也曾提到过我在尝试使用 Gitea + Drone 替换之前个人使用的 GitLab，所以如果你有类似轻量化运行的需求，可以翻阅之前的文章，或许能节约一些折腾过程的时间。

当然，如果你对 GitLab Runner 的编译构建感兴趣，可以翻阅两年前的一篇内容：[《源码编译 GitLab Runner》](https://soulteary.com/2019/08/04/source-code-compilation-gitlab-runner.html)，同样是使用 Golang 编写，但是相比之下，比 Drone 复杂不少。

## 最后

希望这篇文章能够帮到使用 Drone 的你。

–EOF
