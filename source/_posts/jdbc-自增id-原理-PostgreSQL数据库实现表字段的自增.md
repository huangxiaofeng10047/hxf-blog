---
title: jdbc 自增id 原理_PostgreSQL数据库实现表字段的自增
date: 2021-08-25 08:45:27
tags:
- postgres
categories: 
- database
---

在使用Mysql时，创建表结构时可以通过关键字auto\_increment来指定主键是否自增。但在Postgresql数据库中，虽然可以实现字段的自增，但从本质上来说却并不支持Mysql那样的自增。

![image-20210825085148884](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210825085148884.png)

<!--more-->

### **Postgresql的自增机制**

Postgresql中字段的自增是通过序列来实现的。整体机制是：1、序列可以实现自动增长；2、表字段可以指定默认值。3、结合两者，将默认值指定为自增序列便实现了对应字段值的自增。

Postgresql提供了三种serial数据类型：smallserial，serial，bigserial。它们与真正的类型有所区别，在创建表结构时会先创建一个序列，并将序列赋值给使用的字段。

也就是说，这三个类型是为了在创建唯一标识符列时方便使用而封装的类型。

bigserial创建一个bigint类型的自增，serial创建一个int类型的自增，smallserial创建一个smallint类的自增。

### **自增方式一示例**

使用示例如下：

```
create table biz_test(id serial PRIMARY KEY,name varchar);
```

此时生成的表结构为：

```
aa=# \d biz_test                              Table "public.biz_test" Column |       Type        |                       Modifiers--------+-------------------+------------------------------------------------------- id     | integer           | not null default nextval('biz_test_id_seq'::regclass) name   | character varying |Indexes:    "biz_test_pkey" PRIMARY KEY, btree (id)
```

我们可以看到ID字段默认值为nextval('biz\_test\_id\_seq'::regclass)。也就是说，在执行创建语句时首先创建了一个以“表名”+"\_id\_seq"的序列。然后再将该序列赋值给id字段。对应序列的类型为Integer类型。

此时，通过一条insert语句来验证一下是否实现了自增。

```
aa=# insert into biz_test(name) values('Tom')
```

执行查询语句查看插入的数据：

```
aa=# insert into biz_test(name) values('Tom');INSERT 0 1aa=# select * from biz_test; id | name ----+------  1 | Tom(1 row)
```

发送数据的确插入成功，并实现了id的自增。

### **自增方式二示例**

通过上面的示例可以衍生出另外一种实现方式。既然使用默认的三种类型可以完成自增的实现，那么将对应的底层实现进行拆分，是不是也可以实现自增的效果呢？

第一步：创建一个序列

```
aa=
```

第二步，创建表结构时将该序列设置为字段的默认值

```
aa=# create table biz_test(id integer primary key default nextval('biz_test_id_seq'))
```

这样，同样实现了字段的自增效果。

```
aa=# \d biz_test                         Table "public.biz_test" Column |  Type   |                       Modifiers--------+---------+------------------------------------------------------- id     | integer | not null default nextval('biz_test_id_seq'::regclass)Indexes:    "biz_test_pkey" PRIMARY KEY, btree (id)
```

针对第二步，如果建表的时并没有设置该字段为默认值，可以后续添加该字段为自增，使用alter语句来进行修改。

```
ALTER TABLE ONLY public.biz_test ALTER COLUMN id SET DEFAULT nextval('public.biz_test_id_seq'::regclass);
```

### **创建序列的语法**

上面创建序列时使用了默认值，如果需要指定序列的起始值、步长等参数，可以使用如下语句进行序列的创建。

```
CREATE SEQUENCE public.biz_test_id_seq    START WITH 1    INCREMENT BY 1    NO MINVALUE    NO MAXVALUE    CACHE 1;
```

上述语法其实已经很明显了，START WITH指定起始值，INCREMENT BY指定增长的步长。

Postgresql查找索引的方法与Mysql也不一样，对应的查询语句是：

```
select * from pg_indexes where tablename='biz_test'; schemaname | tablename |   indexname   | tablespace |                               indexdef
```

或者：

```
select * from pg_statio_all_indexes where relname='biz_test'; relid | indexrelid | schemaname | relname  | indexrelname  | idx_blks_read | idx_blks_hit-------+------------+------------+----------+---------------+---------------+-------------- 20753 |      20757 | public     | biz_test | biz_test_pkey |             0 |            0(1 row)
```

关于PostgreSQL数据库实现表字段的自增就讲这么多，在学习该项技术时给我最大的启发就是：实现同一功能的不同技术的横向对比，是拓展多维度解决思路的利器。

```
----------  END  ----------
