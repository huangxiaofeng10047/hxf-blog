---
title: Node.js 依赖镜像加速
date: 2021-08-20 10:36:39
tags:
- nodejs
categories: 
- nodejs
---

## [](https://gera2ld.space/posts/nodejs-mirror/#%E8%83%8C%E6%99%AF)背景

由于一些众所周知的原因，我们在安装 Node.js 依赖的时候，速度可能会很慢。

感谢国内的一些镜像服务，比如[阿里云NPM镜像](https://developer.aliyun.com/mirror/NPM)，让我们可以通过切换下载源来缩短下载时间。然而不同包的加载方式也不一样，使得整个加速过程并不是那么顺利。

然而还有很多包是依赖二进制文件的，这些文件可能会很大，可能由不同的服务器提供，可能以国内的网络条件很难下载成功。

正是这些包导致我们的安装一直卡住，像这样：

 [![hang](https://gitee.com/hxf88/imgrepo/raw/master/img/hang.png "hang")](https://gera2ld.space/static/01e36218d448a320d4c0107984ca66c5/1abaa/hang.png) 

## [](https://gera2ld.space/posts/nodejs-mirror/#%E7%BA%AFjs%E5%8C%85%E5%8A%A0%E9%80%9F)纯JS包加速

这个比较简单，镜像的文档里一般都会有，直接指定 `registry` 就可以了，如：

```
$ npm i --registry=https://registry.npm.taobao.org

$ yarn --registry=https://registry.npm.taobao.org
```

上面这种方式是临时指定 `registry`，然而我们并不希望每次安装依赖都加上这一串配置，所以可以通过修改全局配置来实现：

```
$ yarn config set registry https://registry.npm.taobao.org/
```

但是这样修改和切换也会比较麻烦，可以使用现成的工具 YRM 来辅助：

```

$ yarn global add yrm


$ yrm use taobao
```

这时再安装依赖，纯 JavaScript 实现的包的加载速度会得到明显的提升。

## [](https://gera2ld.space/posts/nodejs-mirror/#%E4%BA%8C%E8%BF%9B%E5%88%B6%E5%8C%85%E5%8A%A0%E9%80%9F)二进制包加速

除了纯JS的包以外，我们经常还会用到一些二进制的包，比如 Electron、SQLite3、图像处理相关的库等等。

这些包在不同的平台上对应不同的二进制文件，所以需要在安装时根据当前环境下载对应的文件。而很多包的二进制文件都放在 GitHub 上，国内下载非常困难。

实际上[阿里云NPM镜像](https://developer.aliyun.com/mirror/NPM)不仅提供了NPM包的镜像，同时也提供了一些二进制包的镜像。这里分几种类别介绍一下各种类型的二进制包如何加速。

### [](https://gera2ld.space/posts/nodejs-mirror/#%E6%BA%90%E7%A0%81%E7%BC%96%E8%AF%91)源码编译

部分包的二进制文件早已过时，只能通过源码编译，这时需要我们提前安装编译所需的各种依赖，然后在安装时编译。SQLite3 就是这种情况。

编译安装的好处是需下载的源码较小，不用花费太多时间在网络请求上。但是每次都需重新编译，依赖的环境比较复杂，首次安装时比较容易遇到一些疑难杂症，处理好之后就比较简单了。

一般来说，Windows 上搭建编译环境可以通过以下命令安装一个封装好的包来完成：

```
$ PYTHON_MIRROR=http://npm.taobao.org/mirrors/python npm install --global --production windows-build-tools
```

Linux / Mac OS 一般都有现成的工具链支持，这里就不深入展开了。

### [](https://gera2ld.space/posts/nodejs-mirror/#%E7%8E%AF%E5%A2%83%E5%8F%98%E9%87%8F%E6%94%AF%E6%8C%81)环境变量支持

某些包因为低速网络用户众多，一开始就特意考虑了镜像支持，会优先从环境变量读取镜像地址，然后拼接完整链接下载。

比如 Electron 的二进制文件通过 `@electron/get` 下载，可以通过配置 `ELECTRON_MIRROR` 进行提速：

```
export ELECTRON_MIRROR=https://cdn.npm.taobao.org/dist/electron/
```

### [](https://gera2ld.space/posts/nodejs-mirror/#bin-wrapper)bin-wrapper

还有很多包依赖的是第三方的二进制文件，和 Node.js 版本无关，没必要随 Node.js 编译。

比如图像处理相关的库，[cwebp-bin](https://github.com/imagemin/cwebp-bin)、[mozjpeg-bin](https://github.com/imagemin/mozjpeg-bin)、[pngquant-bin](https://github.com/imagemin/pngquant-bin)，都是采用以下流程安装的：

1.  使用 [bin-wrapper](https://github.com/kevva/bin-wrapper) 检测二进制文件是否已经安装成功；
2.  使用 [download](https://github.com/kevva/download) 尝试下载二进制文件；
3.  如果二进制文件下载失败，则从源码开始编译。

这种安装方式在低速网络下存在比较严重的问题：

-   [bin-wrapper](https://github.com/kevva/bin-wrapper) 内部写死了二进制文件的地址，导致无法使用镜像。
    
    虽然可以使用代理加速，但是可用性以及速度还是远不如镜像的。毕竟不是人人都能拥有可以从国外高速下载资源的代理，而且全局使用代理的话，那些支持国内镜像的资源反而速度会更慢。
    
-   源码下载很慢。
    
    早期的版本中，源码是从各种第三方网站下载的，失败率很高；后来在最新的版本改成了直接内置源码，从源码编译就拥有了上面所述的源码编译的优点和缺点。但是直到现在，很多用到这些工具的包依然引用的是早期的版本，所以即使使用源码编译，也经常因为下载太慢导致安装失败。
    
-   进度不明确。
    
    安装进度卡在 postinstall 时，我们是很绝望的，因为完全不知道后台在做什么。
    

[bin-wrapper](https://github.com/kevva/bin-wrapper) 内部使用的是 [download](https://github.com/kevva/download)，这个库最初的设计思想就是尽量简单，且避免留下副作用，所以它一直拒绝使用缓存，再加上硬编码的下载地址，使我们很难通过镜像进行优化。

### [](https://gera2ld.space/posts/nodejs-mirror/#download--rewrite)download + rewrite

为了解决不能使用镜像的问题，我 [fork了一份download](https://github.com/gera2ld/download)，通过 cosmiconfig 读取 rewrite 配置，然后在下载之前对 URL 做一次 rewrite，这样就有机会把原始链接替换成镜像的下载链接。

得益于 [yarn指定依赖版本的能力](https://classic.yarnpkg.com/en/docs/selective-version-resolutions/)，我们可以直接将依赖中的 [download](https://github.com/kevva/download) 强行替换成我改造的版本：

```

{
  "resolutions": {
    "download": "gera2ld/download#8.0.1"
  }
}
```

然后配置镜像链接：

```

{
  "rewrite": {
    "https://raw.githubusercontent.com/imagemin/cwebp-bin/": "https://npm.taobao.org/mirrors/cwebp-bin/",
    "https://raw.githubusercontent.com/imagemin/mozjpeg-bin/": "https://npm.taobao.org/mirrors/mozjpeg-bin/",
    "https://raw.githubusercontent.com/imagemin/pngquant-bin/": "https://npm.taobao.org/mirrors/pngquant-bin/"
  }
}
```

然后再下载依赖，速度杠杠的，瞬间就安装好了。
