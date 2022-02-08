---
title: openjdk验证码无法显示
date: 2021-10-22 14:32:55
tags: 
- springboot
categories: 
- java
---

##通过镜像运行程序遇到的问题
之前开发的应用都是基于OracleJDK 1.8来做的，图片验证码显示正常，但是更换成OpenJDK1.8后，验证码无法显示，后台代码抛出异常，异常内容如下，java.lang.NullPointerException at sun.awt.FontConfiguration.getVersion（FontConfiguration.java 1264）

，后来发现需要在操作系统层面安装FontConfig组件。本人环境使用的是Centos 7.3 于是直接安装FontConfig即可，如果你使用的docker容器环境，需要在镜像中进行安装，并执行fc-ache --force(必须执行)

假如使用的debain系统，则按照对应的系统执行安装。

我使用的是mini-debian系统，按照doc文档说明使用：

```
RUN install_packages fontconfig
RUN fc-cache --force
```

## minideb

A minimalist Debian-based image built specifically to be used as a base image for containers.

地址：

[https://github.com/bitnami/minideb](https://github.com/bitnami/minideb)

## Why use Minideb

- This image aims to strike a good balance between having small images, and having many quality packages available for easy integration.

- The image is based on glibc for wide compatibility, and has apt for access to a large number of packages. In order to reduce size of the image, some things that aren't required in containers are removed:

  - Packages that aren't often used in containers (hardware related, init systems etc.)
  - Some files that aren't usually required (docs, man pages, locales, caches)

- These images also include an `install_packages` command that you can use instead of apt. This takes care of some things for you:

  - Install the named packages, skipping prompts etc.
  - Clean up the apt metadata afterwards to keep the image small.
  - Retrying if apt fails. Sometimes a package will fail to download due to a network issue, and this may fix that, which is particularly useful in an automated build pipeline.

  For example:

  ```
  $ install_packages apache2 memcached
  ```

