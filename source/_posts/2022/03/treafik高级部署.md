---
title: treafik高级部署
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-07 10:51:36
tags:
---

![image-20220109164500924](https://gitee.com/hxf88/imgrepo/raw/master/img/13b338b7-0f91-41b5-ac0e-4e47a007904f.png)

image-20220109164500924

## 目录

## 实验环境

```
实验环境：1、win10,vmwrokstation虚机；2、k8s集群：3台centos7.6 1810虚机，1个master节点,2个node节点   k8s version：v1.22.2   containerd://1.5.5
```

## 实验软件

链接：https://pan.baidu.com/s/1h-\_er74njnBQwAaox9Vi1A 提取码：5aj3

yaml文件如下：

![image-20220115222837674](https://files.mdnice.com/user/20418/98de74aa-5e51-468d-91f9-6a6c6e640928.png)

image-20220115222837674

## 1、ACME(自动化https)

**「Traefik 通过扩展 CRD 的方式来扩展 Ingress 的功能」**，除了默认的用 Secret 的方式可以支持应用的 HTTPS 之外，**「还支持自动生成 HTTPS 证书。」**

### 📍 演示1：创建一个基于traefik IngressRoute的应用

🍀 比如现在我们有一个如下所示的 `whoami` 应用：

```
[root@master1 ~]#mkdir acme
[root@master1 ~]#cd acme/
[root@master1 acme]#vim who.yaml
#who.yaml
apiVersion: v1
kind: Service
metadata:
  name: whoami
spec:
  ports:
    - protocol: TCP
      name: web
      port: 80
  selector:
    app: whoami
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: whoami
  labels:
    app: whoami
spec:
  replicas: 2
  selector:
    matchLabels:
      app: whoami
  template:
    metadata:
      labels:
        app: whoami
    spec:
      containers:
        - name: whoami
          image: containous/whoami
          ports:
            - name: web
              containerPort: 80
              
#部署并查看
[root@master1 acme]#kubectl apply -f who.yaml 
service/whoami created
deployment.apps/whoami created
[root@master1 acme]#kubectl get po,deploy,svc
NAME                            READY   STATUS    RESTARTS       AGE        
pod/whoami-658d568b94-4fbwp     1/1     Running   0              28s        
pod/whoami-658d568b94-67nfl     1/1     Running   0              28s        

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/my-nginx   1/1     1            1           8h
deployment.apps/whoami     2/2     2            2           28s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   70d
service/whoami       ClusterIP   10.99.227.182   <none>        80/TCP    28s
```

🍀 然后定义一个 IngressRoute 对象：

```
#我们将这个IngressRoute资源对象的yaml内容继续追加在上面who.yaml文件最后
[root@master1 acme]#vim who.yaml
……
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-demo
spec:
  entryPoints:
  - web
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/notls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
      
#然后部署并测试
[root@master1 acme]#kubectl apply -f who.yaml 
service/whoami unchanged
deployment.apps/whoami unchanged
ingressroute.traefik.containo.us/ingressroute-demo created
[root@master1 acme]#kubectl get ingressroute ingressroute-demo
NAME                AGE
ingressroute-demo   17s

#在自己pc笔记本上做下域名解析：C:\WINDOWS\System32\drivers\etc\hosts
172.29.9.52 who.qikqiak.com
```

通过 `entryPoints` 指定了我们这个应用的入口点是 `web`，也就是通过 80 端口访问，然后访问的规则就是要匹配 `who.qikqiak.com` 这个域名，并且具有 `/notls` 的路径前缀的请求才会被 `whoami` 这个 Service 所匹配。我们可以直接创建上面的几个资源对象，然后对域名做对应的解析后，就可以访问应用了。

如果直接访问`who.qikqiak.com` 这个域名的话，是访问不到的，必须要加上后缀`/notls`才行：

![image-20220109185249412](https://files.mdnice.com/user/20418/76d41018-cbdf-478e-80cf-535ef4323dbc.png)

image-20220109185249412

![image-20220109185337041](https://files.mdnice.com/user/20418/0f141f38-719a-4a0e-8771-780c43e08240.png)

image-20220109185337041

测试结束。😘

🍀 在 `IngressRoute` 对象中我们定义了一些匹配规则，这些规则在 Traefik 中有如下定义方式：

![traefik route matcher](https://files.mdnice.com/user/20418/f4005f6d-2956-496e-b1ec-fc4f19d991f1.png)

traefik route matcher

> ❝
>
> 用的最多的就是Host和Path了；
>
> ❞

![image-20220109190030821](https://files.mdnice.com/user/20418/f5ce2e23-7c37-44e6-8c1b-83dc6c812d55.png)

image-20220109190030821

![image-20220109190211668](https://files.mdnice.com/user/20418/ee2d81be-4422-493f-82ee-8b0e0d627a06.png)

image-20220109190211668

### 📍 演示2：使用https来访问我们的应用

如果我们需要用 HTTPS 来访问我们这个应用的话，就需要监听 `websecure` 这个入口点，也就是通过 443 端口来访问，同样用 HTTPS 访问应用必然就需要证书。

在上一个实验的基础上：

🍀 这里我们用 `openssl` 来创建一个自签名的证书：

```
[root@master1 acme]#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=who.qikqiak.com"
Generating a 2048 bit RSA private key
......................................................+++
.........................................................................+++
writing new private key to 'tls.key'
-----
[root@master1 acme]#ls
tls.crt  tls.key  who.yaml
```

🍀 然后通过 Secret 对象来引用证书文件：

```
# 要注意证书文件名称必须是 tls.crt 和 tls.key
[root@master1 acme]#kubectl create secret tls who-tls --cert=tls.crt --key=tls.key 
secret/who-tls created
[root@master1 acme]#kubectl get secrets who-tls
NAME      TYPE                DATA   AGE
who-tls   kubernetes.io/tls   2      17s
```

🍀 这个时候我们就可以创建一个 HTTPS 访问应用的 IngressRoute 对象了：

```
#这里我们继续在上面那个who.yaml文件后面追加
[root@master1 acme]#vim who.yaml
……
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-tls-demo
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
  tls:
    secretName: who-tls
    
#部署并测试
[root@master1 acme]#kubectl apply -f who.yaml 
service/whoami unchanged
deployment.apps/whoami unchanged
ingressroute.traefik.containo.us/ingressroute-demo unchanged
ingressroute.traefik.containo.us/ingressroute-tls-demo created
```

🍀 创建完成后就可以通过 HTTPS 来访问应用了，由于我们是自签名的证书，所以证书是不受信任的：

![image-20220109191521461](https://gitee.com/hxf88/imgrepo/raw/master/img/236b8dea-e61b-4f22-9f6f-c18b600c0d1c.png)

image-20220109191521461

![image-20220109191614645](https://files.mdnice.com/user/20418/0f06df13-a042-4825-a024-e8448ce482a4.png)

image-20220109191614645

测试结束。😘

### 📍 演示3：使用 `Let’s Encrypt` 自动生成证书

除了手动提供证书的方式之外 Traefik 同样也支持使用 `Let’s Encrypt` 自动生成证书，要使用 `Let’s Encrypt` 来进行自动化 HTTPS，就需要首先开启 `ACME`，开启 `ACME` 需要通过静态配置的方式，也就是说可以通过环境变量、启动参数等方式来提供。

ACME 有多种校验方式 `tlsChallenge`、`httpChallenge` 和 `dnsChallenge` 三种验证方式。之前更常用的是 http 这种验证方式，关于这几种验证方式的使用可以查看文档：https://www.qikqiak.com/traefik-book/https/acme/ 了解他们之间的区别。要使用 tls 校验方式的话需要保证 Traefik 的 443 端口是可达的。**「dns 校验方式可以生成通配符的证书，只需要配置上 DNS 解析服务商的 API 访问密钥即可校验」**。

> ❝
>
> httpChallenge：它需要在你的一个服务上面去访问它自动给你生成的一个路径。它要访问你这个服务路径是可达的，这样的话，它才可以认为你过来请求的这个证书是可以直接颁发给你的。但是它具体的这个路径，可能是例如：http://who.qikqiak.com/well-know/xxx类似这种的。所以这种情况，它一定是需要你的服务它的一个80端口是可达的，而且必须是在公网环境上面。因为`Let’s Encrypt` 这个服务器的服务它要来验证，压迫去访问你的这个路径，如果你的http://who.qikqiak.com/well-know/xxx这个路径如果他访问不到的话，它肯定不会给你校验通过的哈。
>
> 当然，你如果用tls的话，也是一样的，它是用这个443端口。它是会去直接检测你这个443端口是否可达。
>
> 所以这2种方式： `tlsChallenge`、`httpChallenge` ，都必须保证你这个服务必须在外网上面可访问。
>
> 第三种方式：`dnsChallenge` (适用于内网环境)。就是 `Let’s Encrypt`它会去请求`dnsChallenge` 这个API的配置，API相关的一些秘钥之类的。
>
> ❞

我们这里用 DNS 校验的方式来为大家说明如何配置 ACME。

🍀 我们可以重新修改 Helm 安装的 values 配置文件，添加如下所示的定制参数：

```
# ci/deployment-prod.yaml #将这些参数追加在原来的内容后面即可
additionalArguments:
# 使用 dns 验证方式
- --certificatesResolvers.ali.acme.dnsChallenge.provider=alidns
# 先使用staging环境进行验证，验证成功后再使用移除下面一行的配置
# - --certificatesResolvers.ali.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory
# 邮箱配置
- --certificatesResolvers.ali.acme.email=ych_1024@163.com #这个邮箱应该是随便填的。
# 保存 ACME 证书的位置
- --certificatesResolvers.ali.acme.storage=/data/acme.json

envFrom:
- secretRef:
    name: traefik-alidns-secret
    # ALICLOUD_ACCESS_KEY
    # ALICLOUD_SECRET_KEY
    # ALICLOUD_REGION_ID

persistence:
  enabled: true  # 开启持久化
  accessMode: ReadWriteOnce
  size: 128Mi
  path: /data

# 由于上面持久化了ACME的数据，需要重新配置下面的安全上下文
securityContext:
  readOnlyRootFilesystem: false
  runAsGroup: 0
  runAsUser: 0
  runAsNonRoot: false
```

:warning: 问题:这里为什么这里要使用root用户？

我们来看下values.yaml文件里，默认securityContext内容为：默认是以65532:65532身份去运行容器的

```
# Set the container security context
# To run the container with ports below 1024 this will need to be adjust to run as root
securityContext:
  capabilities:
    drop: [ALL]
  readOnlyRootFilesystem: true
  runAsGroup: 65532
  runAsNonRoot: true
  runAsUser: 65532

podSecurityContext:
  fsGroup: 65532
```

但由于上面持久化了ACME的数据，需要往root身份创建的文件里填写信息：

```
[root@node1 ~]#ll /data/k8s/traefik/acme.json 
-rw------- 1 root root 3533 Jan 11 09:45 /data/k8s/traefik/acme.json
```

因此需要配置其安全上下文为root身份。

🍀 这样我们可以通过设置 `--certificatesresolvers.ali.acme.dnschallenge.provider=alidns` 参数来指定指定阿里云的 DNS 校验，要使用阿里云的 DNS 校验我们还需要配置3个环境变量：`ALICLOUD_ACCESS_KEY`、`ALICLOUD_SECRET_KEY`、`ALICLOUD_REGION_ID`，分别对应我们平时开发阿里云应用的时候的密钥，可以登录阿里云后台 https://ram.console.aliyun.com/manage/ak 获取，由于这是比较私密的信息，所以我们用 Secret 对象来创建：

```
➜ kubectl create secret generic traefik-alidns-secret --from-literal=ALICLOUD_ACCESS_KEY=<aliyun ak> --from-literal=ALICLOUD_SECRET_KEY=<aliyun sk> --from-literal=ALICLOUD_REGION_ID=cn-beijing -n kube-system

[root@master1 acme]#kubectl create secret generic traefik-alidns-secret --from-literal=ALICLOUD_ACCESS_KEY=LTAIxxx5tGNsuAzZUFBqgswHL8k --from-literal=ALICLOUD_SECRET_KEY=25hxxxbNHrpTkUke936sE7NMI5jadN7oG --from-literal=ALICLOUD_REGION_ID=cn-beijing -n kube-system
secret/traefik-alidns-secret created
[root@master1 acme]#kubectl get secrets traefik-alidns-secret -nkube-system
NAME                    TYPE     DATA   AGE
traefik-alidns-secret   Opaque   3      17s
```

https://ram.console.aliyun.com/manage/ak

![image-20220109195636335](https://gitee.com/hxf88/imgrepo/raw/master/img/c4ae9f68-ad65-4ea0-bb8d-f2ba5c32fad2.png)

image-20220109195636335

![image-20220109195802223](https://files.mdnice.com/user/20418/6a4f5e70-2011-417a-8727-78cdbcaa1b99.png)

image-20220109195802223

🍀 创建完成后将这个 Secret 通过环境变量配置到 Traefik 的应用中，还有一个值得注意的是验证通过的证书我们这里存到 `/data/acme.json` 文件中，我们一定要将这个文件持久化，**「否则每次 Traefik 重建后就需要重新认证」**，而 **「`Let’s Encrypt` 本身校验次数是有限制的」**。所以我们在 values 中重新开启了数据持久化，不过开启过后需要我们提供一个可用的 PV 存储，由于我们将 Traefik 固定到 node1 节点上的，所以我们可以创建一个 hostpath 类型的 PV（后面会详细讲解）：

```
[root@master1 acme]#vim pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: traefik
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 128Mi
  hostPath:
    path: /data/k8s/traefik

#部署并查看
[root@master1 acme]#kubectl apply -f pv.yaml 
persistentvolume/traefik created
[root@master1 acme]#kubectl get pv traefik 
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
traefik   128Mi      RWO            Retain           Available                                   18s
[root@master1 acme]#    
```

🍀 配置：

```
[root@master1 traefik]#vim ci/deployment-prod.yaml
……
# ci/deployment-prod.yaml
additionalArguments:
# 使用 dns 验证方式
- --certificatesResolvers.ali.acme.dnsChallenge.provider=alidns
# 先使用staging环境进行验证，验证成功后再使用移除下面一行的配置
- --certificatesResolvers.ali.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory
# 邮箱配置
- --certificatesResolvers.ali.acme.email=ych_1024@163.com
# 保存 ACME 证书的位置
- --certificatesResolvers.ali.acme.storage=/data/acme.json

envFrom:
- secretRef:
    name: traefik-alidns-secret
    # ALICLOUD_ACCESS_KEY
    # ALICLOUD_SECRET_KEY
    # ALICLOUD_REGION_ID

persistence:
  enabled: true  # 开启持久化
  accessMode: ReadWriteOnce
  size: 128Mi
  path: /data

# 由于上面持久化了ACME的数据，需要重新配置下面的安全上下文
securityContext:
  readOnlyRootFilesystem: false
  runAsGroup: 0
  runAsUser: 0
  runAsNonRoot: false
```

🍀 然后使用如下所示的命令更新 Traefik：

```
➜ helm upgrade --install traefik ./traefik -f ./traefik/ci/deployment-prod.yaml --namespace kube-system
```

🍀 更新完成后现在我们来修改上面我们的 `whoami` 应用：

```
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroute-tls-demo
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
  tls:
    certResolver: ali
    domains:
    - main: "*.qikqiak.com"
```

其他的都不变，只需要将 tls 部分改成我们定义的 `ali` 这个证书解析器，如果我们想要生成一个通配符的域名证书的话可以定义 `domains` 参数来指定，然后更新 IngressRoute 对象，这个时候我们再去用 HTTPS 访问我们的应用（当然需要将域名在阿里云 DNS 上做解析）：

![traefik wildcard domain](https://files.mdnice.com/user/20418/e534b782-1946-48c1-84b5-4f3524c8a58f.png)

traefik wildcard domain

我们可以看到访问应用已经是受浏览器信任的证书了，查看证书我们还可以发现该证书是一个通配符的证书。

到此结束！

:warning: 自己当时测试了好久失败了，但最后成功了。(这里主要是写自己的域名地址，而不是用老师的域名)

😥 呃呃，自己第一次测试失败了。。。

![image-20220109205501705](https://gitee.com/hxf88/imgrepo/raw/master/img/3ee72048-3872-4cb9-abc6-e1bbd47e0943.png)

image-20220109205501705

![image-20220109205619375](https://gitee.com/hxf88/imgrepo/raw/master/img/e935be07-a42c-4029-8445-6682da34836e.jpg)

image-20220109205619375

qikq

可能导致错误的原因如下：

-   这个邮箱可以随便写的吗？--可以随便写的；
    

![image-20220109210125906](https://files.mdnice.com/user/20418/16570fa1-b872-4365-a3ee-6e79cd520394.png)

image-20220109210125906

-   这个zone要怎么选择？(这个region当时自己应该也是填这个的)
    

![image-20220109210156025](https://files.mdnice.com/user/20418/2a2042bc-ccb3-4d4d-bca8-d79853a1c660.png)

image-20220109210156025

-   其他方便也不可能有错啊。。。
    

![image-20220111204340953](https://files.mdnice.com/user/20418/7a66608e-765d-4ceb-b6be-ce0707fa7653.jpg)

image-20220111204340953

奇怪：

![image-20220110192621159](https://gitee.com/hxf88/imgrepo/raw/master/img/30d4e071-6213-4cff-b440-3f8e977123e1.jpg)

image-20220110192621159

老师这个正常的：

![image-20220111105431666](https://gitee.com/hxf88/imgrepo/raw/master/img/9838128a-e86f-416e-9236-905f980778f9.png)

image-20220111105431666

特别注意：

![image-20220116061946573](https://files.mdnice.com/user/20418/20a91c2f-a7c6-41ee-b1ba-2597be1b2e54.png)

image-20220116061946573

![image-20220111211005892](https://files.mdnice.com/user/20418/799bffed-6843-4c01-be05-cd6d61370b67.png)

image-20220111211005892

终于success了哈哈：

![image-20220112080224318](https://files.mdnice.com/user/20418/c13a7f95-79f4-42ee-be91-4d9f3eca69e4.png)

image-20220112080224318

测试结束，完美！

## 2、中间件

**「中间件是 Traefik2.x 中一个非常有特色的功能」**，我们可以根据自己的各种需求去选择不同的中间件来满足服务，Traefik 官方已经内置了许多不同功能的中间件，**「其中一些可以修改请求，头信息，一些负责重定向，一些添加身份验证等等」**，而且**「中间件还可以通过链式组合的方式来适用各种情况。」**

![traefik middleware overview](https://files.mdnice.com/user/20418/b716015e-bf7e-4a13-a821-a379c71ad2eb.png)

traefik middleware overview

### 1.跳转https

#### 📍 演示1：traefik中间件：跳转https

🍀 同样比如上面我们定义的 whoami 这个应用，我们可以通过 `https://who.qikqiak.com/tls` 来访问到应用，但是如果我们用 `http` 来访问的话呢就不行了，就会404了，**「因为我们根本就没有简单80端口这个入口点」**。

![image-20220111105952391](https://files.mdnice.com/user/20418/99c9eebf-e164-4717-a111-218337760cfd.png)

🍀 所以要想通过 `http` 来访问应用的话自然我们需要监听下 `web` 这个入口点：

```
[root@master1 acme]#vim who.yaml #继续在who.yaml文件里添加如下ymal内容
……
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutetls-http
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
```

注意这里我们创建的 IngressRoute 的 entryPoints 是 `web`，然后创建这个对象，这个时候我们就可以通过 http 访问到这个应用了。

```
[root@master1 acme]#kubectl apply -f who.yaml 
service/whoami unchanged
deployment.apps/whoami unchanged
ingressroute.traefik.containo.us/ingressroute-demo unchanged
ingressroute.traefik.containo.us/ingressroute-tls-demo unchanged
ingressroute.traefik.containo.us/ingressroutetls-http created
```

测试效果：

http://who.qikqiak.com/tls

![image-20220111110804530](https://files.mdnice.com/user/20418/d5e4a75c-786a-4942-a190-4ca0b41fd616.png)

image-20220111110804530

🍀 这边，我们顺便在强制跳转https时，再加上`BasicAuth`认证中间间功能

![image-20220111121458608](https://gitee.com/hxf88/imgrepo/raw/master/img/0cc7b7cd-ea98-45c1-aab9-b95ea5617947.png)

image-20220111121458608

```
[root@master1 acme]#vim who.yaml #继续在who.yaml文件里添加如下ymal内容
……
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: test-auth
spec:
  basicAuth:
    secret: secretName
```

生成basic-auth1 secret：

```
[root@master1 acme]#htpasswd -c auth foo
New password:
Re-type new password:
Adding password for user foo
[root@master1 acme]#ls
auth  pv.yaml  tls.crt  tls.key  who.yaml
[root@master1 acme]#kubectl create secret generic basic-auth1 --from-file=auth
secret/basic-auth1 created
[root@master1 acme]#kubectl get secrets basic-auth1
NAME          TYPE     DATA   AGE
basic-auth1   Opaque   1      54s
[root@master1 acme]#kubectl get secrets basic-auth1 -oyaml
apiVersion: v1
data:
  auth: Zm9vOiRhcHIxJFgvTVFPb2JjJGNJaHY2VjkuQjRKN1plUVguMnNQMS4K
kind: Secret
metadata:
  creationTimestamp: "2022-01-11T04:20:55Z"
  name: basic-auth1
  namespace: default
  resourceVersion: "1498910"
  uid: 2aedf99d-bb56-49b4-8ab7-ab139b99856e
type: Opaque
[root@master1 acme]#echo  Zm9vOiRhcHIxJFgvTVFPb2JjJGNJaHY2VjkuQjRKN1plUVguMnNQMS4K|base64 -d
foo:$apr1$X/MQOobc$cIhv6V9.B4J7ZeQX.2sP1.
```

在who.yaml里的引用这个secret：

```
[root@master1 acme]#vim who.yaml 
……
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutetls-http
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
    middlewares: #修改点1：添加中间件名称，这里的中间间相当于是串行的，auth验证通过后才会跳转到https的；
    - name: test-auth  
    - name: redirect-https
……
```

![image-20220111122805907](https://files.mdnice.com/user/20418/0b8a5dbb-acc2-4a06-b7e4-faf994117f1e.jpg)

image-20220111122805907

部署并测试效果：

```
[root@master1 acme]#kubectl apply -f who.yaml 
service/whoami unchanged
deployment.apps/whoami unchanged
ingressroute.traefik.containo.us/ingressroute-demo unchanged
ingressroute.traefik.containo.us/ingressroute-tls-demo unchanged
ingressroute.traefik.containo.us/ingressroutetls-http configured
middleware.traefik.containo.us/redirect-https unchanged
middleware.traefik.containo.us/test-auth created
```

我们直接来访问下这个http链接：

http://who.qikqiak.com/tls 账号密码：foo foo

![image-20220111123006785](https://gitee.com/hxf88/imgrepo/raw/master/img/950ba08a-57cf-42b9-8095-a29cc29b0306.png)

image-20220111123006785

![image-20220111123021422](https://gitee.com/hxf88/imgrepo/raw/master/img/13ad00b0-7036-4419-9e97-5798caa93129.png)

image-20220111123021422

符合预期效果。

🍀 但是我们如果只希望用户通过 https 来访问应用的话呢？按照以前的知识，我们是不是可以让 http 强制跳转到 https 服务去，对的，在 Traefik 中也是可以**「配置强制跳转的」**，只是这个功能现在是通过中间件来提供的了。如下所示，**「我们使用 `redirectScheme` 中间件来创建提供强制跳转服务」**：

```
[root@master1 acme]#vim who.yaml #继续将如下内容添加到who.yaml文件内容后面
……
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https #这个是不是比ingress-nginx通过annotations注解使用起来方便很多了！
spec:
  redirectScheme:
    scheme: https
```

然后将这个中间件附加到 http 的服务上面去，因为 https 的不需要跳转：

```
[root@master1 acme]#vim who.yaml #修改who.yaml里面ingressroutetls-http 内容
……
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutetls-http
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`who.qikqiak.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
    middlewares: #修改点1：添加中间件名称
    - name: redirect-https
```

🍀 这个时候我们部署后再去访问 http 服务可以发现就会自动跳转到 https 去了。

```
[root@master1 acme]#kubectl apply -f who.yaml
service/whoami unchanged
deployment.apps/whoami unchanged
ingressroute.traefik.containo.us/ingressroute-demo unchanged
ingressroute.traefik.containo.us/ingressroute-tls-demo unchanged
ingressroute.traefik.containo.us/ingressroutetls-http configured
middleware.traefik.containo.us/redirect-https created
```

![image-20220111111756187](https://gitee.com/hxf88/imgrepo/raw/master/img/9e2a908e-55d2-4fa0-8ad5-06a61be1e231.png)

image-20220111111756187

![image-20220111111816195](https://files.mdnice.com/user/20418/c43558a6-b7f8-419e-9336-6789ec8b6121.png)

image-20220111111816195

测试结束。

### 2.URL Rewrite

#### 📍 演示1：URL Rewrite

🍀 接着我们再介绍如何使用 Traefik 来**「实现 URL Rewrite 操作」**，比如我们现部署一个 Nexus 应用，通过 IngressRoute 来暴露服务，对应的资源清单如下所示：

```
[root@master1 ~]#mkdir url-rewrite
[root@master1 ~]#cd url-rewrite/
[root@master1 url-rewrite]#vim nexus.yaml
# nexus.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexus
  labels:
    app: nexus
spec:
  selector:
    matchLabels:
      app: nexus
  template:
    metadata:
      labels:
        app: nexus
    spec:
      containers:
      - image: cnych/nexus:3.20.1
        imagePullPolicy: IfNotPresent
        name: nexus
        ports:
        - containerPort: 8081
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nexus
  name: nexus
spec:
  ports:
  - name: nexusport
    port: 8081
    targetPort: 8081
  selector:
    app: nexus
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nexus
  namespace: kube-system  # 和Service，deployment不在同一个命名空间，主要是用来测试 Traefik 的跨命名空间功能。
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: Host(`nexus.qikqiak.com`)
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
```

🍀 由于我们开启了 Traefik 的跨命名空间功能（参数 `--providers.kubernetescrd.allowCrossNamespace=true`），所以可以引用其他命名空间中的 Service 或者中间件(**「但是在ingress-nginx里面肯定是不可以这样的了」**)，直接部署上面的应用即可:

```
[root@master1 url-rewrite]#kubectl apply -f nexus.yaml 
deployment.apps/nexus created
service/nexus created
ingressroute.traefik.containo.us/nexus created
[root@master1 url-rewrite]#kubectl get po -l app=nexus -n default
NAME                     READY   STATUS    RESTARTS   AGE
nexus-6f78b79d4c-5c597   1/1     Running   0          17s
[root@master1 url-rewrite]#kubectl get svc -l app=nexus -n default
NAME    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
nexus   ClusterIP   10.97.215.83   <none>        8081/TCP   24s
[root@master1 url-rewrite]#kubectl get ingressroute  -n kube-system
NAME                AGE
nexus               67s
```

🍀 部署完成后，我们根据 `IngressRoute` 对象中的配置，只需要将域名 `nexus.qikqiak.com` 解析到 Traefik 的节点即可访问：

```
#在自己pc笔记本上做下域名解析：C:\WINDOWS\System32\drivers\etc\hosts172.29.9.52 nexus.qikqiak.com
```

![nexus url](https://files.mdnice.com/user/20418/8f832237-4131-4ad6-ba81-4b4c69a27dea.png)

nexus url

到这里我们都可以很简单的来完成。

😥 奇怪：好端端为啥会报这个错误呢？（这个浪费了我很长时间。。。；最后是k8s节点需要配置下open files参数！！！）

重启也没效果。。。

```
  Warning  FailedCreatePodSandBox  49m                 kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "ce826d4294f471a377ac7313ff2b68ae547924d326c27569ed2f6515fb63bcba": open /run/flannel/subnet.env: no such file or directory

```

![image-20220112221436264](https://files.mdnice.com/user/20418/289044c1-639a-4ede-bd27-b2efc4e74d16.png)

image-20220112221436264

![image-20220112221715076](https://gitee.com/hxf88/imgrepo/raw/master/img/0b66640b-746d-4167-b0f3-1ea2d31190a6.png)

image-20220112221715076

![image-20220114071449563](https://files.mdnice.com/user/20418/f640f404-3aa7-4a11-9699-331a9bcd95f2.png)

image-20220114071449563

![image-20220114072755489](https://files.mdnice.com/user/20418/2eea2938-bdba-4fb6-8cf3-a715b7b4853b.png)

image-20220114072755489

![image-20220114072842860](https://gitee.com/hxf88/imgrepo/raw/master/img/b087f64e-568b-4f96-b08c-1f7fed4f1ec3.png)

image-20220114072842860

重新部署了trafik还是有问题：

![image-20220114075136062](https://gitee.com/hxf88/imgrepo/raw/master/img/289b479e-1e80-43a3-949e-344a6ebdda20.png)

image-20220114075136062

难道是我的traefik有问题？？

k8s集群是没问题的，测试了nginx服务部署时没问题的。

![image-20220114075414974](https://files.mdnice.com/user/20418/f588b1cd-df34-4542-be84-9ad60c706d2d.png)

image-20220114075414974

![image-20220114075431484](https://gitee.com/hxf88/imgrepo/raw/master/img/eb269731-3a61-4287-9315-5143f1ab763b.png)

image-20220114075431484

我现在部署一个traefik的应用看是否存在问题？

经测试野外没有问题的。。。

那估计就是老师的镜像除了问题了。。。

提出问题

阳总，帮看个问题，就是"Traefik 高级配置2"视频里关于中间件的"URL Rewrite"测试实验时，我看你视频里都有现象，我这边来回测试都没现象(k8s集群重启也没效果；traefike重装后再部署ingressroute都有效果；)，感觉像是是你仓库里cnych/nexus:3.20.1镜像的问题，这个你有重新改变过吗? describle 看nexus 这个pod，一直在重启那个nexus pod，看pod logs也没看出什么问题。老师帮忙看下

故障截图

![image-20220114210039164](https://files.mdnice.com/user/20418/9a54ebf0-ec23-4355-8da1-2a7dec71662a.jpg)

image-20220114210039164

![image-20220114204941647](https://gitee.com/hxf88/imgrepo/raw/master/img/7289309c-1ce1-41f6-9946-2fb348e59365.png)

image-20220114204941647

![image-20220114205940337](https://gitee.com/hxf88/imgrepo/raw/master/img/0fd72449-2ee6-4b2b-bdc9-227e0ff0fd19.png)

image-20220114205940337

![image-20220114210218651](https://files.mdnice.com/user/20418/4dd9bc1f-3cb8-4d6c-9944-f79f2cb12f77.png)

image-20220114210218651

![image-20220114210235754](https://files.mdnice.com/user/20418/39403ec1-276d-4afd-80be-98675fa6eb96.png)

image-20220114210235754

ok了哈哈：666，完美。

![image-20220115213319992](https://gitee.com/hxf88/imgrepo/raw/master/img/cddcfc8d-84dd-4adf-a84c-796f8ff15a88.png)

image-20220115213319992

是因为我这里配置了下open files参数：(具体如何配置，请看链接https://blog.csdn.net/weixin\_39246554/article/details/122515237?spm=1001.2014.3001.5501)

```
1、配置file-max参数
echo "fs.file-max = 6553560" >> /etc/sysctl.conf

2、配置ulimit内容
# vim /etc/security/limits.conf
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1024000
* hard nproc 1024000
* soft memlock unlimited
* hard memlock unlimited
* soft core unlimited
* hard core unlimited
* soft stack 1024000
* hard stack 1024000

#说明：
/proc/sys/fs/file-max(系统所有进程一共可以打开的文件数量)
/proc/sys/fs/nr_open (单个进程可分配的最大文件数),这个参数一般建议是1024000
注意：是如下2行配置决定了ulimit -a中opne file的值！！！
* soft nofile 1048576
* hard nofile 1048576

3、重启机器
reboot

4、测试效果
cat /proc/sys/fs/file-max
ulimit -a
```

🍀 同样的现在我们有一个需求是目前我们只有一个域名可以使用，但是我们有很多不同的应用需要暴露，这个时候**「我们就只能通过 PATH 路径来进行区分了」**，比如我们现在希望当我们访问 `http:/nexus.qikqiak.com/foo` 的时候就是访问的我们的 Nexus 这个应用，当路径是 `/bar` 开头的时候是其他应用，这种需求是很正常的，这个时候我们就需要来做 URL Rewrite 了。

首先我们使用 [StripPrefix](https://www.qikqiak.com/traefik-book/middlewares/stripprefix/) 这个中间件，这个中间件的功能是**「在转发请求之前从路径中删除前缀」**，在使用中间件的时候我们只需要理解**「中间件操作的都是我们直接的请求即可」**，并不是真实的应用接收到请求过后来进行修改。

🍀 现在我们添加一个如下的中间件：

```
[root@master1 ~]#vim url-rewrite/nexus.yaml
……
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: strip-foo-path
  namespace: default  # 注意这里的中间件我们定义在default命名空间下面的
spec:
  stripPrefix:
    prefixes:
    - /foo
```

然后现在我们就需要从 `http:/nexus.qikqiak.com/foo` 请求中去匹配 `/foo` 的请求，把这个路径下面的请求应用到上面的中间件中去，因为最终我们的 Nexus 应用接收到的请求是不会带有 `/foo` 路径的，**「所以我们需要在请求到达应用之前将这个前缀删除」**，更新 IngressRoute 对象：

```
[root@master1 ~]#vim url-rewrite/nexus.yaml
……
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nexus
  namespace: kube-system
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`)  # 匹配 /foo 路径
    middlewares:
    - name: strip-foo-path
      namespace: default  # 由于我们开启了traefik的跨命名空间功能，所以可以引用其他命名空间中的中间件
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
```

🍀 创建中间件更新完成上面的 IngressRoute 对象后，这个时候我们前往浏览器中访问 `http:/nexus.qikqiak.com/foo`，这个时候发现我们的页面任何样式都没有了：

```

[root@master1 ~]#kubectl apply -f url-rewrite/nexus.yaml 
deployment.apps/nexus unchanged
service/nexus unchanged
middleware.traefik.containo.us/strip-foo-path created
ingressroute.traefik.containo.us/nexus configured
```

![nexus rewrite url error](https://files.mdnice.com/user/20418/7dfe2c6c-0f67-45da-ac13-f9a2547ce7c9.png)

nexus rewrite url error

我们通过 Chrome 浏览器的 Network 可以查看到 `/foo` 路径的请求是200状态码，但是其他的静态资源对象确全都是404了，这是为什么呢？我们仔细观察上面我们的 IngressRoute 资源对象，我们现在是不是只匹配了 `/foo` 的请求，而我们的静态资源是 `/static` 路径开头的，当然就匹配不到了，所以就出现了404，所以我们只需要加上这个 `/static` 路径的匹配就可以了，同样更新 IngressRoute 对象：

```
[root@master1 ~]#vim url-rewrite/nexus.yaml 
……
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nexus
  namespace: kube-system
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`)
    middlewares:
    - name: strip-foo-path
      namespace: default
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
  - kind: Rule
    match: Host(`nexus.qikqiak.com`) && PathPrefix(`/static`)  # 匹配 /static 的请求
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
```

然后更新 IngressRoute 资源对象，这个时候再次去访问应用，可以发现页面样式已经正常了，也可以正常访问应用了：

```

[root@master1 ~]#kubectl apply -f url-rewrite/nexus.yaml 
deployment.apps/nexus unchanged
service/nexus unchanged
middleware.traefik.containo.us/strip-foo-path unchanged
ingressroute.traefik.containo.us/nexus configured
```

![nexus rewrite url error2](https://gitee.com/hxf88/imgrepo/raw/master/img/6ebece12-59d8-4e0c-92a8-1934faf45d39.png)

nexus rewrite url error2

🍀 但进入应用后发现还是有错误提示信息，通过 Network 分析发现还有一些 `/service` 开头的请求是404，当然我们再加上这个前缀的路径即可：

```
[root@master1 ~]#vim url-rewrite/nexus.yaml 
……
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nexus
  namespace: kube-system
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: Host(`nexus.qikqiak.com`) && PathPrefix(`/foo`)
    middlewares:
    - name: strip-foo-path
      namespace: default
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
  - kind: Rule
    match: Host(`nexus.qikqiak.com`) && (PathPrefix(`/static`) || PathPrefix(`/service`))  # 匹配 /static 和 /service 的请求
    services:
    - kind: Service
      name: nexus
      namespace: default
      port: 8081
```

更新后，再次访问应用就已经完全正常了：

```
[root@master1 ~]#kubectl apply -f url-rewrite/nexus.yaml deployment.apps/nexus unchangedservice/nexus unchangedmiddleware.traefik.containo.us/strip-foo-path unchangedingressroute.traefik.containo.us/nexus configured
```

![nexus rewrite url ok](https://gitee.com/hxf88/imgrepo/raw/master/img/032d60d1-c4f2-4bae-9690-f1865330bedc.png)

nexus rewrite url ok

完美。

实验结束。

Traefik2.X 版本中的中间件功能非常强大，基本上官方提供的系列中间件可以满足我们大部分需求了，其他中间件的用法，可以参考文档：https://www.qikqiak.com/traefik-book/middlewares/overview/。

## 注意

### 📍 traefik官网

https://doc.traefik.io/traefik/

![image-20220111105231727](https://gitee.com/hxf88/imgrepo/raw/master/img/07794252-9383-40b0-a969-48450346d420.png)

image-20220111105231727

### 📍 traefik其他中间件

https://doc.traefik.io/traefik/

![image-20220111123731940](https://gitee.com/hxf88/imgrepo/raw/master/img/4785d383-4694-4b0b-92d6-33e50a94681e.png)

image-20220111123731940

![image-20220111124032333](https://files.mdnice.com/user/20418/a6dea809-e00a-4e03-bcd9-be921200eb70.png)

image-20220111124032333

![image-20220111124112302](https://files.mdnice.com/user/20418/dd9f7d11-933f-46e9-a5c9-8c5694258667.png)

image-20220111124112302

## 关于我

我的博客主旨：我希望每一个人拿着我的博客都可以做出实验现象，先把实验做出来，然后再结合理论知识更深层次去理解技术点，这样学习起来才有乐趣和动力。并且，我的博客内容步骤是很完整的，也分享源码和实验用到的软件，希望能和大家一起共同进步！

各位小伙伴在实际操作过程中如有什么疑问，可随时联系本人免费帮您解决问题：

1.  个人微信二维码：x2675263825 （舍得）， qq：2675263825。
    
    ![image-20211002091450217](https://gitee.com/hxf88/imgrepo/raw/master/img/eb3f1edf-cccd-4325-a4cc-12192789cc5d.png)
    
    image-20211002091450217
    
2.  个人博客地址：www.onlyonexl.cn
    
    ![image-20211002092057988](https://gitee.com/hxf88/imgrepo/raw/master/img/ce1986de-eaf0-465c-90b6-8e48d7282327.png)
    
    image-20211002092057988
    
3.  个人微信公众号：云原生架构师实战
    
    ![image-20211002141739664](https://gitee.com/hxf88/imgrepo/raw/master/img/5629ae35-fb9d-4169-8f12-4ec7bf4b1bba.png)
    
    image-20211002141739664
    
4.  个人csdn
    
    https://blog.csdn.net/weixin\_39246554?spm=1010.2135.3001.5421
    
    ![image-20211002092344616](https://files.mdnice.com/user/20418/a904f524-a005-4d3c-9394-d01de438a85a.png)
    
    image-20211002092344616
    

## 最后

 好了，关于Traefik 高级配置1实验就到这里了，感谢大家阅读，最后贴上我女神的photo，祝大家生活快乐，每天都过的有意义哦，我们下期见！

![image-20220112195921507](https://files.mdnice.com/user/20418/675891f7-2eb3-4551-83f4-3062056aa6a0.png)

image-20220112195921507
