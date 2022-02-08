---
title: Day5 K8S架构＆ Docker 快速建立环境示范
date: 2021-08-30 14:43:43
tags:
- devops
categories: 
- devops
---

首先，先来说明一下昨天的架构图为什么不建议使用「虚拟机」，在成本允许下尽量使用「实体机器」的原因是，每次从「实体机」建置新的「虚拟机」总是需要预留些许资源供机器os使用，所以每多一台「虚拟机器」，多少就会浪费一些资源，当「虚拟机」数量越多浪费的资源就越多。

另外，K8S本身会自行分配Container资源，当Container资源达自动扩展的数值时(可以手动调整该数值)，K8S会自动长出一台Container分散连线数减轻Loading，所以可以不必担心资源过剩的问题，因此在资源成本足够的情况，会建议以「实体机」取代「虚拟机」，不过也是有看过在「虚拟机」上建置K8S Cluster的案例，就看读者们怎么调整与使用。

<!--more-->

___

经过前几天较为枯燥乏味的架构叙述，是时候要来一点实做示范了，[](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-18-04)

当执行完这一行指令时，恭喜你已经完成nginx的环境建置了，只是...还需要在做一些调整

```
$ docker run -d nginx 

#
#
#
```

执行以下指令，可以看见刚刚安装的nginx container

```
$ docker ps -a

#
```

这时你会看见一个看不懂的container 名称，原因是如果没有指令没有指定container名称时，docker会自动提供一个唯一的名称，可以透过下方指令赋予container名称，并且在执行一次 `docker ps -a`

```
$ docker run -d --name=nginx nginx

#
#
```

接着当Nginx Container 安装完毕后，该如何使用呢，目前的操作上是还无法对外服务的，因为尚未将Container 外的Port 对应到Container 内的Port，可以透过以下指令将容器外的Port 与容器内对应。

```
$ docker run -d --name=nginx -p 8081:80 nginx

#
#
```

此时，打开 虽然成功看见nginx画面了，但是该如何将自己的专案放入容器中呢？可以参考下方指令[](http://localhost:8081/)  

-   index.html 内容

```
<h1>1234</h1>
```

```
$ docker run -d --name=nginx -p 8081:80 -v "$(pwd)/index.html:/usr/share/nginx/html/index.html" nginx

#
#
#
```

此时，从新刷新页面[](http://localhost:8081/)

以上操作恭喜你已经完成了，使用docker command 建置属于自己的nginx 服务，明天会说明使用docker command 建置服务的缺点，以及解决办法。
