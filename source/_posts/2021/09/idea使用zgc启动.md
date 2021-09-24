---
title: idea使用zgc启动
date: 2021-09-24 15:12:40
tags:
- java
- idea
categories: 
- java
---

最近看blog，发现zgc已经可以支持windows，好的，刚把系统升级到11，再来体验一把zgc的好处：

![image-20210924151630195](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924151630195.png)

我使用的windows11，idea2021.2版本，开始干了：

<!--more-->

首先选取jdk，这里现在的

JDK这里选择知名JVM提供商 Azul基于OpenJDK编译好的zulu发行版：Java Download | Java 8, Java 11, Java 13 - Linux, Windows & macOS (azul.com)

Azul出品必属精品，ZGC所采用的算法就是Azul Systems很多年前提出的Pauseless GC。

更改idea的Java runtime前一定要先备份配置文件，以免启动不了idea。

把idea64.exe.vmoptions备份以便，一面启动的时候出错，

当发生不能启动时，直接删除idea64.exe.jdk即可。

![image-20210924151851311](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924151851311.png)

这里选择的jdk17，因为jdk17将会是长久支持，认准lts，我选取的版本为：`zulu17.28.13-ca-jdk17.0.0-win_x64`

![image-20210924152103089](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152103089.png)

![image-20210924152118101](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152118101.png)

选择add custom runtime

![image-20210924152135374](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152135374.png)

选择jdk17

![image-20210924152222808](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152222808.png)

下面介绍一下，因为jdk17增强了安全机制，防止反射调用内部方法，因此之前的`--illegal-access=permit`已经失去作用了，现在需要通过add opens来让程序正常运行，下面提出我的启动参数

```
-Xms2048m
-Xmx4096m
-XX:+UnlockExperimentalVMOptions
-XX:+UseZGC
--add-exports=java.base/jdk.internal.ref=ALL-UNNAMED
--add-exports=java.base/java.lang=ALL-UNNAMED
--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED
--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED
--add-exports=java.desktop/sun.font=ALL-UNNAMED
--add-exports=java.desktop/java.awt.event=ALL-UNNAMED
--add-exports=java.desktop/sun.java2d=ALL-UNNAMED
--add-exports=java.desktop/sun.awt.windows=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED 
--add-opens=java.desktop/javax.swing.text.html=ALL-UNNAMED
--add-opens=java.desktop/sun.awt=ALL-UNNAMED
--add-opens=java.desktop/java.awt=ALL-UNNAMED
--add-opens=java.desktop/java.awt.event=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED 
--add-opens=java.base/java.nio=ALL-UNNAMED 
--add-exports=java.base/java.util=ALL-UNNAMED 
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED 
--add-opens=java.management/sun.management=ALL-UNNAMED 
--add-opens=jdk.management/com.ibm.lang.management.internal=ALL-UNNAMED 
--add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED 
--add-exports=java.desktop/sun.awt=ALL-UNNAMED
--add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor.event=ALL-UNNAMED
--add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED
--add-exports=java.desktop/sun.swing=ALL-UNNAMED
--add-opens=java.desktop/sun.font=ALL-UNNAMED
--add-exports=jdk.attach/sun.tools.attach=ALL-UNNAMED
--add-opens=java.base/java.net=ALL-UNNAMED
--add-opens=java.base/java.lang.ref=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED
--add-opens=java.base/java.util=ALL-UNNAMED
--add-opens=java.desktop/javax.swing=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.plaf.basic=ALL-UNNAMED
-ea
-Dsun.io.useCanonCaches=false
-Djdk.http.auth.tunneling.disabledSchemes=""
-Djdk.attach.allowAttachSelf=true
-Djdk.module.illegalAccess.silent=true
-Dkotlinx.coroutines.debug=off
-XX:+HeapDumpOnOutOfMemoryError
-Dfile.encoding=UTF-8
```

下面即可愉快的玩耍了：

![image-20210924152549871](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152549871.png)

![image-20210924152449020](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924152449020.png)

