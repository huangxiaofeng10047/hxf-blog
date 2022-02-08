---
title: yum安装升级docker和docker-compose
date: 2021-09-07 16:36:00
tags:
- shell
categories: 
- devops
---

centos7

> yum remove docker \\  
>                docker-client \\  
>                docker-client-latest \\  
>                docker-common \\  
>                docker-latest \\  
>                docker-latest-logrotate \\  
>                docker-logrotate \\  
>                docker-selinux \\  
>                docker-engine-selinux \\  
>                docker-engine

 或者

> sudo yum remove docker \\  
> docker-common \\  
> container-selinux \\  
> docker-selinux \\  
> docker-engine

<!--more-->

卸载Docker后,/var/lib/docker/目录下会保留原Docker的镜像,网络,存储卷等文件. 如果需要全新安装Docker,需要删除/var/lib/docker/目录

> rm -fr /var/lib/docker/

## 3.1 配置docker yum源

推荐方法1

方法1：

> 先安装yum-utils：
>
> yum install -y yum-utils.noarch
>
> 然后执行：
>
> yum-config-manager \\  
> \--add-repo \\  
>  https://download.docker.com/linux/centos/docker-ce.repo
>
> 配置docker镜像源地址：
>
> ```
> sudo tee /etc/docker/daemon.json <<-'EOF'        "https://1nj0zren.mirror.aliyuncs.com",        "https://docker.mirrors.ustc.edu.cn",        "http://f1361db2.m.daocloud.io",        "https://registry.docker-cn.com"
> ```
>
> 再执行：
>
> ```
> sudo systemctl daemon-reload
> ```


方法2 

> echo '\[docker-ce-stable\]  
> name=Docker CE Stable - $basearch  
> baseurl=https://download.docker.com/linux/centos/7/$basearch/stable  
> enabled=1  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-stable-debuginfo\]  
> name=Docker CE Stable - Debuginfo $basearch  
> baseurl=https://download.docker.com/linux/centos/7/debug-$basearch/stable  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-stable-source\]  
> name=Docker CE Stable - Sources  
> baseurl=https://download.docker.com/linux/centos/7/source/stable  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-edge\]  
> name=Docker CE Edge - $basearch  
> baseurl=https://download.docker.com/linux/centos/7/$basearch/edge  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-edge-debuginfo\]  
> name=Docker CE Edge - Debuginfo $basearch  
> baseurl=https://download.docker.com/linux/centos/7/debug-$basearch/edge  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-edge-source\]  
> name=Docker CE Edge - Sources  
> baseurl=https://download.docker.com/linux/centos/7/source/edge  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-test\]  
> name=Docker CE Test - $basearch  
> baseurl=https://download.docker.com/linux/centos/7/$basearch/test  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-test-debuginfo\]  
> name=Docker CE Test - Debuginfo $basearch  
> baseurl=https://download.docker.com/linux/centos/7/debug-$basearch/test  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-test-source\]  
> name=Docker CE Test - Sources  
> baseurl=https://download.docker.com/linux/centos/7/source/test  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-nightly\]  
> name=Docker CE Nightly - $basearch  
> baseurl=https://download.docker.com/linux/centos/7/$basearch/nightly  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-nightly-debuginfo\]  
> name=Docker CE Nightly - Debuginfo $basearch  
> baseurl=https://download.docker.com/linux/centos/7/debug-$basearch/nightly  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg
>
> \[docker-ce-nightly-source\]  
> name=Docker CE Nightly - Sources  
> baseurl=https://download.docker.com/linux/centos/7/source/nightly  
> enabled=0  
> gpgcheck=1  
> gpgkey=https://download.docker.com/linux/centos/gpg'>/etc/yum.repos.d/docker-ce.repo

## 3.2 安装docker:

查看所有可用的docker版本:

> yum list docker-ce --showduplicates | sort -r

这里我们安装docker-ce-18.06.0.ce-3.el7 版本

> yum -y install docker-ce-18.06.0.ce-3.el7

查看docker版本:

> docker version

安装docker命令补全工具：

> ```
> yum install -y bash-completion
> ```

启动docker服务:

> systemctl status docker  
> systemctl start docker
>
> systemctl restart docker

设置开机自启动:

> systemctl enable docker

## 3.3、安装docker-compose

去github上下载二进制包来安装

> sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

上面这个github的地址太慢了，如果你能耐得住就慢慢等。。  
可以采用下面这个速度较快的方式：

> curl -L https://get.daocloud.io/docker/compose/releases/download/1.28.4/docker-compose-\`uname -s\`-\`uname -m\` > /usr/local/bin/docker-compose
>
> 你可以通过修改URL中的版本，可以自定义您的需要的版本。

将可执行权限赋予二进制文件：

> chmod +x /usr/local/bin/docker-compose

创建软链接：

> sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

执行命令查看安装的版本

> docker-compose version
>
> docker version 

部分参考：

[https://docs.docker.com/engine/install/centos/](https://docs.docker.com/engine/install/centos/)

[https://www.runoob.com/docker/centos-docker-install.html](https://www.runoob.com/docker/centos-docker-install.html)

