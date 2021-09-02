---
title: Day9 该如何将Docker Run 指令，转换成Docker-compose内容
date: 2021-09-02 08:24:44
tags:
- devops
categories: 
- devops
---

初学Docker 时，很常发生在不知道 `docker-compose.yml``docker run`[](https://hub.docker.com/_/redis)

接下来将会示范该如何拆解 `docker run``docker-compose.yml`

<!--more-->



```
$ docker run -v ./redis.conf:/usr/local/etc/redis/redis.conf --name myredis redis redis-server /usr/local/etc/redis/redis.conf
```

首先每一个 `docker-compose.yml`

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  redis:                            # 可以隨意命名，通常以有意義的字串命名
    image: redis:5.0.5-alpine       # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
```

接着开始拆解docker 指令，并转换至`docker-compose.yml`

-   `-v` 表示挂载，并且使用「:」分隔容器内外的路径。

```
## 該範例表示機器當前路徑內的「redis.conf」
## 掛載至容器內的「/usr/local/etc/redis/redis.conf」
-v ./redis.conf:/usr/local/etc/redis/redis.conf
```

看看 `docker-compose.yml`

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  redis:                            # 可以隨意命名，通常以有意義的字串命名
    image: redis:5.0.5-alpine       # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
    volumes:                        # 掛載的撰寫方式，如果有多組不同路徑掛載，只需要在新增幾行條件即可。
      - ./redis.conf:/usr/local/etc/redis/redis.conf
```

-   「- -name」表示指定容器名称
-   预设会将使用「资料夹名称+ 第三行字定义名称+ 顺序数字」

```
--name myredis
```

看看 `docker-compose.yml`

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  redis:                            # 可以隨意命名，通常以有意義的字串命名
    image: redis:5.0.5-alpine       # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
    volumes:                        # 掛載的撰寫方式，如果有多組不同路徑掛載，只需要在新增幾行條件即可。
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    container_name: myredis         # 指容器名稱，這裡比較不同的是指令使用「--name」，但在yml應該使用「container_name」
```

最后剩下一个指令要进行拆解

```
## 這一行是指當容器啟動後，該執行的動作
## 表示容器啟動後還需要跑起redis，才算完成。
## 這邊的 redis.conf 即剛剛掛載進入的redis.conf
## 可以先行編輯完內容在掛載。
redis-server /usr/local/etc/redis/redis.conf
```

看看 `docker-compose.yml`

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  redis:                            # 可以隨意命名，通常以有意義的字串命名
    image: redis:5.0.5-alpine       # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
    volumes:                        # 掛載的撰寫方式，如果有多組不同路徑掛載，只需要在新增幾行條件即可。
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    container_name: myredis         # 指容器名稱，這裡比較不同的是指令使用「--name」，但在yml應該使用「container_name」
    command: redis-server /usr/local/etc/redis/redis.conf # command 表示啟動容器後預備執行的動作
```

另外有时会看见以下范例

```
$ docker run -e "ENV=develop" redis
```

-   「-e」表示将参数带入容器内  
    `docker-compose.yml`

```
version: "3"                        # docker-compose 版本號

services:                           # 開始撰寫 container 服務
  redis:                            # 可以隨意命名，通常以有意義的字串命名
    image: redis:5.0.5-alpine       # 服務容器，若無指定版號表示使用 latest 版本， alpine 容器佔用空間較小，通常建議使用
    volumes:                        # 掛載的撰寫方式，如果有多組不同路徑掛載，只需要在新增幾行條件即可。
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    container_name: myredis         # 指容器名稱，這裡比較不同的是指令使用「--name」，但在yml應該使用「container_name」
    command: redis-server /usr/local/etc/redis/redis.conf # command 表示啟動容器後預備執行的動作
    environment:                    # 提供參數至容器內部，docker 指令是使用「-e 或者 --env」，但在yml應該使用「environment」
      - ENV=develop
```

**以上就完成了 `docker run`**
