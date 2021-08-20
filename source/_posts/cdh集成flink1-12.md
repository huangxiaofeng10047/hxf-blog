---
title: cdh集成flink1.12.5
date: 2021-08-17 17:21:10
tags:
- flink
categories: 
- bigdata
---

参考：https://blog.csdn.net/sinat_37690778/article/details/112533647
<!--more-->
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
 mvn  clean install -DskipTests -Pvendor-repos -Dhadoop.version=3.0.0-cdh6.0.1 -Dscala-2.11 -Drat.skip=true -T10C

 解释一下命令：
 -T10C 以10个线程执行。
```

配置修改.m2/settings.xml文件(需要注销调mirror)不然编译会报错


```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <!-- localRepository
   | The path to the local repository maven will use to store artifacts.
   |
   | Default: ${user.home}/.m2/repository
  <localRepository>/path/to/local/repo</localRepository>
  -->
    <localRepository>D:\software\maven\repo</localRepository>
  <mirrors>
   <!--<mirror>
     <id>huaweicloud</id>
     <mirrorOf>*</mirrorOf>
     <url>https://mirrors.huaweicloud.com/repository/maven/</url>
  </mirror>-->
  </mirrors>
</settings>
```

编译存储占用极高：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818104409176.png" alt="image-20210818104409176" style="zoom:80%;" />

##  制作parcel安装包

1. 下载项目

```shell
git clone https://github.com/pkeropen/flink-parcel.git
```

1. cd flink-parcel
2. 修改配置文件
   vim flink-parcel.properties

```
#FLINK 下载地址
FLINK_URL=https://mirrors.tuna.tsinghua.edu.cn/apache/flink/flink-1.12.5/flink-1.12.5-bin-scala_2.11.tgz

#flink版本号
FLINK_VERSION=1.12.5

#扩展版本号
EXTENS_VERSION=BIN-SCALA_2.11

#操作系统版本，以centos为例
OS_VERSION=7

#CDH 小版本
CDH_MIN_FULL=5.16.1
CDH_MAX_FULL=6.3.2

#CDH大版本
CDH_MIN=5
CDH_MAX=6
```

生成的文件都在FLINK-1.12.5-BIN-SCALA_2.11_build目录下

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818123120140.png" alt="image-20210818123120140" style="zoom:80%;" />

- 生成csd文件，生成文件FLINK_ON_YARN-1.12.5.jar
  a) on yarn 版本：

  ```
  ./build.sh csd_on_yarn
  
  ```

  b) standalone版本：

  ```
  - ./build.sh csd_standalone
  - 
  ```

  

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818123414976.png" alt="image-20210818123414976" style="zoom:80%;" />

- 配置flink环境变量

```shell
export FLINK_HOME=/usr/local/flink-parcel/FLINK-1.12.5-BIN-SCALA_2.11/lib/flink
export PATH=$PATH:$FLINK_HOME/bin
```

3.5 CDH集成Flink
将生成的csd的jar包文件放入指定目录中

```
cp FLINK_ON_YARN-1.12.5.jar /opt/cloudera/csd/
chown cloudera-scm:cloudera-scm /opt/cloudera/csd/FLINK_ON_YARN-1.12.5.jar
systemctl restart cloudera-scm-server
```

将生成的parcel三个文件通过httpd服务配置下载路径
mkdir /var/www/html/flink-1.12.5
cp /usr/local/flink-parcel/FLINK-1.12.5-BIN-SCALA_2.11_build/* /var/www/html/flink-1.12.5

测试访问

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818124445073.png" alt="image-20210818124445073" style="zoom:80%;" />

登录cdh管理界面，点击集群->Parcel

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818124710536.png" alt="image-20210818124710536" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818124824881.png" alt="image-20210818124824881" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818130102552.png" alt="image-20210818130102552" style="zoom:80%;" />

针对上面的报错，为httpd服务的问题

![image-20210818130138545](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818130138545.png)

解决方法
所以排除是hash值导致的，后来查阅资料是发现是httpd服务的问题，在配置文件中需要加上parcel选项，需要修改httpd.conf配置文件，添加parcel。
httpd.conf目录在

在<IfModule mime_module>模块添加 parcel选项


```/etc/httpd/conf/httpd.conf
<IfModule mime_module>
    #
    # TypesConfig points to the file containing the list of mappings from
    # filename extension to MIME-type.
    #
    TypesConfig /etc/mime.types

    #
    # AddType allows you to add to or override the MIME configuration
    # file specified in TypesConfig for specific file types.
    #
    #AddType application/x-gzip .tgz
    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    #
    #AddEncoding x-compress .Z
    #AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz .parcel #此处添加.parcel

    #

#重启http服务
[root@localhost bigdata]#systemctl restart httpd
然后重新进行下载parcel，发现就可以进行下载了，问题解决，然后载根据教程进行parcel的安装就OK。希望对你有帮助。
```


```/etc/httpd/conf/httpd.conf

<IfModule mime_module>
    #
    # TypesConfig points to the file containing the list of mappings from
    # filename extension to MIME-type.
    #
    TypesConfig /etc/mime.types

    #
    # AddType allows you to add to or override the MIME configuration
    # file specified in TypesConfig for specific file types.
    #
    #AddType application/x-gzip .tgz
    #
    # AddEncoding allows you to have certain browsers uncompress
    # information on the fly. Note: Not all browsers support this.
    #
    #AddEncoding x-compress .Z
    #AddEncoding x-gzip .gz .tgz
    #
    # If the AddEncoding directives above are commented-out, then you
    # probably should define those extensions to indicate media types:
    #
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz .parcel #此处添加.parcel

    #

#重启http服务
[root@localhost bigdata]#systemctl restart httpd
然后重新进行下载parcel，发现就可以进行下载了，问题解决
```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210818130330585.png" alt="image-20210818130330585" style="zoom:80%;" />

启动flink会报错误：

rotateLogFilesWithPrefix command not found。

查看原因，网上说是因为没有flink-shaded-hadoop-2-uber-2.7.5-10.0.jar，经过测试不是这个原因。

1. ：flink-yarn.sh: line 17: rotateLogFilesWithPrefix: command not found，网友也遇到了此问题：https://download.csdn.net/download/orangelzc/15936248，最终的解决方案：

```python
[root@cdh632-master01 ~]# scp /opt/module/repository/org/apache/flink/flink-shaded-hadoop-2-uber/2.7.5-10.0/flink-shaded-hadoop-2-uber-2.7.5-10.0.jar root@cdh632-worker03:/opt/cloudera/parcels/FLINK/lib/flink/lib/
[root@cdh632-master01 ~]# scp /opt/module/repository/org/apache/flink/flink-shaded-hadoop-2-uber/2.7.5-10.0/flink-shaded-hadoop-2-uber-2.7.5-10.0.jar root@cdh632-worker02:/opt/cloudera/parcels/FLINK/lib/flink/lib/
[root@cdh632-master01 ~]# scp /opt/module/repository/org/apache/flink/flink-shaded-hadoop-2-uber/2.7.5-10.0/flink-shaded-hadoop-2-uber-2.7.5-10.0.jar root@cdh632-master01:/opt/cloudera/parcels/FLINK/lib/flink/lib/
```

 通过查看flink-1.12.5 是因为此命令已经被去掉了，所以直接修改flink-yarn.sh中这行代码即可。去掉17行代码即可。

flink 运行实例:

```
/opt/cloudera/parcels/FLINK/lib/flink/bin/flink run -m 10.11.5.11:8081  /opt/cloudera/parcels/FLINK/lib/flink/examples/batch/WordCount.jar –input hdfs://10.11.5.11/syt/input/ –output hdfs://10.11.5.11/syt/flinkoutput
```

参考文档：

https://blog.csdn.net/benpaodexiaowoniu/article/details/115500230

