---
title: centos离线安装docker
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
1.  下载docker的安装文件

[https://download.docker.com/linux/static/stable/x86\_64/](https://download.docker.com/linux/static/stable/x86_64/)

下载的是：docker-18.06.3-ce.tgz 这个压缩文件

![](https://img2020.cnblogs.com/blog/1419795/202005/1419795-20200514170642044-109054151.png)

2.  将docker-18.06.3-ce.tgz文件上传到centos7-linux系统上，用ftp工具上传即可

![](https://img2020.cnblogs.com/blog/1419795/202005/1419795-20200514170715454-2121213609.png)

3.  解压

复制代码

-   1

`[root@localhost java]# tar -zxvf docker-18.06.3-ce.tgz` 

4.  将解压出来的docker文件复制到 /usr/bin/ 目录下

复制代码

-   1

`[root@localhost java]# cp docker/* /usr/bin/` 

5.  进入**/etc/systemd/system/**目录,并创建**docker.service**文件

复制代码

-   1
-   2

`[root@localhost java]# cd /etc/systemd/system/
[root@localhost system]# touch docker.service` 

6.  打开**docker.service**文件,将以下内容复制

复制代码

-   1

`[root@localhost system]# vi docker.service` 

**注意**： --insecure-registry=192.168.200.128 此处改为你自己服务器ip

`[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --selinux-enabled=false --insecure-registry=192.168.200.128
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target` 

7.  给docker.service文件添加执行权限

复制代码

-   1

`[root@localhost system]# chmod 777 /etc/systemd/system/docker.service` 

8.  重新加载配置文件（每次有修改docker.service文件时都要重新加载下）

复制代码

-   1

`[root@localhost system]# systemctl daemon-reload` 

9.  启动

复制代码

-   1

`[root@localhost system]# systemctl start docker` 

10.  设置开机启动

复制代码

-   1

`[root@localhost system]` 

11.  查看docker状态

复制代码

-   1

`[root@localhost system]# systemctl status docker` 

出现下面这个界面就代表docker安装成功。

![](https://img2020.cnblogs.com/blog/1419795/202005/1419795-20200514170744352-1186245935.png)

12.  配置镜像加速器,默认是到国外拉取镜像速度慢,可以配置国内的镜像如：阿里、网易等等。下面配置一下网易的镜像加速器。打开docker的配置文件: /etc/docker/**daemon.json**文件：

复制代码

-   1

`[root@localhost docker]# vi /etc/docker/daemon.json` 

配置如下:

复制代码

-   1

`{"registry-mirrors": ["http://hub-mirror.c.163.com"]}` 

配置完后**:wq**保存配置并**重启docker** 一定要重启不然加速是不会生效的！！！

复制代码

-   1

`[root@localhost docker]# service docker restart` 

参考：[https://www.cnblogs.com/kingsonfu/p/11576797.html](https://www.cnblogs.com/kingsonfu/p/11576797.html)

本文作者：青阳闲云

本文链接：https://www.cnblogs.com/helf/p/12889955.html

版权声明：本作品采用知识共享署名-非商业性使用-禁止演绎 2.5 中国大陆许可协议进行许可。

如果您觉得阅读本文对您有帮助，请点一下【推荐】按钮，您的【推荐】将是我最大的写作动力！

欢迎访问我的个人博客: https://heliufang.gitee.io/