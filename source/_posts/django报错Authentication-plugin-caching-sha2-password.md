---
title: django报错Authentication plugin 'caching_sha2_password)
date: 2021-08-17 11:58:28
tags:
- python
categories: 
- tools
---

1.报错如下：

```
django.db.utils.OperationalError: (2059, "Authentication plugin 'caching_sha2_password' cannot be loaded: /usr/lib64/mysql/plugin/caching_sha2_password.so: cannot open shared object file: No such file or directory")
```

2.报错原因:



mysql8.0提供了一种新的认证加密方式caching_sha2_password，建议需要更新到最新的connector与client。不过它还给了另一种选择，即沿用之前版本的加密方式 mysql_native_password。

3.解决方法：
(1)：更换低版本mysql
(2): 更改数据库加密的方式为：mysql_native_password
mysql -uroot -p
登录后

```
use mysql
ALTER USER 'hue'@'%' IDENTIFIED WITH mysql_native_password BY 'hue';
```

