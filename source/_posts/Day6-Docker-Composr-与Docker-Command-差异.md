---
title: Day6 Docker-Composr 与Docker Command 差异
date: 2021-08-30 14:45:32
tags:
- devops
categories: 
- devops
---

昨天示范透过 `docker command``docker command`

- 无法进行版本控制：  

-   当机器死亡时，没有办法迅速将服务建置完成：  
    `docker`
    
    <!--more-->

所以建议透过 docker-compose 安装步骤`docker-compose.yml``docker-compose.yml``yml`[](https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04)

-   实用工具  
    `docker-compose.yml``docker`[](http://localhost:9001/)

```
docker run -d -p 9001:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v /home/rdmb0369/RD/Portainer:/data portainer/portainer
```

![image-20210830144943305](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830144943305.png)

开始介绍该如何使用 `docker-compose.yml``yml``docker-compose up -d``nginx``container``docker-compose.yml`

```
version: '3'            

services:               
  web:                  
    image: nginx:1.12.1 
```

每一次调整 `docker-compose.yml``docker-compose up -d`

```
version: '3'                      

services:                         
  web:                            
    image: nginx:1.12.1           
    container_name: nginx-servie  
    restart: always               
    ports:                        
      - 8081:80
```

上述的范例执行完毕后，打开[](http://localhost:8081/)

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

```

<h1>1234</h1>
```

```
version: '3'                      

services:                         
  web:                            
    image: nginx:1.12.1           
    container_name: nginx-servie  
    restart: always               
    ports:                        
      - 8081:80
    volumes:                      
      - ./default.conf:/etc/nginx/conf.d/default.conf
      - ./index.html:/home/project/index.html
```

上方范例除了覆盖容器内原本的 `default.conf``index.html``/home/project/`

透过`docker-compose.yml``docker-compose up -d`

