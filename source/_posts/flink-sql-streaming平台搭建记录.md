---
title: flink-sql-streaming平台搭建记录
date: 2021-08-19 08:54:47
tags:
- flink
categories: 
- bigdata
---

第一步下载flink-sql-streaming代码：

```shell
git clone git@github.com:zhp8341/flink-streaming-platform-web.git
```
<!--more-->

第二步进行编译

```java
mvn clean install -T10C
```

第三步 进入部署包目录

![image-20210819113656910](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819113656910.png)

flink-streaming-platform-web.tar.gz即为可以安装的包

第三步 解压安装包进行安装

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819114023990.png" alt="image-20210819114023990" style="zoom:80%;" />

修改conf/application.properties

指定其中的数据库配置和用户名和密码

![image-20210819114121701](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819114121701.png)

见下图出现，则是启动成功：

![image-20210819114229338](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819114229338.png)

打开界面地址为：

http://10.11.5.11:9084/admin/listPage

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819115349257.png" alt="image-20210819115349257" style="zoom:80%;" />

输入用户名和密码 admin 123456

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819115436650.png" alt="image-20210819115436650" style="zoom:80%;" />

点击系统配置

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819115522521.png" alt="image-20210819115522521" style="zoom:80%;" />

根据界面上需要的配置填入参数。

新建任务开始

选择配置管理=》SQL流任务列表



<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819115705031.png" alt="image-20210819115705031" style="zoom:80%;" />

```
scp -r  mysql-connector-java-8.0.21.jar  root@cdh2:/opt/cloudera/parcels/FLINK/lib/flink/lib


```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819133240273.png" alt="image-20210819133240273" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819133306637.png" alt="image-20210819133306637" style="zoom:80%;" />

```sql
create table flink_test_1 ( 
  id BIGINT,
  day_time VARCHAR,
  amnount BIGINT,
  proctime AS PROCTIME ()
)
 with ( 
  'connector' = 'kafka',
  'topic' = 'flink_test',
  'properties.bootstrap.servers' = '10.11.5.11:9092,10.11.5.12:9092,10.11.5.13:9092', 
  'properties.group.id' = 'flink_gp_test1',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json',
  'json.fail-on-missing-field' = 'false',
  'json.ignore-parse-errors' = 'true',
  'properties.zookeeper.connect' = '10.11.5.10:2181/kafka'
 );

CREATE TABLE sync_test_1 (
                   day_time string,
                   total_gmv bigint,
                   PRIMARY KEY (day_time) NOT ENFORCED
 ) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:mysql://10.11.5.10:3306/flink_web?characterEncoding=UTF-8',
   'table-name' = 'sync_test_1',
   'driver' = 'com.mysql.cj.jdbc.Driver',
   'username' = 'root',
   'password' = 'root'
 );

INSERT INTO sync_test_1 
SELECT day_time,SUM(amnount) AS total_gmv
FROM flink_test_1
GROUP BY day_time;
```

点击开启配置，再点击提交任务，即可看到任务的状态。

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819125700736.png" alt="image-20210819125700736" style="zoom:80%;" />

点击日志详情：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819133632674.png" alt="image-20210819133632674" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819133657807.png" alt="image-20210819133657807" style="zoom:80%;" />

查看flink集群日志，即可看到yarn上运行的flink任务：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819133757431.png" alt="image-20210819133757431" style="zoom:80%;" />

当dbear链接mysql报Public Key Retrieval is not allowe

解决方法如下allowPublicKeyRetrieval为true即可

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819135150508.png" alt="image-20210819135150508" style="zoom:80%;" />

执行造数据：

```java
kafka-console-producer --broker-list cdh2:9092,cdh3:9092,cdh4:9092 --topic flink_test 
{"day_time": "20201009","id": 7,"amnount":20}

kafka-console-consumer --bootstrap-server cdh2:9092 --topic flink_test --from-beginning 
```

查看运行结果：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210819142637456.png" alt="image-20210819142637456" style="zoom:80%;" />
