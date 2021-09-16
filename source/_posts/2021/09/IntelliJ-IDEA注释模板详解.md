---
title: IntelliJ IDEA注释模板详解
date: 2021-09-15 16:04:17
tags:
- java
- idea
categories: 
- java
---

一、首先我们来设置IDEA中类的模板：（IDEA中在创建类时会自动给添加注释）

File-->settings-->Editor-->File and Code Templates-->Files（Idea默认的快捷键为ctrl+alt+s）

<!--more-->

修改FileHead文件

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915160559199.png" alt="image-20210915160559199" style="zoom:150%;" />

文件内容如下：

```
/**
* All rights Reserved, Designed By xfhuang
* @ProjectName: ${PROJECT_NAME}
* @Package: ${PACKAGE_NAME}
* @ClassName: ${NAME}
* @Description: []
* @Author: [xf huang]
* @Date: ${DATE} ${TIME}
* @Version: V1.0
* @TODO: 注意,本文件xf huang所作,如果转载或使用请标明具体出处!
**/
```

效果图示为

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915160722871.png" alt="image-20210915160722871" style="zoom:150%;" />

二、设置方法注释模板

1、设置Live Templates，File-->Settings-->Editor-->Live Templates

1.1添加Template Group

![image-20210915160843063](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915160843063.png)

![image-20210915160917493](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915160917493.png)

1.2 选中已添加的Template Group（common templates）,点击+，添加 【1.Live Template 】

![image-20210915161007692](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915161007692.png)

选择edit VARIABLES，然后进行如下图选择

![image-20210915161045628](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915161045628.png)

在方法上输入/** + 回车后，可以看到效果

![image-20210915161141499](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210915161141499.png)

