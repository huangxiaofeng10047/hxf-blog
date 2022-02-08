---
title: gradle_解决error-unmappable-character-for-encoding-gbk
date: 2021-08-15 11:55:51
tags:
- gradle
categories: 
- tools
---

在学习某个项目时，`.\gradlew build`总是遇到**error: unmappable character (0x80) for encoding GBK**。至少确定源文件至少会是UTF8的，所以尝试设置文件编码格式来解决这个问题。
一般使用javac编译和java执行程序时，可以使用：

<!--more-->


```
javac -encoding UTF-8 Test.java
java -Dfile.encoding=UTF-8 Test
```

对于Gradle项目，可以设置gradlew.bat:

```
set DEFAULT_JVM_OPTS="-Dfile.encoding=UTF-8"
```

对于IntelliJ Idea，可在配置文件vmoption文件底部添加一行：

```
-Dfile.encoding=UTF-8
```

经过上述尝试，问题依旧存在，仔细一看错误是发生在javadoc任务阶段，一个java文件注释中包含一个字符“ß”导致这个问题的出现。
在build.gradle文件中添加：

```
javadoc {
    options.encoding = 'UTF-8'
}
```

搞定！！！
