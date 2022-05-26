搭建harbor私服，这里采用 v2.4.1 版本，也可以采用更高版本

### harbor官网地址

```
harbor官网地址: 
https://goharbor.io/

github官网地址: 
https://github.com/goharbor/harbor

官方帮助文档:
https://github.com/goharbor/harbor/blob/v2.4.1/docs/installation_guide.md
```

### 主机环境：

-   双核cpu
-   4GB内存
-   40GB硬盘
-   IP地址：192.168.7.151
-   docker version: 19.03.9
-   docker-compose version: 2.1.1

## 前提：要安装 docker-compose

下载地址：[https://github.com/docker/compose](https://github.com/docker/compose)

复制 `docker-compose-linux-x86_64` 到主机

```
mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose 
ll /usr/local/bin/docker-compose
docker-compose -v

```

## harbor安装

### 第一步：下载harbor安装包并安装

下载地址：[https://github.com/goharbor/harbor/releases/tag/v1.9.4](https://github.com/goharbor/harbor/releases/tag/v1.9.4)

由于国内网络问题推荐下载离线安装包 `harbor-offline-installer-v1.9.4.tgz`

```
tar xvf harbor-offline-installer-v2.4.1.tgz

```

### 第二步：修改 `harbor.yml` 文件

```
cd harbor/
cp harbor.yml.tpl harbor.yml
vi harbor.yml

# Configuration file of Harbor

# The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: 192.168.20.50

# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 5000

# https related config
#https:
  # https port for harbor, default is 443
#  port: 443
  # The path of cert and key files for nginx
#  certificate: /your/certificate/path
#  private_key: /your/private/key/path

# # Uncomment following will enable tls communication between all harbor components
# internal_tls:
#   # set enabled to true means internal tls is enabled
#   enabled: true
#   # put your cert and key files on dir
#   dir: /etc/harbor/tls/internal

# Uncomment external_url if you want to enable external proxy
# And when it enabled the hostname will no longer used
# external_url: https://reg.mydomain.com:8433

# The initial password of Harbor admin
# It only works in first time to install harbor
# Remember Change the admin password from UI after launching Harbor.
harbor_admin_password: Harbor12345

# Harbor DB configuration
database:
  # The password for the root user of Harbor DB. Change this before any production use.
  password: root123
  # The maximum number of connections in the idle connection pool. If it <=0, no idle connections are retained.
  max_idle_conns: 100
  # The maximum number of open connections to the database. If it <= 0, then there is no limit on the number of open connections.
  # Note: the default number of connections is 1024 for postgres of harbor.
  max_open_conns: 900

# The default data volume
data_volume: /data

```

### 第三步：运行 `install.sh` 安装和启动

```



mkdir -p /var/log/harbor


./install.sh

```

### 第四步：浏览器登录

[http://192.168.20.50:5000](http://192.168.20.50:5000/)

用户名：admin

密码：Harbor12345

![image-20211221145154486](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20211221145154486.png)  

第一步：服务器端配置

在服务器中添加项目  
![](https://img2020.cnblogs.com/blog/2539702/202112/2539702-20211201215000532-1484224431.png)

![](https://img2020.cnblogs.com/blog/2539702/202112/2539702-20211201215129488-787818154.png)

## 第二步：配置客户端

由于使用的是http方式登录，需要配置一个普通的http注册中心，此配置将无视安全

向 `/etc/docker/daemon.json` 中添加如下配置内容

```
vi /etc/docker/daemon.json 


{
  "insecure-registries" : ["192.168.7.151:5000"]
}

```

## 第三步：登录harbor私服

```

docker login -u admin -p Harbor12345 192.168.7.151:5000


docker logout 192.168.7.151:5000

```

## 第四步：上传镜像

这里使用 `mysql:5.7.31` 镜像制作一个镜像

```

docker tag mysql:5.7.31 192.168.7.151:5000/project1/mysql:v1


docker push 192.168.7.151:5000/project1/mysql:v1 

```

到服务器端验证以下

![](https://img2020.cnblogs.com/blog/2539702/202112/2539702-20211201215225624-1190408027.png)

## 第五步：下载镜像

先删除客户端上重复的镜像

```
docker rmi 192.168.7.151:5000/project1/mysql:v1 
docker images

```

下载私服上的镜像

```
docker pull 192.168.7.151:5000/project1/mysql:v1
docker images

```