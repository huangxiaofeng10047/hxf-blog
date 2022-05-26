 traefik部署

参考文档：https://www.yuque.com/duiniwukenaihe/ehb02i/odflm7

traefik部署nacos

参考文档：https://www.yuque.com/duiniwukenaihe/ehb02i/vsg9vd

# 微服务网关方案：Kong & Nacos

参考文档:https://cloud.tencent.com/developer/article/1813843?from=article.detail.1813698

traefik

参考文档：https://www.qikqiak.com/post/traefik-2.1-101/

删除用 

rpm -e

rpm -q 是查询

iperf2安装：

# [rpm包安装过程中依赖问题“libc.so.6 is needed by XXX”解决方法](http://www.cnblogs.com/think3t/p/4165102.html)

前置依赖条件：

 yum install libstdc++.i686

yum install glibc.i686 

然后安装：

rpm -ivh iperf2-**



- 执行以下命令安装 nfs 服务器所需的软件包

  ```sh
  yum install -y rpcbind nfs-utils
  ```

- 执行命令

   

  ```
  vim /etc/exports
  ```

  ，创建 exports 文件，文件内容如下：

  ```text
  /root/nfs_root/ *(insecure,rw,sync,no_root_squash)
   
      
  ```

- 执行以下命令，启动 nfs 服务

  ```sh
  # 创建共享目录，如果要使用自己的目录，请替换本文档中所有的 /root/nfs_root/
  mkdir /root/nfs_root
  
  systemctl enable rpcbind
  systemctl enable nfs-server
  
  systemctl start rpcbind
  systemctl start nfs-server
  exportfs -r
   
      
  ```

- 检查配置是否生效

  ```sh
  exportfs
  # 输出结果如下所示
  /root/nfs_root /root/nfs_root
  ```



