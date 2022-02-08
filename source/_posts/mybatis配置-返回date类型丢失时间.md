---
title: mybatis配置-返回date类型丢失时间
date: 2021-08-24 15:19:53
tags: 
  - java 
  - mybatis
categories: 
- mybatis
---

![](https://gitee.com/hxf88/imgrepo/raw/master/img/730326-20160715094002592-658803115.png)

resultMap配置返回时间类型时，发现数据库时间是精确到秒的，但是返回给javabean之后丢失时分秒的信息，只有日期，时分秒为00:00:00

原因为配置了date

<!--more-->

将jdbcType="DATE"配置删掉就可以返回日期和时分秒信息了

