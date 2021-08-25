---
title: 限制wsl2占用过多内存
date: 2021-08-25 10:00:16
tags:
- es
categories: 
- bigdata
---

在用户下建立

.wslconfig

```
[wsl2]
 processors=8
 memory=8GB
 swap=8GB
 localhostForwarding=true
```

## 定期释放cache内存

Linux内核中有一个参数`/proc/sys/vm/drop_caches`，是可以用来手动释放Linux中的cache缓存，如果发现wsl2的cache过大影响到宿主机正常运行了，可以手动执行以下命令来释放cache：

```text
 echo 3 > /proc/sys/vm/drop_caches
```

当然也可以设置成定时任务，每隔一段时间释放一次。

简历crontab

```
crontab  -e


```

输入以下命令：

```
30 21 * * *  echo 3 > /proc/sys/vm/drop_caches
```

