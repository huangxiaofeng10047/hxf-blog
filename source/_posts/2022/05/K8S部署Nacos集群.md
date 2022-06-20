---
title: K8S部署Nacos集群
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-30 14:18:26
tags:
---

**1）Nacos集群部署的安装包准备**  
官方下载的nacos-server-1.2.1.zip包需要经过处理下：修改配置、加入docker-startup.sh启动脚本

```
[root@k8s-vm01 nacos-cluster]# pwd
/usr/local/src/nacos-cluster

[root@k8s-vm01 nacos-cluster]# ls
nacos-server-1.2.1.zip

[root@k8s-vm01 nacos-cluster]# unzip nacos-server-1.2.1.zip
nacos-server-1.2.1  nacos-server-1.2.1.zip

[root@k8s-vm01 conf]# pwd
/usr/local/src/nacos-cluster/nacos-server-1.2.1/nacos/conf

这里需要对application.properties进行修改：
[root@k8s-vm01 conf]# cat application.properties
# spring
server.servlet.contextPath=${SERVER_SERVLET_CONTEXTPATH:/nacos}
server.contextPath=/nacos
server.port=${NACOS_SERVER_PORT:8848}
spring.datasource.platform=${SPRING_DATASOURCE_PLATFORM:""}
nacos.cmdb.dumpTaskInterval=3600
nacos.cmdb.eventTaskInterval=10
nacos.cmdb.labelTaskInterval=300
nacos.cmdb.loadDataAtStart=false
db.num=${MYSQL_DATABASE_NUM:1}
db.url.0=jdbc:mysql://${MYSQL_SERVICE_HOST}:${MYSQL_SERVICE_PORT:3306}/${MYSQL_SERVICE_DB_NAME}?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true
db.user=${MYSQL_SERVICE_USER}
db.password=${MYSQL_SERVICE_PASSWORD}
### The auth system to use, currently only 'nacos' is supported:
nacos.core.auth.system.type=${NACOS_AUTH_SYSTEM_TYPE:nacos}


### The token expiration in seconds:
nacos.core.auth.default.token.expire.seconds=${NACOS_AUTH_TOKEN_EXPIRE_SECONDS:18000}

### The default token:
nacos.core.auth.default.token.secret.key=${NACOS_AUTH_TOKEN:SecretKey012345678901234567890123456789012345678901234567890123456789}

### Turn on/off caching of auth information. By turning on this switch, the update of auth information would have a 15 seconds delay.
nacos.core.auth.caching.enabled=${NACOS_AUTH_CACHE_ENABLE:false}

server.tomcat.accesslog.enabled=${TOMCAT_ACCESSLOG_ENABLED:false}
server.tomcat.accesslog.pattern=%h %l %u %t "%r" %s %b %D
# default current work dir
server.tomcat.basedir=
## spring security config
### turn off security
nacos.security.ignore.urls=/,/error,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/v1/auth/**,/v1/console/health/**,/actuator/**,/v1/console/server/**
# metrics for elastic search
management.metrics.export.elastic.enabled=false
management.metrics.export.influx.enabled=false

nacos.naming.distro.taskDispatchThreadCount=10
nacos.naming.distro.taskDispatchPeriod=200
nacos.naming.distro.batchSyncKeyCount=1000
nacos.naming.distro.initDataRatio=0.9
nacos.naming.distro.syncRetryDelay=5000
nacos.naming.data.warmup=true


还需要在bin目录下添加docker-startup.sh启动脚本
容器里nacos集群模式的启动脚本必须使用docker-startup.sh这个，不能使用startup.sh启动脚本
[root@k8s-vm01 bin]# cat docker-startup.sh
#!/bin/bash
# Copyright 1999-2018 Alibaba Group Holding Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -x
export DEFAULT_SEARCH_LOCATIONS="classpath:/,classpath:/config/,file:./,file:./config/"
export CUSTOM_SEARCH_LOCATIONS=${DEFAULT_SEARCH_LOCATIONS},file:${BASE_DIR}/conf/,${BASE_DIR}/init.d/
export CUSTOM_SEARCH_NAMES="application,custom"
PLUGINS_DIR="/home/nacos/plugins/peer-finder"
function print_servers(){
   if [[ ! -d "${PLUGINS_DIR}" ]]; then
    echo "" > "$CLUSTER_CONF"
    for server in ${NACOS_SERVERS}; do
            echo "$server" >> "$CLUSTER_CONF"
    done
   else
    bash $PLUGINS_DIR/plugin.sh
   sleep 30
        fi
}
#===========================================================================================
# JVM Configuration
#===========================================================================================
if [[ "${MODE}" == "standalone" ]]; then

    JAVA_OPT="${JAVA_OPT} -Xms512m -Xmx512m -Xmn256m"
    JAVA_OPT="${JAVA_OPT} -Dnacos.standalone=true"
else

  JAVA_OPT="${JAVA_OPT} -server -Xms${JVM_XMS} -Xmx${JVM_XMX} -Xmn${JVM_XMN} -XX:MetaspaceSize=${JVM_MS} -XX:MaxMetaspaceSize=${JVM_MMS}"
  if [[ "${NACOS_DEBUG}" == "y" ]]; then
    JAVA_OPT="${JAVA_OPT} -Xdebug -Xrunjdwp:transport=dt_socket,address=9555,server=y,suspend=n"
  fi
  JAVA_OPT="${JAVA_OPT} -XX:-OmitStackTraceInFastThrow -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${BASE_DIR}/logs/java_heapdump.hprof"
  JAVA_OPT="${JAVA_OPT} -XX:-UseLargePages"
  print_servers
fi

#===========================================================================================
# Setting system properties
#===========================================================================================
# set  mode that Nacos Server function of split
if [[ "${FUNCTION_MODE}" == "config" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.functionMode=config"
elif [[ "${FUNCTION_MODE}" == "naming" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.functionMode=naming"
fi
# set nacos server ip
if [[ ! -z "${NACOS_SERVER_IP}" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.server.ip=${NACOS_SERVER_IP}"
fi

if [[ ! -z "${USE_ONLY_SITE_INTERFACES}" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.use-only-site-local-interfaces=${USE_ONLY_SITE_INTERFACES}"
fi

if [[ ! -z "${PREFERRED_NETWORKS}" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.preferred-networks=${PREFERRED_NETWORKS}"
fi

if [[ ! -z "${IGNORED_INTERFACES}" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.inetutils.ignored-interfaces=${IGNORED_INTERFACES}"
fi

### If turn on auth system:
if [[ ! -z "${NACOS_AUTH_ENABLE}" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.core.auth.enabled=${NACOS_AUTH_ENABLE}"
fi

if [[ "${PREFER_HOST_MODE}" == "hostname" ]]; then
    JAVA_OPT="${JAVA_OPT} -Dnacos.preferHostnameOverIp=true"
fi

JAVA_MAJOR_VERSION=$($JAVA -version 2>&1 | sed -E -n 's/.* version "([0-9]*).*$/\1/p')
if [[ "$JAVA_MAJOR_VERSION" -ge "9" ]] ; then
  JAVA_OPT="${JAVA_OPT} -cp .:${BASE_DIR}/plugins/cmdb/*.jar:${BASE_DIR}/plugins/mysql/*.jar"
  JAVA_OPT="${JAVA_OPT} -Xlog:gc*:file=${BASE_DIR}/logs/nacos_gc.log:time,tags:filecount=10,filesize=102400"
else
  JAVA_OPT="${JAVA_OPT} -Djava.ext.dirs=${JAVA_HOME}/jre/lib/ext:${JAVA_HOME}/lib/ext:${BASE_DIR}/plugins/health:${BASE_DIR}/plugins/cmdb:${BASE_DIR}/plugins/mysql"
  JAVA_OPT="${JAVA_OPT} -Xloggc:${BASE_DIR}/logs/nacos_gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M"
fi



JAVA_OPT="${JAVA_OPT} -Dnacos.home=${BASE_DIR}"
JAVA_OPT="${JAVA_OPT} -jar ${BASE_DIR}/target/nacos-server.jar"
JAVA_OPT="${JAVA_OPT} ${JAVA_OPT_EXT}"
JAVA_OPT="${JAVA_OPT} --spring.config.location=${CUSTOM_SEARCH_LOCATIONS}"
JAVA_OPT="${JAVA_OPT} --spring.config.name=${CUSTOM_SEARCH_NAMES}"
JAVA_OPT="${JAVA_OPT} --logging.config=${BASE_DIR}/conf/nacos-logback.xml"
JAVA_OPT="${JAVA_OPT} --server.max-http-header-size=524288"

echo "nacos is starting,you can check the ${BASE_DIR}/logs/start.out"
echo "$JAVA ${JAVA_OPT}" > ${BASE_DIR}/logs/start.out 2>&1 &
nohup $JAVA ${JAVA_OPT} > ${BASE_DIR}/logs/start.out 2>&1 < /dev/null


修改后，再将nacos-server-1.2.1目录打包成nacos-server-1.2.1.tar.gz
[root@k8s-vm01 nacos-cluster]# tar -zvcf nacos-server-1.2.1.tar.gz nacos-server-1.2.1
[root@k8s-vm01 nacos-cluster]# ls
nacos-server-1.2.1  nacos-server-1.2.1.tar.gz  nacos-server-1.2.1.zip
```

**2）Nacos镜像制作**

制作镜像并上传Harbor

```
[root@k8s-vm01 nacos-cluster]# cat Dockerfile
FROM 192.168.1.75/wise-ops/jdk1.8.0_192:latest
RUN rm -f /etc/localtime \
&& ln -sv /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone

ENV LANG en_US.UTF-8

ENV MODE cluster
ENV PREFER_HOST_MODE ip
ENV BASE_DIR /home/nacos
ENV CLASSPATH .:/home/nacos/conf:
ENV CLUSTER_CONF /home/nacos/conf/cluster.conf
ENV FUNCTION_MODE all
ENV JAVA_HOME /usr/java/jdk1.8.0_192
ENV NACOS_USER nacos
ENV JAVA /usr/java/jdk1.8.0_192/bin/java
ENV JVM_XMS 2g
ENV JVM_XMX 2g
ENV JVM_XMN 1g
ENV JVM_MS 128m
ENV JVM_MMS 320m
ENV NACOS_DEBUG n
ENV TOMCAT_ACCESSLOG_ENABLED false

WORKDIR /home/nacos
ADD nacos-server-1.2.1.tar.gz /home
RUN set -x && mv /home/nacos-server-1.2.1/nacos/* /home/nacos/ && rm -rf /home/nacos-server-1.2.1

RUN mkdir -p logs && cd logs && touch start.out && ln -sf /dev/stdout start.out && ln -sf /dev/stderr start.out
RUN chmod 755 bin/docker-startup.sh

EXPOSE 8848
ENTRYPOINT ["bin/docker-startup.sh"]
```

**3）部署Nacos集群**

这里采用了configmap存储卷，将mysql配置信息存到了configmap中  

```
[root@k8s-vm01 nacos-cluster]# pwd
/opt/k8s/work/test_yml/nacos-cluster

[root@k8s-vm01 nacos-cluster]# cat nacos-cluster.yml
---
apiVersion: v1
kind: Service
metadata:
  namespace: wise
  name: nacos-cluster
  labels:
    app: nacos-cluster
spec:
  ports:
    - port: 8848
      name: server
      targetPort: 8848
  clusterIP: None
  selector:
    app: nacos-cluster
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: wise
  name: nacos-cluster-cm
data:
  mysql.host: "192.168.1.72"
  mysql.db.name: "nacos"
  mysql.port: "3306"
  mysql.user: "nacos"
  mysql.password: "nacos@123"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  namespace: wise
  name: nacos-cluster
spec:
  serviceName: nacos-cluster
  replicas: 3
  template:
    metadata:
      labels:
        app: nacos-cluster
      annotations:
        pod.alpha.kubernetes.io/initialized: "true"
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: "app"
                    operator: In
                    values:
                      - nacos-cluster
              topologyKey: "kubernetes.io/hostname"
      containers:
        - name: k8snacos
          imagePullPolicy: Always
          image: 192.168.1.75/wise-ops/nacos-cluster:v10
          resources:
            requests:
              memory: 2048Mi
              cpu: 1000m
            limits:
              memory: 2048Mi
              cpu: 1000m
          ports:
            - containerPort: 8848
              name: client
          env:
            - name: NACOS_REPLICAS
              value: "3"
            - name: MYSQL_SERVICE_HOST
              valueFrom:
                configMapKeyRef:
                  name: nacos-cluster-cm
                  key: mysql.host
            - name: MYSQL_SERVICE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: nacos-cluster-cm
                  key: mysql.db.name
            - name: MYSQL_SERVICE_PORT
              valueFrom:
                configMapKeyRef:
                  name: nacos-cluster-cm
                  key: mysql.port
            - name: MYSQL_SERVICE_USER
              valueFrom:
                configMapKeyRef:
                  name: nacos-cluster-cm
                  key: mysql.user
            - name: MYSQL_SERVICE_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: nacos-cluster-cm
                  key: mysql.password
            - name: NACOS_SERVER_PORT
              value: "8848"
            - name: PREFER_HOST_MODE
              value: "hostname"
            - name: NACOS_SERVERS
              value: "nacos-cluster-0.nacos-cluster.wise.svc.cluster.local:8848 nacos-cluster-1.nacos-cluster.wise.svc.cluster.local:8848 nacos-cluster-2.nacos-cluster.wise.svc.cluster.local:8848"
  selector:
    matchLabels:
      app: nacos-cluster
```

**注意：**需要提前在mysql数据库中创建一个nacos库名！然后将上面nacos-server-1.2.1.tar.gz包中的conf/nacos-mysql.sql文件里的sql语句在mysql的nacos库下执行（source nacos-mysql.sql ）导入语句。

创建并查看

```

[root@master1 ~]# kubectl get svc -n nacos
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                               AGE
mysql            ClusterIP   10.96.233.124   <none>        3306/TCP                              48d
nacos-headless   ClusterIP   None            <none>        8848/TCP,9848/TCP,9849/TCP,7848/TCP   48d
[root@master1 ~]# kubectl get statefulset -n nacos
NAME    READY   AGE
nacos   1/1     48d
[root@master1 ~]#

```

配置traefik，外部访问nacos

\*\*\*\*\*\*\*\*\*\*\*\*\*\*\* 当你发现自己的才华撑不起野心时，就请安静下来学习吧！\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*

对比官方文档

https://nacos.io/zh-cn/docs/use-nacos-with-kubernetes.html



本项目包含一个可构建的Nacos Docker Image，旨在利用StatefulSets在[Kubernetes](https://kubernetes.io/)上部署[Nacos](https://nacos.io/)

## 快速开始

-   **Clone 项目**

```
git clone https://github.com/nacos-group/nacos-k8s.git
```

-   **简单例子**

> 如果你使用简单方式快速启动,请注意这是没有使用持久化卷的,可能存在数据丢失风险:

```
cd nacos-k8s
chmod +x quick-startup.sh
./quick-startup.sh
```

-   **测试**
    
    -   **服务注册**
    
    ```
    curl -X POST 'http://cluster-ip:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'
    ```
    
    -   **服务发现**
    
    ```
    curl -X GET 'http://cluster-ip:8848/nacos/v1/ns/instance/list?serviceName=nacos.naming.serviceName'
    ```
    
    -   **发布配置**
    
    ```
    curl -X POST "http://cluster-ip:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"
    ```
    
    -   **获取配置**
    
    ```
    curl -X GET "http://cluster-ip:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test"
    ```
    

## 高级使用

> 在高级使用中,Nacos在K8S拥有自动扩容缩容和数据持久特性,请注意如果需要使用这部分功能请使用PVC持久卷,Nacos的自动扩容缩容需要依赖持久卷,以及数据持久化也是一样,本例中使用的是NFS来使用PVC.

## 部署 NFS

-   创建角色

```
kubectl create -f deploy/nfs/rbac.yaml
```

> 如果的K8S命名空间不是**default**，请在部署RBAC之前执行以下脚本:

```
# Set the subject of the RBAC objects to the current namespace where the provisioner is being deployed
$ NS=$(kubectl config get-contexts|grep -e "^\*" |awk '{print $5}')
$ NAMESPACE=${NS:-default}
$ sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/nfs/rbac.yaml

```

-   创建 `ServiceAccount` 和部署 `NFS-Client Provisioner`

```
kubectl create -f deploy/nfs/deployment.yaml
```

-   创建 NFS StorageClass

```
kubectl create -f deploy/nfs/class.yaml
```

-   验证NFS部署成功

```
kubectl get pod -l app=nfs-client-provisioner
```

## 部署数据库

-   部署主库

```

cd nacos-k8s

kubectl create -f deploy/mysql/mysql-master-nfs.yaml
```

-   部署从库

```

cd nacos-k8s 

kubectl create -f deploy/mysql/mysql-slave-nfs.yaml
```

-   验证数据库是否正常工作

```
# master
kubectl get pod 
NAME                         READY   STATUS    RESTARTS   AGE
mysql-master-gf2vd                        1/1     Running   0          111m

# slave
kubectl get pod 
mysql-slave-kf9cb                         1/1     Running   0          110m
```

## 部署Nacos

-   修改 **deploy/nacos/nacos-pvc-nfs.yaml**

```
data:
  mysql.master.db.name: "主库名称"
  mysql.master.port: "主库端口"
  mysql.slave.port: "从库端口"
  mysql.master.user: "主库用户名"
  mysql.master.password: "主库密码"
```

-   创建 Nacos

```
kubectl create -f nacos-k8s/deploy/nacos/nacos-pvc-nfs.yaml
```

-   验证Nacos节点启动成功

```
kubectl get pod -l app=nacos


NAME      READY   STATUS    RESTARTS   AGE
nacos-0   1/1     Running   0          19h
nacos-1   1/1     Running   0          19h
nacos-2   1/1     Running   0          19h
```

## 扩容测试

-   在扩容前，使用 [`kubectl exec`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#exec)获取在pod中的Nacos集群配置文件信息

```
for i in 0 1; do echo nacos-$i; kubectl exec nacos-$i cat conf/cluster.conf; done
```

StatefulSet控制器根据其序数索引为每个Pod提供唯一的主机名。 主机名采用 - 的形式。 因为nacos StatefulSet的副本字段设置为2，所以当前集群文件中只有两个Nacos节点地址



-   使用kubectl scale 对Nacos动态扩容

```
kubectl scale sts nacos --replicas=3
```

![scale](https://cdn.nlark.com/yuque/0/2019/gif/338441/1562846139093-7a79b709-9afa-448a-b7d6-f57571d3a902.gif)

-   在扩容后，使用 [`kubectl exec`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#exec)获取在pod中的Nacos集群配置文件信息

```
for i in 0 1 2; do echo nacos-$i; kubectl exec nacos-$i cat conf/cluster.conf; done
```



-   使用 [`kubectl exec`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#exec)执行Nacos API 在每台节点上获取当前**Leader**是否一致

```
for i in 0 1 2; do echo nacos-$i; kubectl exec nacos-$i curl -X GET "http://localhost:8848/nacos/v1/ns/raft/state"; done
```

到这里你可以发现新节点已经正常加入Nacos集群当中

## 例子部署环境

-   机器配置

| 内网IP      | 主机名     | 配置                                                         |
| ----------- | ---------- | ------------------------------------------------------------ |
| 172.17.79.3 | k8s-master | CentOS Linux release 7.4.1708 (Core) Single-core processor Mem 4G Cloud disk 40G |
| 172.17.79.4 | node01     | CentOS Linux release 7.4.1708 (Core) Single-core processor Mem 4G Cloud disk 40G |
| 172.17.79.5 | node02     | CentOS Linux release 7.4.1708 (Core) Single-core processor Mem 4G Cloud disk 40G |

-   Kubernetes 版本：**1.12.2** （如果你和我一样只使用了三台机器，那么记得开启master节点的部署功能）
-   NFS 版本：**4.1** 在k8s-master进行安装Server端，并且指定共享目录，本项目指定的\*\*/data/nfs-share\*\*
-   Git

## 限制

-   必须要使用持久卷，否则会出现数据丢失的情况

## 项目目录

| 目录     | 描述                                          |
| -------- | --------------------------------------------- |
| `plugin` | 帮助Nacos集群进行动态扩容的插件Docker镜像源码 |
| `deploy` | K8s 部署文件                                  |

## 配置属性

-   nacos-pvc-nfs.yaml or nacos-quick-start.yaml

| 名称                    | 必要 | 描述                                                         |
| ----------------------- | ---- | ------------------------------------------------------------ |
| `mysql.master.db.name`  | Y    | 主库名称                                                     |
| `mysql.master.port`     | N    | 主库端口                                                     |
| `mysql.slave.port`      | N    | 从库端口                                                     |
| `mysql.master.user`     | Y    | 主库用户名                                                   |
| `mysql.master.password` | Y    | 主库密码                                                     |
| `NACOS_REPLICAS`        | N    | 确定执行Nacos启动节点数量,如果不适用动态扩容插件,就必须配置这个属性，否则使用扩容插件后不会生效 |
| `NACOS_SERVER_PORT`     | N    | Nacos 端口                                                   |
| `PREFER_HOST_MODE`      | Y    | 启动Nacos集群按域名解析                                      |

-   **nfs** deployment.yaml

| 名称         | 必要 | 描述           |
| ------------ | ---- | -------------- |
| `NFS_SERVER` | Y    | NFS 服务端地址 |
| `NFS_PATH`   | Y    | NFS 共享目录   |
| `server`     | Y    | NFS 服务端地址 |
| `path`       | Y    | NFS 共享目录   |

-   mysql

| 名称                         | 必要 | 描述                                       |
| ---------------------------- | ---- | ------------------------------------------ |
| `MYSQL_ROOT_PASSWORD`        | N    | ROOT 密码                                  |
| `MYSQL_DATABASE`             | Y    | 数据库名称                                 |
| `MYSQL_USER`                 | Y    | 数据库用户名                               |
| `MYSQL_PASSWORD`             | Y    | 数据库密码                                 |
| `MYSQL_REPLICATION_USER`     | Y    | 数据库复制用户                             |
| `MYSQL_REPLICATION_PASSWORD` | Y    | 数据库复制用户密码                         |
| `Nfs:server`                 | N    | NFS 服务端地址，如果使用本地部署不需要配置 |
| `Nfs:path`                   | N    | NFS 共享目录，如果使用本地部署不需要配置   |
