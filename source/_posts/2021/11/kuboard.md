---
title: kuboard
date: 2021-11-10 15:45:35
tags:
- es
categories: 
- bigdata
---

前提使用版本：

kuboardv3 多集群版本

安装命令为：

```
kubectl apply -f https://addons.kuboard.cn/kuboard/kuboard-v3.yaml
```

等待 Kuboard v3 就绪

执行指令 `watch kubectl get pods -n kuboard`，等待 kuboard 名称空间中所有的 Pod 就绪，如下所示，

如果结果中没有出现 `kuboard-etcd-xxxxx` 的容器，请查看 常见错误 中关于 `缺少 Master Role` 的描述。

访问界面方法：

```
 kubectl port-forward service/kuboard-v3 8081:80 -n kuboard
```

访问地址为：

[访问kuboard ]: http://localhost:8081/kubernetes/default/namespace/default/workload/view/StatefulSet/my-cluster-mysql

![image-20211110154856130](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211110154856130.png)

支持插件化安装：

可以在线安装组件或者离线安装组件

![image-20211110161653497](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211110161653497.png)

![image-20211110162114937](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211110162114937.png)

服务器搭建nfsserver

```
docker run -d --privileged  \
-v /home/hxf/nfs01:/nfs \
-e NFS_EXPORT_DIR_1=/nfs \
-e NFS_EXPORT_DOMAIN_1=\* \
-e NFS_EXPORT_OPTIONS_1=rw,insecure,no_subtree_check,no_root_squash,fsid=1 \
-p 111:111 -p 111:111/udp \
-p 2049:2049 -p 2049:2049/udp \
-p 32765:32765 -p 32765:32765/udp \
-p 32766:32766 -p 32766:32766/udp \
-p 32767:32767 -p 32767:32767/udp \
fuzzle/docker-nfs-server:latest
```

————————————————
版权声明：本文为CSDN博主「成伟平cwp」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/pingweicheng/article/details/108569848

注意mount参数

![

](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211111162508976.png)

![image-20211110165210249](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211110165210249.png)

![image-20211110165250670](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211110165250670.png)

参数： rw,nfsvers=3,nolock,proto=udp,port=2049



![image-20211112114941802](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211112114941802.png)

```sh
sudo docker run -d \
  --restart=unless-stopped \
  --name=kuboard \
  -p 80:80/tcp \
  -p 10081:10081/tcp \
  -e KUBOARD_ENDPOINT="http://192.168.50.16:80" \
  -e KUBOARD_AGENT_SERVER_TCP_PORT="10081" \
  -v /root/kuboard-data:/data \
  eipwork/kuboard:latest
```

部署nginx

```
---

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations: {}
  labels:
    k8s.kuboard.cn/layer: web
    k8s.kuboard.cn/name: nginx
  name: nginx
  namespace: default
  resourceVersion: '6395'
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s.kuboard.cn/layer: web
      k8s.kuboard.cn/name: nginx
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s.kuboard.cn/layer: web
        k8s.kuboard.cn/name: nginx
    spec:
      containers:

   - image: 'nginx:alpine'
     imagePullPolicy: Always
     name: nginx
     ports:
       - containerPort: 80
         protocol: TCP
         resources: {}
         terminationMessagePath: /dev/termination-log
         terminationMessagePolicy: File
           dnsPolicy: ClusterFirst
           restartPolicy: Always
           schedulerName: default-scheduler
           securityContext: {}
           terminationGracePeriodSeconds: 30
```

获取所有namespace下配置：

```
kubectl get pods --all-namespaces
```

![image-20211118113949313](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211118113949313.png)

