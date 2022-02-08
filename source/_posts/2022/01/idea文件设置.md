
---
title: idea的启动参数配置G1
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
```
# Custom IntelliJ VM Options
#
# https://github.com/FoxxMD/intellij-jvm-options-explained
# https://intellij-support.jetbrains.com/hc/en-us/articles/206544869-Configuring-JVM-options-and-platform-properties
-Xms1024m
-Xmx3072m

-XX:+HeapDumpOnOutOfMemoryError
-XX:+OptimizeStringConcat
-XX:+UseCompressedOops
-XX:+UseCompressedStrings
-XX:+UseFastAccessorMethods
-XX:+UseG1GC
-XX:+UseStringCache
-XX:-OmitStackTraceInFastThrow
-XX:ErrorFile=$USER_HOME/java_error_in_idea_%p.log
-XX:HeapDumpPath=$USER_HOME/java_error_in_idea.hprof
-XX:MaxJavaStackTraceDepth=10000
-XX:NewRatio=2
-XX:ReservedCodeCacheSize=320m
-XX:SoftRefLRUPolicyMSPerMB=50
-Xverify:none
-server

#-Deditor.distraction.free.mode=true 会在编辑器右侧有一个巨大的分割如下图所示

-Dfile.encoding=UTF-8
-Dide.no.platform.update=true
-Djava.net.preferIPv4Stack=true
-Djdk.http.auth.tunneling.disabledSchemes=""
-Dsun.io.useCanonCaches=false

```

```
# Custom IntelliJ VM Options
#
# https://github.com/FoxxMD/intellij-jvm-options-explained
# https://intellij-support.jetbrains.com/hc/en-us/articles/206544869-Configuring-JVM-options-and-platform-properties
-Xms1024m
-Xmx3072m

-XX:+HeapDumpOnOutOfMemoryError
-XX:+OptimizeStringConcat
-XX:+UseCompressedOops
-XX:+UseCompressedStrings
-XX:+UseFastAccessorMethods
-XX:+UseG1GC
-XX:+UseStringCache
-XX:-OmitStackTraceInFastThrow
-XX:ErrorFile=$USER_HOME/java_error_in_idea_%p.log
-XX:HeapDumpPath=$USER_HOME/java_error_in_idea.hprof
-XX:MaxJavaStackTraceDepth=10000
-XX:NewRatio=2
-XX:ReservedCodeCacheSize=320m
-XX:SoftRefLRUPolicyMSPerMB=50
-Xverify:none
-server
-Deditor.distraction.free.mode=true
-Dfile.encoding=UTF-8
-Dide.no.platform.update=true
-Djava.net.preferIPv4Stack=true
-Djdk.http.auth.tunneling.disabledSchemes=""
-Dsun.io.useCanonCaches=false

```

出现以下样子：

![image-20220127130704247](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220127130704247.png)

关闭掉：

```
# Custom IntelliJ VM Options
#
# https://github.com/FoxxMD/intellij-jvm-options-explained
# https://intellij-support.jetbrains.com/hc/en-us/articles/206544869-Configuring-JVM-options-and-platform-properties
-Xms1024m
-Xmx3072m

-XX:+HeapDumpOnOutOfMemoryError
-XX:+OptimizeStringConcat
-XX:+UseCompressedOops
-XX:+UseCompressedStrings
-XX:+UseFastAccessorMethods
-XX:+UseG1GC
-XX:+UseStringCache
-XX:-OmitStackTraceInFastThrow
-XX:ErrorFile=$USER_HOME/java_error_in_idea_%p.log
-XX:HeapDumpPath=$USER_HOME/java_error_in_idea.hprof
-XX:MaxJavaStackTraceDepth=10000
-XX:NewRatio=2
-XX:ReservedCodeCacheSize=320m
-XX:SoftRefLRUPolicyMSPerMB=50
-Xverify:none
-server
-Deditor.distraction.free.mode=false
-Dfile.encoding=UTF-8
-Dide.no.platform.update=true
-Djava.net.preferIPv4Stack=true
-Djdk.http.auth.tunneling.disabledSchemes=""
-Dsun.io.useCanonCaches=false

```

![image-20220127130851307](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220127130851307.png)