---
title: Day10 打造属于团队的Image
date: 2021-09-02 08:26:38
tags:
- devops
categories: 
- devops
---

虽然docker hub 的images 应有尽有，但是总会有不符合自我需求的时候，例如：在nginx container 内希望nginx 本身具备logrotate 功能，能自动打包+ 压缩nginx log，这时就需要使用到Dockerfile 对nginx images 进行加工。

<!--more-->

## 

-   Dockerfile:

```
# 以 nginx 1.12.1 的版本作為基底
FROM nginx:1.12.1 AS builder

# Install logrotate
# RUN 指令可以協助安裝套件或者執行否些指令
RUN apt-get update && apt-get -y install logrotate

# 將logroate規則複製進容器(必須讓檔案為root用戶，才可以執行)
# COPY 指令可以協助將容器外部的檔案，複製到容器內某路徑
COPY ./nginx /etc/logrotate.d/nginx

# CDM 指令指容器啟動後，需要做的行為
# 該範例為啟動 cron 背景服務 + nginx 服務
CMD service cron start && nginx -g 'daemon off;'
```

以上就是nginx 加工后的image ，但是跟如何使用呢？有以下两种方式：

-   直接于 `docker-compose.yml`
    
    -   专案架构：
    
    ```
    .
    ├── default.conf
    ├── docker-compose.yml
    ├── Dockerfile
    ├── index.html
    └── nginx-logrotate
    ```
    
    -   default.conf
    
    ```
    server {
        listen       80;
        server_name  localhost;
    
        location / {
            root   /home/project;
            index  index.html index.htm;
        }
    
    }
    ```
    
    -   index.html
    
    ```
    <h1>1234</h1>
    ```
    
    -   nginx-logrotate
    
    ```
    # logroate規則
    
    /var/log/nginx/*.log {
            daily
            missingok
            rotate 7
            compress
            dateext
            notifempty
            create
            sharedscripts
            postrotate
                    if [ -f /var/run/nginx.pid ]; then
                            kill -USR1 `cat /var/run/nginx.pid`
                    fi
            endscript
    }
    ```
    
    -   docker-compose.yml  
        `docker-compose up -d`
    
    ```
    version: '3'
    
    services:
      web:
        build: 
          context: .                                       # 讀取當前路徑的 Dockerfile
        restart: always                                    # 虛擬機會實體機重起後，容器服務自動帶起
        container_name: nginx                              # 容器名稱
        volumes:
          - ./default.conf:/etc/nginx/conf.d/default.conf  # 掛載 nginx 設定檔，可自由操控nginx設定檔
          - ./index.html:/home/project/index.html          # 掛載專案
        working_dir: /home/project                         # 進入容器後的預設路徑
        ports:                                             # 容器內與容器外 Port
          - 8899:80
        networks:                                          # 指定使用那一條網路
          - web_service
    
    # 表示服務用的網絡是用外部的網路，並且搜尋名稱為 「web_service」 
    # 搜尋成功後會自動與「webs」服務相連
    networks:
      web_service:
        external: true
    ```
    
    以上即可完成nginx 服务建置
    

___

-   build 成image， 在推上docker hub 或者私有harbor (私有库) 保存，日后直接使用
    -   将Dockerfile build 成image 并加上tag
        
        ```
        ## -t 表示替 image 打上 tag 
        ## 因為接下來示範將 images 推至 docker hub 
        ## 故 image tag 直接使用個人的 neil605164/nginx (專案名稱) + 1.12.1 (版本號)
        $ docker build -t neil605164/nginx:1.12.1 .
        ```
        
    -   检查是否build 成功
        
        ```
        $ docker images | grep "neil605164/nginx"
        ```
        
    -   推至公开的docker hub
        
        ```
        $ docker push neil605164/nginx:1.12.1
        ```
        

欢迎读者可以一起至[](https://hub.docker.com/)
