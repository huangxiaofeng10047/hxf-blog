---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
在my.cnf中添加 

　　2.在[mysqld]下加入一行：lower_case_table_names=1

在启动参数中加入

- /usr/local/mysql/bin/mysqld --user=mysql --lower-case-table-names=1 --initialize-insecure --basedir=/usr/local/mysql --datadir=/data/mysql/node1
- 

否在会报错如下：

- 若初始化和启动值不一样则会在错误日志中有如下提示：
- 
- [ERROR] [MY-011087] [Server] Different lower_case_table_names settings for server ('1') and data dictionary ('0').