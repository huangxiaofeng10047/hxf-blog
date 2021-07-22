---
title: iceberg-flink设置
date: 2021-04-29 13:00:10
tags:
---

1.下载flink

`wget https://mirrors.tuna.tsinghua.edu.cn/apache/flink/flink-1.11.3/flink-1.11.3-bin-scala_2.12.tgz`

2.修改start-cluster.sh
<!-- more -->
添加如下内容

`export HADOOP_CLASSPATH=$HADOOP_HOME/bin/hadoop classpath`

```
./bin/start-cluster.sh
```

wget https://repo.maven.apache.org/maven2/org/apache/iceberg/iceberg-flink-runtime/0.10.0/iceberg-flink-runtime-0.10.0.jar

wget https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-hive-2.3.6_2.11/1.11.0/flink-sql-connector-hive-2.3.6_2.11-1.11.0.jar

启动shell

```
./bin/sql-client.sh embedded \
    -j /Users/Terminus/software/flink-1.11.3/plugins/iceberg/iceberg-flink-runtime-0.10.0.jar \
    -j /Users/Terminus/software/flink-1.11.3/plugins/iceberg/flink-sql-connector-hive-2.3.6_2.11-1.11.0.jar \
    shell
```

创建hive catalog

`CREATE CATALOG hive_catalog WITH (`
  `'type'='iceberg',`
  `'catalog-type'='hive',`
  `'uri'='thrift://localhost:9083',`
  `'clients'='5',`
  `'property-version'='1',`
  `'warehouse'='hdfs://nn:8020/warehouse/path'`
`);`



Hdfs 启动

ssh免密

vim authorized_keys 

第一步格式hdfs

hadoop namenode -format

`start-dfs.sh` 

启动hive-metastore

VI hive-site.xml

```xml
<property>
          <name>hive.metastore.uris</name>
          <value>thrift://localhost:9083</value>
   </property>
```

Hive 数据库初始化：

hdfs dfs -mkdir -p /tmp/hive

 hdfs dfs -mkdir -p /hive/warehouse

 hdfs dfs -chmod -R g+w,o+w /tmp 

hdfs dfs -chmod -R g+w,o+w /hive 

```shell
schematool -dbType mysql -initSchema
```

```shell
hive --service metastore
```

flink-hive

要配置环境变量

```
export HIVE_CONF_DIR=${HIVE_HOME}/conf
```

CREATE CATALOG hive_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://localhost:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='hdfs://localhost:9000/hive/warehouse'
);

CREATE CATALOG my_catalog WITH (
  'type'='iceberg',
  'catalog-impl'='com.my.custom.CatalogImpl',
  'my-additional-catalog-config'='my-value'
);

Sql-client-default.yaml配置：

catalogs: # empty list
  - name: gmall
    type: hive
    hive-conf-dir: /opt/module/hive/conf/
    hive-version: 1.2.1
    default-database: gmallFlink SQL> CREATE TABLE gmall.gmall.sample (

    >     `id BIGINT COMMENT 'unique id',`
    >     `data STRING`
    >     `);`
    >     `[INFO] Table has been created.`

```
CREATE TABLE  gmall.gmall.sample_like LIKE gmall.gmall.sample;
```

```
ALTER TABLE gmall.gmall.sample SET ('write.format.default'='avro')
```

```
ALTER TABLE gmall.gmall.sample RENAME TO gmall.gmall.new_sample;
DROP TABLE gmall.gmall.sample;

```

CREATE CATALOG hive_catalog WITH (
  'type'='iceberg',
  'catalog-type'='hive',
  'uri'='thrift://localhost:9083',
  'clients'='5',
  'property-version'='1',
  'warehouse'='hdfs://localhost:8020/hive/warehouse'
);

CREATE TABLE sample (
    id BIGINT COMMENT 'unique id',
    data STRING
);

