---
title: Day8 不同yml档，也可以让容器彼此都能沟通
date: 2021-09-01 08:03:21
tags:
- devops
categories: 
- devops
---

运行容器时，最常发生需要互相沟通的问题，容器与容器间的沟通，与虚拟机相同，只要网段一致，即可直接呼叫IP或容器名称。因此，这边示范如何在不同的容器中，让他们有相同的网段。

![image-20210901081653417](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901081653417.png)

<!--more-->

```
## web_service 表示該段名稱
$ docker network create web_service



## 建置完畢後，可以透過以下指令查看
$ docker network ls
```

另外可以透过前几天介绍的Pontainer 查看网段IP，网路会因为建立顺序而有不同网段，基本上 `172.17.0.x``172.18.0.x``web_service``172.18.0.x`  
![image-20210901081503427](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901081503427.png)

------

将以下两个不同路径的 `docker-compose.yml`[](http://localhost:8080/?overview)

-   以下为范例架构：

```
.
├── Redis
│   └── docker-compose.yml
└── RedisAdmin
    ├── config.inc.php
    └── docker-compose.yml
```

-   Redis / docker-compose.yml

```
version: '3.1'

services:
  redis6379:
    image: redis:alpine
    container_name: Test_6379
    restart: always
    ports: 
      - 6379:6379
    # 指定使用那一條網路
    networks:
      - web_service

# 表示服務用的網絡是用外部的網路，並且搜尋名稱為「web_service」 
# 搜尋成功後會自動與「redis」服務相連
# 若搜尋失敗，則會顯示該錯誤
# ERROR: Please create the network manually using `docker network create web_services` and try again.
networks:
  web_service:
    external: true
```

-   RedisAdmin / docker.compose.yml

```
version: '3.1'

services:
  redis-admin:
    image: erikdubbelboer/phpredisadmin
    container_name: redisAdminer
    restart: always
    ports:
        - 8080:80
    volumes: 
      - ./config.inc.php:/src/app/includes/config.inc.php
    # 指定使用那一條網路
    networks:
      - web_service

# 表示服務用的網絡是用外部的網路，並且搜尋名稱為「web_service」 
# 搜尋成功後會自動與「redis-admin」服務相連
# 若搜尋失敗，則會顯示該錯誤
# ERROR: Please create the network manually using `docker network create web_services` and try again.
networks:
  web_service:
    external: true
```

-   RedisAdmin/config.inc.php

```
<?php
include 'config.sample.inc.php';
$config['servers'] = array();
$config['servers'][] = array(
  'name'   => "Test_6379", # 顯示在 RedisAdmin 頁面上的名稱，可以隨意亂取名
  'host'   => "Test_6379", # Redis 容器名稱
  'port'   => "6379",      # Redis Port
  'filter' => '*',
);

?>
```

以上完成不同的 `docker-compose.yml`

![image-20210901082019798](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210901082019798.png)
