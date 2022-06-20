---
title: LxRunOffline使用手册
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-06 17:13:18
tags:
---

# 一、简介

`WSL`有多香就不介绍了，但其原生命令较为简陋、默认安装在`C`盘，稍有不足。而`LxRunOffline`能够安装任意发行版系统到任意目录，且具备转移已安装`WSL`目录、备份等功能，是一个极好的`WSL`管理软件。

项目地址：[GitHub - DDoSolitary/LxRunOffline: A full-featured utility for managing Windows Subsystem for Linux (WSL)](https://github.com/DDoSolitary/LxRunOffline)

# 二、安装LxRunOffline

- 常规安装：下载项目，手动安装
- 通过`Chocolatey`安装：

```powershell
choco install lxrunoffline
```

- 通过`Scoop`安装：

```powershell
scoop bucket add extras
scoop install lxrunoffline
```

`LxRunOffline`参数介绍：

```
l , list - 列出所有已安装的发行版。

gd , get-default - 获取 bash.exe 使用的默认发行版。

sd , set-default - 设置 bash.exe 使用的默认发行版。

i , install - 安装新的发行版。

sd , set-default - 设置 bash.exe 使用的默认发行版。

ui , uninstall - 卸载发行版。

rg , register - 注册现有的安装目录。

ur , unregister - 取消注册发行版但不删除安装目录。

m , move - 将发行版移动到新目录。

d , duplicate - 在新目录中复制现有发行版。

e , export - 将发行版的文件系统导出到.tar.gz 文件，该文件可以通过 install 命令安装。

r , run - 在发行版中运行命令。

di , get-dir - 获取发行版的安装目录。

gv , get-version - 获取发行版的文件系统版本。

ge , get-env - 获取发行版的默认环境变量。

se , set-env - 设置发行版的默认环境变量。

ae , add-env - 添加到发行版的默认环境变量。

re , remove-env - 从发行版的默认环境变量中删除。

gu , get-uid - 获取发行版的默认用户的 UID。

su , set-uid - 设置发行版的默认用户的 UID。

gk , get-kernelcmd - 获取发行版的默认内核命令行。

sk , set-kernelcmd - 设置发行版的默认内核命令行。

gf , get-flags - 获取发行版的一些标志。有关详细信息，请参考这里。

sf , set-flags - 设置发行版的一些标志。有关详细信息，请参考这里。

s , shortcut - 创建启动发行版的快捷方式。

ec , export-config - 将发行版配置导出到 XML 文件。

ic , import-config - 从 XML 文件导入发行版的配置。

sm , summary - 获取发行版的一般信息。
```

# 三、安装WSL

## 1、开启WSL功能

首先检查自己的电脑是否开启了`WSL`功能，没有的话运行以下命令开启并重启电脑：

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

## 2、下载镜像

以下列出两种镜像下载方式：

- `WSL`官方离线包：[Manually download Windows Subsystem for Linux (WSL) Distros | Microsoft Docs](https://docs.microsoft.com/en-us/windows/wsl/install-manual)
- `LxRunOffline WiKi`中的镜像：[Home · DDoSolitary/LxRunOffline Wiki · GitHub](https://github.com/DDoSolitary/LxRunOffline/wiki)

如果是从微软官方下载`WSL`离线包，文件后缀为`.appx`，我们手动改为`.zip`，然后解压，`install.tar.gz`就是我们后续使用的安装文件。

## 3、开启当前目录大小写敏感

`Windows`文件系统默认不区分大小写，而`Linux`是区分的，这就导致在安装、运行部分软件时会报错，我们新建一个用于存放`WSL`的目录，打开`powershell`并切换到相应目录，运行以下命令开启当前目录大小写敏感：

```powershell
fsutil.exe file setCaseSensitiveInfo .\ enable

# .\ 表示当前目录，此处参数可自定义
```

查看某个目录是否大小写敏感：

```powershell
fsutil.exe file queryCaseSensitiveInfo <path>
```

禁用大小写敏感：

```powershell
fsutil.exe file setCaseSensitiveInfo <path> disable
```

## 4、安装WSL

输入以下命令安装`WSL`：

```powershell
lxrunoffline i -s -n <WSL名称> -d <安装路径> -f <安装包路径>.tar.gz

# -s 参数表示在桌面创建WSL快捷图标
```

# 四、使用WSL

## 1、运行WSL

安装完成后我们可通过以下命令运行`WSL`：

```
lxrunoffline r -n <WSL名称>
```

## 2、退出WSL

`Ctrl`+`D`即可。

## 3、创建快捷方式

```powershell
lxrunoffline s -n <WSL名称> -f <快捷方式路径>.lnk
```

## 4、设置默认WSL

设置默认`WSL`后，我们可在`cmd`和`powershell`中输入`wsl`命令直接调用默认`WSL`：

```powershell
lxrunoffline sd -n <WSL名称>
```

## 5、修改WSL名称

查看`WSL`名称：

```powershell
wsl -l
```

查看`WSL`安装目录：

```powershell
lxrunoffline di -n <WSL名称>
```

导出指定`WSL`配置文件到目标路径：

```powershell
lxrunoffline ec -n <WSL名称> -f <配置文件路径>.xml
```

取消注册：

```powershell
lxrunoffline ur -n <WSL名称>
```

使用新名称注册：

```powershell
lxrunoffline rg -n <WSL名称> -d <WSL路径> -c <配置文件路径>.xml
```

# 五、其它配置

## 1、设置默认用户

修改过`WSL`名称或目录后就无法通过微软的官方方法设置默认用户，[Create user account for Linux distribution | Microsoft Docs](https://docs.microsoft.com/en-us/windows/wsl/user-support)，我们可以通过`LxRunOffline`进行设置。

我们首先运行`WSL`，输入以下命令创建用户：

```bash
useradd -m -s /bin/bash <用户名>
```

然后设置密码：

```bash
passwd <用户名>
```

授予`sudo`权限：

```bash
usermod -aG sudo <用户名>
```

查看`UID`，一般为1000：

```bash
id -u <用户名>
```

`Ctrl`+`D`退出`WSL`，在`powershell`中输入以下命令：

```powershell
lxrunoffline su -n <WSL名称> -v 1000
```

## 2、转移WSL安装目录

查看已安装的`WSL`：

```
lxrunoffline l
```

移动目录：

```powershell
lxrunoffline m -n <WSL名称> -d <路径>
```

查看路径：

```powershell
lxrunoffline di -n <WSL名称>
```

## 3、备份、恢复WSL

备份：

```powershell
lxrunoffline e -n <WSL名称> -f <压缩包路径>.tar.gz
```

恢复：

```powershell
lxrunoffline i -n <WSL名称> -d <安装路径> -f <压缩包路径>.tar.gz
```

# 六、WSL无法ping通主机[#](https://oopsdc.com/post/lxrunoffline/#六wsl无法ping通主机)

安装好相关工具后发现主机能`ping`通`WSL`，但`WSL`无法`ping`通主机，盲猜是防火墙的问题。

按一下`Windows`键，打开控制面板，选择`高级设置`=>`入站规则`=>`新建规则`=>`自定义`=>`所有程序`=>`任何`=>在`应用于哪些本地IP地址`选择`任何IP地址`，在`应用于哪些远程IP地址`选择`下列IP地址`，然后粘贴通过`ifconfig`命令查看到的`WSL`的`IP`=>后面全点下一步，给规则起名称的时候按个人喜好，能有明显的区分度，笔者设置为`WSL2`。至此，`WSL`就能成功`ping`通主机了。
