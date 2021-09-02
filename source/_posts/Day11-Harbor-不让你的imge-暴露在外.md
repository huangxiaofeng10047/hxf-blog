---
title: Day11 Harbor 不让你的imge 暴露在外
date: 2021-09-02 08:28:35!tags:
- devops
categories: 
- devops[](https://i.imgur.com/IAguMb8.png)
---

今天要来介绍一个Docker 私有库工具Harbor，Harbor 是由VMWare 公司用Go 语言所开发的开源软体，用于除存团队私有的image，Harbor 提供了简易的UI 介面，包含权限控管，及跨机器的自动同步功能，且安装容易。

**上述提及Harbor 提供权限控管的功能，以下介绍Harbor 区分哪些权限：**

<!--more-->

## 权限访问介绍

-   `Guest:`仅提供该用户拥有 `pull images`
-   `Developer:`提供该用户拥有 `pull or push images`
-   `Admin:` 提供该用户拥有管理该群组的所有权限，(EX:新增/汰除该群组人员、建立新专案、建立人员、选择专案是否对外...)

![](https://i.imgur.com/Eaie9y4.png)

## 接着介绍该如何安装[](https://github.com/goharbor/harbor/releases)

> 以v1.7.5 做为范例

![](https://i.imgur.com/hw6GZnm.png)

-   解压缩

```
 $ tar xvf 下載的壓縮檔案.tgz
```

-   配置harbor.yml 档案(建议调整以下设定即可)
    -   hostname: or
    -   harbor\_admin\_password： 调整预设的admin密码

## 执行安装脚本

-   建议更改`docker-compose.yml`
-   EX: 挂载于当前目录`./data``./template`
-   于当前目录执行

```
#
sudo ./install.sh
```

以上三个步骤即可安装完Harbor，是不是很简单呢？接下来还需要设定几个步骤，才有办法从本机将Image 推至Harbor  

-   新增以下档案内容

```
#
{
    "insecure-registries": ["<Your Harbor Domain> or <IP>"]
}
```

-   重新启动docker & systemctl

```
$ sudo systemctl daemon-reload && sudo systemctl restart docker
```

-   登入docker register

```
$ docker login <Your Harbor Domain> or <IP>

#
Username: admin
Password:
Login Succeeded
```

## 测试是否可以推Image

### 以下以docker hub 的nginx 作为示范

```
$ docker pull nginx:1.12.1
```

### Push Image

```
# 替 image 建立一個版號
$ docker tag <Your Harbor Domain> or <IP>/nginx/nginx:1.12.1 nginx:1.12.1

# 推至私有庫
$ docker push <Your Harbor Domain> or <IP>/nginx/nginx:1.12.1
```

### Pull Image

```
# 從私有庫取image
$ docker pull <Your Harbor Domain> or <IP>/nginx/nginx:1.12.1
```

以上完成整体的建制& 测试，并附上Build Images 至Harbor 的流程图。

![](https://i.imgur.com/8UOrbVL.png)
