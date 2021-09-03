---
title: mm-wiki搭建记录
date: 2021-09-02 14:45:54
tags:
- wiki
categories: 
- devops
---

第一步创建目录：



```
mkdir  -p /data/mm-wiki/conf/
mkdir -p /data/mm-wiki/data
mkdir /data/mm-wiki/docs/search

```

第二步创建服务

```
docker run -d -p 8080:8081 -v /data/mm-wiki/conf/:/opt/mm-wiki/conf/ -v /data/mm-wiki/data:/data/mm-wiki/data/  -v /data/mm-wiki/docs/search_dict/:/opt/mm-wiki/docs/search_dict/ --name mm-wiki huangxiaofenglogin/mm-wiki-image:v1.0.1
```

遇到问题：

构建自己的镜像，因为官方镜像会报错，提示dictionary.txt不存在

