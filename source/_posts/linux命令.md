---
title: linux命令
date: 2021-08-13 08:22:44
tags:
- shell
categories: 
- linux
---

# linux 下 取进程占用 cpu 最高的前10个进程
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +3|head


# linux 下 取进程占用内存(MEM)最高的前10个进程
ps aux|head -1;ps aux|grep -v PID|sort -rn -k +4|head

查看端口占用

```
netstat -tunlp | grep 端口号
```

 

