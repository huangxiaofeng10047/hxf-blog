---
title: 一文教你用Typora + Gitee(码云) + PicGo 实现 云 markdown笔记
date: 2021-07-28 09:59:14
tags: gitee typora picgo
---

## 前言

你在开心写markdown文档时，有没有为图片的分享，而煎熬，现在通过picgo吧图片上传gitee上，实现文档的分享，会不会很开心。好的，下面开始介绍如何操作

1.picgo安装

下载picgo

<!--more-->

下载路径：

https://github.com/Molunerfinn/PicGo/releases

![image-20210728110457315](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728110457315.png)

如上图选择对应的安装文件下载：

点击安装picgo进行配置：

### 1.1 安装gitee插件

![image-20210728110604641](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728110604641.png)

输入gitee搜索：

![image-20210728110631995](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728110631995.png)

先安装gitee-uploader，再安装gitee 2.0.3

接下面配置图床：

 ![](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728111204092.png)

配置gitee图床：

1）*repo: 为 username + 仓库名，![image-20210728111307879](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728111307879.png)

2）branch: 分支，之前创建仓库的时候使用Readme文件初始化仓库的时候为我们创建了master 分支

3）*token:：私人令牌，获取方式
点击头像 --> 进入个人主页 --> 点击私人令牌 （私人令牌只出现一次，丢了需要重新创建）

4）path 设为img

5）customepath选择年月即可

点击确定，设为默认图床

点击测试上传，来验证是否生效

![image-20210728111621502](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728111621502.png)

![image-20210728111639810](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728111639810.png)

图片可以在gitee上看见

2.接下来配置typora

![image-20210728112225189](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728112225189.png)

对于typora还是需要在配置命令行，因为无法选择app

进入命令行目录

```
cd C:\Users\hxf\AppData\Roaming\Typora\picgo\win64
.\picgo.exe install gitee-uploader
.\picgo.exe  set uploader

```

选择gitee

配置如下：

```
{
  "picBed": {
    "current": "smms",
    "gitee": {
      "repo": "hxf88/imgrepo",
      "branch": "master",
      "token": "994875f6f8aacc9508dc707ade1485c1",
      "path": "img",
      "customPath": "yearMonth",
      "customUrl": ""
    },
    "uploader": "smms",
    "transformer": "path"
  },
  "picgoPlugins": {
    "picgo-plugin-gitee": true,
    "picgo-plugin-gitee-uploader": true,
    "picgo-plugin-smms-user": true
  }
}
```

![image-20210728112806311](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210728112806311.png)

当配置完后选择，testuploader，当看到上传成功即可。

下面就可以愉快写文档了。

