---
title: drone升级到2.0
date: 2021-08-24 16:07:48
tags:
- drone
- ci 
categories: 
- devops
---

## 前言

提过hexo来记录日志，不用每天构建，来一个devops(drone ci+gitea+nginx)的网站，美美的

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824163110820.png" alt="image-20210824163110820" style="zoom:50%;" />

<!--more-->

___

## Traefik

Traefik 是一款开源的反向代理与负载均衡工具，很多人会拿它和Nginx 进行对比，其实个人觉得两者各有千秋。像我使用时，由于traefik 对静态网站的支持不好，所以还是会配合Nginx 使用。但这也不妨碍它是一款优秀的反向代理工具的事实。

### 配置与启动

Traefik 的配置括静态配置和动态配置两种，静态配置是Traefik自身启动时的配置，需要重启才能生效，动态配置则可以视为被代理服务的配置，修改后不需要重启。无论是动态或静态配置都支持`Cli` 形式和配置文件形式，但配置文件与cli 参数是不能叠加的。

-   静态配置
    
    以在docker-compose 启动Traefik 服务为例，我们可以看下cli 和配置文件的方式：
    
    ```
    services:
      traefik:
        restart: always
        image: traefik:latest
        ports:
          - "80:80"
          - "443:443"
        # command:
        #  - "--providers.docker=true"
        #  - "--providers.docker.exposedbydefault=false"
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - ./acme.json:/acme.json
          - ./traefik/:/etc/traefik # 如果有配置文件了，则command 失效 
      who:
        image: containous/whoami
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoa.rule=Host(`who.nefelibata.art)"
    复制代码
    ```
    
    我们配置了traefik 容器，并把将包含了`traefik.toml`和`dynamic.toml`文件的`./traefik` 目录映射到容器的`/etc/traefik`目录中，traefik 会在启动时读取`/etc/traefik`目录下的`traefik.toml`， 如果想以cli 的方式，则是通过command 将配置参数传入。
    
-   动态配置
    
    -   配置文件形式
        
        首先我们需要在`traefik.toml` 中有如下配置：
        
        ```
        [providers]
          ## ...
          [providers.file]
            filename = "/etc/traefik/dynamic_conf.toml"
            watch = true
        复制代码
        ```
        
        然后在 `dynamic_conf.toml` 中配置`routers`和`services`
        
        ```
        [http.routers]
          [http.routers.https-egg]
            rule = "Host(`egg.nefelibata.art`)"
            service = "egg-service"
            [http.routers.https-egg.tls] ## 开启https
               certresolver = "le"
          [http.routers.http-egg]
            rule = "Host(`egg.nefelibata.art`)"
            service = "egg-service"
        
        [http.services]
          [[http.services.egg-service.loadBalancer.servers]]
            url = "http://egg_server:9000"
        复制代码
        ```
        
        `http.routers` 后面跟着的是自定义的名字，没有硬性要求规则，但子级都要在这个名字基础上拓展，如：`http.routers.https-egg`下开启tls 时，用的是 `http.routers.https-egg.tls`
        
        需要注意的是，我们为`egg.nefelibata.art`定义了 两个routers，这是因为，如果设置了`tls`为true，则不再支持http访问，如果希望同时支持`http`和`https`，则需要再定义一个`不同名`的路由
        
    -   Docker labels形式
        
        如果我们不想都在动态配置文件中配置，可以在`traefik.toml` 里面的`providers` 下写入如下配置：
        
        ```
        [providers]
          [providers.docker]
            # 以下均为可选项
            network = "traefik"
            exposedByDefault = false
            defaultRule = "Host(`{{ normalize .Name }}.nefelibata.localhost`)"
            watch = true
          ## ... 其他配置
        复制代码
        ```
        
        以上述的egg 服务为例，将上面的动态配置改为以labels的方式的话，会如下：
        
        ```
        egg_server:
            build: ./egg_server
            expose:
              - "9000"
            networks:
              - default
            labels:
              - "traefik.enable=true"
              - "traefik.http.routes.egg_server.rule=Host(`egg.nefelibata.art`)"
        复制代码
        ```
        
        这时就不再需要配置`services`了，只需要把端口暴露给容器即可。
        
        注意，如果在配置中关闭了`exposedByDefault` 选项，则在其他容器的labels 中如果不定义`traefik.enable=true`的话，该容器服务会被traefik 忽略
        

### 开启Dashboard

Traefik 带有一个Dashboard，如果你想要开启该服务并为其配置一个域名的话，可以以上述的动态配置方式配置，以配置文件形式为例：

```
## traefik.toml
### 其他配置...
[api]
### 其他配置... providers, ping .etc

## dynamic.toml
[http.routers.api]
    rule = "Host(`traefik.nefelibata.art`)"
    service = "api@internal"
    middlewares = ["dashboard-auth"]

[http.middlewares]
   [http.middlewares.dashboard-auth.basicAuth]
   users = [
     "evont: $xxxxxxxxxxx"
   ]
复制代码
```

在`traefik.toml`中开启`api`选项后(或cli 中`--api=true`) ，traefik 会有一个特殊的service 叫`api@internal`，将其配置完成后，一般为了防止别人访问，会进行身份验证，所以加了一个`middlewares`，使用traefik 提供的`basicAuth`中间件，使用`htpasswd` 生成一个用户密钥，注意，比如你的名字叫`evont`，密码是`123456`，最终生成的是`evont:$apr1$bL6G3wl2$HllalTsbNwJ/zhoBMhx541`，打开Dashboard 登录时，填入的密码仍旧是123456而不是密钥串。

配置成功后重启服务，打开该服务的域名，就可以看到登陆界面

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa7d60a28b6a97~tplv-t2oaga2asx-watermark.image)

登陆成功之后就可以进入到管理界面中，看到我们配置的路由规则了。

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa7d691b2336f5~tplv-t2oaga2asx-watermark.image)

### 静态网站支持

Traefik 对静态网站并没有很好的支持（至少我没有找到使用方法），所以我只能搭配Nginx 作为静态网站的服务器，但443和80端口不能同时给两个反向代理工具，所以只能通过Traefik 转发请求给Nginx 的方法，我们通过启动一个Nginx 服务，指定networks让Nginx 和Traefik 处在同一networks 下，然后通过labels 的方式，将限定的域名分配给Nginx 处理即可

```
services:
  nginx:
    restart: always
    image: nginx
    networks:
      - default
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./html:/usr/share/nginx/html/
    labels:
      - traefik.enable=true
      - traefik.http.routers.w3.rule=Host(`www.nefelibata.art`) || Host(`mock.nefelibata.art`)
      - traefik.http.routers.w3.tls=true
      - traefik.http.routers.w3.tls.certresolver=le
      - traefik.http.routers.w3-http.rule=Host(`www.nefelibata.art`) || Host(`mock.nefelibata.art`)

复制代码
```

在Nginx 的`nginx.conf` 文件中，依然使用80端口，根据server\_name 分配静态网站的目录即可

```
http {
  server {
    listen       80;
    server_name  www.nefelibata.art;
    root /usr/share/nginx/html/www1;
    location / {
      index index.html;
    }
  }
  server {
    listen       80;
    server_name  mock.nefelibata.art;
    root /usr/share/nginx/html/www2;
    location / {
      index index.html;
    }
  }
}
复制代码
```

### https 支持（同时支持http）

在前面我们提及到了tls和https，有个`certresolver = "le"`，那这个`le` 是哪里来的呢，网站的证书又是怎么生成的呢？

如果你想要使用`Let's Encrypt`自动生成证书，traefik 为我们提供了很方便的方案，我们只需要在静态配置中使用如下配置:

```
## traefik.toml
### 其他配置...
[certificatesResolvers.le.acme]
  email = "evontgoh@foxmail.com" # 你自己的邮箱
  storage = "acme.json"

  [certificatesResolvers.le.acme.httpChallenge]
    entryPoint = "http"
复制代码
```

并在docker-compose 中配置`volumes`映射一个本地`acme.json`到容器中即可

如果你有自己的证书，你也可以忽略到上述步骤，在`dynamic.toml`中配置

```
[[tls.certificates]]
  certFile = "/path/to/domain.cert"
  keyFile = "/path/to/domain.key"
复制代码
```

这部分可以参考[traefik 的tls 配置](https://link.juejin.cn/?target=https%3A%2F%2Fdocs.traefik.io%2Fhttps%2Ftls%2F "https://docs.traefik.io/https/tls/")

### 版本坑

刚开始配置的时候，网上多数教程都还是基于v1，于是一直配置不成功，后来发现是因为v1 和v2版本差异过大，配置项都不相同，甚至连[traefik 中文文档](https://link.juejin.cn/?target=https%3A%2F%2Fdocs.traefik.cn%2F "https://docs.traefik.cn/") 都还是基于v1的配置，比如在定义路由规则时

```
## v1 规则如下：
[frontends] ## 规定前端进入规则
   [frontends.frontend1]
   backend = "backend1" # 指定后端服务
   [frontends.frontend1.routes]  ## 定义路由
      [frontends.frontend1.routes.route0]
        rule = "Host:test.localhost"  ## 注意，这里写法也变了
[backends] ## 定义后端服务
  [backends.backend1]
    [backends.backend1.servers.server0]
        url = "http://xx.xx.xx.xx:80"
  
## v2 规则弃用了frontend & backend 
[http.routers] ## 用routers 规定路由规则
  [http.routers.router0]
    rule = "Host(`test.localhost`)" ## 写法变了
    service = "my-service"

[http.services]
  [[http.services.my-service.loadBalancer.servers]]
    url = "http://xx.xx.xx.xx:80"
复制代码
```

同时，以上规则在v1 时是定义在`[file]` 字段下的，在v2 时，则是在`[providers]` 下的`[providers.file]` 下定义的且变成了独立的动态配置文件

关于这方面，我建议阅读[官方版本迁移文档](https://link.juejin.cn/?target=https%3A%2F%2Fdocs.traefik.io%2Fmigration%2Fv1-to-v2%2F "https://docs.traefik.io/migration/v1-to-v2/")，并且以官方文档为基准（虽然也写得比较松散，也对英语差的人不是很友好）。

___

## Drone CI

以前一直用Jenkins 这一业界标准的CI 工具，但是一直觉得因为功能太丰富而稍显笨重，而Drone 对Docker、K8s 这些容器环境又有优化，也足够轻便和灵活，如果你在两者中不知如何挑选可以看看[这篇文章](https://link.juejin.cn/?target=https%3A%2F%2Fblog.51cto.com%2F12462495%2F2108263 "https://blog.51cto.com/12462495/2108263")

### OAuth

首先，Drone 只支持Git，以Github 为例，为了拉取代码，你需要先在Github 的[Developer settings](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fsettings%2Fdevelopers "https://github.com/settings/developers")中（你可以用其他的git 仓）新建一个OAuth 应用，填入你的Drone 服务的域名，注意 callback URL 需要填login

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa88d4263a2d3a~tplv-t2oaga2asx-watermark.image)

### 安装

依然是基于服务器所有服务都在Docker 里的理念，在`docker-compose.yml`中新建Drone 服务，很多教程会配置drone-runner 代理客户端(agents) ，但它不是必须的，实际上你可以完全单独使用drone-server 完成服务

```
version: "3"

services:
  drone-server:
    image: drone/drone:latest
    labels:
      - traefik.http.routers.drone.rule=Host(`ci.nefelibata.art`)
      - traefik.enable=true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/docker/:/etc/docker
      - ./drone:/var/lib/drone/ # 注意设置这一目录，用于放置sqlite文件，如果用mysql 或其他数据库，酌情处理
    restart: always
    networks:
      - default
    environment:
      - DRONE_OPEN=TRUE    
      - DRONE_ADMIN=xxx
      - DRONE_USER_CREATE=username:xxx,admin:true
      - DRONE_DATABASE_DATASOURCE=/var/lib/drone/drone.sqlite # 指向该目录
      - DRONE_DATABASE_DRIVER=sqlite3 # 数据库引擎
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
      - DRONE_RPC_PROTO=${DRONE_RPC_PROTO}
      - DRONE_AGENTS_DISABLED=true 
      - DRONE_GITHUB_CLIENT_ID=${DRONE_GITHUB_CLIENT_ID}
      - DRONE_GITHUB_CLIENT_SECRET=${DRONE_GITHUB_CLIENT_SECRET}
      - DRONE_SERVER_HOST=${DRONE_SERVER_HOST}
      - DRONE_SERVER_PROTO=${DRONE_SERVER_PROTO}
networks:
  default:
    external:
      name: traefik
复制代码
```

在配置中，为了不希望我们的一些密钥之类的暴露出去，我们可以将这部分变量写入`.env` 文件中，docker 会读取同目录的这一文件的变量写入上述${xxx} 的变量中：

```
DRONE_GITHUB_CLIENT_ID=xxxxx  # 填入OAuth 生成的client id
DRONE_GITHUB_CLIENT_SECRET=xxxxx # 填入OAuth 生成的client secret
DRONE_RPC_SECRET=xxxxx  # 可以通过openssl rand -hex 16 生成
DRONE_SERVER_HOST=ci.nefelibata.art
DRONE_SERVER_PROTO=http
DRONE_RPC_PROTO=http
复制代码
```

Drone 的注册默认是公开的，也就是说，所有能够访问你CI地址的人都能注册并使用你的CI 系统，如果你想要限制使用的用户，你可以在environment 中配置`- DRONE_USER_FILTER=evont, xxx`的方式，添加允许加入的用户（但先前已注册过的用户不会被限制住，真是奇怪的逻辑）。

启动服务，访问服务域名，跳转到Github 进行登录，如果上一步中限制了登录用户且当前Github 账户名不在允许账户中时，回到服务时会显示登录失败。

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa9cfa2a1008ee~tplv-t2oaga2asx-watermark.image)

如果成功，就可以看到你的Github 仓库项目列表了

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa9dd031ef70c2~tplv-t2oaga2asx-watermark.image)

进入项目并激活该项目，如果登录用户是管理员，会在`Project settings` 中出现`Trusted` 选项，否则就只有一个`Protected` 选项，只有被`Trusted` 的仓库才能在构建过程中和宿主机进行`Volumes` 映射。

![](https://gitee.com/hxf88/imgrepo/raw/master/img/16fa9de780e8e6e9~tplv-t2oaga2asx-watermark.image)

### 项目构建

以我的项目为例，我希望提交代码后，Drone 帮我构建镜像然后推送到镜像仓库。

新建一个项目，完成基础的代码后，在项目根目录下新建一个如下的 `.drone.yml`，使用Drone 的[Docker](https://link.juejin.cn/?target=http%3A%2F%2Fplugins.drone.io%2Fdrone-plugins%2Fdrone-docker%2F "http://plugins.drone.io/drone-plugins/drone-docker/") 插件，指定了镜像仓库地址和分支。

由于用的是私有的仓库，需要登录。这时候我们就可以在CI 界面的`Secrets` 一栏中可以填入一些变量供构建过程使用，就不会暴露在`.drone.yml` 中了。如前面图中所示，在`Secrets` 部分添加自定义的`DOCKER_USERNAME` 和`DOCKER_PASSWORD`字段，然后在`.drone.yml` 中通过`from_secret` 传入`username` 和`password`，就不需要写在配置文件中从而不会被其他能够访问到代码的人所看到了。

另外，由于拉取Docker 镜像的速度很缓慢，这时候你可以通过设置`mirror` 指定Docker 加速源。

```
---
kind: pipeline
type: docker
name: default


steps:
  - name: egg-docker
    image: plugins/docker
    settings: 
      mirror: https://xxxx(自己的用户id).mirror.aliyuncs.com
      username: 
        from_secret: DOCKER_USERNAME
      password:
        from_secret: DOCKER_PASSWORD 
      repo: registry.cn-hangzhou.aliyuncs.com/nefelibata/egg
      registry: registry.cn-hangzhou.aliyuncs.com
      auto_tag: true

trigger:
  branch:
    - master
  event:
    - push
复制代码
```

确认无误后，提交代码到该项目触发构建。如果Drone 版本大于1.4.0 且没有开启Agent 时，你很可能会和我一样一直卡在Pending 状态，这是由于默认情况下Drone 是多机模式(`multi-machine mode`)，如果是单个服务器下，你不需要设置代理服务器。网上很多配置是教`DRONE_AGENTS_ENABLED=false` ，然而实际上应该是通过`DRONE_AGENTS_DISABLED=true` 来开启单机模式(`single-machine mode`)

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/1/15/16fa8b8043dbe7b1~tplv-t2oaga2asx-watermark.image)

设置妥当后并触发构建就可以看到项目出现了构建过程，它会拉取项目代码到一个临时目录中，构建完成后该目录就会被销毁。

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824162701085.png" alt="image-20210824162701085" style="zoom:50%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824162728313.png" alt="image-20210824162728313" style="zoom:50%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824162751745.png" alt="image-20210824162751745" style="zoom:50%;" />

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824163153943.png" alt="image-20210824163153943" style="zoom:50%;" />



构建完成，推送到了镜像仓库，撒花！

新界面还是挺好看的，撒花

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210824163226140.png" alt="image-20210824163226140" style="zoom:50%;" />

___

## Docker

-   networks
    
    不同Docker Compose 之间的容器是互不相同的，每个Docker Compose 都有属于自己的networks，上述的服务是分离在不同的`docker-compose.yml` 文件中的，为了让它们互联，我们需要让它们处在同一个networks中，这时候可以先通过执行`docker network create treaefik` 建立一个共享的networks，然后在各个`docker-compose.yml` 中配置networks 指向这个新建的networks，最后在容器中指定其networks即可
    
    ```
      services:
         nginx:
          # ...
          image: nginx
          networks:
            - default
          # ...
      networks:
        default:
          external:
            name: treaefik
    复制代码
    ```
    
-   其他
    
    docker 相关文章很多，暂时没有在项目中遇到什么这方面的坑，待记录。
    
    <img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901125031070.png" alt="image-20210901125031070" style="zoom:150%;" />

