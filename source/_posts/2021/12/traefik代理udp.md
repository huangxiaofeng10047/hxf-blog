---
title: Traefik2.2代理udp
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2021-12-27 16:18:37
tags:
---
此外 Traefik2.2 版本开始就已经提供了对 UDP 的支持，所以我们可以用于诸如 DNS 解析的服务提供负载。

首先部署一个如下所示的 UDP 服务：

```javascript
apiVersion: v1
kind: Service
metadata:
  name: whoamiudp
spec:
  ports:
  - protocol: UDP
    name: udp
    port: 8080
  selector:
    app: whoamiudp
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: whoamiudp
  labels:
    app: whoamiudp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoamiudp
  template:
    metadata:
      labels:
        app: whoamiudp
    spec:
      containers:
        - name: whoamiudp
          image: www.harbor.mobi/bcs_dev/iptables:v0.0.1
          ports:
            - name: udp
              containerPort: 8080
```

注意service的端口和deployment的端口应该是一致的。

直接部署上面的应用，部署完成后我们需要在 Traefik 中定义一个 UDP 的 entryPoint 入口点，修改我们部署 Traefik 的 `values-prod.yaml` 文件（[查看前文](http://mp.weixin.qq.com/s?__biz=MzU4MjQ0MTU4Ng==&mid=2247488793&idx=1&sn=bb2b0ad1402d4af50f2b4211621612b6&chksm=fdb91a04cace93121d8678c8025e197b36d429b199b11cb5b5e66797e30abb73150f03c8bd80&scene=21#wechat_redirect)），增加 UDP 协议的入口点：

```javascript
# values-prod.yaml
# Configure ports
ports:
  web:
    port: 8000
    hostPort: 80
  websecure:
    port: 8443
    hostPort: 443
  mongo:
    port: 27017
    hostPort: 27017
  udpep:
    port: 18080
    hostPort: 18080
    protocol: UDP
```

我们这里定义了一个名为 udpep 的入口点，但是 protocol 协议是 UDP（此外 TCP 和 UDP 共用同一个端口也是可以的，但是协议一定要声明为不一样），然后重新更新 Traefik：

```javascript
➜ helm upgrade --install traefik --namespace=kube-system ./traefik -f ./values-prod.yaml 
```

更新完成后我们可以导出 Traefik 部署的资源清单文件来检测是否增加上了 UDP 的入口点：

```javascript
➜ kubectl get deploy traefik -n kube-system -o yaml
......
containers:
- args:
  - --entryPoints.mongo.address=:27017/tcp
  - --entryPoints.traefik.address=:9000/tcp
  - --entryPoints.udpep.address=:18080/udp
  - --entryPoints.web.address=:8000/tcp
  - --entryPoints.websecure.address=:8443/tcp
  - --api.dashboard=true
  - --ping=true
  - --providers.kubernetescrd
  - --providers.kubernetesingress
......
```

UDP 的入口点增加成功后，接下来我们可以创建一个 `IngressRouteUDP` 类型的资源对象，用来代理 UDP 请求：

```javascript
➜ cat <<EOF | kubectl apply -f -
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteUDP
metadata:
  name: whoamiudp
spec:
  entryPoints:
  - udpep
  routes:
  - services:
    - name: whoamiudp
      port: 8080
EOF
➜ kubectl get ingressrouteudp                      
NAME        AGE
whoamiudp   31s
```

创建成功后我们首先在集群上通过 Service 来访问上面的 UDP 应用：

```javascript
➜ kubectl get svc
NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                 AGE
whoamiudp           ClusterIP   10.106.10.185    <none>        8080/UDP                                36m
➜ echo "WHO" | socat - udp4-datagram:10.106.10.185:8080
Hostname: whoamiudp-d884bdb64-6mpk6
IP: 127.0.0.1
IP: 10.244.1.145
➜ echo "othermessage" | socat - udp4-datagram:10.106.10.185:8080
Received: othermessage
```

我们这个应用当我们输入 `WHO` 的时候，就会打印出访问的 Pod 的 Hostname 这些信息，如果不是则打印接收到字符串。现在我们通过 Traefik 所在节点的 IP（10.151.30.11）与 18080 端口来访问 UDP 应用进行测试：

```javascript
➜ echo "othermessage" | socat - udp4-datagram:10.151.30.11:18080
Received: othermessage
➜  echo "WHO" | socat - udp4-datagram:10.151.30.11:18080
Hostname: whoamiudp-d884bdb64-hkw6k
IP: 127.0.0.1
IP: 10.244.2.87
```

我们可以看到测试成功了，证明我就用 Traefik 来代理 UDP 应用成功了。除此之外 Traefik 还有很多功能，特别是强大的[中间件](https://cloud.tencent.com/product/tdmq?from=10680)和自定义插件的功能，为我们提供了不断扩展其功能的能力，我们完成可以根据自己的需求进行二次开发。