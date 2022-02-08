[![](https://s2.51cto.com/oss/202111/10/add94eedb3517d08c454a406b698edda.jpg?x-oss-process=image/format,jpg,image/resize,w_651)](https://s2.51cto.com/oss/202111/10/add94eedb3517d08c454a406b698edda.jpg?x-oss-process=image/format,jpg,image/resize,w_651)

大家好，我是乔克。

提到Traefik，有些人可能并不熟悉，但是提到Nginx，应该都耳熟能详。

暂且我们把Traefik当成和Nginx差不多的一类软件，待读完整篇文章，你就会对Traefik有不一样的认识。

本文主要带大家对Traefik有一个全面的认识，我将从下面几个方面作介绍。

[![](https://s3.51cto.com/oss/202111/10/c1332c85a76d6999162937b5d3f10e89.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s3.51cto.com/oss/202111/10/c1332c85a76d6999162937b5d3f10e89.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

本文基于Traefik 2.5.3进行介绍。

## 什么是Traefik

Traefik是一个开源的边缘路由网关，它简单易用并且功能全面。官方【1】的介绍是：Traefik is an \[open-source\](https://github.com/traefik/traefik) \_Edge Router\_ that makes publishing your services a fun and easy experience.

Traefik原生支持多种集群，如Kubernetes、Docker、Docker Swarm、AWS、Mesos、Marathon等；并且可以同时处理许多集群。

[![](https://s6.51cto.com/oss/202111/10/98aa36bc6341e5dd9e48b8e4ef2f1954.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s6.51cto.com/oss/202111/10/98aa36bc6341e5dd9e48b8e4ef2f1954.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

## Traefik的核心概念及能力

Traefik是一个边缘路由器，它会拦截外部的请求并根据逻辑规则选择不同的操作方式，这些规则决定着这些请求到底该如何处理。Traefik提供自动发现能力，会实时检测服务，并自动更新路由规则。

[![](https://s5.51cto.com/oss/202111/10/ad012ad170058a5163b9ca9d8459c59f.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s5.51cto.com/oss/202111/10/ad012ad170058a5163b9ca9d8459c59f.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

从上图可知，请求首先会连接到entrypoints，然后分析这些请求是否与定义的rules匹配，如果匹配，则会通过一系列middlewares，再到对应的services上。

这就涉及到以下几个重要的核心组件。

-   Providers
-   Entrypoints
-   Routers
-   Services
-   Middlewares

**Providers**

Providers是基础组件，Traefik的配置发现是通过它来实现的，它可以是协调器，容器引擎，云提供商或者键值存储。

Traefik通过查询Providers的API来查询路由的相关信息，一旦检测到变化，就会动态的更新路由。

**Entrypoints**

Entrypoints是Traefik的网络入口，它定义接收请求的接口，以及是否监听TCP或者UDP。

**Routers**

Routers主要用于分析请求，并负责将这些请求连接到对应的服务上去，在这个过程中，Routers还可以使用Middlewares来更新请求，比如在把请求发到服务之前添加一些Headers。

**Services**

Services负责配置如何到达最终将处理传入请求的实际服务。

**Middlewares**

Middlewares用来修改请求或者根据请求来做出一些判断(authentication, rate limiting, headers, ...)，中间件被附件到路由上，是一种在请求发送到你的服务之前(或者在服务的响应发送到客户端之前)调整请求的一种方法。

## 部署Traefik

Traefik的部署方式有多种，这里主要采用Helm方式进行部署管理。

**Helm部署**

环境：kubernetes: 1.22.3 helm: 3.7.1

1、添加traefik helm仓库

1.  $ helm repo add traefik https://helm.traefik.io/traefik 
2.  $ helm repo update 

2、将traefik包下载到本地进行管理

1.  $ helm  search repo traefik 
2.  NAME CHART VERSION APP VERSION DESCRIPTION 
3.  traefik/traefik 10.6.0        2.5.3       A Traefik based Kubernetes ingress controller 
4.  $ helm pull traefik/traefik 

3、部署Traefik

默认的value.yaml\[2\]配置文件配置比较多，可能需要花一定的时间去梳理，不过根据相关的注释还是可以很快的理解。

这里自定义一个配置文件my-value.yaml，如下：

1.  service: 
2.   type: NodePort 

4.  ingressRoute: 
5.   dashboard: 
6.   enabled: false 
7.  ports: 
8.   traefik: 
9.   port: 9000 
10.   expose: true 
11.   web: 
12.   port: 8000 
13.   expose: true 
14.   websecure: 
15.   port: 8443 
16.   expose: true 
17.  persistence: 
18.   enabled: true 
19.   name: data 
20.   accessMode: ReadWriteOnce 
21.   size: 5G 
22.   storageClass: "openebs-hostpath" 
23.   path: /data 
24.  additionalArguments: 
25.   - "--serversTransport.insecureSkipVerify=true" 
26.   - "--api.insecure=true" 
27.   - "--api.dashboard=true" 

进行部署，命令如下：

1.  $ kubectl create ns traefik-ingress 

3.  $ helm install traefik -n traefik-ingress -f my-value.yaml . 

这里部署使用的是默认的value.yaml\[2\]配置文件。

然后可以看到部署结果，如下：

1.  # kubectl get all -n traefik-ingress 
2.  NAME READY   STATUS    RESTARTS   AGE 
3.  pod/traefik-77ff894bb5-qqszd   1/1     Running   0          6m26s 

5.  NAME TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                                     AGE 
6.  service/traefik   NodePort   10.108.170.22   <none>        9000:32271/TCP,80:31728/TCP,443:30358/TCP   6m26s 

8.  NAME READY   UP-TO\-DATE AVAILABLE   AGE 
9.  deployment.apps/traefik   1/1     1            1           6m26s 

11.  NAME DESIRED CURRENT READY   AGE 
12.  replicaset.apps/traefik-77ff894bb5   1         1         1       6m26s 

然后可以通过NodePort访问Dashboard页面，如下：

[![](https://s2.51cto.com/oss/202111/10/b94fd5630ddbf0473d54b72eb4e6a54f.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s2.51cto.com/oss/202111/10/b94fd5630ddbf0473d54b72eb4e6a54f.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

## 使用Traefik

### 创建第一个路由规则

我们上面访问Dashboard是采用的NodePort的方式，既然已经把Traefik部署好了，为什么不使用路由网关的方式呢?

下面我们就来创建第一个路由网关来访问Dashboard。

Traefik创建路由规则有多种方式，比如：

-   原生Ingress写法
-   使用CRD IngressRoute方式
-   使用GatewayAPI的方式

这里暂时介绍前面两种方式，关于GatewayAPI的方式在后续进行介绍。

### 原生Ingress路由规则

原生Ingress的路由规则，写法就比较简单，如下：

1.  # cat traefik-ingress.yaml 
2.  apiVersion: networking.k8s.io/v1 
3.  kind: Ingress 
4.  metadata: 
5.   name: traefik-dashboard-ingress 
6.   annotations: 
7.   kubernetes.io/ingress.class: traefik 
8.   traefik.ingress.kubernetes.io/router.entrypoints: web 
9.  spec: 
10.   rules: 
11.   - host: traefik-web.coolops.cn 
12.   http: 
13.   paths: 
14.   - pathType: Prefix 
15.   path: / 
16.   backend: 
17.   service: 
18.   name: traefik 
19.   port: 
20.   number: 9000 

创建路由规则，命令如下：

1.  # kubectl apply -f traefik-ingress.yaml -n traefik-ingress 

3.  ingress.networking.k8s.io/traefik-dashboard-ingress created 

现在就可以通过域名http://traefik-web.coolops.cn:31728/dashboard/#/ 进行访问了(31728是80端口的映射端口)，如下：

[![](https://s5.51cto.com/oss/202111/10/ff3c305f1a2d1a249c4683e9fe4e614a.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s5.51cto.com/oss/202111/10/ff3c305f1a2d1a249c4683e9fe4e614a.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

### 使用CRD方式配置路由规则

在早期版本，Traefik仅提供kubernetes ingress方式配置路由规则，社区认为采用开发一个自定义CRD的类型能够更好的提供Kubernetes的访问配置【3】。

IngressRoute的配置方式也比较简单，如下：

1.  # cat traefik-ingressRoute.yaml 
2.  apiVersion: traefik.containo.us/v1alpha1 
3.  kind: IngressRoute 
4.  metadata: 
5.   name: traefik-dashboard-route 
6.  spec: 
7.   entryPoints: 
8.   - web 
9.   routes: 
10.   - match: Host(\`traefik-web2.coolops.cn\`) 
11.   kind: Rule 
12.   services: 
13.   - name: traefik 
14.   port: 9000 

部署命令如下：

1.  # kubectl apply -f traefik-ingressRoute.yaml -n traefik-ingress 
2.  ingressroute.traefik.containo.us/traefik-dashboard-route created 

然后就可以通过http://traefik-web2.coolops.cn:31728/dashboard/#/ 进行访问了。

[![](https://s5.51cto.com/oss/202111/10/f7cfbcbcf61260b91ecd5abf462bf6ac.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s5.51cto.com/oss/202111/10/f7cfbcbcf61260b91ecd5abf462bf6ac.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

### 暴露HTTP服务

首先，部署一个简单的whoami\[4\]应用，YAML文件如下：

2.  apiVersion: v1 
3.  kind: Pod 
4.  metadata: 
5.   name: whoami 
6.   labels: 
7.   app: whoami 
8.  spec: 
9.   containers: 
10.   - name: whoami 
11.   image: traefik/whoami:latest 
12.   ports: 
13.   - containerPort: 80 

15.  apiVersion: v1 
16.  kind: Service 
17.  metadata: 
18.   name: whoami 
19.  spec: 
20.   ports: 
21.   - port: 80 
22.   protocol: TCP 
23.   targetPort: 80 
24.   selector: 
25.   app: whoami 
26.   type: ClusterIP 

部署成功后，创建一个路由规则，使外部可以访问。

1.  # cat ingressroute.yaml 
2.  apiVersion: traefik.containo.us/v1alpha1 
3.  kind: IngressRoute 
4.  metadata: 
5.   name: whoami-route 
6.  spec: 
7.   entryPoints: 
8.   - web 
9.   routes: 
10.   - match: Host(\`whoami.coolops.cn\`) 
11.   kind: Rule 
12.   services: 
13.   - name: whoami 
14.   port: 80 

创建过后，就可以进行访问了，如下：

[![](https://s3.51cto.com/oss/202111/10/9c896e47505abc58bc077ef8b505013d.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s3.51cto.com/oss/202111/10/9c896e47505abc58bc077ef8b505013d.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

### 暴露HTTPS服务

上面的whoami应用，是通过HTTP进行访问的，如果要通过HTTPS进行访问，应该如何配置呢?

Traefik支持HTTPS和TLS，对于证书可以选择自有证书，也可以使用Let's Encrypt【5】自动生成证书。这里会分别介绍这两种方式。

### **自有证书配置HTTPS**

现在公司基本都会自己购买更安全的证书，那对于自有证书配置HTTPS就会使用更加频繁，这里主要介绍这种配置方式。

**1、申请或者购买证书**

我这里是在腾讯云申请的免费证书。

[![](https://s6.51cto.com/oss/202111/10/d4985f6279312eed242e53597425ed40.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s6.51cto.com/oss/202111/10/d4985f6279312eed242e53597425ed40.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

然后下载对应的证书，并上传到服务器上。

**2、将证书文件保存为Secret**

1.  # kubectl create secret tls whoami-tls 

**3、创建IngressRoute对象，使其可以通过TLS访问**

1.  # cat ingressroutetls.yaml 
2.  apiVersion: traefik.containo.us/v1alpha1 
3.  kind: IngressRoute 
4.  metadata: 
5.   name: whoami-route-tls 
6.  spec: 
7.   entryPoints: 
8.   - websecure 
9.   routes: 
10.   - match: Host(\`whoami.coolops.cn\`) 
11.   kind: Rule 
12.   services: 
13.   - name: whoami 
14.   port: 80 
15.   tls: 
16.   secretName: whoami-tls 

创建完成后，就可以通过https://whoami.coolops.cn:30358/ 进行访问了(30358是443映射出来的端口)。图片

### 自动生成HTTPS证书

Traefik除了使用自有证书外，还支持Let's Encrypt自动生成证书【6】。

要使用Let's Encrypt自动生成证书，需要使用ACME。需要在静态配置中定义 "证书解析器"，Traefik负责从ACME服务器中检索证书。

然后，每个 "路由器 "被配置为启用TLS，并通过tls.certresolver配置选项与一个证书解析器关联。

Traefik的ACME验证方式主要有以下三种：

-   tlsChallenge
-   httpChallenge
-   dnsChallenge

如果使用tlsChallenge，则要求Let's Encrypt到 Traefik 443 端口必须是可达的。如果使用httpChallenge，则要求Let's Encrypt到 Traefik 80端口必须是可达的。如果使用dnsChallenge，则需要对应的providers\[7\]。

但是我们上面部署Traefik的时候并没有把80和443端口暴露出来，要测试tlsChallenge和httpChallenge的话就必须暴露，下面我们更改一下my-value.yaml，如下：

1.  service: 
2.   type: NodePort 

4.  ingressRoute: 
5.   dashboard: 
6.   enabled: false 
7.  ports: 
8.   traefik: 
9.   port: 9000 
10.   expose: true 
11.   web: 
12.   port: 8000 
13.   hostPort: 80 
14.   expose: true 
15.   websecure: 
16.   port: 8443 
17.   hostPort: 443 
18.   expose: true 
19.  persistence: 
20.   enabled: true 
21.   name: data 
22.   accessMode: ReadWriteOnce 
23.   size: 5G 
24.   storageClass: "openebs-hostpath" 
25.   path: /data 
26.  additionalArguments: 
27.   - "--serversTransport.insecureSkipVerify=true" 
28.   - "--api.insecure=true" 
29.   - "--api.dashboard=true" 

然后重新更新一下Traefik，命令如下：

1.  helm upgrade traefik -n traefik-ingress -f my-value.yaml . 

现在我们就可以直接通过80或443端口进行访问了。

**1、tlsChallenge**

上面已经介绍过，要使用tlsChallenge，必须能访问入口的443端口，现在我们入口已经放开，接下来就修改Traefik的my-value.yaml配置，如下：

1.  ...... 
2.  deployment: 
3.   initContainers: 
4.   - name: volume-permissions 
5.   image: busybox:1.31.1 
6.   command: \["sh", "-c", "chmod -Rv 600 /data/\*"\] 
7.   volumeMounts: 
8.   - name: data 
9.   mountPath: /data 
10.  additionalArguments: 
11.   - "--serversTransport.insecureSkipVerify=true" 
12.   - "--api.insecure=true" 
13.   - "--api.dashboard=true" 
14.   - "--certificatesresolvers.coolops.acme.email=coolops@163.com" 
15.   - "--certificatesresolvers.coolops.acme.storage=/data/acme.json" 
16.   - "--certificatesresolvers.coolops.acme.tlschallenge=true" 

PS：这里需要将/data目录权限给更改一下，默认是0660，权限太大是不允许的。

然后我们创建一个ingressRoute，如下：

1.  # cat ingressrouteautotls.yaml 
2.  apiVersion: traefik.containo.us/v1alpha1 
3.  kind: IngressRoute 
4.  metadata: 
5.   name: whoami-route-auto-tls 
6.  spec: 
7.   entryPoints: 
8.   - websecure 
9.   routes: 
10.   - match: Host(\`whoami3.coolops.cn\`) 
11.   kind: Rule 
12.   services: 
13.   - name: whoami 
14.   port: 80 
15.   tls: 
16.   certResolver: coolops 

这时候我们访问https://whoami3.coolops.cn是可以正常使用证书的，如下：

[![](https://s4.51cto.com/oss/202111/10/86e8f006750b0851b98df0c3b356e4b8.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s4.51cto.com/oss/202111/10/86e8f006750b0851b98df0c3b356e4b8.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

**2、httpChallenge**

下面再使用httpChallenge进行测试，修改my-value.yaml配置文件如下：

1.  ...... 
2.  deployment: 
3.   initContainers: 
4.   - name: volume-permissions 
5.   image: busybox:1.31.1 
6.   command: \["sh", "-c", "chmod -Rv 600 /data/\*"\] 
7.   volumeMounts: 
8.   - name: data 
9.   mountPath: /data 
10.  additionalArguments: 
11.   - "--serversTransport.insecureSkipVerify=true" 
12.   - "--api.insecure=true" 
13.   - "--api.dashboard=true" 
14.   - "--certificatesresolvers.coolops.acme.email=coolops@163.com" 
15.   - "--certificatesresolvers.coolops.acme.storage=/data/acme.json" 
16.   - "--certificatesresolvers.coolops.acme.httpchallenge=true" 
17.   - "--certificatesresolvers.coolops.acme.httpchallenge.entrypoint=web" 

更新Traefik过后，然后再创建一个ingressRoute进行测试，YAML文件如下：

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami-route-auto-tls-http 
5.  spec: 
6.   entryPoints: 
7.   - websecure 
8.   routes: 
9.   - match: Host(\`whoami4.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 
14.   tls: 
15.   certResolver: coolops 

然后使用https://whoami4.coolops.cn，效果如下：

[![](https://s3.51cto.com/oss/202111/10/8d9432d910fa7856934856f86fccb403.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s3.51cto.com/oss/202111/10/8d9432d910fa7856934856f86fccb403.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

**3、dnsChallenge**

dnsChallenge在使用上相对比较麻烦，因为需要配置对应的provider，不过它可以生成通配符证书，这里以阿里云DNS【8】为例。

使用阿里DNS的前提是您的域名是在阿里云上面，不然在签署证书的时候会报错，如下：

1.  Unable to obtain ACME certificate for domains \\"\*.coolops.cn\\" : unable to generate a certificate for the domains \[\*.coolops.cn\]: error: one or more domains had a problem:\\n\[\*.coolops.cn\] \[\*.coolops.cn\] acme: error presenting token: alicloud: zone coolops.cn. not found in AliDNS for domain coolops.cn\\n" providerName=coolops.acme 

使用阿里云的 DNS 校验需要配置3个环境变量：ALICLOUD\_ACCESS\_KEY、ALICLOUD\_SECRET\_KEY、ALICLOUD\_REGION\_ID，分别对应我们平时开发阿里云应用的时候的密钥，可以登录阿里云后台获取，由于这是比较私密的信息，所以我们用 Secret 对象来创建：

1.  $ kubectl create secret generic traefik-alidns 

修改Traefik的my-value.yaml，如下：

1.  ...... 
2.  additionalArguments: 
3.   - "--serversTransport.insecureSkipVerify=true" 
4.   - "--api.insecure=true" 
5.   - "--api.dashboard=true" 
6.   - "--certificatesresolvers.coolops.acme.email=coolops@163.com" 
7.   - "--certificatesresolvers.coolops.acme.storage=/data/acme.json" 
8.   - "--certificatesresolvers.coolops.acme.dnschallenge=true" 
9.   - "--certificatesResolvers.coolops.acme.dnsChallenge.provider=alidns" 
10.  envFrom: 
11.   - secretRef: 
12.   name: traefik-alidns 

更新Traefik过后，然后再创建一个ingressRoute进行测试，YAML文件如下(由于coolops.cn不在阿里云上，所以换了一个域名)：

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami-route-auto-tls-dns 
5.  spec: 
6.   entryPoints: 
7.   - websecure 
8.   routes: 
9.   - match: Host(\`whoami6.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 
14.   tls: 
15.   certResolver: coolops 
16.   domains: 
17.   - main: "\*.coolops.cn" 

然后访问域名后，就可以看到证书签署成功，如下：

[![](https://s4.51cto.com/oss/202111/10/d63a8bcbba426044325dce70494a942e.jpg?x-oss-process=image/format,jpg)](https://s4.51cto.com/oss/202111/10/d63a8bcbba426044325dce70494a942e.jpg?x-oss-process=image/format,jpg)

### 中间件的使用

在介绍Traefik的核心概念的时候有提到一个请求匹配Rules后，会经过一系列的Middleware，再到具体的Services上。这个Middleware是什么呢?

[![](https://s5.51cto.com/oss/202111/10/9d10709187483ff38c780f1378e631f0.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s5.51cto.com/oss/202111/10/9d10709187483ff38c780f1378e631f0.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

Middleware是Traefik 2.0之后新增的功能，用户可以根据不通的需求来选择不同的Middleware来满足服务，提高了定制化的能力。

Traefik内置了很多不同功能的Middleware，主要是针对HTTP和TCP，HTTP占大部分\[9\]，这里挑选几个比较常用的进行演示。

### 强制跳转HTTPS

强制跳转HTTPS是经常会配置的功能，这里还是以上没的whoami应用为例。

**1、创建一个HTTPS的ingressRoute**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami-route-auto-tls 
5.  spec: 
6.   entryPoints: 
7.   - websecure 
8.   routes: 
9.   - match: Host(\`whoami3.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 
14.   tls: 
15.   certResolver: coolops 

**2、定义一个跳转HTTPS的中间件**

这里会用到RedirectScheme的内置中间件，配置如下：

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: Middleware 
3.  metadata: 
4.   name: redirect-https-middleware 
5.  spec: 
6.   redirectScheme: 
7.   scheme: https 

**3、定义一个HTTP的ingressRoute，并使用Middleware**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami3-route 
5.  spec: 
6.   entryPoints: 
7.   - web 
8.   routes: 
9.   - match: Host(\`whoami3.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 
14.   middlewares: 
15.   - name: redirect-https-middleware 

然后访问http://whoami3.coolops.cn就会被强制跳转到https://whoami3.coolops.cn。

[![](https://s6.51cto.com/oss/202111/10/7bb5103f90f05b4250a1ab7e45167481.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s6.51cto.com/oss/202111/10/7bb5103f90f05b4250a1ab7e45167481.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

### 去除请求路径前缀

有时候会遇到这么一个需求：

-   只有一个域名
-   相通过这个域名访问不同的应用

这种需求是非常常见的，在NGINX中，我们可以配置多个Location来定制规则，使用Traefik也可以这么做。

但是定制不同的前缀后，由于应用本身并没有这些前缀，导致请求返回404，这时候我们就需要对请求的path进行处理，还是以whoami应用为例。

**1、创建一个带前缀的ingressRoute**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami7-route 
5.  spec: 
6.   entryPoints: 
7.   - web 
8.   routes: 
9.   - match: Host(\`whoami7.coolops.cn\`) && PathPrefix('/coolops') 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 

我们现在访问是会返回404状态的。

[![](https://s2.51cto.com/oss/202111/10/9f57a24ae84535a597cfcc01a1c020bf.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s2.51cto.com/oss/202111/10/9f57a24ae84535a597cfcc01a1c020bf.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

**2、定义去除前缀的中间件**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: Middleware 
3.  metadata: 
4.   name: prefix-coolops-url-middleware 
5.  spec: 
6.   stripPrefix: 
7.   prefixes: 
8.   - /coolops 

**3、修改上面的ingressRoute，应用中间件**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: whoami7-route 
5.  spec: 
6.   entryPoints: 
7.   - web 
8.   routes: 
9.   - match: Host(\`whoami7.coolops.cn\`) && PathPrefix('/coolops') 
10.   kind: Rule 
11.   services: 
12.   - name: whoami 
13.   port: 80 
14.   middlewares: 
15.   - name: prefix-coolops-url-middleware 

然后就可以正常访问了。

### 添加IP白名单

在工作中，有一些URL并不希望对外暴露，比如prometheus、grafana等的url，这时候我们希望通过白名单IP来达到需求，就可以使用Traefik中的ipWhiteList中间件来完成。

**1、定义白名单IP的中间件**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: Middleware 
3.  metadata: 
4.   name: ip-white-list-middleware 
5.  spec: 
6.   ipWhiteList: 
7.   sourceRange: 
8.   - 127.0.0.1/32 
9.   - 192.168.100.180 

然后将中间件应用到对应的Rules上，就可以完成白名单功能。

除了上面的功能，Traefik内置Middleware还支持很多其他功能，比如限流、认证鉴权等，可以通过引用【9】进行查看。

### 暴露TCP服务

Traefik 2.0支持暴露TCP，这里以Redis为例。

**1、部署一个Redis服务**

1.  apiVersion: apps/v1 
2.  kind: Deployment 
3.  metadata: 
4.   name: redis 
5.  spec: 
6.   selector: 
7.   matchLabels: 
8.   app: redis 
9.   template: 
10.   metadata: 
11.   labels: 
12.   app: redis 
13.   spec: 
14.   containers: 
15.   - name: redis 
16.   image: redis:5.0.14 
17.   ports: 
18.   - containerPort: 6379 
19.   protocol: TCP 

21.  apiVersion: v1 
22.  kind: Service 
23.  metadata: 
24.   name: redis 
25.  spec: 
26.   ports: 
27.   - port: 6379 
28.   targetPort: 6379 
29.   selector: 
30.   app: redis 

**2、暴露Redis端口**

暴露TCP端口使用的是SNI【10】，而SNI又是依赖TLS的，所以我们需要配置证书才行，但是如果没有证书的话，我们可以使用通配符\*进行配置。

**(1)添加一个redis的entrypoints**

修改Traefik的部署文件my-value.yaml，添加如下内容：

1.  ports: 
2.   traefik: 
3.   port: 9000 
4.   expose: true 
5.   web: 
6.   port: 8000 
7.   hostPort: 80 
8.   expose: true 
9.   websecure: 
10.   port: 8443 
11.   hostPort: 443 
12.   expose: true 
13.   redis: 
14.   port: 6379 
15.   containerPort: 6379 
16.   hostPort: 6379 
17.  additionalArguments: 
18.   - "--entryPoints.redis.address=:6379" 
19.   - "--serversTransport.insecureSkipVerify=true" 
20.   - "--api.insecure=true" 
21.   - "--api.dashboard=true" 
22.   - "--certificatesresolvers.coolops.acme.email=coolops@163.com" 
23.   - "--certificatesresolvers.coolops.acme.storage=/data/acme.json" 
24.   - "--certificatesresolvers.coolops.acme.httpchallenge=true" 
25.   - "--certificatesresolvers.coolops.acme.httpchallenge.entrypoint=web" 

在启动参数中添加--entryPoints.redis.address=:27017用来指定entrypoint。

**(2)创建ingressRoute进行对外暴露**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRouteTCP 
3.  metadata: 
4.   name: redis-traefik-tcp 
5.  spec: 
6.   entryPoints: 
7.   - redis 
8.   routes: 
9.   - match: HostSNI(\`\*\`) 
10.   services: 
11.   - name: redis 
12.   port: 6379 

然后可以使用客户端工具进行Redis的操作了。

1.  # redis-cli -h redis.coolops.cn 
2.  redis.coolops.cn:6379> set a b 
3.  OK 
4.  redis.coolops.cn:6379> get a 
5.  "b" 
6.  redis.coolops.cn:6379> 

### 灰度发布

Traefik2.0 以后的一个更强大的功能就是灰度发布，灰度发布我们有时候也会称为金丝雀发布(Canary)，主要就是让一部分测试的服务也参与到线上去，经过测试观察看是否符号上线要求。

假设一个应用现在运行着V1版本，新的V2版本需要上线，这时候我们需要在集群中部署好V2版本，然后通过Traefik提供的带权重的轮询(WRR)来实现该功能。

**1、部署appv1、appv2应用**

2.  apiVersion: apps/v1 
3.  kind: Deployment 
4.  metadata: 
5.   name: appv1 
6.  spec: 
7.   selector: 
8.   matchLabels: 
9.   app: appv1 
10.   template: 
11.   metadata: 
12.   labels: 
13.   use: test 
14.   app: appv1 
15.   spec: 
16.   containers: 
17.   - name: nginx 
18.   image: nginx 
19.   imagePullPolicy: IfNotPresent 
20.   lifecycle: 
21.   postStart: 
22.   exec: 
23.   command:  \["/bin/sh", "-c", "echo Hello v1 > /usr/share/nginx/html/index.html"\] 
24.   ports: 
25.   - containerPort: 80 
26.   name: portv1 

30.  apiVersion: v1 
31.  kind: Service 
32.  metadata: 
33.   name: appv1 
34.  spec: 
35.   selector: 
36.   app: appv1 
37.   ports: 
38.   - name: http 
39.   port: 80 
40.   targetPort: portv1 

**appv2.yaml**

2.  apiVersion: apps/v1 
3.  kind: Deployment 
4.  metadata: 
5.   name: appv2 
6.  spec: 
7.   selector: 
8.   matchLabels: 
9.   app: appv2 
10.   template: 
11.   metadata: 
12.   labels: 
13.   use: test 
14.   app: appv2 
15.   spec: 
16.   containers: 
17.   - name: nginx 
18.   image: nginx 
19.   imagePullPolicy: IfNotPresent 
20.   lifecycle: 
21.   postStart: 
22.   exec: 
23.   command:  \["/bin/sh", "-c", "echo Hello v2 > /usr/share/nginx/html/index.html"\] 
24.   ports: 
25.   - containerPort: 80 
26.   name: portv2 

30.  apiVersion: v1 
31.  kind: Service 
32.  metadata: 
33.   name: appv2 
34.  spec: 
35.   selector: 
36.   app: appv2 
37.   ports: 
38.   - name: http 
39.   port: 80 
40.   targetPort: portv2 

**2、创建TraefikService**

在 Traefik2.1以后新增了一个 TraefikService的 CRD 资源，我们可以直接利用这个对象来配置 WRR。

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: TraefikService 
3.  metadata: 
4.   name: app-wrr 
5.  spec: 
6.   weighted: 
7.   services: 
8.   - name: appv1 
9.   weight: 3 
10.   port: 80 
11.   kind: Service 
12.   - name: appv2 
13.   weight: 1 
14.   port: 80 
15.   kind: Service 

**3、创建ingressRoute**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: app-ingressroute-canary 
5.  spec: 
6.   entryPoints: 
7.   - web 
8.   routes: 
9.   - match: Host(\`app.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: app-wrr 
13.   kind: TraefikService 

注意：这里配置的不是Service类型，而是TraefikService。

然后就可以通过访问http://app.coolops.cn来校验结果。

[![](https://s5.51cto.com/oss/202111/10/3f7dc1bb45539ec0db0fe897b12e91eb.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s5.51cto.com/oss/202111/10/3f7dc1bb45539ec0db0fe897b12e91eb.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

待V2测试没问题后，就可以将流量全切到V2了。

### 流量复制

在Traefik 2.0之后还引入了镜像服务\[11\]，它可以将请求的流量按规则复制一份发送给其他服务，并且会忽略这部分请求的响应。

这个功能在做一些压测或者问题复现的时候还是很有用。

这里依然以上没的appv1和appv2为例进行简单的演示。

**1、创建TraefikService，定义复制规则**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: TraefikService 
3.  metadata: 
4.   name: app-mirror 
5.  spec: 
6.   mirroring: 
7.   name: appv1 
8.   port: 80 
9.   mirrors: 
10.   - name: appv2 
11.   percent: 50 
12.   port: 80 

上面定义的意思是将请求到appv1的50%请求复制到appv2。

**2、创建ingressRoute，进行效果演示**

1.  apiVersion: traefik.containo.us/v1alpha1 
2.  kind: IngressRoute 
3.  metadata: 
4.   name: app-ingressroute-mirror 
5.  spec: 
6.   entryPoints: 
7.   - web 
8.   routes: 
9.   - match: Host(\`mirror.coolops.cn\`) 
10.   kind: Rule 
11.   services: 
12.   - name: app-mirror 
13.   kind: TraefikService 

然后进行测试，效果如下：

[![](https://s3.51cto.com/oss/202111/10/d72089b3724df7fb82a7184921d7077c.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s3.51cto.com/oss/202111/10/d72089b3724df7fb82a7184921d7077c.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

发了4次请求，appv1可以正常接收4次请求，appv2可以收到2次请求，收到的响应是appv1的，并没有appv2的响应。

### Kubernetes Gateway API

我们在上面创建路由规则要么使用ingress，要么使用ingressRoute，其实在Traefik 2.4以后支持Kubernetes Gateway API\[12\]提供的CRD方式创建路由规则。

**什么是Gateway API?**

Gateway API【13】是一个由SIG-NETWORK社区管理的开源项目。它是Kubernetes中服务网络模型的资源集合。这些资源(GatewayClass、Gateway、HTTPRoute、TCPRoute、Service)旨在通过表达式的、可扩展的和面向角色的接口来发展Kubernetes服务网络，这些接口由许多供应商实现，并得到了广泛的行业支持。

[![](https://s2.51cto.com/oss/202111/10/4d681e5570171c7358a9b577870d14d8.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s2.51cto.com/oss/202111/10/4d681e5570171c7358a9b577870d14d8.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

-   GatewayClass：GatewayClass 是基础结构提供程序定义的群集范围的资源。此资源表示可以实例化的网关类。一般该资源是用于支持多个基础设施提供商用途的，这里我们只部署一个即可。
-   Gateway：Gateway 与基础设施配置的生命周期是 1:1。当用户创建网关时，GatewayClass 控制器会提供或配置一些负载平衡基础设施。
-   HTTPRoute：HTTPRoute 是一种网关 API 类型，用于指定 HTTP 请求从网关侦听器到 API 对象(即服务)的路由行为。

### 使用Gateway API

**1、安装Gateway API 的CRD**

Traefik Gateway provider 仅支持 v0.3.0 (v1alpha1)

1.  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" \\ 
2.  | kubectl apply -f - 

**2、创建rbac，给traefik授权**

2.  apiVersion: rbac.authorization.k8s.io/v1 
3.  kind: ClusterRole 
4.  metadata: 
5.   name: gateway-role 
6.  rules: 
7.   - apiGroups: 
8.   - "" 
9.   resources: 
10.   - services 
11.   - endpoints 
12.   - secrets 
13.   verbs: 
14.   - get 
15.   - list 
16.   - watch 
17.   - apiGroups: 
18.   - networking.x-k8s.io 
19.   resources: 
20.   - gatewayclasses 
21.   - gateways 
22.   - httproutes 
23.   - tcproutes 
24.   - tlsroutes 
25.   verbs: 
26.   - get 
27.   - list 
28.   - watch 
29.   - apiGroups: 
30.   - networking.x-k8s.io 
31.   resources: 
32.   - gatewayclasses/status 
33.   - gateways/status 
34.   - httproutes/status 
35.   - tcproutes/status 
36.   - tlsroutes/status 
37.   verbs: 
38.   - update 

41.  apiVersion: rbac.authorization.k8s.io/v1 
42.  kind: ClusterRoleBinding 
43.  metadata: 
44.   name: gateway-controller 

46.  roleRef: 
47.   apiGroup: rbac.authorization.k8s.io 
48.   kind: ClusterRole 
49.   name: gateway-role 
50.  subjects: 
51.   - kind: ServiceAccount 
52.   name: traefik 
53.   namespace: traefik-ingress 

**3、Traefik开启gateway api支持**

修改my-value.yaml 文件，如下：

1.  ...... 
2.  additionalArguments: 
3.   - "--entryPoints.redis.address=:6379" 
4.   - "--serversTransport.insecureSkipVerify=true" 
5.   - "--api.insecure=true" 
6.   - "--api.dashboard=true" 
7.   - "--certificatesresolvers.coolops.acme.email=coolops@163.com" 
8.   - "--certificatesresolvers.coolops.acme.storage=/data/acme.json" 
9.   - "--certificatesresolvers.coolops.acme.httpchallenge=true" 
10.   - "--certificatesresolvers.coolops.acme.httpchallenge.entrypoint=web" 
11.   - "--experimental.kubernetesgateway" 
12.   - "--providers.kubernetesgateway" 

更新Traefik，命令如下：

1.  helm upgrade traefik -n traefik-ingress -f my-value.yaml . 

**4、通过Gateway api的方式暴露traefik dashboard应用**

**(1)创建GatewayClass**

1.  apiVersion: networking.x-k8s.io/v1alpha1 
2.  kind: GatewayClass 
3.  metadata: 
4.   name: traefik 
5.  spec: 
6.   controller: traefik.io/gateway-controller 

**(2)创建gateway**

1.  apiVersion: networking.x-k8s.io/v1alpha1 
2.  kind: Gateway 
3.  metadata: 
4.   name: http-gateway 
5.   namespace: traefik-ingress 
6.  spec: 
7.   gatewayClassName: traefik 
8.   listeners: 
9.   - protocol: HTTP 
10.   port: 8000 
11.   routes: 
12.   kind: HTTPRoute 
13.   namespaces: 
14.   from: All 
15.   selector: 
16.   matchLabels: 
17.   app: traefik 

**(3)创建HTTPRoute**

1.  apiVersion: networking.x-k8s.io/v1alpha1 
2.  kind: HTTPRoute 
3.  metadata: 
4.   name: whoami-gateway-api-route 
5.   namespace: traefik-ingress 
6.   labels: 
7.   app: traefik 
8.  spec: 
9.   hostnames: 
10.   - "traefik1.coolops.cn" 
11.   rules: 
12.   - matches: 
13.   - path: 
14.   type: Prefix 
15.   value: / 
16.   forwardTo: 
17.   - serviceName: traefik 
18.   port: 9000 
19.   weight: 1 

**(4)现在就可以直接在浏览器访问了**

[![](https://s2.51cto.com/oss/202111/10/b19bb803c91b941eb0a2bec35a5ee0ba.jpg?x-oss-process=image/format,jpg,image/resize,w_600)](https://s2.51cto.com/oss/202111/10/b19bb803c91b941eb0a2bec35a5ee0ba.jpg?x-oss-process=image/format,jpg,image/resize,w_600)

GatewayClass在集群中可以只创建一个，然后Gateway和HTTPRoute是需要对应的。

比如我这里要暴露default命名空间下的whoami应用，YAML就应该如下：

1.  apiVersion: networking.x-k8s.io/v1alpha1 
2.  kind: Gateway 
3.  metadata: 
4.   name: http-gateway 
5.  spec: 
6.   gatewayClassName: traefik 
7.   listeners: 
8.   - protocol: HTTP 
9.   port: 8000 
10.   routes: 
11.   kind: HTTPRoute 
12.   namespaces: 
13.   from: All 
14.   selector: 
15.   matchLabels: 
16.   app: whoami 

18.  apiVersion: networking.x-k8s.io/v1alpha1 
19.  kind: HTTPRoute 
20.  metadata: 
21.   name: whoami-gateway-api-route 
22.   labels: 
23.   app: whoami 
24.  spec: 
25.   hostnames: 
26.   - "whoami8.coolops.cn" 
27.   rules: 
28.   - matches: 
29.   - path: 
30.   type: Prefix 
31.   value: / 
32.   forwardTo: 
33.   - serviceName: whoami 
34.   port: 80 
35.   weight: 1 

## 最后

Traefik是一个功能比较强大的边缘网关，基本能满足绝大部分的场景需求，而且还有Mesh等工具，比较好用，有兴趣的朋友可以到官网\[14\]进行学习，也欢迎交流。

**引用**

\[1\] https://doc.traefik.io/traefik/

\[2\] https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml

\[3\] https://doc.traefik.io/traefik/providers/kubernetes-crd/

\[4\] https://github.com/traefik/whoami

\[5\] https://letsencrypt.org/zh-cn/

\[6\] https://doc.traefik.io/traefik/https/acme/

\[7\] https://doc.traefik.io/traefik/https/acme/#tlschallenge

\[8\] https://go-acme.github.io/lego/dns/alidns/

\[9\] https://doc.traefik.io/traefik/middlewares/http/overview/

\[10\] https://doc.traefik.io/traefik/routing/routers/#configuring-tcp-routers

\[11\] https://doc.traefik.io/traefik/routing/services/#mirroring-service

\[12\] https://doc.traefik.io/traefik/providers/kubernetes-gateway/

\[13\] https://gateway-api.sigs.k8s.io/

\[14\] https://traefik.io/

【编辑推荐】

【责任编辑：[武晓燕](mailto:sunsj@51cto.com) TEL：（010）68476606】

[点赞 0](https://network.51cto.com/art/202111/689466.htm###)