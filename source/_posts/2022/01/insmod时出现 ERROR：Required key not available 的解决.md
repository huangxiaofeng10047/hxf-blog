
---
title: insmod时出现 ERROR：Required key not available 的解决
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
# insmod时出现 ERROR：Required key not available 的解决

解决方法如下：

在终端执行如下指令：

sudo apt install mokutil

sudo mokutil --disable-validation

会设置密码

重启，进入安全模式

按要求关闭掉验证模式。

