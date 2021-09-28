---
title: yarn卡主解决办法
date: 2021-09-28 13:41:22
tags:
- hexo
- npm
categories: 
- node
---
更进一步
实际使用中不可能每个项目都复制一份 hooks scripts，要脱离 case by case 必须自动化。

不细讲，以下是最终版本，欢迎大家试用：

hook-binary-mirror

用法

```
全局安装 hook-binary-mirror 模块

# tnpm 方式

tnpm --by=npm i hook-binary-mirror -g

# npm 方式

npm --registry=https://registry.npm.taobao.org i hook-binary-mirror -g
```

删除原有的 node_modules 目录
```
cd project_dir
rm -rf node_modules
```

为 package.json 增加一处 scripts

```
"scripts": {
  "preinstall": "hook-binary-mirror"
}
```

完成

结束
困扰了半年多的问题终于解决，此项任务终于可以放心的置为「已结束」。过程中翻阅了 npminstall 的源码，获益良多。

![image-20210928134652339](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210928134652339.png)

![image-20210928134715920](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210928134715920.png)

**简介：** \# 背景 半年前开始关注 \`npm shrinkwrap\` ，因为项目里每次 \`npm install\` 都会出现因依赖库版本不一致导致的构建问题。 当时的默认安装工具是 tnpm，由于 tnpm 从 cnpm 来，cnpm 又通过 npminstall 实现，而 npminstall 又不支持 \`shrinkwrap\` ，无奈只能考虑通过 npm 方式进行安装。

半年前开始关注 `npm shrinkwrap` ，因为项目里每次 `npm install` 都会出现因依赖库版本不一致导致的构建问题。

当时的默认安装工具是 tnpm，由于 tnpm 从 cnpm 来，cnpm 又通过 npminstall 实现，而 npminstall 又不支持 `shrinkwrap` ，无奈只能考虑通过 npm 方式进行安装。

官方 npm 没有 `@ali` 依赖，必须使用 `--registry=http://registry.npm.alibaba-inc.com` 指定资源仓库。

对于一般的项目，设置一个别名即可解决这个问题：

```
alias alinpm='npm --registry=http://registry.npm.alibaba-inc.com'

alias alinpm='npm --registry=https://registry.npm.taobao.org'
```

但问题又来了，本地项目中有一模块 `@ali/imagemin` 依赖以下这些模块：

-   advpng-bin
-   jpeg-recompress-bin
-   jpegtran-bin
-   optipng-bin
-   pngcrush-bin
-   pngquant-bin

这些模块安装时会从 github 下载执行文件，具体流程如下：

> ![image.png](https://gitee.com/hxf88/imgrepo/raw/master/img/1442ad90c72f5ce693277607fc449e81.png "image.png")

因为有两处逻辑涉及下载，而下载地址又是 github cdn。国内环境不出意外的话一定被墙，所以 npm 安装方式行不通，安装到 pngquant 时会报 `pngquant pre-build test failed`。之后走源码构建逻辑又从 github 下载，继续报 `pngquant failed to build`：

> ![image.png](http://ata2-img.cn-hangzhou.img-pub.aliyun-inc.com/ed796b796d448ae67b228778b9422a25.png "image.png")

但奇怪的是 tnpm 安装却一切正常：

> ![image.png](https://gitee.com/hxf88/imgrepo/raw/master/img/821485c7291d941c457e001d4cfe86fc.png "image.png")

非常有意思，扒扒 npminstall 源码跟踪安装流程，发现 `bin/install.js` 脚本中有一段：

```

const inChina = argv.china || !!process.env.npm_china;

const customChinaMirrorUrl = argv['custom-china-mirror-url'];
```

顺着 `customChinaMirrorUrl` 找到了：

> ![image.png](https://gitee.com/hxf88/imgrepo/raw/master/img/724ef99994e9b926e6658023de82baf6.png "image.png")

这段代码表示从这几处资源仓库里找 `binary-mirror-config` 模块的最新版本，下载后返回`mirrors.china`。搜一下，发现 npminstall 用了一个比较鸡贼的办法：

> ![image.png](http://ata2-img.cn-hangzhou.img-pub.aliyun-inc.com/c813d05b2244ded7598a8e805e99123f.png "image.png")

case by case 的把所有需要下载的二进制全做了一次镜像！

抑制不住兴奋继续往下扒，看看在哪里做了处理：

```
yield installLocal(config);
 + require('./local_install')
  + _install()
   + installOne()
    + install()
     + _install()
      + download()
       + npm()
        + download()
```

终于在 `lib/download/npm.js` 的第 238 行看到了 `pngquant-bin`：

```


const indexFilepath = path.join(ungzipDir, 'lib/index.js');
yield replaceHostInFile(pkg, indexFilepath, binaryMirror, options);
const installFilepath = path.join(ungzipDir, 'lib/install.js');
yield replaceHostInFile(pkg, installFilepath, binaryMirror, options);
```

npminstall 在下载流程里单独处理了所有需要镜像的二进制执行文件，找到一处匹配就 replace 其 binary host，起到镜像的效果。

找到关键点就好办了，目前有两种方案：

1.  单独为每个模块的 package.json 添加 postinstall 脚本
2.  通过 npm 钩子 `hooks script` 对所有模块单独进行处理

修改别人的模块显然不可能，那就只能用方案2了

要使 `hooks script` 起作用，得在 node\_modules 目录里创建一个 .hooks 目录，里面存放着以「事件名称」命名的脚本文件（安装脚本请参见：[npm scripts](https://docs.npmjs.com/misc/scripts)）

```
project_dir
 + node_modules
  + .hooks
   + preinstall <---
```

在 preinstall 脚本里可以使用 `process.env.npm_package_name` 获得当前安装的模块名称，伪代码如下：

```

if('pngquant-bin' === process.env.npm_package_name){
    const PWD = process.env.PWD;
    replaceHostInFile(path.join(PWD, 'lib/index.js'));
    replaceHostInFile(path.join(PWD, 'lib/install.js'));
}
function replaceHostInFile(filepath) {
    const exists = fs.existsSync(filepath);
    if (!exists) return;
    let content = fs.readFileSync(filepath, 'utf8');
    content = content.replace(/\/\/raw\.github\.com/, '//raw.github.cnpmjs.org');
    content = content.replace(/\/\/github\.com/, '//github.com.cnpmjs.org');
    fs.writeFileSync(filepath, content);
}
```

执行结果：

> ![image.png](https://gitee.com/hxf88/imgrepo/raw/master/img/61e31dd5f4b860c24a50c5f30d7a4717.png "image.png")

到此，问题已完全解决，安装上最新的 npm 5.x ，轻松使用 `package-lock.json` 提供的版本锁定特性。

实际使用中不可能每个项目都复制一份 hooks scripts，要脱离 case by case 必须自动化。

不细讲，以下是最终版本，欢迎大家试用：

[hook-binary-mirror](https://www.npmjs.com/package/hook-binary-mirror)
