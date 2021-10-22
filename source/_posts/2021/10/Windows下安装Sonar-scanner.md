---
title: Windows下安装Sonar-scanner
date: 2021-10-21 15:55:14
tags: 
- springboot
categories: 
- java
---

Windows下安装sonarqube：https://www.jianshu.com/p/118dcf612333
 Windows下安装mysql：https://www.jianshu.com/p/ffcbfa05771f

## 下载

官网地址：[https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/](https://links.jianshu.com/go?to=https%3A%2F%2Fdocs.sonarqube.org%2Flatest%2Fanalysis%2Fscan%2Fsonarscanner%2F)

![image-20211021155909574](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211021155909574.png)

## 配置

环境变量的配置：



![img](https:////upload-images.jianshu.io/upload_images/23724430-eff52eefca22c3e9.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

##### 验证配置成功

命令行输入`sonar-scanner -version`，出现下面界面表示sonar-scanner安装配置成功。

![img](https:////upload-images.jianshu.io/upload_images/23724430-54ac688b69d9674a.png?imageMogr2/auto-orient/strip|imageView2/2/w/1092/format/webp)

image.png



## 扫描代码设置

1.到要检查的代码根目录下创建文件sonar-project.properties



```bash
# must be unique in a given SonarQube instance
sonar.projectKey=study
# this is the name and version displayed in the SonarQube UI. Was mandatory prior to SonarQube 6.1.
sonar.projectName=study
sonar.projectVersion=1.0

# Path is relative to the sonar-project.properties file. Replace "\" by "/" on Windows.
# This property is optional if sonar.modules is set.
sonar.sources=./src

sonar.java.binaries=./target/classes
sonar.language=java
# Encoding of the source code. Default is default system encoding
#sonar.sourceEncoding=UTF-8
```

2.命令行到要检查的代码目录下，输入命令：`sonar-scanner`
 检查的结果直接可以在浏览器SonarQube上查看

![img](https:////upload-images.jianshu.io/upload_images/23724430-e735fd3e37822f45.png?imageMogr2/auto-orient/strip|imageView2/2/w/1200/format/webp)

