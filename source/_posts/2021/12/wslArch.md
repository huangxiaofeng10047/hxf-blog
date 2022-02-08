最近把IDEA更新到了2021，发现新版本增强了对WSL2的支持。之前的WSL2很鸡肋，吹很厉害，但真要开发又很不方便。 本来还想等着windows增强WSL2对gui的支持，然后在WSL2里装个IDEA。  
倒是IDEA动作快一点，先做了支持。不错，值得捣鼓一番。之前为了gui把wsl环境弄得很混乱，直接重装，随便记录一下操作。  
2021.11更新：wsl-gui环境配置及idea使用

### 一 配置WSL

按惯例，先给出官方文档地址，基础性操作参考这个： [https://docs.microsoft.com/zh-cn/windows/wsl/](https://docs.microsoft.com/zh-cn/windows/wsl/)

#### 1 开启wsl

参考：[https://docs.microsoft.com/zh-cn/windows/wsl/install-win10](https://docs.microsoft.com/zh-cn/windows/wsl/install-win10)

##### 1 安装「适用于 Linux 的 Windows 子系统」和「虚拟机平台」这两个可选组件

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestartdism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

##### 2 重启

##### 3 配置默认使用wsl2

```
 wsl --set-default-version 2
```

#### 2 安装windows terminal

在应用商店下载安装，自行美化即可，新版本已可直接通过选项配置，不需要直接操作配置文件

### 二 配置ubuntu

#### 1 安装ubuntu

在应用商店搜索下载ubuntu，当前版本为：20.04.2，下载完打开图标进行安装  
安装过程会提示输入一个默认用户和对应密码，注意不能用root（已存在）

#### 2 修改默认用户为root

##### 1 查看当前wsl列表：

之所以要这一步是因为如果装了多个版本的ubuntu，其标识可能不一样

```
wsl -l 
```

##### 2 修改对应wsl默认用户

```
Ubuntu config --default-user root
```

#### 3 将linux根目录映射到win10磁盘

在win10文件地址栏输入 \\wsl$ ，可以看到已安装的wsl文件系统，如 Ubuntu  
右键-映射网络驱动器，选择要映射的盘符即可。  
另外注意，可以用`explorer.exe .`命令使用windows文件资源管理器打开当前路径

#### 4 配置 terminal 打开默认路径

在 terminal 配置文件中，找到Ubuntu配置项，添加如下配置即可  
startingDirectory" : "//wsl$/Ubuntu-20.04/home"

#### 5 更新镜像源

##### 1 查看具体版本

```
cat /etc/lsb-release
```

##### 2 到 [https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/) 复制最新的镜像

阿里的支持傻瓜式操作，但经常打不开，就算了

```
 #备份： mv /etc/apt/sources.list /etc/apt/sources.list.backup #编辑： vi /etc/apt/sources.list
```

##### 3 更新

```
apt-get update -y && apt-get upgrade -y
```

#### 6 配置代理

如果代理软件是装在windows系统的，参考第四部分的 获取宿主机ip 部分配置my.win就行了

```
echo 'export ALL_PROXY="http://$host_ip:7890"'>>/etc/profile
```

#### 7 禁止添加Windows-PATH

> 此部分内容过期，可不配置，视情况而定，没问题可以不管。像在window和wsl同时安装npm会有问题，就需要配置。

为了避免开发环境冲突，需关闭Windows-PATH  
wsl.conf配置参考：[https://docs.microsoft.com/zh-cn/windows/wsl/wsl-config](https://docs.microsoft.com/zh-cn/windows/wsl/wsl-config)  
新建 /etc/wsl.conf，添加以下内容：  
`shell # 不加载Windows中的PATH内容 [interop] appendWindowsPath = false`

### 三 IDEA开发和总结

经过测试，常规SpringBoot工程，在Windows目录下的，可以使用WSL环境进行debug、部署  
对于纯maven工程，支持也还好

> 此部分过期：  
> 但对于纯gradle工程（非spring），则无法完成gradle初始化，无论工程是否是在WSL中都不行  
> 设置JDK是WSL，但将Gradle路径指定为WSL却一直不行，说路径有问题，只能使用默认的Gradle。  
> 根据issue的说法，建议将Windows的gradle path设置为WSL的路径，不过我没有试，我觉得这单纯就是官方的bug。  
> 官方issue：[https://youtrack.jetbrains.com/issues/IDEA?q=wsl](https://youtrack.jetbrains.com/issues/IDEA?q=wsl)  
> 另外，对于WSL下工程的git，idea似乎也无法识别

总之，IDEA（2021.1）的WSL2支持尚不成熟，但是也已经初步支持，还可以自动下载、选择WSL环境的JDK  
可以作为日常开发的辅助支持，但目前仍不建议全面迁移过去

对我来说，WSL的开发应用场景主要在于：  
大数据功能开发：之前简单的hdfs操作都需要在windows中配置hadoop相关的环境变量，而且各种版本或兼容性问题，很麻烦，以后这些直接丢wsl里面  
大数据组件编译：很多组件并不是纯Java代码，可能还需要一些脚本，这些有平台依赖性的，很可能因为windows而导致编译失败  
脚本开发：在windows新建的sh脚本在拿去linux系统之前都要先转换一下格式，以后直接作为wsl系统下文件新建，就不用考虑这些乱七八糟的问题

最终目标是以后把所有的工程都迁移到wsl下，开发相关全部使用wsl环境

2021年11月更新：  
IDEA2021.2.3的wsl工程的bug已经较少，git、gradle支持相对正常，可以满足一般场景下的开发需求。  
但仍不能在工程里读取到wsl的环境变量（能读取到windows的），所以我选择放弃。  
直接在WSLg里装jetbrains toolbox，然后启动idea。  
除去一些小bug，已经和原生linux体验差不多了，用来做大数据开发很舒服。  
配置好环境就可以直接本地进行大数据操作，不再需要远程开发了，之前被这东西折磨得不行。  
性能的话比windows idea的wsl开发要快很多，前提是你内存够。  
wsl比较吃内存，当然开发的标配是32g，一般还是够用的。

目前遇到的问题有：

1.  全屏偏移  
    在全屏状态下，无法进行部分拖拽操作，可能与这个issue有关  
    [https://github.com/microsoft/wslg/issues/502](https://github.com/microsoft/wslg/issues/502)
2.  卡死  
    通常是在调出新的窗口的时候  
    需要手动wsl --shutdown，再启动，但可能造成idea文件未保存，修改丢失的情况  
    在windows上不管怎么造基本都不会出现idea文件修改丢失的情况

### 四 其他

#### 1 wsl2获取宿主机ip

windows可以直接访问wsl的应用，使用localhost即可，但是不能使用127.0.0.1  
wsl可以通过以下操作获取windows的ip并设置host，以后直接提供my.win访问，一般用于访问windows的代理服务  
注意需要使用/tmp/hosts作为中转，否则/etc/hosts会被清空

```
echo 'host_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")'>>/etc/profileecho 'sed -e "/my.win/d"  /etc/hosts  > /tmp/hosts'>>/etc/profileecho 'cat /tmp/hosts > /etc/hosts>>/etc/profileecho 'echo "$host_ip my.win" >>/etc/hosts'>>/etc/profile
```

#### 2 局域网访问wsl2

需要使用netsh interface portproxy功能，按照help提示操作就行  
在powershell 管理员模式下执行以下命令，局域网其他机器只需要连接宿主机的19909端口即可访问wsl2内19909端口的内容

```
# 重置网络代理netsh interface portproxy reset# v4tov6 springboot网络默认是v6的netsh interface portproxy add v4tov6 listenport=19909 listenaddress=0.0.0.0 connectport=19909 connectaddress=localhostnetsh interface portproxy add v4tov4 listenport=19909 listenaddress=0.0.0.0 connectport=19909 connectaddress=localhostnetsh interface portproxy show all
```

#### 3 手动添加jetbrains toolbox软件的快捷方式到开始菜单

```
cd ~/.local/share/applicationssudo cp *.desktop /usr/share/applications
```

参考链接：[https://juejin.cn/post/6966630345915498526](https://juejin.cn/post/6966630345915498526)

#### 3 中文环境及输入法

这个教程比较多，而且写得都不一样，但大同小异，需要注意的是  
输入法没有切换处理很可能是快捷键被windows系统的覆盖了，  
需要手动调出来输入法的配置界面，修改快捷键  
比方说fcix的是fcitx-config-gtk3命令  
然后我的配置是这样的，就是shift键，保持和windows使用习惯统一  
[![](https://lian-gallery.oss-cn-guangzhou.aliyuncs.com/img/1636899123(1).png)](https://lian-gallery.oss-cn-guangzhou.aliyuncs.com/img/1636899123(1).png)

这里的教程可以参考：[https://monkeywie.cn/2021/09/26/wsl2-gui-idea-config/](https://monkeywie.cn/2021/09/26/wsl2-gui-idea-config/)  
搜狗输入法参考：[https://zhuanlan.zhihu.com/p/142206571](https://zhuanlan.zhihu.com/p/142206571)  
搜狗输入法配置命令：sogouIme-configtool  
我的配置和里面的不一样， 也没有遇到idea切不出输入法的问题  
如果有的话参考文章里的方法或者看：[https://github.com/microsoft/wslg/issues/278](https://github.com/microsoft/wslg/issues/278)

Q.E.D.