---
title: cdh集成es
date: 2021-08-23 11:35:57
tags:
- es
categories: 
- bigdata
---



<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823124604096.png" alt="image-20210823124604096" style="zoom:80%;" />

此前Elasticsearch我一直是单独搭建的，后来偶然发现可以在Cloudera Manager中添加ES服务,在搭建过程中这篇博客给了我很多帮助

[https://www.cnblogs.com/zhangrui153169/p/11447423.html](https://www.cnblogs.com/zhangrui153169/p/11447423.html)

但存在一些问题,在这里记录下来以作为这篇文章的补充,也希望能帮助大家减少踩坑。

目前对应的cdh环境是cdh6.2。所有运行命令都是在linux下进行的，推荐linux，不然会因为文件系统造成出错。

<!--more-->

## 一、制作Elasticsearch的Parcel包和csd文件

**1.配置java，maven等环境变量**

 **java:**

```
export JAVA_HOME=/usr/local/java
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tool.jar:$CLASSPATH
```

 **maven:**

```
export MVN_HOME=/home/plugin/apache-maven-3.3.9
export PATH=$MVN_HOME/bin:$PATH
```

**2.下载cm\_ext**

Cloudera提供的cm\_ext工具,对生成的csd和parcel进行校验

-   Cloudera提供的cm\_ext工具,对生成的csd和parcel进行校验

如果mvn package出现如下的报错，两种解决方法：

第一种方法(推荐)：

将mvn package改为执行：mvn clean package -Dmaven.test.skip=true

![](https://gitee.com/hxf88/imgrepo/raw/master/img/2020051311421835.png)

第二种方法：

在GitHub中下载完整的cm\_ext包：[https://github.com/guoliduo3/cm\_ext](https://github.com/guoliduo3/cm_ext) ，上传到 /github/cloudera 目录中，然后解压，将解压文件改名为cm\_ext，进入cm\_ext，再执行mvn package

-   **下载Elasticsearch安装包**

将elasticsearch包上传到 /github/cloudera/elasticsearch 目录下，我用的elasticsearch-7.14.0版本，贴上下载地址：

[https://www.elastic.co/cn/downloads/past-releases#elasticsearch](https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.14.0-linux-x86_64.tar.gz)

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823135707485.png" alt="image-20210823135707485" style="zoom:80%;" />

-   **下载制作Parcel包和CSD文件的脚本**

```shell
workspace/github/cloudera
➜ git clone git@github.com:kedong2014/elasticsearch-parcel-1.git
```

 注意：这里是 /github/cloudera 目录

下面是CDH6.X版本需要修改之处：

```
1.将elasticsearch-parcel文件夹下的 /parcel-src/meta/parcel.json文件 中 "depends": "CDH (>= 5.0), CDH (<< 6.0)" 修改为 "depends": "CDH (>= 5.0), CDH (<< 10.0)",
2.将elasticsearch-parcel文件夹下的 /csd-src/descriptor/service.sd1 文件中 "cdhVersion": {"min":5} 修改为："cdhVersion": {"min":6}
```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823135822708.png" alt="image-20210823135822708" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823135850675.png" alt="image-20210823135850675" style="zoom:80%;" />

-   **制作 Elasticsearch 的Parcel包和CSD文件并校验**

```shell
POINT_VERSION=5 VALIDATOR_DIR=/mnt/d/workspace/github/cloudera/cm_ext OS_VER=el7 PARCEL_NAME=ElasticSearch ./build-parcel.sh /mnt/d/workspace/github/cloudera/elasticsearch/elasticsearch-7.14.0-linux-x86_64.tar.gz
 VALIDATOR_DIR=/mnt/d/workspace/github/cloudera/cm_ext CSD_NAME=ElasticSearch ./build-csd.sh
```

 OS\_VER=el7 是指 linux 使用的Centos7.X版本

值得一提的是 路径一定要正确，pwd命令确认一下路径是有必要的

制作完成之后，elasticsearch-parcel 新增了build-parcel 和 build-csd文件夹，查看：

![image-20210823140425220](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823140425220.png)

![image-20210823140456243](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823140456243.png)

## 二、在Cloudrea Manager中安装部署Elasticsearch服务

**1.将Parcel包:ELASTICSEARCH-0.0.5.elasticsearch.p0.5-el7.parcel 和 manifest.json 文件部署到httpd服务中**



```

```

 2.**重启cloudera-scm-server服务**点击分配->激活

![image-20210823130157822](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823130157822.png)

重启cm-server即可安装服务

```
systemctl restart cloudera-scm-server

```

点击安装服务：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823130424284.png" alt="image-20210823130424284" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823130506203.png" alt="image-20210823130506203" style="zoom:80%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823130719379.png" alt="image-20210823130719379" style="zoom:80%;" />

在/etc/profile中设置

```
export ES_JAVA_HOME=/usr/lib/jvm/java-openjdk/jre
```

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823133903593.png" alt="image-20210823133903593" style="zoom:80%;" />

访问如下网址，看es是否正常

```
http://cdh2:9200/_nodes/process?pretty


```

![image-20210823134950762](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823134950762.png)

另外需要加入以下配置，cluster.initial_master_nodes: ["bigdata2","bigdata3","bigdata4"]注意此处，节点名称一定要和discovery中的节点一致

![image-20210823151045735](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823151045735.png)

否则es集群访问集群会出现：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823142420941.png" alt="image-20210823142420941" style="zoom:67%;" />

![image-20210823142329505](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823142329505.png)

启动依然出错：

```log
org.elasticsearch.bootstrap.StartupException: java.lang.IllegalStateException: failed to obtain node locks, tried [[/var/lib/elasticsearch]] with lock id [0]; maybe these locations are not writable or multiple nodes were started without increasing [node.max_local_storage_nodes] (was [1])?
	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:163) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:150) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.cli.EnvironmentAwareCommand.execute(EnvironmentAwareCommand.java:75) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:116) ~[elasticsearch-cli-7.14.0.jar:7.14.0]
	at org.elasticsearch.cli.Command.main(Command.java:79) ~[elasticsearch-cli-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:115) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:81) ~[elasticsearch-7.14.0.jar:7.14.0]
Caused by: java.lang.IllegalStateException: failed to obtain node locks, tried [[/var/lib/elasticsearch]] with lock id [0]; maybe these locations are not writable or multiple nodes were started without increasing [node.max_local_storage_nodes] (was [1])?
	at org.elasticsearch.env.NodeEnvironment.<init>(NodeEnvironment.java:292) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.node.Node.<init>(Node.java:376) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.node.Node.<init>(Node.java:281) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Bootstrap$5.<init>(Bootstrap.java:219) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:219) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:399) ~[elasticsearch-7.14.0.jar:7.14.0]
	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:159) ~[elasticsearch-7.14.0.jar:7.14.0]
	... 6 more
```

解决方式如下：

在elasticsearch.yml中增加

```
node.max_local_storage_nodes: 100


```

![image-20210823143802566](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823143802566.png)

![image-20210823150824337](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210823150824337.png)

当出现上图代表es才表示安装成功

出现问题：

# master not discovered yet, this node has not previously joined a bootstrapped (v7+) cluster

这个是表示因为配置的节点名称不一致，造成无法让其成为主节点。

解决方式：（elasticsearch.yml）

```yml
cluster.initial_master_nodes: ["BIGDATA2","BIGDATA3","BIGDATA4"]#要和下面的discovery保持一致
node.max_local_storage_nodes: 100
discovery.zen.ping.unicast.hosts: [BIGDATA2, BIGDATA3, BIGDATA4, localhost]#与cluster.initial_master_nodes保持一致
```

