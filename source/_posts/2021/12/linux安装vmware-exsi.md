---
title: linux安装vmware exsi
date: 2021-12-15 11:30:18
tags:
---



**说明**  
**本脚本仅作为学习使用，请勿用于任何商业用途。**  
**本文为原创，遵循CC 4.0 by-sa版权协议，转载请附上原文出处链接和本声明。**

**本文链接：[https://www.cnblogs.com/4geek/p/12187463.html](https://www.cnblogs.com/4geek/p/12187463.html)**

 今天更新操作系统，更新完又出现了VMware-workstation无法启动的情况！启动后和上次一样提示kernel module updater，然后点击install提示在安装**vmnet**和**vmmon** 然而一会就有个失败的日志提示，打开看和上次的差不多。内容和具体原因可参见上一篇博文：[https://www.cnblogs.com/4geek/p/11511592.html](https://www.cnblogs.com/4geek/p/11511592.html)

 这次不想再像上次那样一步一步的去重新编译再替换，所以在想有没有什么办法可以在每次更新系统后出现同样问题时一键就能顺利打开VMware workstation呢？于是乎又是一顿google操作最终找见了方法。在这里记录下来，依然是为了方便踩入坑的你！

\[Toc\]

 翻了很多“文献”，很多社区都有被墙，这里就拿vmware官方的为列吧：[https://communities.vmware.com/thread/609330](https://communities.vmware.com/thread/609330)

![复制代码](https://common.cnblogs.com/images/copycode.gif)

![复制代码](https://common.cnblogs.com/images/copycode.gif)

 脚本可以直接前往Gitee下载：[为极客而生](https://gitee.com/forgeek/VMware_update.git)（https://gitee.com/forgeek/VMware\_update.git）

　　其中“VMWARE\_VERSION=workstation-15.5.1”，这里的版本号可以通过vmware-installer -l来查看。如果您的版本和我的不一样，是必须要修改以下脚本中的版本号。

![复制代码](https://common.cnblogs.com/images/copycode.gif)

![复制代码](https://common.cnblogs.com/images/copycode.gif)

![复制代码](https://common.cnblogs.com/images/copycode.gif)

![复制代码](https://common.cnblogs.com/images/copycode.gif)

　　**最后就是见证奇迹了！以后只要更新系统出现类似问题，只需要重新运行一下这个脚本就可以很方便的解决这个问题了！**

**[![](https://img2018.cnblogs.com/common/1765360/202001/1765360-20200113151637322-1627447771.png)](https://img2018.cnblogs.com/common/1765360/202001/1765360-20200113151637322-1627447771.png)**

\_\_EOF\_\_

![](https://images.cnblogs.com/cnblogs_com/4geek/1676724/o_200409162958geek.jpg)

centos上vmware启动不起来：

使用如下脚本解决（针对版本8.0）

```
#!/bin/bash
VMWARE_VERSION=workstation-15.5.1
TMP_FOLDER=/tmp/patch-vmware
rm -fdr $TMP_FOLDER
mkdir -p $TMP_FOLDER
cd $TMP_FOLDER
git clone https://github.com/mkubecek/vmware-host-modules.git
cd $TMP_FOLDER/vmware-host-modules
git checkout $VMWARE_VERSION
git fetch
make
sudo make install
sudo rm /usr/lib/vmware/lib/libz.so.1/libz.so.1
sudo ln -s /lib/x86_64-linux-gnu/libz.so.1 
/usr/lib/vmware/lib/libz.so.1/libz.so.1
sudo /etc/init.d/vmware restart
```



**目录**

[一、ESXi网络配置方法](https://blog.csdn.net/wxt_hillwill/article/details/119927089#t0)

[二、虚拟机网络配置方法](https://blog.csdn.net/wxt_hillwill/article/details/119927089#t1)

___

## 一、ESXi网络配置方法

1、搭建完成ESXi平台后，即可为它设置系统IP。如下图，在此界面按F2，输入用户名密码后进入配置界面：

![](https://img-blog.csdnimg.cn/20210826110756198.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_28,color_FFFFFF,t_70,g_se,x_16)

2、左侧菜单栏可以看到：

-   Configure Management Network：配置管理网络
-   Restart Management Network：重启管理网络
-   Test Management Network：测试管理网络

![](https://img-blog.csdnimg.cn/20210826110809861.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_28,color_FFFFFF,t_70,g_se,x_16)

3、进入Configure Management Network，可以看到：

![](https://img-blog.csdnimg.cn/2021082611083995.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_28,color_FFFFFF,t_70,g_se,x_16)

-   Network Adapters：网络适配器，选择可用的物理网卡；

![](https://img-blog.csdnimg.cn/20210826111054435.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_17,color_FFFFFF,t_70,g_se,x_16)

-   VLAN（optional）：输入VLAN

![](https://img-blog.csdnimg.cn/20210826111111707.png)

-   IPv4 Configuration：配置IPv4网络；

![](https://img-blog.csdnimg.cn/20210826111156812.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_17,color_FFFFFF,t_70,g_se,x_16)

-   DNS Configuration：配置DNS；
-   IPv6 Configuration：如果需要可以配置IPv6网络；
-   Custom DNS Suffixes：如果需要可以配置自定义DNS后缀；

4、保存好网络配置，Esc退出，再进入Restart Magagement Network界面重启网络。重启后平台的网络就能通了；

2、成功安装软件，打开软件包中的注册机，可以轻松生成vmware esxi 7.0序列号。
五组许可证，请用户自选：
JA0W8-AX216-08E19-A995H-1PHH2
JU45H-6PHD4-481T1-5C37P-1FKQ2
1U25H-DV05N-H81Y8-7LA7P-8P0N4
HV49K-8G013-H8528-P09X6-A220A
1G6DU-4LJ1K-48451-3T0X6-3G2MD
5U4TK-DML1M-M8550-XK1QP-1A052

## 二、虚拟机网络配置方法

1、登录平台的Web界面，在“网络”->“VMkernel网卡”界面就能看到刚才配置的Management Network。

        VMkernel网络适配器是ESXi用来主机管理的，下图中vmk0的IP是10.4.116.200，也就是说我们可以通过这个IP（http://IP）访问以及这台ESXi和它里面的资源；

![](https://img-blog.csdnimg.cn/2021082611124998.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_52,color_FFFFFF,t_70,g_se,x_16)

        编辑一下vmk0，可以看到它有哪些配置项：

![](https://img-blog.csdnimg.cn/20210826111310282.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_17,color_FFFFFF,t_70,g_se,x_16)

        VMware官网对这些配置项的解释如下：

-   MTU：选择是从交换机获取网络适配器的 MTU，还是设置自定义大小。不能将 MTU 大小设置为一个大于 9000 字节的值。MTU指的是最大传输单元（Maximum Transmission Unit，MTU）是指一种通信协议在某一层上面所能通过的最大数据报大小（以字节为单位），它通常与链路层协议有密切的关系。
-   TCP/IP堆栈：一共有三个选项（默认TCP/IP堆栈 、vMotion、 置备堆栈），如果选择 vMotion 或置备堆栈，则可用服务中只能使用 vMotion 或置备流量，而如果设置了置备 TCP/IP 堆栈，将可以使用所有可用服务。
-   可用服务：包括vMotion（允许 VMkernel 适配器向另一台主机播发声明，自己就是发送 vMotion 流量所应使用的网络连接）、置备（处理虚拟机冷迁移、克隆和快照迁移传输的数据）、Fault Tolerance日志记录、管理（流量管理）、复制（处理从源 ESXi 主机发送到 vSphere Replication 服务器的出站复制数据）和NFC复制（处理目标复制站点上的入站复制数据）。

2、在“网络”->“物理网卡”界面看到物理设备上所有的网卡；

![](https://img-blog.csdnimg.cn/2021082611142157.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_52,color_FFFFFF,t_70,g_se,x_16)

-   名称：物理网卡简称vmnic，ESXi内核的第一块称为vmnic0，第二块称为vmnic1。
-   驱动程序：因为物理网卡是一个硬件设备，所以需要有对应的驱动程序。接着驱动程序向操作系统内核注册该网卡设备，从而让内核识别该物理网卡。
-   MAC地址：MAC地址是一个是一个用来确认网络设备位置的位址，用于在网络中唯一标示一个[网卡](https://baike.baidu.com/item/%E7%BD%91%E5%8D%A1)，一台设备若有一或多个网卡，则每个网卡都需要并会有一个唯一的MAC地址。
-   自动协商：自动协商模式是端口根据另一端设备的连接速度和双工模式，自动把它的速度调节到最高的公共水平，即线路两端能具有的最快速度和双工模式。
-   链路速度：“链路已断开”说明此网口未接网线或不可用，“1000 Mpbs”可以判断该网口是一个千兆网口（下图可以看到这个环境中vmnic2、vmnic3是可用的网口，且均为千兆网口），“10000 Mpbs”可以判断该网口是一个万兆网口。
-   全双工：是指在发送数据的同时也能够接收数据，两者同步进行；而半双工刚好相反，同一时间只能发送或接收数据，两者不能同步进行。

3、接下来是“虚拟交换机”的界面。下图中的vSwitch0是安装成功之后界面上就会出现的，如果需要还可以配置其他的虚拟交换机：

        虚拟交换机，简称vSwitch，由ESXi内核提供，用于确保虚拟机和管理界面之间的相互通信。其功能与物理交换机相似。物理机通过网线或光纤连接到物理交换机的端口，而虚拟机通过虚拟网卡连接到虚拟交换机的虚拟端口。

![](https://img-blog.csdnimg.cn/20210826111450671.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_52,color_FFFFFF,t_70,g_se,x_16)

        编辑一下vSwitch0，可以看到这里有个“添加上行链路”的按钮，意思就是说可以在这里添加多个上行链路以达到故障冗余的效果：

![](https://img-blog.csdnimg.cn/20210826111505524.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_18,color_FFFFFF,t_70,g_se,x_16)

4、最后是“端口组”的界面，Management Network端口组是配置好步骤1~4之后就会生成的，VM Network端口组是我新建的，专门用于连接ESXi主机内虚拟机间的通讯，一个虚拟机必须连接到一个端口组（并且不能使用Management Network，必须新建一个或多个给虚拟机使用），已达到通过主机的物理网卡与外部通讯的效果，端口组无不需要地址。

        这里的Management Network就是物理网络。物理网络是为了使物理服务器之间能够正常通信而建立的网络。
    
        VM Network是虚拟网络，虚拟网络是在ESXi主机上运行的虚拟机为了互相通信而互相通信而逻辑连接形成的网络。

![](https://img-blog.csdnimg.cn/20210826111528775.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_52,color_FFFFFF,t_70,g_se,x_16)

        点进去可以看到VM Network的详情，虚拟交换机直使用了vSwitch0，然后安全、网卡绑定、流量调整全部从vSwitch继承下来：

![](https://img-blog.csdnimg.cn/20210826111545338.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_19,color_FFFFFF,t_70,g_se,x_16)

        然后我们就可以用这个VM Network端口组为虚拟机配置网络适配器，首先右键“虚拟机”，选择“创建/注册虚拟机”：

![](https://img-blog.csdnimg.cn/20210826111603377.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_15,color_FFFFFF,t_70,g_se,x_16)

         然后在第四步自定义设置中，网络适配器选择VM Network：        

![](https://img-blog.csdnimg.cn/20210826111625844.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_Q1NETiBAd3h0X2hpbGx3aWxs,size_25,color_FFFFFF,t_70,g_se,x_16)

         虚拟机创建完成，安装好系统后，就可以为它设置IP、网关、掩码、DNS了。配置好即可ping通。

# ESXI添加硬盘时提示 无法创建 VMFS 数据存储 - 无法更改主机配置

第一步：启用esxi ssh登录权限

查看对应硬盘的地址

![image-20211220135317667](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20211220135317667.png)

第二步： ssh上esxi服务器

第三步：

[root@localhost:~] partedUtil setptbl /vmfs/devices/disks/t10.ATA_____TOSHIBA_MG04ACA200N_____________________________51U6K1M6F69D msdos
msdos
0 0 0 0

第四步： 重新添加即可。

设置静态ip

本学习主要针对 Centos 7.0.1406 版本进行学习整理！

如果你使用 VirtualBox 配置 Centos 那么请参考我的这篇文章 Centos 7 学习之静态IP设置(续)

1、编辑 ifcfg-eth0 文件，vim 最小化安装时没有被安装，需要自行安装不描述。

# vim /etc/sysconfig/network-scripts/ifcfg-eth0
2、修改如下内容

BOOTPROTO="static" #dhcp改为static 
ONBOOT="yes" #开机启用本配置
IPADDR=192.168.7.106 #静态IP
GATEWAY=192.168.7.1 #默认网关
NETMASK=255.255.255.0 #子网掩码
DNS1=192.168.7.1 #DNS 配置
3、修改后效果

# ]# cat /etc/sysconfig/network-scripts/ifcfg-eth0
HWADDR="00:15:5D:07:F1:02"
TYPE="Ethernet"
BOOTPROTO="static" #dhcp改为static 
DEFROUTE="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_PEERDNS="yes"
IPV6_PEERROUTES="yes"
IPV6_FAILURE_FATAL="no"
NAME="eth0"
UUID="bb3a302d-dc46-461a-881e-d46cafd0eb71"
ONBOOT="yes" #开机启用本配置
IPADDR=192.168.7.106 #静态IP
GATEWAY=192.168.7.1 #默认网关
NETMASK=255.255.255.0 #子网掩码
DNS1=192.168.7.1 #DNS 配置
4、重启下网络服务

# service network restart
5、查看改动后的效果，Centois 7 不再使用 ifconfig 而是用 ip 命令查看网络信息。
# ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 1000
    link/ether 00:15:5d:07:f1:02 brd ff:ff:ff:ff:ff:ff
    inet 192.168.7.106/24 brd 192.168.7.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fe07:f102/64 scope link 
       valid_lft forever preferred_lft forever
