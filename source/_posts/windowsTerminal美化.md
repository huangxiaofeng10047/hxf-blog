---
title: windowsTerminal美化
date: 2021-07-29 17:32:47
tags:  windowsTerminal powershell7
---

安装 Window Terminal 

有两种安装方式，这个要自行选择

 git 安装

  1.0正式版本已经发布了，不需要自行编译了。直接去Github Window Terminal下载安装即可 

商店安装
<!--more-->
在微软商店里搜windows terminal，安装即可。 1、商店打不开的，自行解决，直接了当的方式就是升级系统到最新版本，重启。 2、提示当前所在的区域不支持的话 ： 登录账号的进账号把自己所在区域地址改成美国，然后把系统时间设置成美国。重启 正常情况下，你会安装成功的。 可以继续往下看了，先放一张图：

![image-20210730112728438](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210730112728438.png)我们需要安装以下模块：


```

Install-Module git-aliases -AllowColbber
Install-Module posh-git
Install-Module oh-my-posh
Install-Module DirColors#让ls等命令可以像Unix系统终端一样具有多彩的颜色。

```

## 保存配置

```
 notepad $PROFILE
```

通过notepad打开配置文件：

输入以下内容：

```
Import-Module posh-git # 引入 posh-git
Import-Module oh-my-posh # 引入 oh-my-posh
Import-Module DirColors
Import-Module git-aliases -DisableNameChecking

Set-PoshPrompt -Theme PowerLine

Set-PSReadLineOption -PredictionSource History # 设置预测文本来源为历史记录

Set-PSReadlineKeyHandler -Key Tab -Function Complete # 设置 Tab 键补全
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function MenuComplete # 设置 Ctrl+d 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo # 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward # 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward # 设置向下键为前向搜索历史纪录
```

## 分屏

windows terminal 也支持分屏，分屏的快捷键为：

- 水平分屏 alt + shift + - (减号)
- 垂直分屏 alt + shift + + (加号)

切换当前的分屏视图：alt + left/right/up/down
调整分屏的窗口的大小：alt + shift + left/right/up/down

缩放当前视图：ctrl + +/-/鼠标滚轮

退出当前分屏视图：直接输入`exit`

参考文章：[windows terminal 终极美化](https://www.chuchur.com/article/windows-terminal-beautify)

[https://blog.tcs-y.com/2021/05/24/windows-powershell-beautify/](https://blog.tcs-y.com/2021/05/24/windows-powershell-beautify/)

## 删除丑陋的xxx@hostname

 subl  ~/jandedobbeleer.omp.json      

修改对应的theme中

```
{
  "type": "session",
  "style": "diamond",
  "foreground": "#ffffff",
  "background": "#c386f1",
  "leading_diamond": "\uE0B6",
  "trailing_diamond": "\uE0B0",
  "properties": {
    "display_default": false  ##这个很重要，通过来让hostname显示
  }
}
```

notepad $PROFILE



1. In my powershell profile, I set the new environment variable to my own username: 
2. `$env:POSH_SESSION_DEFAULT_USER = [System.Environment]::UserName`

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210902170000719.png" alt="image-20210902170000719" style="zoom:150%;" />

即可。

看效果：

![image-20210902170027584](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210902170027584.png)

完美！！！！

