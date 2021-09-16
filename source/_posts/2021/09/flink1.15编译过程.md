---
title: flink1.15编译过程
date: 2021-09-15 16:04:17
tags:
- bigdata
- flink
categories: 
- java
---
flink编译记录

npm install -g @angular/cli

<!--more-->

**先测试编译环境是否正常:**
只保留<module>flink-runtime-web</module>
注释掉其他所有module
mvn clean install -T 2C  -DskipTests  -Dmaven.compile.fork=true

占用资源高。

![image-20210916123504433](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210916123504433.png)

**整体编译:**
flink/pom.xml恢复原样 (取消原来的注释)
mvn clean install -T 2C  -DskipTests  -Dmaven.compile.fork=true

![image-20210916123653712](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210916123653712.png)

资源占用很高

参考：

[flink1.12编译](https://www.codetd.com/article/11298428)

