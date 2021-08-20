---
title: 如何让 YARN 支持 CNPM 的完整加速
date: 2021-08-20 10:47:42
tags:
- yarn
categories: 
- 前端
---

> 国内的前端开发人或多或少都了解过 cnpm ，但项目开发因人而异，很多时候不会或不能使用 cnpm ，不计其数的项目在使用 yarn 或者其他包管理器安装依赖。本文将介绍这样的情况下如何加速二进制文件下载。

在前一段时间发布的 Github Octoverse 2019 报告中，JavaScript 继续蝉联最受欢迎编程语言。JavaScript 生态的保持繁荣，与 Node.js 的流行密不可分。而说到 JavaScript 生态，不得不提到 npm，npm 不仅是前端开发首选的包管理器，也是除了 Github 之外最重要的代码共享途径。Snyk 2019 开源安全年报中指出，npm 生态的包数量远超其他包管理器。

![各个包管理器生态的包总数](https://gitee.com/hxf88/imgrepo/raw/master/img/bVbAY2R "各个包管理器生态的包总数")

现阶段，主流的前端开源项目在发布时都会使用 npm 的在线托管服务 [https://www.npmjs.com/](https://link.segmentfault.com/?url=https%3A%2F%2Fwww.npmjs.com%2F)。但开发者能够使用的包管理器却不止 npm 一个，来自开源社区的 yarn 和 pnpm 正在被越来越多人使用，它们最显著的优点就是加快依赖的安装速度。对于中国开发者，由阿里巴巴开源的 cnpm 也是一个重要的选择。

## 关于 CNPM 的那些事

由 `react` 和 `vue` 引领的前端工程化开发在国内大规模流行以来，前端项目的依赖安装成为了日常工作的重要组成部分。cnpm 的出现解决了由于网络环境造成的安装速度慢问题，受到了大量国内开发者的欢迎。

cnpm 的诞生早于 yarn 和 pnpm ，它使用 `npminstall` 模块执行安装。由淘宝开发团队维护的 npm 仓库镜像，会定时同步 npm 官方的所有模块 。cnpm 无需任何配置就会默认从淘宝镜像下载所有的包，从而达到国内加速的目的。具体的使用方式可以查看官方文档 [https://npm.taobao.org/](https://link.segmentfault.com/?url=https%3A%2F%2Fnpm.taobao.org%2F)。

虽然目前 cnpm 的速度一如既往得快，但对比其他竞品它却不再像刚诞生时那样有优势了，加上实际开发时莫名其妙的报错也难以解决，还有各种各样的其他因素。越来越多的团队又切换回了 npm ，或者转而使用具备更多功能的 yarn 或 pnpm 。

> yarn 是 Facebook 团队开源的包管理器，它能创建更扁平的依赖树，只会安装变更的模块，使用并行下载，用本机缓存加速安装。而 pnpm 作为黑马，其口碑甚至优于 yarn ，但由于笔者没有使用经验，所以不会在本文中介绍它的使用方式。

我想肯定有读者想吐槽，为什么不用 cnpm ，非要折腾？但这并没有具体的答案，每个团队，每个人都有各自的情况，无须妄加批评。终归都是发现问题解决问题。接下来会介绍怎么用最低限度的配置让 yarn 也获得 cnpm 的国内加速能力。

## NPM 和 YARN 使用镜像加速

这个部分不是什么新鲜内容了，所有的包管理器都可以设置仓库地址。具体的细节建议阅读 npm 的官方文档。

除了“众所周知的命令行配置法”以外，也可以在项目中创建 `.npmrc` 文件。如果将该文件一并提交到 Git 就能与所有环境共享该配置，利于多人协作，也可以被 CI 和其他第三方工具使用。因此也是笔者推荐使用的方法。

registry = https://registry.npm.taobao.org

yarn 同样也会读取这个文件，除非你在 .yarnrc 中覆盖了这一配置。

registry "https://registry.npm.taobao.org"

## 配置二进制文件的镜像地址

单纯的使用国内 npm 镜像并不能解决所有问题。最知名的例子：

为了简化 CSS 的编写，许多项目都会使用预处理器。在国内，预处理器`less`比生态更加完整的 `sass` 处理器流行的原因之一，便是因为 `sass` 的编译工具 `node-sass` 的安装曾经十分困难，许多公司、团队和个人开发者因此决定了选型使用 `less`。

`node-sass` 之所以难以安装，是它在 npm 安装流程之后，还会触发一个而外的编译流程。其中使用了 C++ 编译的二进制文件，该文件根据版本托管在 [https://github.com/sass/node-...](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fsass%2Fnode-sass%2Freleases) 。Github 使用了亚马逊的 AWS 服务作为 CDN，由于某些众所周知的原因，在中国大陆有时会无法访问。于是乎在该文件下载失败后，就会触发本机编译以生成替代的二进制文件，这一过程往往以失败告终（尤其是在 Windows 7 系统）。很多网络教程这时候会建议安装 C++ 相关的编译环境，也有人会说 “用 Linux 保平安”。

但实际上只要能解决二进制文件的下载问题就能大大提高成功率。淘宝镜像上也提供了相应的二进制包，通过设置环境变量使用国内加速。cnpm 内置了这一过程，所以可以自动解决这一情况。

不使用 cnpm 的话，则通过命令行设置环境变量：

yarn config set sass\_binary\_site https://npm.taobao.org/mirrors/node-sass/


SASS\_BINARY\_SITE=https://npm.taobao.org/mirrors/node-sass/ && yarn add node-sass

yarn add node-sass --sass\_binary\_site https://npm.taobao.org/mirrors/node-sass/

或者同样将其配置在 `.npmrc` 文件中达到分享配置的效果：

sass\_binary\_site = https://npm.taobao.org/mirrors/node-sass/
electron\_mirror = https://npm.taobao.org/mirrors/electron/

`phantomjs` 和 `electron` 等同样可以使用此方法加速，因为他们都允许使用环境变量设置镜像 url。我们可以在 [https://npm.taobao.org/mirrors](https://link.segmentfault.com/?url=https%3A%2F%2Fnpm.taobao.org%2Fmirrors) 上查看所有可用的镜像。

网络上绝大多数的文章也就到此为止了，然而这还不是全部。

## 使用 bin-wrapper-china

`imagemin` 是一系列基于 C++ 实现的图片压缩模块，其中包含了 `pngquant` 和 `mozjpeg` 等知名库，和 `node-sass` 一样需要下载二进制文件。然而它却没有不支持使用环境变量配置镜像仓库 url，自主编译的成功率也要低得多。这时候无论是 npm 还是 yarn 都只能听天由命祈祷网络畅通。

没错，cnpm 通过内置的处理也解决了这种情况，那是不是要吃回头草用 cnpm 呢？

当然不用，查看源码可以发现，相当一部分使用了二进制文件的模块，都会通过 `bin-wrapper` 执行下载和编译。于是乎只要能在下载之前将 `bin-wrapper` 内使用的下载链接替换成镜像仓库的 url，问题便迎刃而解。

笔者为此创建了一个工具 [bin-wrapper-china](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fbest-shot%2Fbin-wrapper-china)，该工具 fork 了原版的 `bin-wrapper`，并读取了 cnpm 所使用的 [binary-mirror-config](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fcnpm%2Fbinary-mirror-config) 获取所有可用的镜像淘宝镜像 url，替换下载文件的链接。这样就可以愉快地使用加速功能。那么问题来了，怎样用 `bin-wrapper-china` 代替 `bin-wrapper` 执行下载呢？

答案是使用 yarn 的杀手级功能 `resolutions` （npm 不支持），它允许我们用 yarn 执行安装时，用指定的模块替换另一个模块，具体的配置方法如下：

{
  "resolutions": {
    "bin-wrapper": "npm:bin-wrapper-china"
  }
}

`bin-wrapper-china` 的“冒名顶替”发生在安装过程之中，`bin-wrapper` 的运行发生在安装之后 ，所以能够无缝的运行。这样一来 `imagemin` 系列的安装成功率便能大为提高，关于 `resolutions` 的相关说明，详见：

-   [https://yarnpkg.com/lang/en/d...](https://link.segmentfault.com/?url=https%3A%2F%2Fyarnpkg.com%2Flang%2Fen%2Fdocs%2Fselective-version-resolutions%2F)
-   [https://github.com/yarnpkg/rf...](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fyarnpkg%2Frfcs%2Fblob%2Fmaster%2Fimplemented%2F0000-selective-versions-resolutions.md)

对于支持环境变量的模块，例如 `node-sass` 等，`bin-wrapper-china` 也能提供了 `china-bin-env` 命令代替手动环境变量的支持。但由于我们不建议注入 yarn 或 npm 本身，而环境变量的注入必须在安装之前执行，故在有需要的情况下在项目内手动设置 `preinstall` 命令：

{
  "scripts": {
    
    "preinstall": "npm install bin-wrapper-china -D && china-bin-env",
    
    "preinstall": "yarn add bin-wrapper-china -D && china-bin-env"
  }
}

基于 `preinstall` 的操作需要 `bin-wrapper-china` 的提前安装，笔者也希望后续有更好的解决方案。

## 总结

由于 cnpm 的一些功能缺失，我们可能会决定弃用它，但是它的加速能力又是我们所需要的。

总结起来，cnpm 做了三件事：

-   使用淘宝 npm 镜像仓库加速常规模块的安装。
-   可配置的二进制文件，提前注入环境变量进行加速。
-   不可配置的二进制文件，强行替换 url 加速下载。

这也是我们要做的三件事（通常配置在项目中）：

-   通过 .npmrc 文件配置 npm 仓库地址为国内镜像地址。
-   通过 .npmrc 文件配置环境变量，或通过 `bin-wrapper-china` 的 `china-bin-env` 命令注入环境变量。
-   配置 yarn resolutions， 用 `bin-wrapper-china` 冒充 `bin-wrapper` 实现 url 替换。

当然了，如果你下定决心使用 cnpm ，或者所处的工作网络能够畅通无阻，或者项目不需要安装含二进制文件的模块（例如笔者在项目中用 sass 替换 node-sass），就不需要考虑这问题了。本文虽然推荐使用 yarn ，但其核心流程适用于大多数 Node.js 生态内的包管理器，各位读者有兴趣可以做更多探索。

相关项目：

-   [https://github.com/best-shot/...](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fbest-shot%2Fbin-wrapper-china)
-   [https://github.com/cnpm/binar...](https://link.segmentfault.com/?url=https%3A%2F%2Fgithub.com%2Fcnpm%2Fbinary-mirror-config)
