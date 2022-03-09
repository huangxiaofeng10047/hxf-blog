---
title: 转载：Ubuntu 20.04安装RT-PREEMPT实时内核补丁
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-04 09:30:22
tags:
---

一、准备
1.1 获取内核源码与RT补丁
RT补丁： https://www.kernel.org/pub/linux/kernel/projects/rt/
内核源码： https://www.kernel.org/pub/linux/kernel

        对于某些内核版本找不到的场合，寻找相近的内核源码就可以，但是要注意到RT补丁与所下载的内核源码版本号需要严格对应。下载好后，将补丁包与解压后的内核源码文件夹放在同一级目录下。

1.2 安装依赖项
sudo apt-get install libncurses5-dev libssl-dev build-essential openssl zlibc libelf-dev minizip libidn11-dev libidn11 bison flex
二、安装补丁
        下面以linux-5.10.100-rt62的安装为例。

sudo mkdir /usr/src/rt_kernal
sudo cp ~/下载/linux-5.10.100.tar.xz /usr/src/rt_kernal/
sudo cp ~/下载/patch-5.10.100-rt62.patch.xz /usr/src/rt_kernal/
cd /usr/src/rt_kernal/
sudo su
xz -cd linux-5.10.100.tar.xz | tar xvf -
cd linux-5.1.100
xzcat ../patch-5.10.100-rt62.patch.xz | patch -p1
三、配置内核
        复制系统当前内核的.config文件

cp /boot/config-5.4.0-41-generic .config
        调用图形化界面，设置.config文件，改动结束后，在图形化界面最下边框选择save，则将当前的改动保存到.config文件中。

make menuconfig
     需要改动的地方主要是（带*号环节可以忽略）：

1. General setup

Preemption Model (Voluntary Kernel Preemption(Desktop))
—[x] Fully Preemptible Kernel(RT)

(如果在这一级找不到 Preemption model 的设置的话，在Processor type and featuer
里找)
*2. Kernel hacking

Memory Debugging
—[] check for stack overflow

(如果没有则忽略；如果默认关闭 就不用管了，这里针对的是默认开启内存溢出检查的场合)
*3. Device Drivers

—[] staging drivers

(如果默认开启，按N键取消)

        修改.config文件，搜索关键词，将
    
        CONFIG_MODULE_SIG_ALL
    
        CONFIG_MODULE_SIG_KEY
    
        CONFIG_SYSTEM_TRUSTED_KEYS
    
        CONFIG_SYSTEM_REVOCATION_LIST
    
        CONFIG_SYSTEM_REVOCATION_KEYS

五项注释掉，把CONFIG_DEBUG_INFO=y去掉，不然新内核带debug信息超大。

gedit .config
四、编译内核
        按照本机线程数设置编译线程，例子中本机为16线程。

make -j8
make modules_install -j8
make install 
update-grub
五、校验结果
cd /boot
ls
        查看/boot 目录下是否有生成的rt核心， 应该生成的文件包括：config-5.10.100-rt62、System.map-5.10.100-rt62、initrd.img-5.10.100-rt62、vmlinuz-5.10.100-rt62。

reboot
uname -r
        重启电脑，在开机引导中选择“linux-5.10.100-rt62”，开机后检查当前内核版本号，若为linux-5.10.100-rt62则正确安装实时内核补丁。

六、测试
        安装rt_test

sudo apt-get install rt-tests 
        运行测试（5个线程，线程优先级80，以ns显示时间）

sudo cyclictest -t 5 -p 80 -N
 测试结果中各项含义如下

T: 0     序号为0的线程
P: 0     线程优先级为0
C: 9397  计数器。线程的时间间隔每达到一次，计数器加1
I: 1000  时间间隔为1000微秒(us)
Min:     最小延时(us)
Act:     最近一次的延时(us)
Avg：    平均延时(us)
Max：    最大延时(us)  

七、启动设置
        如果重启后直接开机，没有出现选择内核的页面，则在进入系统后，执行下面的命令：

sudo gedit /etc/default/grub
GRUB_TIMEOUT=10  %超时时间，单位s

GRUB_DEFAULT="1>2"  %1代表默认启动内核，2代表所启动内核位于列表中第2个（序号从0开始）

        然后更新grub

sudo update-grub
————————————————
版权声明：本文为CSDN博主「看他个锤子」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_28882933/article/details/118293544
