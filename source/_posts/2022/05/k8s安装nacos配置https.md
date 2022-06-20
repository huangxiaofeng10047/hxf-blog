---
title: k8s安装nacos配置https
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-30 14:35:50
tags:
---

## 前言

最近在学习如何使用k8s搭建nacos服务以及如何使用，记录下来分享给大家。

## 准备工作

-   K8S：我使用的是阿里云ACK(阿里的k8s服务)，
-   Nacos：因为我使用的是阿里云RDS的mysql，所以 用的是[nacos-group/nacos-k8s](https://link.segmentfault.com/?enc=dmqSugrodmKaI9lOOdVaRQ%3D%3D.rNO9I2SRgmBDpILb3U5dKUuOUYehKOu2eSrzzZREo%2FDtJZ4X4PPd%2BdfeOs%2BvblWz)的nacos-no-pvc-ingress.yaml文件  
    ![image.png](https://segmentfault.com/a/image.png "image.png")

## 开始搭建

首先我们来查看nacos-no-pvc-ingress.yaml文件

```
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-headless
  labels:
    app: nacos-headless
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - port: 8848
      name: server
      targetPort: 8848
    - port: 9848
      name: client-rpc
      targetPort: 9848
    - port: 9849
      name: raft-rpc
      targetPort: 9849
      
    - port: 7848
      name: old-raft-rpc
      targetPort: 7848
  selector:
    app: nacos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nacos-cm
data:
  mysql.host: "10.127.1.12"
  mysql.db.name: "nacos_devtest"
  mysql.port: "3306"
  mysql.user: "nacos"
  mysql.password: "passwd"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nacos
spec:
  serviceName: nacos-headless
  replicas: 3
  template:
    metadata:
      labels:
        app: nacos
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
                      - nacos
              topologyKey: "kubernetes.io/hostname"
      containers:
        - name: k8snacos
          imagePullPolicy: Always
          image: nacos/nacos-server:latest
          resources:
            requests:
              memory: "2Gi"
              cpu: "500m"
          ports:
            - containerPort: 8848
              name: client
            - containerPort: 9848
              name: client-rpc
            - containerPort: 9849
              name: raft-rpc
            - containerPort: 7848
              name: old-raft-rpc
          env:
            - name: NACOS_REPLICAS
              value: "3"
            - name: MYSQL_SERVICE_HOST
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.host
            - name: MYSQL_SERVICE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.db.name
            - name: MYSQL_SERVICE_PORT
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.port
            - name: MYSQL_SERVICE_USER
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.user
            - name: MYSQL_SERVICE_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.password
            - name: MODE
              value: "cluster"
            - name: NACOS_SERVER_PORT
              value: "8848"
            - name: PREFER_HOST_MODE
              value: "hostname"
            - name: NACOS_SERVERS
              value: "nacos-0.nacos-headless.default.svc.cluster.local:8848 nacos-1.nacos-headless.default.svc.cluster.local:8848 nacos-2.nacos-headless.default.svc.cluster.local:8848"
  selector:
    matchLabels:
      app: nacos
---

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nacos-headless
  namespace: default

spec:
  rules:
  - host: nacos-web.nacos-demo.com
    http:
      paths:
      - path: /
        backend:
          serviceName: nacos-headless
          servicePort: server
```

接着我们改改上面的配置文件变成我们自己的。

-   1、ingress支持https，这里有篇[使用cert-manager申请免费的HTTPS证书](https://link.segmentfault.com/?enc=VOKozcSFLKAZ%2F3wVvemkWA%3D%3D.uUlVvcqnds0Qw0iLg1GzO0bdfSk8RF7tvHeGQoUop7uHCcbVPJ2T5WMHniCFrdnBCgpHrlx%2FD2bO9xUdF33UAlm1n1uYxYwVBw0QygJLqI%2FoRVlrFy1vKsSWJEnYj7BUDnRoR0l6KqtKANtwedkhFg%3D%3D)详细过程就不叙述了，过程为：

1.  部署cert-manager
2.  创建ClusterIssuer
3.  创建Ingress资源对象

-   2、ingress配置http 自动跳转到https，使用`nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'`注解
-   3、ConfigMap配置自己的Mysql地址和密码
-   4、StatefulSet集群模式下配置副本数replicas至少为2，否则不起作用
-   5、StatefulSet设置内存、CPU和模式

内存、CPU：

```
- name: k8snacos
  imagePullPolicy: Always
  image: nacos/nacos-server:latest
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
```

模式：

```
- name: MODE
  # 单机部署，value: "standalone" 
  # 集群部署，value: "cluster"    
  value: "cluster"  
```

其他的都不用变，如下所示 ：

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nacos-headless
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    
    cert-manager.io/cluster-issuer: "letsencrypt-prod-http01"
    nginx.ingress.kubernetes.io/service-weight: ''
    nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
spec:
  
  tls:
    - hosts:
        
        - baidu.com        
      secretName: server-seaurl-tls
  rules:
    - host: demo.nacos.com
      http:
        paths:
          - path: /nacos
            backend:
              serviceName: nacos-headless
              servicePort: server
---
apiVersion: v1
kind: Service
metadata:
  name: nacos-headless
  labels:
    app: nacos-headless
spec:
  type: ClusterIP
  
  clusterIP: None
  ports:
    - port: 8848
      name: server
      targetPort: 8848
    - port: 9848
      name: client-rpc
      targetPort: 9848
    - port: 9849
      name: raft-rpc
      targetPort: 9849
    
    - port: 7848
      name: old-raft-rpc
      targetPort: 7848
  selector:
    app: nacos
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nacos-cm
data:
  mysql.host: "your-aliyun-rds-host"
  mysql.db.name: "nacos"
  mysql.port: "3306"
  mysql.user: "username"
  mysql.password: "password"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nacos
spec:
  serviceName: nacos-headless
  
  replicas: 3
  template:
    metadata:
      labels:
        app: nacos
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
                      - nacos
              topologyKey: "kubernetes.io/hostname"
      containers:
        - name: k8snacos
          imagePullPolicy: Always
          image: nacos/nacos-server:latest
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
          ports:
            - containerPort: 8848
              name: client
            - containerPort: 9848
              name: client-rpc
            - containerPort: 9849
              name: raft-rpc
            - containerPort: 7848
              name: old-raft-rpc
          env:
            - name: NACOS_REPLICAS
              
              value: "3"
            - name: MYSQL_SERVICE_HOST 
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.host
            - name: MYSQL_SERVICE_DB_NAME
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.db.name
            - name: MYSQL_SERVICE_PORT
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.port
            - name: MYSQL_SERVICE_USER
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.user
            - name: MYSQL_SERVICE_PASSWORD
              valueFrom:
                configMapKeyRef:
                  name: nacos-cm
                  key: mysql.password
            - name: NACOS_SERVER_PORT
              value: "8848"
            - name: NACOS_APPLICATION_PORT
              value: "8848"
            - name: PREFER_HOST_MODE
              value: "hostname"
            - name: NACOS_SERVERS
              
              value: "nacos-0.nacos-headless.default.svc.cluster.local:8848 nacos-1.nacos-headless.default.svc.cluster.local:8848 nacos-2.nacos-headless.default.svc.cluster.local:8848"
            - name: MODE
              
              
              value: "cluster"            
  selector:
    matchLabels:
      app: nacos


```

然后执行命令来创建Nacos服务：

```
kubectl apply -f nacos.yaml
```

通过命令查看是否成功

```
kubectl get StatefulSet
kubectl get ingress
kubectl get svc
kubectl get pod
```

![image.png](https://segmentfault.com/a/image.png "image.png")  
从图中可以看出部署nacos服务成功，我们访问试试：  
![image.png](https://segmentfault.com/a/image.png "image.png")

## 总结

1、首先我们了解下什么是Service headless，就是type: ClusterIP且clusterIP: None的Service，所以只能通过dns对外去访问你的服务nacos-headless，  
2、单机模式没有使用过，大家可以试试

## 注意事项

1、如果集群模式下只有一个副本会出现问题，至少两个副本

## **\------------ 2021-7-5更新-----------------**

部署好之后，我发现本地开发环境启动微服务注册不到ingress的nacos域名：`https://demo.nacos.com/nacos`。  
**原因分析：**经过阿里小哥的帮助发现，ingress不需要配置path: /nacos，而直接**应该直接使用path: /**，可能是因为你加了/nacos，然后k8s去找的时候也加了nacos，变成了`https://demo.nacos.com/nacos/nacos`(我猜是这样的)，所以最终的ingress应该是：

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nacos-headless
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    
    cert-manager.io/cluster-issuer: "letsencrypt-prod-http01"
    nginx.ingress.kubernetes.io/service-weight: ''
    nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
spec:
  
  tls:
    - hosts:
        
        - baidu.com        
      secretName: server-seaurl-tls
  rules:
    - host: demo.nacos.com
      http:
        paths:
          - path: /
            backend:
              serviceName: nacos-headless
              servicePort: server
```

再总结一下：**本地开发环境dev，使用域名`https://demo.nacos.com`来访问，而测试环境test，我们用k8s部署的微服务，如网关等等只能通过k8s dns暴露的service地址来访问，如：**`http://nacos-headless.default.svc.cluster.local:8848`**，切记！不同环境下使用的nacos地址不一样！！！**

## **\------------ 2021-11-12更新-----------------**

因k8s升级到1.22版本，ingress有所调整，如下所示：

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nacos-headless
  
  namespace: nacos
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod-http01"
    nginx.ingress.kubernetes.io/service-weight: ''
    nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
spec:
  tls:
    - hosts:
        - nacos-web.nacos-demo.com        # 替换为您的域名。
      secretName: server-secret-tls
  rules:
    - host: nacos-web.nacos-demo.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nacos-headless
                port:
                  name: server
```

## 引用

[使用cert-manager申请免费的HTTPS证书](https://link.segmentfault.com/?enc=5PzGbNvk0OrJ2w6KhnndgA%3D%3D.HvI8K9KakYk%2BGbdgtDhp1FA0EVXFzYjMGKTh1yChBn7ptShY1FRk5Mjth9SpdZVztr%2FmAvccpV7QxLldr72F3Kc%2BBuVGWIkiMaE%2FrwjD8e%2BxtcWqk%2BVAgqARVKRPsU0%2FuKfStrnqMkrr9%2FZdf%2FwZdw%3D%3D)  
[K8S部署Nacos微服务](https://link.segmentfault.com/?enc=PtR8FUbAyb6esbTz3oILnA%3D%3D.G3vPYDdFOiOcrC8O%2FNIXhnuTL8hmqnzXzYiAguhP5v9eTMsQcbCkV3Q4u8GIRRxa)  
[k8s部署单节点nacos报错 server is DOWN now, please try again later! 解决](https://link.segmentfault.com/?enc=Sj0ouBMu8VfMiBExfQw3XA%3D%3D.tqKzte2wgJ16UssYFLq6ysVac%2FI%2BBNZNPsCTSOvG8hv6HcAU6qCpHUh%2FdX7DfeLdnQsm0NDxdgprzTs0YJ4hkw%3D%3D)  
[在 Kubernetes 中使用 DNS 和 Headless Service 发现运行中的 Pod](https://link.segmentfault.com/?enc=NdTSaAPOIm24I2rDwDbc5w%3D%3D.hn98%2Fvo7rRX%2BrQzz9Qxruj0Ocd4ZWhkqNyyzLfvCCgtKN5wLH0OtsHaFRM2dmkxs)  
[K8S容器编排之Headless浅谈](https://link.segmentfault.com/?enc=4Vbrqk8sHjYnuXmMDitYlQ%3D%3D.iWsP9HT6XtFVcwS%2FnQK0%2F48qy4SwvLDXAgr%2Ba2FiwlyHBkq1%2By7%2BO77RjHRPd9Cj)

文章来源：

https://segmentfault.com/a/1190000040246902
