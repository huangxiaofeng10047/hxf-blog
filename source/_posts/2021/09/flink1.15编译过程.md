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

编译命令

```
解释： mvn clean install \
	-DskipTests \                # 跳过测试部分
	-Dfast \         # 跳过QA 的插件和 JavaDocs 的生成
	-T 4 \                       # 支持多处理器或者处理器核数参数,加快构建速度,推荐Maven3.3及以上
	-Dmaven.compile.fork=true                   #允许多线程编译,推荐maven在3.3及以上
	
mvn clean install \
-DskipTests \
-Dfast \
-T 4 \
-Dmaven.compile.fork=true 
```

