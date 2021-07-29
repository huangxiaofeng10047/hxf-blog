---
title: yarn设置淘宝镜像源
date: 2021-07-29 09:04:29
tags: yarn
---

全局修改：

```shell
yarn config set registry https://registry.npm.taobao.org/
```

临时修改

```shell
yarn save 软件名 --registry https://registry.npm.taobao.org/
```

```
# 全局配置，单台设备上永久生效
yarn config set sass_binary_site https://npm.taobao.org/mirrors/node-sass/

# 针对单次安装
SASS_BINARY_SITE=https://npm.taobao.org/mirrors/node-sass/ && yarn add node-sass
# or
yarn add node-sass --sass_binary_site https://npm.taobao.org/mirrors/node-sass/
```

