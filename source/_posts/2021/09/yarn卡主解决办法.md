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

