---
title: centos卸载postgres
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-09 13:08:51
tags:
---

[centos安装与卸载postgresql](https://www.cnblogs.com/yanmiao/p/3262306.html)

1、卸载旧版本postgresql

```
$ yum remove postgresql*
```

![img](https://images0.cnblogs.com/blog/157758/201308/16151335-1435c349a5a448bc8fe016f87ef17b55.png)

2、更新yum

```
$ yum update
```

3、下载[pgdg-centos92-9.2-6.noarch.rpm](http://yum.pgrpms.org/9.2/redhat/rhel-5-x86_64/pgdg-centos92-9.2-6.noarch.rpm)，或者到http://yum.pgrpms.org/reporpms/选择相应版本

```
 wget http://yum.pgrpms.org/9.2/redhat/rhel-5-x86_64/pgdg-centos92-9.2-6.noarch.rpm
```

4、

```
rpm -ivh pgdg-centos92-9.2-6.noarch.rpm 
```

5、

```
$ sudo yum -y install postgresql92-server
```

![img](https://images0.cnblogs.com/blog/157758/201308/16152327-f4e7f5f830cf4b61ac03aeeb988c66da.png)

6、初始化

```
$ service postgresql-9.2 initdb
```

如果提示-bash: service: command not found，则需要设置环境变量

```
$vi .bash_profile
```

export PATH=$PATH:/sbin

7、启动postgresql

```
$ service postgresql-9.2 start
```

8、设置开机自动启动服务



```
chkconfig postgresql-9.2 on
```
