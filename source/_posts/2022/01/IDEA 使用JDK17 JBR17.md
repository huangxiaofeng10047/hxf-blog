---
title: idea使用zgc
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
# IDEA 使用JDK17 JBR17

JBR 17：[https://github.com/JetBrains/JetBrainsRuntime/tree/master17](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2FJetBrains%2FJetBrainsRuntime%2Ftree%2Fmaster17)
 IDEA：2021.3 EAP

需要添加以下配置，如果使用过程中报错warn，继续添加 add-opens

```
-Xms4096m
-Xmx4096m
-XX:ReservedCodeCacheSize=512m
-XX:+IgnoreUnrecognizedVMOptions
-XX:+UseZGC
-XX:+UnlockExperimentalVMOptions
-XX:SoftRefLRUPolicyMSPerMB=50
-XX:CICompilerCount=2
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-ea
-Dsun.io.useCanonCaches=false
-Djdk.http.auth.tunneling.disabledSchemes=""
-Djdk.attach.allowAttachSelf=true
-Djdk.module.illegalAccess.silent=true
-Dkotlinx.coroutines.debug=off
-Dsun.tools.attach.tmp.only=true
--illegal-access=warn
-Dsun.java2d.metal=true
--add-opens=java.desktop/java.awt.event=ALL-UNNAMED
--add-opens=java.desktop/sun.font=ALL-UNNAMED
--add-opens=java.desktop/java.awt=ALL-UNNAMED
--add-opens=java.desktop/sun.awt=ALL-UNNAMED
--add-opens=java.desktop/sun.awt.image=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED
--add-opens=java.base/java.util=ALL-UNNAMED
--add-opens=java.desktop/javax.swing=ALL-UNNAMED
--add-opens=java.desktop/sun.swing=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.plaf.basic=ALL-UNNAMED
--add-opens=java.desktop/java.awt.peer=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.text.html=ALL-UNNAMED
--add-exports=java.desktop/sun.font=ALL-UNNAMED
--add-exports=java.desktop/com.apple.eawt=ALL-UNNAMED
--add-exports=java.desktop/com.apple.laf=ALL-UNNAMED
--add-exports=java.desktop/com.apple.eawt.event=ALL-UNNAMED
--add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED

```

修改在windows上启动启动文件修改为：

```
-Xms8096m
-Xmx8096m
-XX:ReservedCodeCacheSize=512m
-XX:+IgnoreUnrecognizedVMOptions
-XX:+UseZGC
-XX:+UnlockExperimentalVMOptions
-XX:SoftRefLRUPolicyMSPerMB=50
-XX:CICompilerCount=2
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-ea
-Dsun.io.useCanonCaches=false
-Djdk.http.auth.tunneling.disabledSchemes=""
-Djdk.attach.allowAttachSelf=true
-Djdk.module.illegalAccess.silent=true
-Dkotlinx.coroutines.debug=off
-Dsun.tools.attach.tmp.only=true
--illegal-access=warn
-Dsun.java2d.metal=true
--add-opens=java.desktop/java.awt.event=ALL-UNNAMED
--add-opens=java.desktop/sun.font=ALL-UNNAMED
--add-opens=java.desktop/java.awt=ALL-UNNAMED
--add-opens=java.desktop/sun.awt=ALL-UNNAMED
--add-opens=java.base/java.lang=ALL-UNNAMED
--add-opens=java.base/java.util=ALL-UNNAMED
--add-opens=java.desktop/javax.swing=ALL-UNNAMED
--add-opens=java.desktop/sun.swing=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.plaf.basic=ALL-UNNAMED
--add-opens=java.desktop/java.awt.peer=ALL-UNNAMED
--add-opens=java.desktop/javax.swing.text.html=ALL-UNNAMED
--add-exports=java.desktop/sun.font=ALL-UNNAMED
--add-exports=java.desktop/sun.java2d=ALL-UNNAMED
--add-exports=java.desktop/sun.awt.windows=ALL-UNNAMED
--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED
--add-opens=java.desktop/sun.awt.windows=ALL-UNNAMED


```

