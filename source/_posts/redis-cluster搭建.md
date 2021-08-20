---
title: redis-cluster搭建
date: 2021-08-20 11:34:25
tags:
---

安装redis

从redis官网下载最新版本redis（目前版本为6.2.5）

解压redis压缩包到指定位置，进行安装

```shell
make &&make install
```

<!--more-->

主要有两步

- 配置文件
- 启动验证

##### 集群规划

根据官方推荐，集群部署至少要 3 台以上的master节点，最好使用 3 主 3 从六个节点的模式。

| 节点            | 配置           | 端口 |
| --------------- | -------------- | ---- |
| cluster-master1 | redis7001.conf | 7001 |
| cluster-master2 | redis7002.conf | 7002 |
| cluster-master3 | redis7003.conf | 7003 |
| cluster-slave1  | redis7004.conf | 7004 |
| cluster-slave2  | redis7006.conf | 7005 |
| cluster-slave3  | redis7006.conf | 7006 |

##### 配置文件

咱们准备 6 个配置文件 ，端口 7001，7002，7003，7004，7005，7006

分别命名成 redis7001.conf ......redis7006.conf

redis7001.conf 配置文件内容如下(记得复制6份并替换端口号)

```shell
# 端口
port 7001  
# 启用集群模式
cluster-enabled yes 
# 根据你启用的节点来命名，最好和端口保持一致，这个是用来保存其他节点的名称，状态等信息的
cluster-config-file nodes_7001.conf 
# 超时时间
cluster-node-timeout 5000
appendonly yes
# 后台运行
daemonize yes
# 非保护模式
protected-mode no 
pidfile  /var/run/redis_7001.pid
```

##### 启动 redis 节点

- 挨个启动节点

```shell
redis-server redis7001.conf
redis-server redis7002.conf
redis-server redis7003.conf
redis-server redis7004.conf
redis-server redis7005.conf
redis-server redis7006.conf
```

看以下启动情况

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820113711538.png" alt="image-20210820113711538" style="zoom:80%;" />

- 启动集群

```shell
# 执行命令
# --cluster-replicas 1 命令的意思是创建master的时候同时创建一个slave

$ redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
# 执行成功结果如下
# 我们可以看到 7001，7002，7003 成为了 master 节点，
# 分别占用了 slot [0-5460]，[5461-10922]，[10923-16383]
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica 127.0.0.1:7005 to 127.0.0.1:7001
Adding replica 127.0.0.1:7006 to 127.0.0.1:7002
Adding replica 127.0.0.1:7004 to 127.0.0.1:7003
>>> Trying to optimize slaves allocation for anti-affinity
[WARNING] Some slaves are in the same host as their master
M: 0313641a28e42014a48cdaee47352ce88a2ae083 127.0.0.1:7001
   slots:[0-5460] (5461 slots) master
M: 4ada3ff1b6dbbe57e7ba94fe2a1ab4a22451998e 127.0.0.1:7002
   slots:[5461-10922] (5462 slots) master
M: 719b2f9daefb888f637c5dc4afa2768736241f74 127.0.0.1:7003
   slots:[10923-16383] (5461 slots) master
S: 987b3b816d3d1bb07e6c801c5048b0ed626766d4 127.0.0.1:7004
   replicates 4ada3ff1b6dbbe57e7ba94fe2a1ab4a22451998e
S: a876e977fc2ff9f18765a89c12fbd2c5b5b1f3bf 127.0.0.1:7005
   replicates 719b2f9daefb888f637c5dc4afa2768736241f74
S: ac8d6c4067dec795168ca705bf16efaa5f04095a 127.0.0.1:7006
   replicates 0313641a28e42014a48cdaee47352ce88a2ae083
Can I set the above configuration? (type 'yes' to accept): yes 
# 这里有个要手动输入 yes 确认的过程
```

![image-20210820113910359](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820113910359.png)

##### 数据验证

```
[root@BIGDATA1 redis-6.2.5]#  redis-cli -p 7001 -c
127.0.0.1:7001> set k1 v1
-> Redirected to slot [12706] located at 127.0.0.1:7003
OK
127.0.0.1:7003> get k1
"v1"
127.0.0.1:7003> 
```

