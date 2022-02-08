---
title: harbor配置外部数据库
date: 2022-01-04 11:29:34
description: 点击阅读前文前, 首页能看到的文章的简短描述
tags:
---

### **PostgreSQL**

1）下载PostgreSQL官方YUM源配置文件包并安装

```text
wget https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
rpm -ivh pgdg-redhat-repo-latest.noarch.rpm 
```

2）安装PostgreSQL

```text
yum  -y install postgresql96-server postgresql96-contrib 
```

3）初始化数据库

```text
/usr/pgsql-9.6/bin/postgresql96-setup initdb  
```

4）启动数据库

```text
systemctl enable postgresql-9.6 && systemctl restart postgresql-9.6
```

5）PostgreSQL数据库配置

1. 修改密码

```text
# su - postgres
-bash-4.2$ psql
psql (9.6.17)
Type "help" for help.
postgres=# ALTER USER postgres WITH PASSWORD 'postgres';
ALTER ROLE
```

1. 开启远程访问

```text
vi /var/lib/pgsql/9.6/data/postgresql.conf

# listen_addresses = 'localhost' 改为 listen_addresses='*'
```

1. 信任远程连接

```
vim /var/lib/pgsql/9.6/data/pg_hba.conf
```

加入:

```text
#host    replication     postgres        ::1/128                 ident
host     all             all             192.168.20.50/32         trust
host    all             all             192.168.20.147/32         trust
host    all             all             172.18.0.9/24             trust
```

6）重启PostgreSQL服务

```text
systemctl restart postgresql-9.6
```

7）验证服务

```text
psql -h 192.168.20.50 -p 5432 -U postgres
```

修改harbor.yml文件

添加external_database,具体如下：

```
external_database:
   harbor:
     host: 192.168.20.50
     port: 5432
     db_name: registry
     username: postgres
     password: postgres
     ssl_mode: disable
     max_idle_conns: 2
     max_open_conns: 0
   notary_signer:
     host: 192.168.20.50
     port: 5432
     db_name: notarysigner
     username: postgres
     password: postgres
     ssl_mode: disable
   notary_server:
     host: 192.168.20.50
     port: 5432
     db_name: notaryserver
     username: postgres
     password: postgres
     ssl_mode: disable
```

参考文档：

> [生产级harbor可用的搭建 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/346697757)
