---
title: 使用 SSH config 文件
date: 2021-08-19 08:43:53
tags:
---
有如下配置文件：

```bash
$ vim ~/.ssh/config
Host cdh1
    HostName cdh1
    User root
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

使用配置文件登录：

```bash
$ ssh cdh1
```

