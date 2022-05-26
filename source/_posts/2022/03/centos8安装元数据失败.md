---
title: centos8安装元数据失败
description: '下载元数据失败'
date: 2022-03-03 09:08:10
tags:
---

centos8 进行yum update 出现了，下载元数据失败。这是因为centos8不维护的原因。

解决这个问题需要修改yum.repos.d文件下内容：

路径为：`/etc/yum.repos.d`

修改三个文件：

第一个文件：`CentOS-Base.repo`

```

# CentOS-Base.repo
[BaseOS]
name=CentOS-$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
baseurl=https://mirrors.aliyun.com/centos/$releasever-stream/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

```

第二个文件： `CentOS-AppStream.repo`

```

# CentOS-AppStream.repo
[AppStream]
name=CentOS-$releasever - AppStream
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
baseurl=https://mirrors.aliyun.com/centos/$releasever-stream/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

```

第三个文件：`CentOS-Extras.repo`

```
 cat CentOS-Extras.repo
# CentOS-Extras.repo
[extras]
name=CentOS-$releasever - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
baseurl=https://mirrors.aliyun.com/centos/$releasever-stream/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

```

修改后需要重新生成元数据

```
yum clean all
yum makecache
```

当出现下图时，证明成功

![image-20220303091511447](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20220303091511447.png)

开机启动服务：

在linux下，有一个目录专门用以管理所有的服务的启动脚本的，即/etc/rc.d/init.d下，进去看看，
