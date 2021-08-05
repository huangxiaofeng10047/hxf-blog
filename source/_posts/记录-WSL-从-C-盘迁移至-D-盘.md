---
title: 记录 WSL 从 C 盘迁移至 D 盘
date: 2021-08-05 11:19:16
tags:
---

前言
WSL 默认安装在 C 盘，随着开发时间的增长，数据越来越多，子系统数据占用高达 60 GB，对于原本 100 GB 的 C 盘，不堪重负，终于只剩下不足 300 MB 的空间，随之而来的就是 PHPStorm 无法打开

为了解决这个问题，需要迁移 WSL 默认存储位置

<!--more-->

过程
下载工具

LxRunOffline：一个非常强大的管理子系统的工具

下载并解压后，在解压目录中打开 PowerShell

查看已安装的子系统

 $ LxRunOffline.exe list

![image-20210805112423151](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210805112423151.png)


查看子系统所在目录

 $ LxRunOffline.exe get-dir -n ArchLinux

![image-20210805112646034](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210805112646034.png)


新建目标目录并授权

 $ icacls D:\wsl\installed /grant "hxf:(OI)(CI)(F)"
目标目录：D:\wsl\installed
用户名：hxf
迁移系统

 $ .\LxRunOffline move -n ArchLinux -d D:\wsl\installed\ArchLinux
Copy
然后耐心等待一大堆 Warning 的结束
