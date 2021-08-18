---
title: cdh集成flink1.12
date: 2021-08-17 17:21:10
tags:
---

参考：https://blog.csdn.net/sinat_37690778/article/details/112533647

```
wget https://mirrors.tuna.tsinghua.edu.cn/apache/flink/flink-1.12.5/flink-1.12.5-src.tgz 
```

```
<profile>
    <id>vendor-repos</id>
    <activation>
        <property>
            <name>vendor-repos</name>
        </property>
    </activation>

    <!-- Add vendor maven repositories -->
    <repositories>
        <!-- Cloudera -->
        <repository>
            <id>cloudera-releases</id>
            <url>https://repository.cloudera.com/artifactory/cloudera-repos</url>
            <releases>
                <enabled>true</enabled>
            </releases>
            <snapshots>
                <enabled>false</enabled>
            </snapshots>
        </repository>
        <!-- Hortonworks -->
        <repository>
            <id>HDPReleases</id>
            <name>HDP Releases</name>
            <url>https://repo.hortonworks.com/content/repositories/releases/</url>
            <snapshots><enabled>false</enabled></snapshots>
            <releases><enabled>true</enabled></releases>
        </repository>
        <repository>
            <id>HortonworksJettyHadoop</id>
            <name>HDP Jetty</name>
            <url>https://repo.hortonworks.com/content/repositories/jetty-hadoop</url>
            <snapshots><enabled>false</enabled></snapshots>
            <releases><enabled>true</enabled></releases>
        </repository>
        <!-- MapR -->
        <repository>
            <id>mapr-releases</id>
            <url>https://repository.mapr.com/maven/</url>
            <snapshots><enabled>false</enabled></snapshots>
            <releases><enabled>true</enabled></releases>
        </repository>
    </repositories>

</profile>
```

```
 mvn  clean install -D skipTests -P vendor-repos -D hadoop.version=3.0.0-cdh6.0.1 -D scala-2.11 -D rat.skip=true -T 10C


```

