---
title: Postgresql数据库cpu使用率高排查和解决
date: 2021-08-13 09:48:13
tags:
- postgres
- sql
categories: 
- 数据库
---

### 追踪慢SQL

CPU使用率高，往往是因为数据库当时在执行比较耗时的SQL，所以处理问题的关键点就是找出执行慢的SQL。下面就介绍一些能追查到慢SQL的方法。

 

**一. 直接定位进程法**，步骤如下：

1. 通过`top`和`ps`命令，直接定位到是哪个进程占用cpu高，拿到进程ID

2. 通过进程ID，结合pg_stat_activity得到该进程对应的SQL

   ```
    select * from pg_stat_activity where pid=进程ID
   ```

此方法不适用于云数据库，因为用户没有查看云数据库进程的权限。

 

**二. 通过pg_stat_statements插件定位**

在使用pg_stat_statements之前，数据需要先安装pg_stat_statements插件，安装方法简单概括如下：

①编译安装

②修改postgresql.conf的`shared_preload_libraries`增加pg_stat_statements来载入

③执行SQL启动插件：`create extension pg_stat_statements;`

一般云数据库已经预先安装了pg_stat_statements， 所以可以跳过安装步骤。一切就绪后，可通过如下步骤查找慢SQL：

1. 重置计数器（可选操作）。

   ```
   select pg_stat_reset();
   ```

   ```
   select pg_stat_statements_reset();
   ```

2. 使用命令查看最耗时的SQL

   ```
   select * from pg_stat_statements order by total_time desc limit 5;
   ```

3. 查询读取Buffer次数最多的SQL，buffer次数多，可能是因为没有索引，也同时导致了cpu高。

   ```
   select * from pg_stat_statements order by shared_blks_hit+shared_blks_read desc limit 5;
   ```

 

**三. 通过pg_stat_activity，查找当前正在执行且已经执行了很久的SQL**

- 参考如下sql

  ```
  select datname,
  ```

  ```
         usename,
  ```

  ```
         client_addr,
  ```

  ```
         application_name,
  ```

  ```
         state,
  ```

  ```
         backend_start,
  ```

  ```
         xact_start,
  ```

  ```
         xact_stay,
  ```

  ```
         query_start,
  ```

  ```
         query_stay,
  ```

  ```
         replace(query, chr(10), ' ') as query
  ```

  ```
  from
  ```

  ```
    (select pgsa.datname as datname,
  ```

  ```
            pgsa.usename as usename,
  ```

  ```
            pgsa.client_addr client_addr,
  ```

  ```
            pgsa.application_name as application_name,
  ```

  ```
            pgsa.state as state,
  ```

  ```
            pgsa.backend_start as backend_start,
  ```

  ```
            pgsa.xact_start as xact_start,
  ```

  ```
            extract(epoch
  ```

  ```
                    from (now() - pgsa.xact_start)) as xact_stay,
  ```

  ```
            pgsa.query_start as query_start,
  ```

  ```
            extract(epoch
  ```

  ```
                    from (now() - pgsa.query_start)) as query_stay,
  ```

  ```
            pgsa.query as query
  ```

  ```
     from pg_stat_activity as pgsa
  ```

  ```
     where pgsa.state != 'idle'
  ```

  ```
       and pgsa.state != 'idle in transaction'
  ```

  ```
       and pgsa.state != 'idle in transaction (aborted)') idleconnections
  ```

  ```
  order by query_stay desc
  ```

  ```
  limit 5;
  ```

 

**四. 通过慢查询日志**

在权限有限的情况下，日志或许是唯一能追踪问题的方式。但要注意的是，cpu使用率的时候，原本不慢的sql也会变慢，从而产生慢查询日志，对查错会产生一定误导性。

 

**五. 找出全表扫描最多的表**

CPU使用率高，有可能是因为没有建索引，导致大量的全表扫描。所以找出这些没索引，而且查询次数多的表，也是一种解决问题的思路。

1. 参考如下SQL语句，查出使用表扫描最多的表。

   ```
   select * from pg_stat_user_tables where n_live_tup > 100000 and seq_scan > 0 order by seq_tup_read desc limit 10;
   ```

2. 参考如下SQL语句，查询当前正在运行的访问到上述表的慢查询。

   ```
   select * from pg_stat_activity where query ilike '%<table name>%' and query_start - now() > interval '10 seconds';
   ```

 

## 处理慢SQL

1. 对于已经排查出来的慢SQL，可以先杀掉他们，让业务先恢复

   ```
   select pg_cancel_backend(pid)
   ```

   ```
   select pg_terminate_backend(pid)
   ```

2. 使用explain查看sql执行过程，对其中显示慢的点进行优化。比如对其中的Table Scan涉及的表，建立索引。

   ```
   explain {sql}
   ```

   ```
   explain (buffers true, analyze true, verbose true) {sql}
   ```

3. 对sql进行优化，去掉子查询、调整join顺序、去掉like模糊查询等等

 
