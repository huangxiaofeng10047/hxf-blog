---

title: 一次成功的FlinkSQL功能测试及实战演练
date: 2021-08-20 15:06:09
tags:
---

#### 1 前期准备

###### 1.1 环境配置

本次研究测试需要用到以下组件：

```
CDH 6.2.0
Flink 1.12.5
mysql 8.0
impala 3.2.0-cdh6.2.0
kafka 2.2.1-cdh6.2.0
```
<!--more-->
###### 1.2 依赖关系

本次测试会将FlinkSql与kafka、mysql、impala等组件进行conn，因此需要以下依赖包：

```
flink-connector-kafka_2.11-1.12.2.jar
flink-connector-jdbc_2.11-1.11.2.jar
mysql-connector-java-5.1.47.jar
ImpalaJDBC4.jar
ImpalaJDBC41.jar
flink-sql-connector-kafka_2.11-1.12.2.jar
```

#### 2 FlinkSql-kafka测试

FlinkSql-kafka相关资料：

```
https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/dev/table/connectors/kafka.html
```

###### 2.1 FlinkSql-kafka常规功能测试

通过FlinkSql将Kafka中的数据映射成一张表

**2.1.1 创建常规topic**

1、创建topic kafka-topics --create --zookeeper 192.168.5.185:2181,192.168.5.165:2181,192.168.5.187:2181 --replication-factor 3 --partitions 3 --topic test01

2、模拟消费者 kafka-console-consumer --bootstrap-server 192.168.5.185:9092,192.168.5.165:9092,192.168.5.187:9092 --topic test01 --from-beginning

3、模拟生产者 kafka-console-producer --broker-list 192.168.5.185:9092,192.168.5.165:9092,192.168.5.187:9092 --topic test01

4、删除topic kafka-topics --delete --topic test01 --zookeeper 192.168.5.185:2181,192.168.5.165:2181,192.168.5.187:2181

**2.1.2 FlinkSql建表**

```
 CREATE TABLE t1 (
    name string,
    age BIGINT,
    isStu INT,
    opt STRING,
    optDate TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
    'connector' = 'kafka',  -- 使用 kafka connector
    'topic' = 'test01',  -- kafka topic
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'cdh2:9092,cdh2:9092,cdh4:9092',  -- kafka broker 地址
    'format' = 'csv'  -- 数据源格式为 csv，
);
 CREATE TABLE print_table (
   name string,
    age BIGINT,
    isStu INT,
    opt STRING,
     optDate TIMESTAMP(3)
 ) WITH (
  'connector' = 'print'
 );
  
insert into print_table  select * from t1;
```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820153033529.png" alt="image-20210820153033529" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820153116109.png" alt="image-20210820153116109" style="zoom:80%;" />

sql_t1为提交的任务

点击任务id即可跳转到flink控制页面

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820153215899.png" alt="image-20210820153215899" style="zoom:67%;" />

**2.1.3 写入数据**

```
kafka-console-producer --broker-list cdh2:9092,cdh3:9092,cdh3:9092 --topic test01
```

往kafka中写入数据，同时查看flinksql中t1表的变化

```
lisi,18,1,2
wangwu,30,2,2
```

观察表的变化（在taskmanger中）这是printconnector是在taskmanger上打印的。

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820154914018.png" alt="image-20210820154914018" style="zoom:67%;" />

**2.1.4 小结**

通过kafka数据映射成表这个步骤，可以将数据实时的汇入表中，通过sql再进行后续操作，相对代码编写来说更为简易，同时有问题也相对好排查

###### 2.2 FlinkSql-upsertKafka常规功能测试

upsert-kafka 连接器生产 changelog 流，其中每条数据记录代表一个更新或删除事件。

如果有key则update，没有key则insert，如果value的值为空，则表示删除

**2.2.1 FlinkSql建upsert表**

```
--drop table t1;
CREATE TABLE t1 (
    name string,
    age BIGINT,
    isStu INT,
    opt STRING,
    optDate TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
    'connector' = 'kafka',  -- 使用 kafka connector
    'topic' = 'test02',  -- kafka topic
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'cdh2:9092,cdh2:9092,cdh4:9092',  -- kafka broker 地址
    'format' = 'csv'  -- 数据源格式为 csv，
);
--drop table t2;
CREATE TABLE t2 (
  name STRING,
  age bigint,
  isStu INT,
  opt STRING,
  optDate TIMESTAMP(3) ,
  PRIMARY KEY (name) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'test03',
  'properties.bootstrap.servers' = 'cdh2:9092,cdh3:9092,cdh4:9092',  -- kafka broker 地址
  'key.format' = 'csv',
  'value.format' = 'csv'
);
INSERT INTO t2 SELECT * FROM t1 ;
 CREATE TABLE print_table (
   name string,
    age BIGINT,
    isStu INT,
    opt STRING,
     optDate TIMESTAMP(3)
 ) WITH (
  'connector' = 'print'
 );
insert into print_table select * from t2;
```

**2.2.2 建立映射关系**

将t1表中的数据写入到t2中

```
INSERT INTO t2 SELECT * FROM t1 ;
select * from t2;
```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820155552933.png" alt="image-20210820155552933" style="zoom:67%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820155618080.png" alt="image-20210820155618080" style="zoom:67%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820155905015.png" alt="image-20210820155905015" style="zoom:67%;" />



结果如下：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820160025776.png" alt="image-20210820160025776" style="zoom:67%;" />

**2.2.3 更新数据**

继续模拟kafka生产者，写入如下数据

```
zhangsan,25,1,2
risen,8,8,8
lisi,0,0,
```

结果如下：

![image-20210820160252365](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820160252365.png)

**2.2.4小结**

通过如上测试，两条更新，一条插入，都已经实现了，

根据官方文档描述，指定key的情况下，当value为空则判断为删除操作

但是假如我插入一条数据到kafka，例如：

```
lisi,,,
```

![image-20210820160406848](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820160406848.png)

因为建表的时候有几个类型定义为了Int类型，这里为空它默认为是""空字符串，有点呆，推测如果是json格式这类可以指定数据类型的，才能直接使用。对于csv这种数据类型不确定的，会存在无法推断类型的情况。

鉴于此，为了探究是否真的具备删除操作，我又将上述所有表结构都进行了修改。为了试验简单，我直接修改表结构再次测试。

```sql
CREATE TABLE t1 (
    name STRING,
    age STRING,
    isStu STRING,
    opt STRING,
    optDate TIMESTAMP(3) METADATA FROM 'timestamp'
) WITH (
    'connector' = 'kafka',  -- 使用 kafka connector
    'topic' = 'test02',  -- kafka topic
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'cdh2:9092,cdh3:9092,cdh4:9092',  -- kafka broker 地址
    'format' = 'csv'  -- 数据源格式为 csv，
);
CREATE TABLE t2 (
  name STRING,
  age STRING,
  isStu STRING,
  opt STRING,
  optDate TIMESTAMP(3) ,
  PRIMARY KEY (name) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'test03',
  'properties.bootstrap.servers' = 'cdh2:9092,cdh3:9092,cdh4:9092',  -- kafka broker 地址
  'key.format' = 'csv',
  'value.format' = 'csv'
);
INSERT INTO t2 SELECT * FROM t1 ;
INSERT INTO t2 SELECT * FROM t1 ;
 CREATE TABLE print_table (
   name string,
    age STRING,
    isStu STRING,
    opt STRING,
     optDate TIMESTAMP(3),
       PRIMARY KEY (name) NOT ENFORCED

 ) WITH (
  'connector' = 'print'
 );
insert into print_table select * from t2;
```

![image-20210820161149697](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820161149697.png)

依然没有在t2表中删除掉该条记录，该功能需要进一步探索，以后在跟进。

#### 2.3 FlinkSql-upsertKafka关于kafka中数据过期测试

**2.3.1 创建10分钟策略的topic**

```
kafka-topics  --create --zookeeper cdh2:2181,cdh3:2181,cdh4:2181 --replication-factor 3 --partitions 3 --topic test01   --config log.retention.minutes=10
kafka-console-producer  --broker-list cdh2:9092,cdh3:9092,cdh4:9092 --topic test01
kafka-topics --delete --topic test01 --zookeeper cdh2:2181,cdh3:2181,cdh4:2181
kafka-console-consumer  --bootstrap-server cdh2:9092,cdh3:9092,cdh4:9092 --topic output --from-beginning
kafka-topics  --zookeeper cdh2:2181,cdh3:2181,cdh4:2181 --topic test01 --describe
```

**2.3.2 创建flinksql的表**

```
CREATE TABLE t1 (
    name string,
    age BIGINT,
    isStu INT,
    opt STRING,
    optDate TIMESTAMP(3) METADATA FROM 'timestamp',
    WATERMARK FOR optDate as optDate - INTERVAL '5' SECOND  -- 在ts上定义watermark，ts成为事件时间列
) WITH (
    'connector' = 'kafka',  -- 使用 kafka connector
    'topic' = 'test01',  -- kafka topic
    'scan.startup.mode' = 'earliest-offset',
    'properties.bootstrap.servers' = 'cdh2:9092,cdh3:9092,cdh4:9092',  -- kafka broker 地址
    'format' = 'csv'  -- 数据源格式为 csv，
);
CREATE TABLE t2 (
  name STRING,
  age bigint,
  PRIMARY KEY (name) NOT ENFORCED
) WITH (
  'connector' = 'upsert-kafka',
  'topic' = 'output',
  'properties.bootstrap.servers' = 'cdh2:9092,cdh3:9092,cdh4:9092',  -- kafka broker 地址
  'key.format' = 'csv',
  'value.format' = 'csv'
);
INSERT INTO t2
SELECT
name,
max(age)
FROM t1
GROUP BY name;
 CREATE TABLE print_table (
  name STRING,
  age bigint,
  PRIMARY KEY (name) NOT ENFORCED
 ) WITH (
  'connector' = 'print'
 );
insert into print_table select * from t2;
 CREATE TABLE print_table1 (
  name string,
    age BIGINT,
    isStu INT,
    opt STRING,
    optDate TIMESTAMP(3) 
 ) WITH (
  'connector' = 'print'
 );
insert into print_table1 select * from t1;

```

**2.3.3 写入数据**

```
zhangsan,18,1,insert
lisi,20,2,update
wangwu,30,1,delete
```

**2.3.4 等待策略过期**

![image-20210820165954108](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210820165954108.png)

但是t2是基于t1的汇总表，在t1被清空的情况下，t2依旧存在

#### 3 FlinkSql-JDBC

FlinkSql-JDBC相关资料：

```
https://ci.apache.org/projects/flink/flink-docs-release-1.12/dev/table/connectors/jdbc.html
```

###### 3.1 FlinkSql-JDBC-Mysql常规功能测试

**3.1.1 mysql建表并写入数据**

```sql
create table test.test01(name varchar(10),age int, primary key (name));
INSERT INTO test.test01(name, age)VALUES('zhangsan', 20);
INSERT INTO test.test01(name, age)VALUES('lisi', 30);
INSERT INTO test.test01(name, age)VALUES('wangwu', 18);
```

**3.1.2 flinkSql建表**

```sql
drop table mysqlTest ;
create table mysqlTest (
name string,
age int,
PRIMARY KEY (name) NOT ENFORCED
) with (
 'connector' = 'jdbc',
 'url' = 'jdbc:mysql://cdh1:3306/test',
 'username' = 'root',
 'password' = 'root',
 'table-name' = 'test01'

);
 CREATE TABLE print_table1 (
name string,
age int,
PRIMARY KEY (name)  NOT ENFORCED
 ) WITH (
  'connector' = 'print'
 );
insert into print_table1 select * from mysqlTest;
```
