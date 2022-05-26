---
title: dockerfile编写
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
如今 GitHub 仓库中已经包含了成千上万的 `Dockerfile` ，但并不是所有的 `Dockerfile` 都是高效的。很多新手一上来就是FROM centos然后RUN 一堆yum install的，这样还停留在虚拟机的角度。可以FROM alpine或者干脆拿官方的改，alpine初期的时候问题蛮多的，很多人建议使用alpine做基础镜像最好是测试好再上线，现在alpine的快速发展，这种现象很少了。本文将从四个方面来介绍 `Dockerfile` 的最佳实践，以此来帮助大家编写更优雅的 `Dockerfile`。

> 本文使用一个基于 Maven 的 Java 项目作为示例，然后不断改进 `Dockerfile` 的写法，直到最后写出一个最优雅的 `Dockerfile`。中间的所有步骤都是为了说明某一方面的最佳实践。

## [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%87%8F%E5%B0%91%E6%9E%84%E5%BB%BA%E6%97%B6%E9%97%B4 "减少构建时间")减少构建时间

一个开发周期包括构建 Docker 镜像，更改代码，然后重新构建 Docker 镜像。在构建镜像的过程中，如果能够利用缓存，可以减少不必要的重复构建步骤。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E6%9E%84%E5%BB%BA%E9%A1%BA%E5%BA%8F%E5%BD%B1%E5%93%8D%E7%BC%93%E5%AD%98%E7%9A%84%E5%88%A9%E7%94%A8%E7%8E%87 "构建顺序影响缓存的利用率")构建顺序影响缓存的利用率

[![dockerfile-1](https://s2.loli.net/2022/01/10/qZV12kriMPLnCpN.jpg)](https://system51.github.io/images/dockerfile-1.jpg)

镜像的构建顺序很重要，当你向 `Dockerfile` 中添加文件，或者修改其中的某一行时，那一部分的缓存就会失效，该缓存的后续步骤都会中断，需要重新构建。所以优化缓存的最佳方法是把不需要经常更改的行放到最前面，更改最频繁的行放到最后面。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%8F%AA%E6%8B%B7%E8%B4%9D%E9%9C%80%E8%A6%81%E7%9A%84%E6%96%87%E4%BB%B6%EF%BC%8C%E9%98%B2%E6%AD%A2%E7%BC%93%E5%AD%98%E6%BA%A2%E5%87%BA "只拷贝需要的文件，防止缓存溢出")只拷贝需要的文件，防止缓存溢出

[![dockerfile-2](https://s2.loli.net/2022/01/10/zmDA4Ll9YFuZvTC.jpg)](https://system51.github.io/images/dockerfile-2.jpg)

当拷贝文件到镜像中时，尽量只拷贝需要的文件，切忌使用 `COPY .` 指令拷贝整个目录。如果被拷贝的文件内容发生了更改，缓存就会被破坏。在上面的示例中，镜像中只需要构建好的 jar 包，因此只需要拷贝这个文件就行了，这样即使其他不相关的文件发生了更改也不会影响缓存。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E6%9C%80%E5%B0%8F%E5%8C%96%E5%8F%AF%E7%BC%93%E5%AD%98%E7%9A%84%E6%89%A7%E8%A1%8C%E5%B1%82 "最小化可缓存的执行层")最小化可缓存的执行层

[![dockerfile-3](https://s2.loli.net/2022/01/10/Wh2JAjHrkxX1etq.jpg)](https://system51.github.io/images/dockerfile-3.jpg)

每一个 `RUN` 指令都会被看作是可缓存的执行单元。太多的 `RUN` 指令会增加镜像的层数，增大镜像体积，而将所有的命令都放到同一个 `RUN` 指令中又会破坏缓存，从而延缓开发周期。当使用包管理器安装软件时，一般都会先更新软件索引信息，然后再安装软件。推荐将更新索引和安装软件放在同一个 `RUN` 指令中，这样可以形成一个可缓存的执行单元，否则你可能会安装旧的软件包。

## [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%87%8F%E5%B0%8F%E9%95%9C%E5%83%8F%E4%BD%93%E7%A7%AF "减小镜像体积")减小镜像体积

镜像的体积很重要，因为镜像越小，部署的速度更快，攻击范围越小。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%88%A0%E9%99%A4%E4%B8%8D%E5%BF%85%E8%A6%81%E4%BE%9D%E8%B5%96 "删除不必要依赖")删除不必要依赖

[![dockerfile-4](https://s2.loli.net/2022/01/10/1KTgoSeL9dzQMC6.jpg)](https://system51.github.io/images/dockerfile-4.jpg)

删除不必要的依赖，不要安装调试工具。如果实在需要调试工具，可以在容器运行之后再安装。某些包管理工具（如 `apt`）除了安装用户指定的包之外，还会安装推荐的包，这会无缘无故增加镜像的体积。`apt` 可以通过添加参数 `-–no-install-recommends` 来确保不会安装不需要的依赖项。如果确实需要某些依赖项，请在后面手动添加。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%88%A0%E9%99%A4%E5%8C%85%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7%E7%9A%84%E7%BC%93%E5%AD%98 "删除包管理工具的缓存")删除包管理工具的缓存

[![dockerfile-5](https://s2.loli.net/2022/01/10/TDURdPpkEoHl4tg.jpg)](https://system51.github.io/images/dockerfile-5.jpg)

包管理工具会维护自己的缓存，这些缓存会保留在镜像文件中，推荐的处理方法是在每一个 `RUN` 指令的末尾删除缓存。如果你在下一条指令中删除缓存，不会减小镜像的体积。

当然了，还有其他更高级的方法可以用来减小镜像体积，如下文将会介绍的多阶段构建。接下来我们将探讨如何优化 `Dockerfile` 的可维护性、安全性和可重复性。

## [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%8F%AF%E7%BB%B4%E6%8A%A4%E6%80%A7 "可维护性")可维护性

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%B0%BD%E9%87%8F%E4%BD%BF%E7%94%A8%E5%AE%98%E6%96%B9%E9%95%9C%E5%83%8F "尽量使用官方镜像")尽量使用官方镜像

[![dockerfile-6](https://s2.loli.net/2022/01/10/Z8gCfxiQTKsP3Im.jpg)](https://system51.github.io/images/dockerfile-6.jpg)  
使用官方镜像可以节省大量的维护时间，因为官方镜像的所有安装步骤都使用了最佳实践。如果你有多个项目，可以共享这些镜像层，因为他们都可以使用相同的基础镜像。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E4%BD%BF%E7%94%A8%E6%9B%B4%E5%85%B7%E4%BD%93%E7%9A%84%E6%A0%87%E7%AD%BE "使用更具体的标签")使用更具体的标签

[![dockerfile-7](https://s2.loli.net/2022/01/10/GdRMSztWZfKb47e.jpg)](https://system51.github.io/images/dockerfile-7.jpg)  
基础镜像尽量不要使用 `latest` 标签。虽然这很方便，但随着时间的推移，`latest` 镜像可能会发生重大变化。因此在 `Dockerfile` 中最好指定基础镜像的具体标签。我们使用 `openjdk` 作为示例，指定标签为 `8`。其他更多标签请查看官方仓库。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E4%BD%BF%E7%94%A8%E4%BD%93%E7%A7%AF%E6%9C%80%E5%B0%8F%E7%9A%84%E5%9F%BA%E7%A1%80%E9%95%9C%E5%83%8F "使用体积最小的基础镜像")使用体积最小的基础镜像

[![dockerfile-8](https://s2.loli.net/2022/01/10/75Mi8dAC2mjYc6s.jpg)](https://system51.github.io/images/dockerfile-8.jpg)

基础镜像的标签风格不同，镜像体积就会不同。`slim` 风格的镜像是基于 Debian 发行版制作的，而 `alpine` 风格的镜像是基于体积更小的 Alpine Linux 发行版制作的。其中一个明显的区别是：Debian 使用的是 GNU 项目所实现的 C 语言标准库，而 Alpine 使用的是 Musl C 标准库，它被设计用来替代 GNU C 标准库（glibc）的替代品，用于嵌入式操作系统和移动设备。因此使用 Alpine 在某些情况下会遇到兼容性问题。 以 openjdk 为例，`jre` 风格的镜像只包含 Java 运行时，不包含 `SDK`，这么做也可以大大减少镜像体积。

## [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E9%87%8D%E5%A4%8D%E5%88%A9%E7%94%A8 "重复利用")重复利用

到目前为止，我们一直都在假设你的 jar 包是在主机上构建的，这还不是理想方案，因为没有充分利用容器提供的一致性环境。例如，如果你的 Java 应用依赖于某一个特定的操作系统的库，就可能会出现问题，因为环境不一致（具体取决于构建 jar 包的机器）。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%9C%A8%E4%B8%80%E8%87%B4%E7%9A%84%E7%8E%AF%E5%A2%83%E4%B8%AD%E4%BB%8E%E6%BA%90%E4%BB%A3%E7%A0%81%E6%9E%84%E5%BB%BA "在一致的环境中从源代码构建")在一致的环境中从源代码构建

源代码是你构建 Docker 镜像的最终来源，Dockerfile 里面只提供了构建步骤。  
[![dockerfile-9](https://system51.github.io/images/dockerfile-9.jpg)](https://system51.github.io/images/dockerfile-9.jpg)

首先应该确定构建应用所需的所有依赖，本文的示例 Java 应用很简单，只需要 `Maven` 和 `JDK`，所以基础镜像应该选择官方的体积最小的 `maven` 镜像，该镜像也包含了 `JDK`。如果你需要安装更多依赖，可以在 `RUN` 指令中添加。`pom.xml`文件和 `src` 文件夹需要被复制到镜像中，因为最后执行 `mvn package` 命令（-e 参数用来显示错误，-B 参数表示以非交互式的“批处理”模式运行）打包的时候会用到这些依赖文件。

虽然现在我们解决了环境不一致的问题，但还有另外一个问题：每次代码更改之后，都要重新获取一遍 pom.xml 中描述的所有依赖项。下面我们来解决这个问题。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E5%9C%A8%E5%8D%95%E7%8B%AC%E7%9A%84%E6%AD%A5%E9%AA%A4%E4%B8%AD%E8%8E%B7%E5%8F%96%E4%BE%9D%E8%B5%96%E9%A1%B9 "在单独的步骤中获取依赖项")在单独的步骤中获取依赖项

[![dockerfile-10](https://s2.loli.net/2022/01/10/h6dWiYFRTL3IpV8.jpg)](https://system51.github.io/images/dockerfile-10.jpg)

结合前面提到的缓存机制，我们可以让获取依赖项这一步变成可缓存单元，只要 pom.xml 文件的内容没有变化，无论代码如何更改，都不会破坏这一层的缓存。上图中两个 COPY 指令中间的 RUN 指令用来告诉 Maven 只获取依赖项。

现在又遇到了一个新问题：跟之前直接拷贝 jar 包相比，镜像体积变得更大了，因为它包含了很多运行应用时不需要的构建依赖项。

#### [](https://system51.github.io/2020/11/12/intro-guide-to-dockerfile-best-practices/#%E4%BD%BF%E7%94%A8%E5%A4%9A%E9%98%B6%E6%AE%B5%E6%9E%84%E5%BB%BA%E6%9D%A5%E5%88%A0%E9%99%A4%E6%9E%84%E5%BB%BA%E6%97%B6%E7%9A%84%E4%BE%9D%E8%B5%96%E9%A1%B9 "使用多阶段构建来删除构建时的依赖项")使用多阶段构建来删除构建时的依赖项

[![dockerfile-11](https://s2.loli.net/2022/01/10/fbBVW1H4GCwMFuv.jpg)](https://system51.github.io/images/dockerfile-11.jpg)

多阶段构建可以由多个 FROM 指令识别，每一个 FROM 语句表示一个新的构建阶段，阶段名称可以用 `AS` 参数指定。本例中指定第一阶段的名称为 `builder`，它可以被第二阶段直接引用。两个阶段环境一致，并且第一阶段包含所有构建依赖项。

第二阶段是构建最终镜像的最后阶段，它将包括应用运行时的所有必要条件，本例是基于 Alpine 的最小 JRE 镜像。上一个构建阶段虽然会有大量的缓存，但不会出现在第二阶段中。为了将构建好的 jar 包添加到最终的镜像中，可以使用 `COPY --from=STAGE_NAME` 指令，其中 STAGE\_NAME 是上一构建阶段的名称。

[![dockerfile-12](https://system51.github.io/images/dockerfile-12.jpg)](https://system51.github.io/images/dockerfile-12.jpg)

多阶段构建是删除构建依赖的首选方案。  
本文从在非一致性环境中构建体积较大的镜像开始优化，一直优化到在一致性环境中构建最小镜像，同时充分利用了缓存机制。