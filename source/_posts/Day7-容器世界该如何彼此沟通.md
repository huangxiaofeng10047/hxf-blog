---

title: Day7 容器世界该如何彼此沟通
date: 2021-08-31 08:16:53
tags:
- devops
categories: 
- devops
---

从「虚拟机」转战到容器环境时，最容易产生的疑问是容器之间该如何沟通，其实就跟「虚拟机」的环境一样，透过IP 或者URL 的DNS 解析，指到对应的「虚拟机」即可沟通。

Docker Container 也是一样，每次产生一个容器或者重新生成容器都会对应到一个浮动IP，当Container 移除后IP 会立即释放，因此不建议透过IP 沟通，而是应该采用容器名称(可以想像成URL 的DNS 解析)，来达到彼此沟通，以下会示范该如何让容器之间彼此互相沟通。

<!--more-->

-   Redis + RedisAdmin

```
version: '3.1'

services:
  redis6379:
    image: redis:alpine
    container_name: Test_6379
    restart: always
    ports: 
      - 6379:6379

  redis-admin:
    image: erikdubbelboer/phpredisadmin
    container_name: redisAdminer
    restart: always
    ports:
        - 8080:80
    volumes: 
      - ./config.inc.php:/src/app/includes/config.inc.php
```

执行完 `docker-compose up -d`[](http://localhost:8080/?overview)`Test_6379`

-   DB + DB Admin[](https://hub.docker.com/_/mysql)

```
version: '3.1'

services:
  db:
    image: mysql:5.6
    container_name: db
    # DB型別為utf8mb4 ...
    command: ['--character-set-server=utf8', '--collation-server=utf8_unicode_ci', --default-authentication-plugin=mysql_native_password]
    restart: always
    ports:
      - 3306:3306
    environment:
      MYSQL_USER: root
      MYSQL_ROOT_PASSWORD: qwe1234
      MYSQL_DATABASE: GoAdmin

  adminer:
    image: adminer
    container_name: adminer
    restart: always
    ports:
      - 8888:8080
```

-   伺服器(容器名称)：db-service
-   帐号： root
-   密码： qwe1234
-   资料库： Test

![image-20210831085314602](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831085314602.png)

遇到以下问题：

解决办法：需要添加其他用户，不要使用root账户



```log
2021-08-31 01:08:54+00:00 [ERROR] [Entrypoint]: MYSQL_USER="root", MYSQL_USER and MYSQL_PASSWORD are for configuring a regular user and cannot be used for the root user
    Remove MYSQL_USER="root" and use one of the following to control the root user password:
    - MYSQL_ROOT_PASSWORD
    - MYSQL_ALLOW_EMPTY_PASSWORD
    - MYSQL_RANDOM_ROOT_PASSWORD
```







   - ```yml
     version: '3.1'
     
     services:
       db:
         image: mysql:5.6
         container_name: db
         # DB型別為utf8mb4 ...
         command: ['--character-set-server=utf8', '--collation-server=utf8_unicode_ci', --default-authentication-plugin=mysql_native_password]
         restart: always
         ports:
           - 3306:3306
         environment:
           MYSQL_USER: hxf
           MYSQL_PASSWORD: qwe1234
           MYSQL_ROOT_PASSWORD: qwe1234
           MYSQL_DATABASE: GoAdmin
     
       adminer:
         image: adminer
         container_name: adminer
         restart: always
         ports:
     
        - 8888:8080
     ```

     ![image-20210831091300318](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210831091300318.png)



___

补充解释一下，由于两个Container 服务本身是撰写在同一支`docker-compose.yml`  
![](https://i.imgur.com/yWPA0Qy.png)

但是总是会碰到container 撰写于不相同的`docker-compose.yml`

