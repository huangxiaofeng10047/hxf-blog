---
title: CDH集群中部署Presto
date: 2021-08-27 16:28:01
tags:
- presto
categories: 
- bigdata
---

presto parcel文件

http://10.11.5.10/presto-repo/repository

<!--more-->

![image-20210831103137332](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831103137332.png)

![image-20210831102602779](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831102602779.png)

![image-20210831102720671](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831102720671.png)

激活后，重启一下cloudera-sm-server即可

```
 systemctl restart cloudera-scm-server
```

需要进行安装服务操作，启用presto即可



下载prestoparcel的服务包

服务地址： git@github.com:s-wool/presto-parcel.git

clone代码

执行`mvn clean install`进行编译

```java
presto-parcel on  master [📝🤷‍] via ☕ v1.8.0
➜ mvn clean install
[INFO] Scanning for projects...
[WARNING]
[WARNING] Some problems were encountered while building the effective model for com.facebook.presto.parcel:PRESTO:jar:0.1
[WARNING] 'build.plugins.plugin.version' for org.codehaus.mojo:exec-maven-plugin is missing. @ line 15, column 15
[WARNING]
[WARNING] It is highly recommended to fix these problems because they threaten the stability of your build.
[WARNING]
[WARNING] For this reason, future Maven versions might no longer support building such malformed projects.
[WARNING]
[INFO]
[INFO] -----------------< com.facebook.presto.parcel:PRESTO >------------------
[INFO] Building presto-parcel 0.1
[INFO] --------------------------------[ jar ]---------------------------------
[INFO]
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ PRESTO ---
[INFO] Deleting /home/hxf/presto-parcel/target
[INFO]
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ PRESTO ---
[WARNING] File encoding has not been set, using platform encoding UTF-8, i.e. build is platform dependent!
[WARNING] Using platform encoding (UTF-8 actually) to copy filtered resources, i.e. build is platform dependent!
[INFO] Copying 5 resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ PRESTO ---
[INFO] No sources to compile
[INFO]
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ PRESTO ---
[WARNING] Using platform encoding (UTF-8 actually) to copy filtered resources, i.e. build is platform dependent!
[INFO] skip non existing resourceDirectory /home/hxf/presto-parcel/src/test/resources
[INFO]
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ PRESTO ---
[INFO] No sources to compile
[INFO]
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ PRESTO ---
[INFO] No tests to run.
[INFO]
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ PRESTO ---
[INFO] Building jar: /home/hxf/presto-parcel/target/PRESTO-0.147.presto0.1.jar
[INFO]
[INFO] --- exec-maven-plugin:3.0.0:exec (assemble) @ PRESTO ---
~/presto-parcel ~/presto-parcel
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
100   317  100   317    0     0    203      0  0:00:01  0:00:01 --:--:--   317
  0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0
100  5307  100  5307    0     0   2420      0  0:00:02  0:00:02 --:--:--  2420

gzip: stdin: not in gzip format
tar: Child returned status 1
tar: Error is not recoverable: exiting now
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  463M  100  463M    0     0  15.2M      0  0:00:30  0:00:30 --:--:-- 15.5M
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 12.1M  100 12.1M    0     0  5737k      0  0:00:02  0:00:02 --:--:-- 5738k
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3869  100  3869    0     0    412      0  0:00:09  0:00:09 --:--:--   928
Scanning directory: .
Found parcel PRESTO-0.147.presto0.1-el7.parcel
~/presto-parcel
[INFO]
[INFO] --- maven-install-plugin:2.4:install (default-install) @ PRESTO ---
[INFO] Installing /home/hxf/presto-parcel/target/PRESTO-0.147.presto0.1.jar to /home/hxf/.m2/repository/com/facebook/presto/parcel/PRESTO/0.1/PRESTO-0.1.jar
[INFO] Installing /home/hxf/presto-parcel/pom.xml to /home/hxf/.m2/repository/com/facebook/presto/parcel/PRESTO/0.1/PRESTO-0.1.pom
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  01:14 min
[INFO] Finished at: 2021-08-31T10:21:46+08:00
[INFO] ------------------------------------------------------------------------
```

进入target目录，查看repository目录下：

![image-20210831103014728](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831103014728.png)

当看到el7即可。



POINT_VERSION=5 VALIDATOR_DIR=/mnt/d/workspace/github/cloudera/cm_ext OS_VER=el7 PARCEL_NAME=presto ./build-parcel.sh /mnt/c/Users/hxf/Downloads/presto-server-0.230.tar.gz

 VALIDATOR_DIR=/mnt/d/workspace/github/cloudera/cm_ext CSD_NAME=presto ./build-csd.sh

![image-20210831114209754](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831114209754.png)

![image-20210831114223557](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831114223557.png)

![image-20210831134018731](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831134018731.png)

![image-20210831135137170](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831135137170.png)

### FAQ

**添加服务找不到es服务**

> 访问 http://localhost:7180/cmf/csd/list 查看csd安装是否故障

注意presto配置：

![image-20210901090317921](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901090317921.png)

这个服务为coordinator的地址，基于这个发现地址，work和coordinator才能彼此发现。

查看presto界面：Coordinator WebUI

![image-20210901090434633](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901090434633.png)

看到worker即可。

配置presto与hive链接，通过presto可以查看hive数据库：

![image-20210901092736002](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901092736002.png)

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901092818931.png" alt="image-20210901092818931" style="zoom:150%;" />

可以看到user表，通过hive命令对比一下：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901092903459.png" alt="image-20210901092903459" style="zoom:150%;" />

