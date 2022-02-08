---
title: k8s部署mysql-operator
date: 2021-11-10 15:12:19
tags:
- es
categories: 
- bigdata
---

k3d创建一个1主2从的集群

```console
k3d cluster create first-cluster --port 8080:80@loadbalancer --port 8443:443@loadbalancer --api-port 6443 --servers 1 --agents 2
k3d cluster create first-cluster --port 8080:80@loadbalancer --port 8443:443@loadbalancer --api-port 6443 --servers 1 --agents 2

#下面会解释的
#设置上下文
kubectl config use-context k3d-first-cluster
#获取集群信息
kubectl cluster-info

workspace/docker-compose/mysql took 15s
➜ helm repo add presslabs https://presslabs.github.io/charts

"presslabs" has been added to your repositories

workspace/docker-compose/mysql took 2s
➜ helm install presslabs/mysql-operator --name mysql-operator
➜ kubectl logs -f mysql-operator-1636510209-0
error: a container name must be specified for pod mysql-operator-1636510209-0, choose one of: [operator orchestrator]
这种报错代表pod里面有两个容器，需要指定一个才能访问，比如像下面这个样子
➜ kubectl logs -f mysql-operator-1636510209-0 -c operator

获取密码
mysql -h 127.0.0.1 -P 3306 -uroot -p$(kubectl get secret zabbix-db-secret -o jsonpath="{.data.ROOT_PASSWORD}" | base64 --decode)

```

kubectl 常用的命令总结
只显示默认命名空间的pods
kubectl get pods

显示所有空间的pod
kubectl get pods --all-namespaces

显示指定空间的pod
kubectl get pods -o wide --namespace apm

#以nodeport方式暴露服务

kubectl port-forward svc/my-cluster-mysql-master 33306:3306

#查询所有的服务

kubectl get svc

#以base64解码

➜ echo bm90LXNvLXNlY3VyZQ== | base64 --decode
not-so-secure%

参考文档：

https://github.com/bitpoke/mysql-operator/blob/master/docs/deploy-mysql-cluster.md



解释一下我们创建集群时配置的端口映射：

- `--port 8080:80@loadbalancer` 会将本地的 8080 端口映射到 loadbalancer 的 80 端口，然后 loadbalancer 接收到 80 端口的请求后，会代理到所有的 k8s 节点。
- `--api-port 6443` 默认提供的端口号，k3s 的 api-server 会监听 6443 端口，主要是用来操作 Kubernetes API 的，即使创建多个 Master 节点，也只需要暴露一个 6443 端口，loadbalancer 会将请求代理分发给多个 Master 节点。
- 如果我们期望通过 NodePort 的形式暴露服务，也可以自定义一些端口号映射到 loadbalancer 来暴露 k8s 的服务，比如：`-p 10080-20080:10080-20080@loadbalancer`

现在我们集群和主机的网络通信是这样子的：

![img](https://pic3.zhimg.com/80/v2-e0ad82d764b11437309b9b116bee1636_720w.jpg)

接下来部署mysql-operator:

第一步部署operator：

```
helm repo add presslabs https://presslabs.github.io/charts
helm install presslabs/mysql-operator --name mysql-operator
```

注意上面只是部署了一个controller，还不是正式的mysql

部署玩可以看到服务：

![image-20211110144214521](C:\Users\hxf\AppData\Roaming\Typora\typora-user-images\image-20211110144214521.png)

第二部部署mysql-cluster：

## Deploy a cluster

### Specify the cluster credentials

Before creating a cluster, you need a secret that contains the ROOT_PASSWORD key. An example for this secret can be found at [examples/example-cluster-secret.yaml](https://github.com/presslabs/mysql-operator/blob/master/examples/example-cluster-secret.yaml).

Create a file named `example-cluster-secret.yaml` and copy into it the following YAML code:

```
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  # root password is required to be specified
  ROOT_PASSWORD: bm90LXNvLXNlY3VyZQ==
  # a user name to be created, not required
  USER: dXNlcm5hbWU=
  # a password for user, not required
  PASSWORD: dXNlcnBhc3Nz
  # a name for database that will be created, not required
  DATABASE: dXNlcmRi
```

This secret contains information about the credentials used to connect to the cluster, like `ROOT_PASSWORD`, `USER`, `PASSWORD`, `DATABASE`. Note that once those fields are set, changing them will not reflect in the MySQL server because they are used only at cluster bootstrap.

> ###### NOTE
>
> All secret fields must be base64 encoded.

Moreover, the controller will add some extra fields into this secret with other internal credentials that are used, such as the orchestrator user, metrics exporter used, and so on.

### Create and deploy the cluster

Now, to create a cluster you need just a simple YAML file that defines it. Create a file named `example-cluster.yaml` and copy into it the following YAML code:

```
apiVersion: mysql.presslabs.org/v1alpha1
kind: MysqlCluster
metadata:
  name: my-cluster
spec:
  replicas: 2
  secretName: my-secret
```

A more comprehensive YAML example can be found at [examples/examples-cluster.yaml](https://github.com/presslabs/mysql-operator/blob/master/examples/example-cluster.yaml).

> ###### NOTE
>
> Make sure that the cluster name is not too long, otherwise the cluster will fail to register with the orchestrator. See issue [#170](https://github.com/presslabs/mysql-operator/issues/170) to learn more.

To deploy the cluster, run the commands below which will generate a secret with credentials and the `MySQLCluster` resources into Kubernetes.

```
$ kubectl apply -f example-cluster-secret.yaml
$ kubectl apply -f example-cluster.yaml
```

![image-20211110144854595](C:\Users\hxf\AppData\Roaming\Typora\typora-user-images\image-20211110144854595.png)

查看svc：

![image-20211110144929170](C:\Users\hxf\AppData\Roaming\Typora\typora-user-images\image-20211110144929170.png)

通过nodeport即可访问到mysql ，mysql的密码则是上面value中的值。

同时只能在mysql master上读写，而mysql-replicas上是直接可以读，但是不可以写。

![image-20211110145522769](C:\Users\hxf\AppData\Roaming\Typora\typora-user-images\image-20211110145522769.png)

nfs存储就是为了让数据库可以飘走。

## 1.PV和PVC的引入

Volume 提供了非常好的数据持久化方案，不过在可管理性上还有不足。

拿前面 AWS EBS 的例子来说，要使用 Volume，Pod 必须事先知道如下信息：

1. 当前 Volume 来自 AWS EBS。
2. EBS Volume 已经提前创建，并且知道确切的 volume-id。

Pod 通常是由应用的开发人员维护，而 Volume 则通常是由存储系统的管理员维护。开发人员要获得上面的信息：

1. 要么询问管理员。
2. 要么自己就是管理员。

这样就带来一个管理上的问题：应用开发人员和系统管理员的职责耦合在一起了。如果系统规模较小或者对于开发环境这样的情况还可以接受。但当集群规模变大，特别是对于生成环境，考虑到效率和安全性，这就成了必须要解决的问题。

Kubernetes 给出的解决方案是 PersistentVolume 和 PersistentVolumeClaim。

PersistentVolume (PV) 是外部存储系统中的一块存储空间，由管理员创建和维护。与 Volume 一样，PV 具有持久性，生命周期独立于 Pod。

PersistentVolumeClaim (PVC) 是对 PV 的申请 (Claim)。PVC 通常由普通用户创建和维护。需要为 Pod 分配存储资源时，用户可以创建一个 PVC，指明存储资源的容量大小和访问模式（比如只读）等信息，Kubernetes 会查找并提供满足条件的 PV。

有了 PersistentVolumeClaim，用户只需要告诉 Kubernetes 需要什么样的存储资源，而不必关心真正的空间从哪里分配，如何访问等底层细节信息。这些 Storage Provider 的底层信息交给管理员来处理，只有管理员才应该关心创建 PersistentVolume 的细节信息。

 

## 2.通过NFS实现持久化存储

### 2.1配置nfs

k8s-master nfs-server

k8s-node1 k8s-node2 nfs-client

所有节点安装nfs

```
yum install -y nfs-common nfs-utils 
```

在master节点创建共享目录

```
[root@k8s-master k8s]# mkdir /nfsdata
```

授权共享目录

```
[root@k8s-master k8s]# chmod 666 /nfsdata
```

编辑exports文件

```
[root@k8s-master k8s]# cat /etc/exports/nfsdata *(rw,no_root_squash,no_all_squash,sync)
```

**配置生效**

 [root@k8s-master k8s]# export -r

**启动rpc和nfs（注意顺序）**

```
[root@k8s-master k8s]# systemctl start rpcbind[root@k8s-master k8s]# systemctl start nfs
```

作为准备工作，我们已经在 k8s-master 节点上搭建了一个 NFS 服务器，目录为 `/nfsdata`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181111230151074-1035313903.png)

### 2.2创建PV

下面创建一个 PV `mypv1`，配置文件 `nfs-pv1.yml` 如下：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181111235530679-603261881.png)

① `capacity` 指定 PV 的容量为 1G。

② `accessModes` 指定访问模式为 `ReadWriteOnce`，支持的访问模式有：
ReadWriteOnce – PV 能以 read-write 模式 mount 到单个节点。
ReadOnlyMany – PV 能以 read-only 模式 mount 到多个节点。
ReadWriteMany – PV 能以 read-write 模式 mount 到多个节点。

③ `persistentVolumeReclaimPolicy` 指定当 PV 的回收策略为 `Recycle`，支持的策略有：
Retain – 需要管理员手工回收。
Recycle – 清除 PV 中的数据，效果相当于执行 `rm -rf /thevolume/*`。
Delete – 删除 Storage Provider 上的对应存储资源，例如 AWS EBS、GCE PD、Azure Disk、OpenStack Cinder Volume 等。

④ `storageClassName` 指定 PV 的 class 为 `nfs`。相当于为 PV 设置了一个分类，PVC 可以指定 class 申请相应 class 的 PV。

⑤ 指定 PV 在 NFS 服务器上对应的目录。

创建 `mypv1`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112000531942-414756760.png)

`STATUS` 为 `Available`，表示 `mypv1` 就绪，可以被 PVC 申请。

 

### 2.3创建PVC

接下来创建 PVC `mypvc1`，配置文件 `nfs-pvc1.yml` 如下：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112000627933-1042498180.png)

PVC 就很简单了，只需要指定 PV 的容量，访问模式和 class。

执行命令创建 `mypvc1`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112000756484-304192696.png)

从 `kubectl get pvc` 和 `kubectl get pv` 的输出可以看到 `mypvc1` 已经 Bound 到 `mypv1`，申请成功。

### 2.4创建pod

上面已经创建好了pv和pvc，pod中直接使用这个pvc即可

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112000941263-134961896.png)

与使用普通 Volume 的格式类似，在 `volumes` 中通过 `persistentVolumeClaim` 指定使用 `mypvc1` 申请的 Volume。

 通过命令创建`mypod1`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112001048694-922664654.png)

### 2.5验证

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181112003213905-627552664.png)

可见，在 Pod 中创建的文件 `/mydata/hello` 确实已经保存到了 NFS 服务器目录 `/nfsdata`中。

如果不再需要使用 PV，可用删除 PVC 回收 PV。

## 3.PV的回收

当 PV 不再需要时，可通过删除 PVC 回收。

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114140524904-1462205182.png)

未删除pvc之前 pv的状态是Bound

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114140620468-1513256026.png)

**![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114140643382-503979351.png)**

删除pvc之后pv的状态变为Available，，此时解除绑定后则可以被新的 PVC 申请。

/nfsdata文件中的文件被删除了

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114140816328-1594861053.png)

 

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114141038825-733094704.png)

因为 PV 的回收策略设置为 `Recycle`，所以数据会被清除，但这可能不是我们想要的结果。如果我们希望保留数据，可以将策略设置为 `Retain`。

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114140944474-244523375.png)

通过 `kubectl apply` 更新 PV：

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114141123152-1573323006.png)

回收策略已经变为 `Retain`，通过下面步骤验证其效果：

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114141846850-14718544.png)

① 重新创建 `mypvc1`。

② 在 `mypv1` 中创建文件 `hello`。

③ `mypv1` 状态变为 `Released`。

④ PV 中的数据被完整保留。

虽然 `mypv1` 中的数据得到了保留，但其 PV 状态会一直处于 `Released`，不能被其他 PVC 申请。为了重新使用存储资源，可以删除并重新创建 `mypv1`。删除操作只是删除了 PV 对象，存储空间中的数据并不会被删除。

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114142318452-1082688967.png)

新建的 `mypv1` 状态为 `Available`，已经可以被 PVC 申请。

PV 还支持 `Delete` 的回收策略，会删除 PV 在 Storage Provider 上对应存储空间。NFS 的 PV 不支持 `Delete`，支持 `Delete` 的 Provider 有 AWS EBS、GCE PD、Azure Disk、OpenStack Cinder Volume 等。

## 4.PV的动态供给

前面的例子中，我们提前创建了 PV，然后通过 PVC 申请 PV 并在 Pod 中使用，这种方式叫做静态供给（Static Provision）。

与之对应的是动态供给（Dynamical Provision），即如果没有满足 PVC 条件的 PV，会动态创建 PV。相比静态供给，动态供给有明显的优势：不需要提前创建 PV，减少了管理员的工作量，效率高。

动态供给是通过 StorageClass 实现的，StorageClass 定义了如何创建 PV，下面是两个例子。

StorageClass `standard`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114142759910-1404134003.png)

StorageClass `slow`：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114142818881-1657034993.png)

这两个 StorageClass 都会动态创建 AWS EBS，不同在于 `standard` 创建的是 `gp2` 类型的 EBS，而 `slow` 创建的是 `io1` 类型的 EBS。不同类型的 EBS 支持的参数可参考 AWS 官方文档。

StorageClass 支持 `Delete` 和 `Retain` 两种 `reclaimPolicy`，默认是 `Delete`。

与之前一样，PVC 在申请 PV 时，只需要指定 StorageClass 和容量以及访问模式，比如：

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114142851545-262925360.png)

除了 AWS EBS，Kubernetes 支持其他多种动态供给 PV 的 Provisioner，完整列表请参考 https://kubernetes.io/docs/concepts/storage/storage-classes/#provisioner

## 5.PV&&PVC在应用在mysql的持久化存储

下面演示如何为 MySQL 数据库提供持久化存储，步骤为：

1. 创建 PV 和 PVC。
2. 部署 MySQL。
3. 向 MySQL 添加数据。
4. 模拟节点宕机故障，Kubernetes 将 MySQL 自动迁移到其他节点。
5. 验证数据一致性。

 

首先创建 PV 和 PVC，配置如下：

mysql-pv.yml

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114164249311-815553434.png)

mysql-pvc.yml

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114164321137-1044555599.png)

创建 `mysql-pv` 和 `mysql-pvc`：

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114164423538-1248541390.png)

接下来部署 MySQL，配置文件如下：

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114164556988-1613625971.png)

 PVC `mysql-pvc` Bound 的 PV `mysql-pv` 将被 mount 到 MySQL 的数据目录 `var/lib/mysql`。

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114164706515-1715855365.png)

MySQL 被部署到 `k8s-node2`，下面通过客户端访问 Service `mysql`：

```
kubectl run -it --rm --image=mysql:5.6 --restart=Never mysql-client -- mysql -h mysql -ppassword
```

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114165320049-1580108497.png)

更新数据库：

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114165947863-142820308.png)

① 切换到数据库 mysql。

② 创建数据库表 my_id。

③ 插入一条数据。

④ 确认数据已经写入。

 关闭 `k8s-node2`，模拟节点宕机故障。

 ![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114170125072-435593197.png)

验证数据的一致性：

 由于node2节点已经宕机，node1节点接管了这个任务。

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114170806935-1324900057.png)

通过kubectl run 命令 进入node1的这个pod里，查看数据是否依旧存在

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114173251942-323542163.png)

![img](https://img2018.cnblogs.com/blog/1215197/201811/1215197-20181114173235264-1137808713.png)

 

MySQL 服务恢复，数据也完好无损。

## **6.小结**

本章我们讨论了 Kubernetes 如何管理存储资源。

emptyDir 和 hostPath 类型的 Volume 很方便，但可持久性不强，Kubernetes 支持多种外部存储系统的 Volume。

PV 和 PVC 分离了管理员和普通用户的职责，更适合生产环境。我们还学习了如何通过 StorageClass 实现更高效的动态供给。

最后，我们演示了如何在 MySQL 中使用 PersistentVolume 实现数据持久性。

 
