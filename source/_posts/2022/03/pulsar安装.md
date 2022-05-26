---
title: pulsar安装
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-10 09:45:05
tags:
---

https://packages.confluent.io/maven/io/confluent/kafka-connect-avro-converter/7.0.1/kafka-connect-avro-converter-7.0.1.jar

mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-connect-avro-converter -Dversion=7.0.1 -Dpackaging=jar -Dfile=kafka-connect-avro-converter-7.0.1.jar



mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry -Dversion=5.3.0 -Dpackaging=jar -Dfile=kafka-schema-registry-5.3.0.jar





mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=5.3.0 -Dpackaging=jar -Dfile=kafka-avro-serializer-5.3.0.jar

mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-connect-avro-converter -Dversion=5.3.0 -Dpackaging=jar -Dfile=kafka-connect-avro-converter-5.3.0.jar

kafka-connect-avro-converter

kafka-connect-avro-converter-shaded

mvn install:install-file -DgroupId=io.streamnative -DartifactId=kafka-connect-avro-converter-shaded -Dversion=2.9.1.1 -Dpackaging=jar -Dfile=kafka-connect-avro-converter-shaded-2.9.1.1.jar





```
<!-- https://mvnrepository.com/artifact/org.apache.pulsar/kafka-connect-avro-converter-shaded -->
<dependency>
    <groupId>org.apache.pulsar</groupId>
    <artifactId>kafka-connect-avro-converter-shaded</artifactId>
    <version>2.9.1</version>
</dependency>
mvn install:install-file -DgroupId=org.apache.pulsar -DartifactId=kafka-connect-avro-converter-shaded -Dversion=2.9.1 -Dpackaging=jar -Dfile=kafka-connect-avro-converter-shaded-2.9.1.jar


<!-- https://mvnrepository.com/artifact/io.confluent/kafka-schema-registry-client -->
<dependency>
    <groupId>io.confluent</groupId>
    <artifactId>kafka-schema-registry-client</artifactId>
    <version>5.3.0</version>
</dependency>
mvn install:install-file -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=5.3.0 -Dpackaging=jar -Dfile=kafka-schema-registry-client-5.jar



kubectl delete namespace NAMESPACENAME --force --grace-period=0
<!-- https://mvnrepository.com/artifact/io.confluent/common-config -->
<dependency>
    <groupId>io.confluent</groupId>
    <artifactId>common-config</artifactId>
    <version>5.3.0</version>
</dependency>

mvn install:install-file -DgroupId=io.confluent -DartifactId=common-config -Dversion=5.3.0 -Dpackaging=jar -Dfile=common-config-5.3.0.jar
```

编译命令，spotbugs会检查bugs

```
mvn clean install -DskipTests=true -Dspotbugs.skip=true -Dlicense.skip=true


```

 

切换branch

```
git checkout -b  v2.9_build branch-2.9
mvn clean install -DskipTests=true
```

