---
title: flink手动编译
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-09 16:53:07
tags:	
---





缺少kafka

```
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=6.2.2 -Dpackaging=jar  -Dfile=/mnt/d/Users/Administrator/Downloads/kafka-schema-registry-client-6.2.2.jar

mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=6.2.2 -Dpackaging=jar  -Dfile=D:\Users\Administrator\Downloads\kafka-avro-serializer-6.2.2.jar
编译flink

mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=6.2.2 -Dpackaging=jar  -Dfile=D:\Users\Administrator\Downloads\kafka-schema-registry-client-6.2.2.jar
kafka-avro-serializer
```

```
mvn clean install -T 2C -Dfast -Dmaven.compile.fork=true -DskipTests -Dscala-2.11 -X -Drat.skip=true -Dmaven.javadoc.skip=true -Dcheckstyle.skip=true -Dmaven.skip.test=true


 mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=6.2.2 -Dpackaging=jar  -Dfile=/mnt/d/Users/Administrator/Downloads/kafka-avro-serializer-6.2.2.jar
```

配置web

```

install -registry=https://registry.npm.taobao.org 


mclean package -T 4 -Dfast -Dmaven.compile.fork=true -DskipTests -Dscala-2.11
```

