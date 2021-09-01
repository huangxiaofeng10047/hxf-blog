---
title: drone自动取消多个commit提交
date: 2021-09-01 13:54:03
tags:
- k8s
- drone
categories: 
- devops
---

大家一定会问什么是『自动取消』呢？中文翻作自动取消，这机制会用在CI/CD的哪个流程或步骤呢？我们先来探讨一个场景，不知道大家有没有遇到过在同一个分支陆续发了3个commit，会发现在CI/CD会依序启动3个Job来跑这3个commit，假设你有设定同时间可以跑一个Job，这样可以的commit会先开始启动，然后就可以了一个提交成功`Penging`的状态，等到第一个作业完成后，才会继续执行。

即将有问题出现，假设一次团队完成了10个任务，这样等待状态开启又多了，这会越来越少，开发者一定会想，有没有办法只有最新的这个功能在[Travis CI](https://travis-ci.org/)已经有后台可以启动了，新专也是预设启动的，也就是假设现在有一个作业正在执行，有九个作业正在等待中，新的工作一进入后，CI/CD 服务会自动取消旧有的九个工作，只保留最新的，确保系统不会浪费时间在跑旧的工作。无人机在 1.6 也支持了此功能，底下来看看如何设置drone达到这个需求。

<!--more-->

## 设置drone

drone在1.6版才正式支持『自动取消』，而且每个专门的方案预设是不启动的，需要通过[drone cli](https://docs.drone.io/cli/install/ "drone命令行界面")才能正确启动。底下来看看能否通过CLI启动：


```
# 啟用 pull request
drone repo update \
  --auto-cancel-pull-requests=true 
  gitea/hxf-blog
# 啟用 push event
drone repo update \
  --auto-cancel-pushes=true \
  gitea/hxf-blog
```

现在还没有办法通过后台UI介面启用，请大家使用上述操作来开启自动取消功能。需要针对相应的项目执行drone命令。

## 编译drone ci

drone ci代码下载到src中，编译后的drone命令，需要到bin目录下查看

```
~/go/src
➜ git clone git@github.com:drone/drone-cli.git
正克隆到 'drone-cli'...
remote: Enumerating objects: 6260, done.
remote: Counting objects: 100% (189/189), done.
remote: Compressing objects: 100% (134/134), done.
remote: Total 6260 (delta 95), reused 121 (delta 53), pack-reused 6071
接收对象中: 100% (6260/6260), 15.89 MiB | 5.39 MiB/s, 完成.
处理 delta 中: 100% (2987/2987), 完成.

~/go/src took 6s
➜ cd drone-cli

drone-cli on  master via 🐹 v1.17
➜ go install ./...
go: github.com/drone/drone-go@v1.6.2: Get "https://goproxy.cn/github.com/drone/drone-go/@v/v1.6.2.mod": proxyconnect tcp: dial tcp 172.24.208.1:7890: i/o timeout
go: downloading github.com/urfave/cli v1.20.0
go: downloading github.com/drone/funcmap v0.0.0-20190918184546-d4ef6e88376d
go: downloading github.com/drone/drone-yaml v0.0.0-20190729072335-70fa398b3560
go: downloading github.com/drone/drone-go v1.6.2
go: downloading github.com/drone/envsubst v1.0.3
go: downloading github.com/mattn/go-colorable v0.1.4
go: downloading github.com/mattn/go-isatty v0.0.11
go: downloading github.com/jackspirou/syscerts v0.0.0-20160531025014-b68f5469dff1
go: downloading golang.org/x/net v0.0.0-20190603091049-60506f45cf65
go: downloading golang.org/x/oauth2 v0.0.0-20181203162652-d668ce993890
go: downloading github.com/fatih/color v1.9.0
go: downloading github.com/google/go-jsonnet v0.16.0
go: downloading github.com/pkg/browser v0.0.0-20180916011732-0a3d74bf9ce4
go: github.com/drone/drone-go@v1.6.2: Get "https://goproxy.cn/github.com/drone/drone-go/@v/v1.6.2.mod": proxyconnect tcp: dial tcp 172.24.208.1:7890: i/o timeout

drone-cli on  master via 🐹 v1.17 took 5m31s
❯ ls
 drone      CHANGELOG.md   Dockerfile.alpine      Dockerfile.linux.arm64     go.mod   LICENSE
 BUILDING   Dockerfile     Dockerfile.linux.arm   Dockerfile.linux.ppc64le   go.sum   README.md

drone-cli on  master via 🐹 v1.17
➜ p-off

drone-cli on  master via 🐹 v1.17
➜ go install ./...
go: downloading github.com/drone/funcmap v0.0.0-20190918184546-d4ef6e88376d
go: downloading github.com/urfave/cli v1.20.0
go: downloading github.com/drone/drone-go v1.6.2
go: downloading github.com/drone/drone-yaml v0.0.0-20190729072335-70fa398b3560
go: downloading github.com/drone/envsubst v1.0.3
go: downloading github.com/mattn/go-colorable v0.1.4
go: downloading github.com/mattn/go-isatty v0.0.11
go: downloading github.com/jackspirou/syscerts v0.0.0-20160531025014-b68f5469dff1
go: downloading golang.org/x/net v0.0.0-20190603091049-60506f45cf65
go: downloading golang.org/x/oauth2 v0.0.0-20181203162652-d668ce993890
go: downloading github.com/fatih/color v1.9.0
go: downloading github.com/google/go-jsonnet v0.16.0
go: downloading github.com/pkg/browser v0.0.0-20180916011732-0a3d74bf9ce4
go: downloading golang.org/x/sync v0.0.0-20190423024810-112230192c58
go: downloading golang.org/x/sys v0.0.0-20200803210538-64077c9b5642
go: downloading gopkg.in/yaml.v2 v2.2.4
go: downloading github.com/pkg/errors v0.8.0
go: downloading github.com/golang/protobuf v1.3.3

drone-cli on  master via 🐹 v1.17 took 15s
➜ ls
 drone      CHANGELOG.md   Dockerfile.alpine      Dockerfile.linux.arm64     go.mod   LICENSE
 BUILDING   Dockerfile     Dockerfile.linux.arm   Dockerfile.linux.ppc64le   go.sum   README.md

drone-cli on  master via 🐹 v1.17
➜ ls -all
drwxr-xr-x    - hxf  1 9月  12:39  .git
drwxr-xr-x    - hxf  1 9月  12:39  .github
drwxr-xr-x    - hxf  1 9月  12:39  drone
.rwxr-xr-x 1.6k hxf  1 9月  12:39  .drone.sh
.rw-r--r-- 1.8k hxf  1 9月  12:39  .drone.yml
.rw-r--r--   17 hxf  1 9月  12:39  .github_changelog_generator
.rw-r--r--   25 hxf  1 9月  12:39  .gitignore
.rw-r--r--  133 hxf  1 9月  12:39  BUILDING
.rw-r--r-- 1.8k hxf  1 9月  12:39  CHANGELOG.md
.rw-r--r--   85 hxf  1 9月  12:39  Dockerfile
.rw-r--r--  121 hxf  1 9月  12:39  Dockerfile.alpine
.rw-r--r--   83 hxf  1 9月  12:39  Dockerfile.linux.arm
.rw-r--r--   86 hxf  1 9月  12:39  Dockerfile.linux.arm64
.rw-r--r--   88 hxf  1 9月  12:39  Dockerfile.linux.ppc64le
.rw-r--r-- 1.1k hxf  1 9月  12:39  go.mod
.rw-r--r--  20k hxf  1 9月  12:39  go.sum
.rw-r--r--  11k hxf  1 9月  12:39  LICENSE
.rw-r--r-- 1.1k hxf  1 9月  12:39  README.md

drone-cli on  master via 🐹 v1.17
➜ cd drone

drone-cli/drone on  master via 🐹 v1.17
➜ ls
 autoscale   convert   encrypt   format   internal   lint   node        plugins   repo     server   starlark   user
 build       cron      exec      info     jsonnet    log    orgsecret   queue     secret   sign     template   main.go

drone-cli/drone on  master via 🐹 v1.17
➜ cd build

drone-cli/drone/build on  master via 🐹 v1.17
➜ ls
 build.go           build_create.go    build_info.go   build_list.go      build_queue.go      build_start.go
 build_approve.go   build_decline.go   build_last.go   build_promote.go   build_rollback.go   build_stop.go

drone-cli/drone/build on  master via 🐹 v1.17
➜ cd ..

drone-cli/drone on  master via 🐹 v1.17
➜ ls
 autoscale   convert   encrypt   format   internal   lint   node        plugins   repo     server   starlark   user
 build       cron      exec      info     jsonnet    log    orgsecret   queue     secret   sign     template   main.go

drone-cli/drone on  master via 🐹 v1.17
➜ cd ..

drone-cli on  master via 🐹 v1.17
➜ ls
 drone      CHANGELOG.md   Dockerfile.alpine      Dockerfile.linux.arm64     go.mod   LICENSE
 BUILDING   Dockerfile     Dockerfile.linux.arm   Dockerfile.linux.ppc64le   go.sum   README.md

drone-cli on  master via 🐹 v1.17
➜ ls -all
drwxr-xr-x    - hxf  1 9月  12:39  .git
drwxr-xr-x    - hxf  1 9月  12:39  .github
drwxr-xr-x    - hxf  1 9月  12:39  drone
.rwxr-xr-x 1.6k hxf  1 9月  12:39  .drone.sh
.rw-r--r-- 1.8k hxf  1 9月  12:39  .drone.yml
.rw-r--r--   17 hxf  1 9月  12:39  .github_changelog_generator
.rw-r--r--   25 hxf  1 9月  12:39  .gitignore
.rw-r--r--  133 hxf  1 9月  12:39  BUILDING
.rw-r--r-- 1.8k hxf  1 9月  12:39  CHANGELOG.md
.rw-r--r--   85 hxf  1 9月  12:39  Dockerfile
.rw-r--r--  121 hxf  1 9月  12:39  Dockerfile.alpine
.rw-r--r--   83 hxf  1 9月  12:39  Dockerfile.linux.arm
.rw-r--r--   86 hxf  1 9月  12:39  Dockerfile.linux.arm64
.rw-r--r--   88 hxf  1 9月  12:39  Dockerfile.linux.ppc64le
.rw-r--r-- 1.1k hxf  1 9月  12:39  go.mod
.rw-r--r--  20k hxf  1 9月  12:39  go.sum
.rw-r--r--  11k hxf  1 9月  12:39  LICENSE
.rw-r--r-- 1.1k hxf  1 9月  12:39  README.md

drone-cli on  master via 🐹 v1.17
➜ cd ..

~/go/src
➜ cd ..

~/go
➜ ls
 bin   pkg   src

~/go
➜ cd bin

~/go/bin
➜ ls
 dlv   dlv-dap   drone   drone-server   embedmd   go-outline   gomodifytags   gopkgs   goplay   gopls   gorush   gotests   impl   staticcheck

~/go/bin
➜ ./drone repo update  --auto-cancel-running=true gitea/hxf-blog
Successfully updated repository gitea/hxf-blog
```
达到的效果如下图所示：
![image-20210901151819083](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901151819083.png)
