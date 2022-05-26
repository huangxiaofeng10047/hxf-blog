---
title: helm安装kafka
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-24 14:01:57
tags:
---

# helm部署zookeeper+kafka集群

系统环境
一个k8s集群，安装helm，实现动态PV供给（非必须），并且设置为默认storageclass
k8s集群信息

[root@master ~]# kubectl get node -A
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    <none>   52d   v1.17.11
node1    Ready    <none>   52d   v1.17.11
node2    Ready    <none>   52d   v1.17.11
node3    Ready    <none>   52d   v1.17.11

动态PV（后端为nfs存储）

[root@master ~]# kubectl get storageclass
NAME                    PROVISIONER   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-storage (default)   nfs-storage   Retain          Immediate           false                  31h

helm版本

[root@master ~]# helm version
version.BuildInfo{Version:"v3.4.1", GitCommit:"c4e74854886b2efe3321e185578e6db9be0a6e29", GitTreeState:"clean", GoVersion:"go1.14.11"}

下载zookeeper kafka的helm包
添加bitnami仓库

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ali-incubator https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/

列出添加的helm仓库

helm repo list
NAME         	URL                                                                      
bitnami      	https://charts.bitnami.com/bitnami                                       
ali-incubator	https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/

查询helm包

helm search repo zookeeper
NAME             		CHART VERSION		APP VERSION	DESCRIPTION                                       
bitnami/zookeeper	6.0.0        			3.6.2      			A centralized service for maintaining configura...
bitnami/kafka    	12.2.4       			2.6.0      			Apache Kafka is a distributed streaming platform.

下载helm包到本地，在线安装可不用下载

[root@master zk]# helm pull bitnami/zookeeper
[root@master zk]# helm pull bitnami/kafka
[root@master zk]# clear
[root@master zk]# ls
kafka-12.2.4.tgz  zookeeper-6.0.0.tgz

安装zookeeper kafka
安装方法参考bitnami官网：https://docs.bitnami.com/tutorials/deploy-scalable-kafka-zookeeper-cluster-kubernetes/
在线安装

安装zookeeper，可通过-n namaspace添加名称空间，因不暴露在公网，关闭了认证(--set auth.enabled=false)，并允许匿名访问，设置zookeeper副本为3
helm install zookeeper bitnami/zookeeper   --set replicaCount=3   --set auth.enabled=false   --set allowAnonymousLogin=true
安装kafka，取消自动创建zookeeper，使用刚刚创建的zookeeper，制定zookeeper的服务名称，
helm install kafka bitnami/kafka   --set zookeeper.enabled=false   --set replicaCount=3  --set externalZookeeper.servers=zookeeper
1
2
3
4
离线安装
解压下载好的tar包

[root@master zk]# tar -zxf zookeeper-6.0.0.tgz 
[root@master zk]# tar -zxf kafka-12.2.4.tgz
修改values.yaml，主要修改仓库地址以及存储storageclass（kafka的配置文件类似）
[root@master zookeeper]# vim values.yaml
image:
  registry: docker.io
  repository: bitnami/zookeeper
  tag: 3.6.2-debian-10-r58
persistence:
  ## A manually managed Persistent Volume and Claim
  ## If defined, PVC must be created manually before volume will be bound
  ## The value is evaluated as a template
  ##
  # existingClaim:
  enabled: true		#测试环境可设置为false
  # storageClass: "-"	#未配置默认动态PV，可打开注释，并写入storageClass的名称
创建名称空间
[root@master zk]# kubectl create ns zk
namespace/zk created
[root@master zk]# kubectl get ns
NAME                   STATUS   AGE
default                Active   52d
kube-public            Active   52d
kube-system            Active   52d
kubernetes-dashboard   Active   51d
zk                     Active   6s

安装zookeeper

[root@master zk]# helm install zookeeper -n zk --set replicaCount=3  --set auth.enabled=false --set allowAnonymousLogin=true /root/zk/zookeeper/
NAME: zookeeper
LAST DEPLOYED: Thu Jan 28 17:40:11 2021
NAMESPACE: zk
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

ZooKeeper can be accessed via port 2181 on the following DNS name from within your cluster:

    zookeeper.zk.svc.cluster.local

To connect to your ZooKeeper server run the following commands:

    export POD_NAME=$(kubectl get pods --namespace zk -l "app.kubernetes.io/name=zookeeper,app.kubernetes.io/instance=zookeeper,app.kubernetes.io/component=zookeeper" -o jsonpath="{.items[0].metadata.name}")
    kubectl exec -it $POD_NAME -- zkCli.sh

To connect to your ZooKeeper server from outside the cluster execute the following commands:

    kubectl port-forward --namespace zk svc/zookeeper 2181:2181 &
    zkCli.sh 127.0.0.1:2181
[root@master zk]# kubectl get pod -n zk 
NAME          READY   STATUS    RESTARTS   AGE
zookeeper-0   1/1     Running   0          24s
zookeeper-1   1/1     Running   0          23s
zookeeper-2   1/1     Running   0          23s

安装kafka

[root@master zk]# helm install kafka -n zk --set zookeeper.enabled=false --set replicaCount=3  --set externalZookeeper.servers=zookeeper /root/zk/kafka/
NAME: kafka
LAST DEPLOYED: Thu Jan 28 17:41:21 2021
NAMESPACE: zk
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Kafka can be accessed by consumers via port 9092 on the following DNS name from within your cluster:

    kafka.zk.svc.cluster.local

Each Kafka broker can be accessed by producers via port 9092 on the following DNS name(s) from within your cluster:

    kafka-0.kafka-headless.zk.svc.cluster.local:9092
    kafka-1.kafka-headless.zk.svc.cluster.local:9092
    kafka-2.kafka-headless.zk.svc.cluster.local:9092

To create a pod that you can use as a Kafka client run the following commands:

    kubectl run kafka-client --restart='Never' --image 10.41.11.100/lh/bitnami/kafka:2.6.0-debian-10-r78 --namespace zk --command -- sleep infinity
    kubectl exec --tty -i kafka-client --namespace zk -- bash
    
    PRODUCER:
        kafka-console-producer.sh \
            
            --broker-list kafka-0.kafka-headless.zk.svc.cluster.local:9092,kafka-1.kafka-headless.zk.svc.cluster.local:9092,kafka-2.kafka-headless.zk.svc.cluster.local:9092 \
            --topic test
    
    CONSUMER:
        kafka-console-consumer.sh \
            
            --bootstrap-server kafka.zk.svc.cluster.local:9092 \
            --topic test \
            --from-beginning
[root@master zk]# kubectl get pod -n zk 
NAME          READY   STATUS    RESTARTS   AGE
kafka-0       1/1     Running   0          21s
kafka-1       1/1     Running   0          21s
kafka-2       1/1     Running   0          21s
zookeeper-0   1/1     Running   0          92s
zookeeper-1   1/1     Running   0          91s
zookeeper-2   1/1     Running   0          91s


验证kafka与zookeeper；日志中有以下信息
kubectl logs -f -n zk kafka-0


测试集群
进入kafka的pod创建一个topic

[root@master zk]# kubectl exec -it -n zk kafka-0 bash
I have no name!@kafka-0:/$ kafka-topics.sh --create --zookeeper zookeeper:2181 --replication-factor 1 --partitions 1 --topic testtopic

启动一个消费者

I have no name!@kafka-0:/$ kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic testtopic


新开一个窗口，进入kafka的pod，启动一个生产者，输入消息；在消费者端可以收到消息

[root@master zk]# kubectl exec -it -n zk kafka-0 bash 
I have no name!@kafka-0:/$ kafka-console-producer.sh --bootstrap-server kafka:9092 --topic mytopic


卸载应用
[root@master zk]# helm uninstall kafka -n zk
release "kafka" uninstalled
[root@master zk]# helm uninstall zookeeper -n zk
release "zookeeper" uninstalled
[root@master zk]# kubectl delete pvc,pv -n zk --all

