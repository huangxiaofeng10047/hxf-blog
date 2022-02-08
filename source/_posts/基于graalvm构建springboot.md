---
title: 基于graalvm构建springboot
date: 2021-09-10 11:41:59
tags:
- graalvm
- java
categories: 
- java
---

**GraalVM**\[1\] 是一种高性能的虚拟机，它可以显著的提高程序的性能和运行效率，非常适合微服务。最近比较火的 Java 框架 **Quarkus**\[2\] 默认支持 GraalVM

下图为 Quarkus 和传统框架（SpringBoot） 等对比图，**更快的启动数据、更小的内存消耗、更短的服务响应**。

![](https://img.21ic.com/weixin/2020/12/jQZZRr.jpeg)

Spring Boot 2.4 开始逐步提供对 GraalVM 的支持，**旨在提升上文所述的 启动、内存、响应的使用体验**。  

### 安装 GraalVM

-   目前官方社区版本最新为 20.3.0 ，是基于 OpenJDK 8u272 and 11.0.9 定制的，可以理解为 OpenJDK 的衍生版本 。
    

![](https://gitee.com/hxf88/imgrepo/raw/master/img/raamue.jpeg)

-   官方推荐的是  **SDKMAN**\[3\] 用于快速安装和切换不同版本 JDK 的工具 ，类似于 nodejs 的  **nvm**\[4\]。
    

使用类似命令即可完成指定版本安装和指定默认版本

```
sdk install java 11.0.9.hs-adptsdk default java 11.0.9.hs-adpt
```

不过安装过程中需要从国外下载相关资源 ，笔者在尝试后使用体验并不是很好，所有建议大家下载指定版本 GraalVM 安装即可（和 JDK 安装方式一样）。

-   安装成功查看版本
    

```
⋊> ~ java -version                                                      11:30:34openjdk version "11.0.9" 2020-10-20OpenJDK Runtime Environment GraalVM CE 20.3.0 (build 11.0.9+10-jvmci-20.3-b06)OpenJDK 64-Bit Server VM GraalVM CE 20.3.0 (build 11.0.9+10-jvmci-20.3-b06, mixed mode, sharing)
```

### 安装 native-image

native-image 是由 Oracle Labs 开发的一种 AOT 编译器，应用所需的 class 依赖项及 runtime 库打包编译生成一个单独可执行文件。**具有高效的 startup 及较小的运行时内存开销的优势**。

但 GraalVM 并未内置只是提供 gu 安装工具，需要我们单独安装。

```
- 切换到 jdk 的安装目录⋊> ~ cd $JAVA_HOME/bin/- 使用gu命令安装⋊>  ./gu install native-image
```

### 初始化 Spring Boot 2.4 项目

-   Spring Initializr 创建 demo 项目
    

```
curl https://start.spring.io/starter.zip -d dependencies=web \           -d bootVersion=2.4.1 -o graal-demo.zip
```

-   先看一下启动基准数据 ， 单纯运行空项目 需要 1135 ms 秒
    

```
java -jar demo-0.0.1-SNAPSHOT.jarengine: [Apache Tomcat/9.0.41]2020-12-18 11:48:36.856  INFO 91457 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext2020-12-18 11:48:36.856  INFO 91457 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 1135 ms
```

-   内存占用情况
    

```
ps aux | grep demo-0.0.1-SNAPSHOT.jar | grep -v grep | awk '{print $11 "\t" $6/1024"MB" }'/usr/bin/java 480.965MB
```

### 支持 GraalVM

-   增加相关依赖， **涉及插件较多完整已上传**  **Gitee Gist**\[5\]
    

```
<dependency>    <groupId>org.springframework.experimentalgroupId>    <artifactId>spring-graalvm-nativeartifactId>    <version>0.8.3version>dependency><dependency>    <groupId>org.springframeworkgroupId>    <artifactId>spring-context-indexerartifactId>dependency><repositories>  <repository>      <id>spring-milestonesid>      <name>Spring Milestonesname>      <url>https://repo.spring.io/milestoneurl>  repository>repositories>
```

-   Main 方法修改,proxyBeanMethods = false
    

```
@SpringBootApplication(proxyBeanMethods = false)
```

-   使用 native-image 构建可执行文件
    

```
 mvn -Pnative package#构建过程比较慢，日志如下spring.factories files...[com.example.demo.demoapplication:93430]    classlist:   4,633.58 ms,  1.18 GB   _____                     _                             _   __           __     _  / ___/    ____    _____   (_)   ____    ____ _          / | / /  ____ _  / /_   (_) _   __  ___  \__ \    / __ \  / ___/  / /   / __ \  / __ `/         /  |/ /  / __ `/ / __/  / / | | / / / _ \ ___/ /   / /_/ / / /     / /   / / / / / /_/ /         / /|  /  / /_/ / / /_   / /  | |/ / /  __//____/   / .___/ /_/     /_/   /_/ /_/  \__, /         /_/ |_/   \__,_/  \__/  /_/   |___/  \___/        /_/                            /____/...[com.example.demo.demoapplication:93430]      [total]: 202,974.38 ms,  4.23 GB
```

-   编译结果
    

在 targe 目录生成 名称为 `com.example.demo.demoapplication` 可执行文件

-   启动应用  **这里执行的编译后的可执行文件而不是 jar**
    

```
cd target./com.example.demo.demoapplication
```

-   启动时间 0.215 seconds
    

```
2020-12-18 12:30:40.625  INFO 94578 --- [           main] com.example.demo.DemoApplication         : Started DemoApplication in 0.215 seconds (JVM running for 0.267)
```

-   看一下内存占用 24.8203MB
    

```
ps aux | grep com.example.demo.demoapplication | grep -v grep | awk '{print $11 "\t" $6/1024"MB" }'./com.example.demo.demoapplication 24.8203MB
```

### 数据对比

是否引入 GraalVM

内存占用

启动时间

否

480.965MB

1135 ms

是

24.8203MB

215 ms

#### 参考资料

\[1\]GraalVM: _https://www.graalvm.org_

\[2\]Quarkus: _https://quarkus.io_

\[3\]SDKMAN: _https://sdkman.io/install_

\[4\]nvm: _https://github.com/creationix/nvm_

\[5\]Gitee Gist: _https://gitee.com/gi2/codes/famcqz6n21iylpg3us7j036_
