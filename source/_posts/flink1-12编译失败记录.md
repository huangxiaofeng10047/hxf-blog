---
title: flink1.12编译失败记录
date: 2021-08-19 08:49:13
tags:
---

编译flink1.12.5命令：

```shell
 mvn  clean install -DskipTests -Pvendor-repos -Dhadoop.version=3.0.0-cdh6.0.1 -Dscala-2.11 -Drat.skip=true -T10C
```

出现以下报错

```log
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.8.1:compile (default-compile) on project metastore-tools-common: Execution default-compile of goal org.apache.maven.plugins:maven-compiler-plugin:3.8.1:compile failed: 
Plugin org.apache.maven.plugins:maven-compiler-plugin:3.8.1 or one of its dependencies could not be resolved:
Could not transfer artifact com.google.errorprone:javac:jar:9+181-r4173-1 from/to alimaven (http://maven.aliyun.com/nexus/content/repositories/central/): Authorization failed for http://maven.aliyun.com/nexus/content/repositories/central/com/google/errorprone/javac/9+181-r4173-1/javac-9+181-r4173-1.jar 403 Forbidden -> [Help 1]
```

**整个意思是javac-9+181-r4173-1.jar因为阿里云的maven仓库的403权限问题无法下载
下面开始排查com.google.errorprone是哪个pom.xml写入的依赖需求**

针对这个问题解决方案就是，手动安装这个jar包。

```shell
mvn install:install-file -DgroupId=com.google.errorprone -DartifactId=javac -Dversion=9+181-r4173-1 -Dpackaging=jar -Dfile=C:\Users\hxf\Downloads\javac-9+181-r4173-1.jar
```

参考：

[https://blog.csdn.net/figosoar/article/details/119037521](https://blog.csdn.net/figosoar/article/details/119037521)

