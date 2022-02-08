---
title: vscode链接wsl2失败记录
date: 2021-09-26 17:29:49
tags:
- vscode
categories: 
- wsl2
---

出现的现象：

```
Unsupported console settings. In order to use this feature, the legacy conso
```



```
wsl2 code  Unable to read file 'vscode-remote://wsl+archlinux/home/hxf/cdhproject/kafkademo/0283-kafka-shell' (Error: Command failed: C:\WINDOWS\Sysnative\wsl.exe -d ArchLinux sh -c [ -f '/tmp/vscode-distro-env.DmgP2k' ] && cat '/tmp/vscode-distro-env.DmgP2k' || echo '').
```

这两个报错，所以无法打开wsl中文件

解决办法：

![image-20210926173214021](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926173214021.png)

去掉红圈缩圈的地方，这个地方会造成上面的报错：

去掉后成功，使用code。

特此记录

出现这种问题很无语

通过google和baidu都无法解决问题

通过everyting还查到wsl.exe有问题，但经过实际测试，发现不是这种问题，

上面的 解决办法是碰到的。

