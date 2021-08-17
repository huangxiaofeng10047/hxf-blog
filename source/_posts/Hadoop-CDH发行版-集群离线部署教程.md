---
title: Hadoop-CDH发行版--集群离线部署教程
date: 2021-08-17 13:47:18
tags:
- shell
categories: 
- bigdata
---

为贴近真实环境,本文档假设以下条件:

1.集群中各机器无法连接外网,只能通过内网向集群发送文件  
2.集群内各机器间网络互通  
3.操作者拥有集群内各机器的root权限

1.  jdk(这一步放到了脚本中) 从上面配置好的apache上下载,集群每个主机必须安装受支持的统一版本,Cloudera强烈建议安装在`/usr/java/jdk-version`目录下,这样可以自动检测到它

1.挂载iso,并复制文件供http挂载(vm虚拟机上该方案有可能因inode不足而失败,提供备选方案)

```
# 复制到大量文件到某一目录下可能出现inode节点数不足或空间不足的现象,需要预先处理

mkdir -p /data/iso
mount -o loop -t iso9660 /home/yangzhaoyunfei/CentOS-7-x86_64-Everything-1804.iso  /data/iso
mkdir -p /data/centos7
cp -rf  /data/iso/*  /data/centos7
umount /data/iso/

# vw虚拟机上使用如下脚本
mkdir -p /data/iso
mount /dev/cdrom  /data/iso
mkdir -p /data/centos7
cp -rf  /data/iso/*  /data/centos7
umount /data/iso/

```

2.制作并只启用本地yum源(因为无法连接外网,所以必须使用本地源)

```
cd /etc/yum.repos.d/
ll
# 备份原repo文件
for file in `ls` ;do sudo mv $file $file"bak";done
ll

cat>/etc/yum.repos.d/local.repo<<EOF
[local] 
name=local
baseurl=file:///data/centos7
enabled=1
gpgcheck=0 
EOF

#验证
yum clean all
yum makecache

```

> 前置要求: local repo

```
# 禁用防火墙
systemctl stop firewalld.service
systemctl disable firewalld.service
# 禁用selinux
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
reboot

yum install -y httpd
systemctl enable httpd
systemctl start httpd
# 软链接挂载
cd /var/www/html && ll
ln -s /data/centos7/ /var/www/html/centos7 && ll

```

访问浏览器[http\_yum](http://192.168.181.128/centos7)测试

```
# 如果无法访问,检查firewall,检查selinux,正确配置后重启
# service httpd restart
```

> 上一步制作的local.repo可以启用,统一采用http.repo

```
mv /etc/yum.repos.d/local.repo /etc/yum.repos.d/local.repobak && ll /etc/yum.repos.d/

cat>/etc/yum.repos.d/http.repo<<EOF
[http] 
name=http
baseurl=http://192.168.181.128/centos7
enabled=1
gpgcheck=0 
EOF

ll /etc/yum.repos.d/
yum clean all
yum makecache

```

将下载的jdk也挂载到http中

```
mkdir -p /data/softwares/ 
# 将jdk,jdbc驱动等放到这个文件夹中
ln -s /data/softwares/ /var/www/html/softwares

```

访问浏览器[http\_softwares](http://192.168.181.128/softwares)验证

1.下载Tarball

```
Cloudera Manager 5: https://archive.cloudera.com/cm5/repo-as-tarball/
```

2.解压缩tarball，将文件移动到Web服务器目录，然后修改文件权限

```
tar xvfz cm5.15.1-centos7.tar.gz
sudo mv cm /var/www/html
sudo chmod -R ugo+rX /var/www/html/cm

```

访问[cm\_rpms](http://192.168.181.128/cm)验证是否正确设置 3.创建repo文件

```
cat>/etc/yum.repos.d/cloudera-repo.repo<<EOF
[cloudera-repo]
name=cloudera-repo
baseurl=http://192.168.181.128/cm/5
enabled=1
gpgcheck=0
EOF

yum clean all
yum makecache

```

1.先从cloudera官网下载对应系统平台的 \*\*\*parcel and manifest.json and sha1 文件

```
CDH 5: Impala, Kudu, Spark 1, and Search are included in the CDH parcel.
    CDH - https://archive.cloudera.com/cdh5/parcels/
    Accumulo - - https://archive.cloudera.com/accumulo-c5/parcels/
    GPL Extras - https://archive.cloudera.com/gplextras5/parcels/
Cloudera Distribution of Apache Spark 2 for CDH 5:
    The exact parcel name is dependent on the OS. You can find all the parcels at https://archive.cloudera.com/spark2/parcels/.
Sqoop Connectors:
    https://archive.cloudera.com/sqoop-connectors/parcels/
```

1.移动`.parcel, .sha1 and manifest.json`文件到web server目录,然后修改权限

```
sudo mkdir -p /var/www/html/cloudera-parcels/cdh5/5.15.1/
sudo mv *.parcel* /var/www/html/cloudera-parcels/cdh5/5.15.1/
sudo mv manifest.json /var/www/html/cloudera-parcels/cdh5/5.15.1/
sudo chmod -R ugo+rX /var/www/html/cloudera-parcels/cdh5/5.15.1/

```

> 5.15.1 替换为你的版本 (如 5.14.0)

访问[cdh\_parcels](http://192.168.181.128/cloudera-parcels/cdh5/5.15.1)

```
#服务端(master)
yum install -y chrony

vi /etc/chrony.conf
# 注释以下四个外网时间同步服务器,并添加master机器为时间同步服务器
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 192.168.181.128 iburst

# 重启服务
systemctl restart chronyd
chronyc -a makestep
chronyc sources -v

```

cat»/etc/sysctl.conf«EOF ####################### 自行添加 ########################### #关闭ipv6 net.ipv6.conf.all.disable\_ipv6 = 1 net.ipv6.conf.default.disable\_ipv6 = 1 ####################### 自行添加 ########################### EOF

````

## 安装expect, 执行脚本(仅master)
```bash
# 上传脚本及hostname文件
yum -y install expect

chmod +x InstallCDH_SSH.sh

./InstallCDH_SSH.sh root root hostsname.txt 

````

> 前置要求: 配置cm,cdh的repo(rpm)库

```
sudo yum install -y cloudera-manager-daemons cloudera-manager-server

```

> 为Cloudera Software安装和配置MariaDB  
> cloudera建议的配置文件在centos7.5自带5.x mariadb下无法启动,可能需要只适合10.x版本

```
# 安装,开机自启,启动
sudo yum install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

# 停止数据库服务,mariadb配置文件`/etc/my.cnf`,修改内容为
>这个配置文件不适用与centos7自带5.x mariadb
sudo systemctl stop mariadb
mv /etc/my.cnf /etc/my.cnfbak
############################################# 这个配置文件不适用与5.x mariadb
cat>/etc/my.cnf<<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks;
# to do so, uncomment this line:
symbolic-links = 0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MariaDB, if you enable the binary log and do not set
#a server_id, MariaDB will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
EOF

# 修改完配置后重新启动数据库
sudo systemctl start mariadb

# 运行脚本 为MariaDB进行初始化,包括设置root密码和一些选项:(^mariadbtxzpw01&FR)
sudo /usr/bin/mysql_secure_installation

```

```
# 输出如下
[...]
Enter current password for root (enter for none):
OK, successfully used password, moving on...
[...]
Set root password? [Y/n] Y
New password:
Re-enter new password:
[...]
Remove anonymous users? [Y/n] Y
[...]
Disallow root login remotely? [Y/n] N
[...]
Remove test database and access to it [Y/n] Y
[...]
Reload privilege tables now? [Y/n] Y
[...]
All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!

```

```
# 前置要求: 将下载的Connector上传到http的softwares目录中
curl http://192.168.181.128/softwares/mysql-connector-java-5.1.47.tar.gz -O --progress 
tar zxvf mysql-connector-java-5.1.47.tar.gz
sudo mkdir -p /usr/share/java/
cd mysql-connector-java-5.1.47
sudo cp mysql-connector-java-5.1.47-bin.jar /usr/share/java/mysql-connector-java.jar

```

```
# 登陆mariadb
mysql -u root -p
# 输入密码(^mariadbtxzpw01&FR)
```

```
# 执行以下sql,完成创建数据库,创建用户,授予权限
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON metastore.* TO 'hive'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY '^cdhtxzpw01&FR';
SHOW DATABASES;
# 查看所有用户
SELECT DISTINCT CONCAT('User: ''',user,'''@''',host,''';') AS query FROM mysql.user;
# 可以查看某用户的权限信息
SHOW GRANTS FOR 'scm'@'%';

```

> 前置要求: 安装cms,创建cms数据库,mariadb与cms在同一主机上,如果不在,参考官方文档  
> 备注: cms包含一个可以为自己创建和配置数据库的脚本scm\_prepare\_database.sh

```
# 对上一步创建的数据库依次运行下面的命令
#sudo /usr/share/cmf/schema/scm_prepare_database.sh <databaseType> <databaseName> <databaseUser>
# <databaseName>是cms要使用的数据库,其会在其中创建一些表用来保存管理数据等,如果指定-p -u选项,这回创建这个数据库
# <databaseType>填mysql
# <databaseUser>要创建或使用scm数据库的用户名,[创建权限的时候已经默认创建了该用户]


# 例如,出现提示后输入scm数据库的访问密码(^cdhtxzpw01&FR)
sudo /usr/share/cmf/schema/scm_prepare_database.sh mysql scm scm

# 上一步中,如果没有创建cms数据库,则必须使用 -u -p 选项来创建cms数据库,命令如下
sudo /usr/share/cmf/schema/scm_prepare_database.sh mysql -uroot -p
```

输出如下

```
[root@foo-1 yangzhaoyunfei]# sudo /usr/share/cmf/schema/scm_prepare_database.sh mysql scm scm
Enter SCM password: 
JAVA_HOME=/usr/java/jdk1.8.0_162
Verifying that we can write to /etc/cloudera-scm-server
Creating SCM configuration file in /etc/cloudera-scm-server
Executing:  /usr/java/jdk1.8.0_162/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/java/postgresql-connector-java.jar:/usr/share/cmf/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
[                          main] DbCommandExecutor              INFO  Successfully connected to database.
All done, your SCM database is configured correctly!
```

> 前置要求: 系统环境,jdk,database,connector,元数据库,配置cdh的repo(rpm)/http(parcel)库;数据库;数据库连接驱动,cms

```
# 启动cms
sudo systemctl start cloudera-scm-server

# 查看启动日志
sudo tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

```

```
# 输入如下, 日志出现 Started Jetty server. ,启动成功
[yangzhaoyunfei@foo-1 ~]$ sudo tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
2018-08-29 14:00:36,582 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Generating entities:2018-08-29T06:00:36.582Z
2018-08-29 14:00:36,590 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Num entities:208
2018-08-29 14:00:36,590 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Generating documents:2018-08-29T06:00:36.590Z
2018-08-29 14:00:36,630 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Num docs:221
2018-08-29 14:00:36,630 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Constructing repo:2018-08-29T06:00:36.630Z
2018-08-29 14:00:37,249 INFO WebServerImpl:org.mortbay.log: jetty-6.1.26.cloudera.4
2018-08-29 14:00:37,261 INFO WebServerImpl:org.mortbay.log: Started SelectChannelConnector@0.0.0.0:7180
2018-08-29 14:00:37,261 INFO WebServerImpl:com.cloudera.server.cmf.WebServerImpl: Started Jetty server. #出现这句启动成功
2018-08-29 14:00:37,356 INFO SearchRepositoryManager-0:com.cloudera.server.web.cmf.search.components.SearchRepositoryManager: Finished constructing repo:2018-08-29T06:00:37.356Z
2018-08-29 14:00:42,368 INFO ScmActive-0:com.cloudera.server.cmf.components.ScmActive: ScmActive completed successfully.

```

浏览器打开[安装界面](http://192.168.181.128:7180/)进行安装

1.  `群集安装-->选择存储库-->选择方法`
2.  `使用 Parcel (建议)` , `更多选项`
3.  `删除所有远程 Parcel 存储库 URL`
4.  添加本地parcel库地址 `http://192.168.181.128/cloudera-parcels/cdh5/5.15.1/`
5.  其他 `Spark 2,Sqoop Connectors,cdh5` 等组件设置等同.
6.  选择您要安装在主机上的 Cloudera Manager Agent 特定发行版,`自定义存储库`
7.  agent存储库地址为上面配置过的cm repo地址 `http://192.168.181.128/cm/5/`
8.  因为配置过`ssh互信`,`提供 SSH 登录凭据` 选择 `接受相同私钥,把master的私钥下载后选中`

解决检查出的问题后继续

```
Cloudera 建议将 /proc/sys/vm/swappiness 设置为最大值 10。当前设置为 60。使用 sysctl 命令在运行时更改该设置并编辑 /etc/sysctl.conf，以在重启后保存该设置。您可以继续进行安装，但 Cloudera Manager 可能会报告您的主机由于交换而运行状况不良。以下主机将受到影响： 
 查看详细信息
foo-[1-3].mycluster.com
已启用透明大页面压缩，可能会导致重大性能问题。请运行"echo never > /sys/kernel/mm/transparent_hugepage/defrag"和"echo never > /sys/kernel/mm/transparent_hugepage/enabled"以禁用此设置，然后将同一命令添加到 /etc/rc.local 等初始化脚本中，以便在系统重启时予以设置。以下主机将受到影响: 
 查看详细信息
foo-[1-3].mycluster.com
```

查看前面相关的数据库设置

保持默认即可

等待部署完成

1.  修改最大线程数IO等限制(暂不进行)

```
vi /etc/systemd/system.conf
# 修改如下内容
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000

```

2.  关闭THP(脚本中已有)

```
# 检查状态
cat /sys/kernel/mm/transparent_hugepage/defrag
# output: [always] madvise never
cat /sys/kernel/mm/transparent_hugepage/enabled
# output: [always] madvise never

# 修改启动脚本,每次开机都禁用它们
cat>>/etc/rc.d/rc.local<<EOF
####################### 自行添加 ###########################
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
####################### 自行添加 ###########################
EOF

chmod +x /etc/rc.d/rc.local
reboot
```

1.  内核参数优化(暂不进行,应该由专业运维人员来做)

```
# 添加以下内容
cat>>/etc/sysctl.conf<<EOF
####################### 自行添加 ###########################
#关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
#关闭路由转发
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
#开启反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
#处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
#关闭sysrq功能
kernel.sysrq = 0
#core文件名中添加pid作为扩展名
kernel.core_uses_pid = 1
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
#修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
#设置最大内存共享段大小bytes
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
#timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 262144
#限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
#未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
#内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
#内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
#启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
#开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
#当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 30
#允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024 65000
#修改防火墙表大小，默认65536

#系统级别的能够打开的文件句柄的数量,ulimit 是进程级别的
fs.file-max = 265535
#系统允许的最大跟踪连接条目。在/etc/sysctl.conf文件中增加此属性，并运行>/sbin/sysctl.conf –p
net.ipv4.ip_conntrack_max=265535

# 确保无人能修改路由表
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.nf_conntrack_max = 6553600

# 如果在sysctl -p的时候报error: 'net.ipv4.ip_conntrack_max' is an unknown key ,通过以下命令向内核中加入模块修正：
modprobe ip_conntrack
echo "modprobe ip_conntrack" >> /etc/rc.local
# net.netfilter.nf_conntrack_max=655350
# net.netfilter.nf_conntrack_tcp_timeout_established=1200
####################### 自行添加 ###########################
EOF

# 从/etc/sysctl.conf加载内核参数
sysctl -p

```

1.Disable the tuned Service(暂不进行)

```
systemctl start tuned
tuned-adm off
tuned-adm list
# 输出中应该包含如下字样
# No current active profile
systemctl stop tuned
systemctl disable tuned

```

8.系统优化 ALL 禁用交换分区 sysctl -w vm.swappiness=0 禁用透明大页面 echo never > /sys/kernel/mm/transparent\_hugepage/defrag

1.  chrony时间同步存在问题,显示不可达
2.  linux系统还有几项可以优化
3.  脚本还需加入上面的修改项

InstallCDH\_SSH.sh 文件内容如下:

```
#!/bin/bash

# 该脚本的参数有三个,username,password,hostnames-file:
# hostnames-file 内容示例,如:
# 192.168.181.128=foo-1.mycluster.com
# 192.168.181.129=foo-2.mycluster.com
# 192.168.181.130=foo-3.mycluster.com
# 192.168.181.131=foo-4.mycluster.com
# 192.168.181.132=foo-5.mycluster.com
# 192.168.181.133=foo-6.mycluster.com
# 192.168.181.134=foo-7.mycluster.com
# 192.168.181.135=foo-8.mycluster.com
# 192.168.181.136=foo-9.mycluster.com
# 
# 该脚本执行前需要按说明文档中先完成前置工作:
# 1.createhostfile()中,
# 2.createssh()中,
# 3.createssh()中,repo文件,jdk文件需要放到第一台机器的httpd服务器中,供其所有机器下载

if [ $# -ne 3 ]; then # 如果传入的参数不是3个
    echo "Usage:"
    echo "$0  linuxuser linuxpasswd hostsFile"
    exit 1
fi

# 获取参数
linuxuser=$1
linuxpasswd=$2
hostfilename=$3

# 创建/etc/hosts文件,这个函数仅操作第一台机器
createhostfile()
{
# 读取变量1个字符的变量,并赋给answer
read -n 1 -p "需要重置host文件吗？(y/n)?" answer

case $answer in
Y | y)
        local hostfile=$1 # 局部变量
        echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================"
        echo `date "+%Y-%m-%d %H:%M:%S"`" step 01 开始生成 /etc/hosts 文件"
        cat /dev/null>/etc/hosts # 清空hosts文件
        echo "127.0.0.1 localhost"
        for line in `cat $hostfile`
        do 
            ip=`echo $line|awk -F'=' '{print $1}'`
            hostname=`echo $line|awk -F'=' '{print $2}'`
            echo "$ip $hostname">>/etc/hosts # 追加
        done  
        echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4">>/etc/hosts
        echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6">>/etc/hosts
        echo `date "+%Y-%m-%d %H:%M:%S"`" step 01 生成 /etc/hosts 文件完成，请查看"
        echo `date "+%Y-%m-%d %H:%M:%S"`" ========================="
        cat /etc/hosts
        echo `date "+%Y-%m-%d %H:%M:%S"`" ========================="
        echo `date "+%Y-%m-%d %H:%M:%S"`""
        read -n1 -p "请确认是否正确？(y/n)?" answer
        case $answer in
        Y | y)
              echo `date "+%Y-%m-%d %H:%M:%S"`" step 01 生成 /etc/hosts 文件完成"
              echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================" 
              ;;
        N | n)
              echo "请确认传入参数文件是否正确"
              exit 1
              ;;
        *)
              echo "error choice"
              exit 1
              ;;
        esac  
      ;;
N | n)
      echo "跳过" 
      ;; 
esac  



}



# 免密登陆,这里只需在一个主机上信任自身,然后拷贝到其他机器上,即可完成整个集群的互信
createssh()
{

read -n 1 -p "需要重置SSH吗？(y/n)?" answer

case $answer in
Y | y)
               
        echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================"
        echo `date "+%Y-%m-%d %H:%M:%S"`" step 02 开始自动化建立SSH互信"
        local DEST_USER=$1
        local PASSWORD=$2
        local HOSTS_FILE=$3
        if [ $# -ne 3 ]; then
            echo "Usage:"
            echo "$0 remoteUser remotePassword hostsFile"
            exit 1
        fi

        SSH_DIR=~/.ssh
        SCRIPT_PREFIX=./tmp
        # 1. prepare  directory .ssh
        mkdir $SSH_DIR
        chmod 700 $SSH_DIR

        # 2. generat ssh key
        TMP_SCRIPT=$SCRIPT_PREFIX.sh # ./tmp.sh
        echo  "#!/usr/bin/expect">$TMP_SCRIPT
        echo  "spawn ssh-keygen -b 1024 -t rsa">>$TMP_SCRIPT
        echo  "expect *key*">>$TMP_SCRIPT # 检测到'key'
        echo  "send \r">>$TMP_SCRIPT
        if [ -f $SSH_DIR/id_rsa ]; then # 检测文件是否为普通文件
            echo  "expect *verwrite*">>$TMP_SCRIPT
            echo  "send y\r">>$TMP_SCRIPT
        fi
        echo  "expect *passphrase*">>$TMP_SCRIPT
        echo  "send \r">>$TMP_SCRIPT
        echo  "expect *again:">>$TMP_SCRIPT
        echo  "send \r">>$TMP_SCRIPT
        echo  "interact">>$TMP_SCRIPT

        chmod +x $TMP_SCRIPT

        /usr/bin/expect $TMP_SCRIPT
        rm $TMP_SCRIPT

        ################### 3. generat file authorized_keys
        cat $SSH_DIR/id_rsa.pub>>$SSH_DIR/authorized_keys # 将本机id加到信任列表

        ################### 4. chmod 600 for file authorized_keys
        chmod 600 $SSH_DIR/authorized_keys
        echo "==========================="
        
        ################### 5. copy all files to other hosts
        for ip in `cat $HOSTS_FILE|awk -F'=' '{print $2}'`  # 对每个主机搜索
        do
            if [ "x$ip" != "x" ]; then # ip不为空
                echo -------------------------
                TMP_SCRIPT=${SCRIPT_PREFIX}.$ip.sh
                # check known_hosts
                val=`ssh-keygen -F $ip` # 在 know_hosts 中 find 指定 hostname
                if [ "x$val" == "x" ]; then # 没有搜索到
                    echo "$ip not in $SSH_DIR/known_hosts, need to add"
                    val=`ssh-keyscan $ip 2>/dev/null` # 扫描该主机中的公钥,标错输出到空
                    if [ "x$val" == "x" ]; then # 如果没有扫描到
                        echo "ssh-keyscan $ip failed!"
                    else
                        echo $val>>$SSH_DIR/known_hosts # 将扫描到的公钥添加到
                    fi
                fi
                echo "copy $SSH_DIR to $ip" 
                        
                echo  "#!/usr/bin/expect">$TMP_SCRIPT
                echo  "spawn scp -r  $SSH_DIR $DEST_USER@$ip:~/">>$TMP_SCRIPT
                echo  "expect *assword*">>$TMP_SCRIPT
                echo  "send $PASSWORD\r">>$TMP_SCRIPT
                echo  "interact">>$TMP_SCRIPT # 执行完成后保持交互状态，把控制权交给控制台，这个时候就可以手工操作了
                
                chmod +x $TMP_SCRIPT
            
                /usr/bin/expect $TMP_SCRIPT
                rm $TMP_SCRIPT
                echo "copy done."                
            fi
        done

        echo done.
        echo `date "+%Y-%m-%d %H:%M:%S"`" step 02 建立SSH互信完成，开始验证互信情况"

        for ip in `cat $HOSTS_FILE|awk -F'=' '{print $2}'`
        do
           localDATE=`date +%Y%m%d`
           REMOTEDATE=`ssh ${ip} date +%Y%m%d`
           if [ ${localDATE}==${REMOTEDATE} ];then
                echo "主机与远程IP：${ip} 连通测试成功"
           else
                echo "主机与远程IP：${ip} 连通测试失败"
           fi
        done
        echo `date "+%Y-%m-%d %H:%M:%S"`" step 02 验证互信情况完成"
        echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================"
        read -n 1 -p "请确认互信情况是否正确？(y/n)?" answer
        case $answer in
        Y | y)
              echo `date "+%Y-%m-%d %H:%M:%S"`" step 02 建立SSH互信完成，验证互信成功"
              echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================"
              ;;
        N | n)
              echo "请定位问题"
              exit 1
              ;;
        *)
              echo "error choice"
              exit 1
              ;;
        esac 
      ;;
N | n)
      echo "跳过SSH互信" 
      ;; 
esac  

 

}


# 设置主机名
changeHostName()
{


read -n 1 -p "需要对每台主机名进行配置吗？(y/n)?" answer


case $answer in
Y | y)

    local HOSTS_FILE=$1
    echo `date "+%Y-%m-%d %H:%M:%S"`" ================================================"
    echo `date "+%Y-%m-%d %H:%M:%S"`" step 03 开始修改主机名并分发host文件"
    cat>>/etc/profile<<EOF
################################ 自行添加 ###########################

export JAVA_HOME=/usr/java/jdk1.8.0_162
PATH=\$PATH:\$JAVA_HOME/bin/;
export PATH


################################ 自行添加 ###########################
EOF
    for line in `cat $HOSTS_FILE`
    do 
        echo `date "+%Y-%m-%d %H:%M:%S"`" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
        ip=`echo $line|awk -F'=' '{print $1}'` # =为分隔符
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" 开始处理 $ip"
        hostname=`echo $line|awk -F'=' '{print $2}'`
        originhostsname=`ssh ${ip} hostnamectl --static`  
        if [ ! ${hostname} == ${originhostsname} ];then
            echo `date "+%Y-%m-%d %H:%M:%S"`" $ip 需要修改Host" 
            ssh $ip "hostnamectl set-hostname $hostname"
            echo `date "+%Y-%m-%d %H:%M:%S"`" $ip 修改完毕"
        else
            echo `date "+%Y-%m-%d %H:%M:%S"`" $ip 不需要修改Hostname" 
        fi
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始发送hosts文件"
        scp /etc/hosts root@$hostname:/etc/
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始发送repo文件" 
        ######################## 这个http的repo需要实现准备好 #########################################
        scp /etc/yum.repos.d/http.repo  root@$hostname:/etc/yum.repos.d 
        files="/etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-CR.repo /etc/yum.repos.d/CentOS-Debuginfo.repo /etc/yum.repos.d/CentOS-fasttrack.repo /etc/yum.repos.d/CentOS-Media.repo /etc/yum.repos.d/CentOS-Sources.repo /etc/yum.repos.d/CentOS-Vault.repo"
        for file in $files ;do ssh $ip "mv $file ${file}bak" ;done # 备份原有repo
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始处理yum"
        ssh $ip "yum clean all"
        ssh $ip "yum makecache"
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始处理SELINUX"
        ssh $ip "setenforce 0"
        ssh $ip "sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config" # 将文本中的en..替换成dis..
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始处理防火墙"
        ssh $ip "systemctl stop firewalld"
        ssh $ip "systemctl disable firewalld"
        ssh $ip "systemctl status firewalld"
        
        ############################ 这里是不是跟 这里换用了chrony,而不是老的ntp ##################################
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始处理NTP时钟同步" 
        ssh $ip "yum install -y chrony"
        scp /etc/chrony.conf root@$hostname:/etc/
        ssh $ip "systemctl restart chronyd"
        ssh $ip "chronyc sources"
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始下载JDK包并解压" 
        # 从预先配置好的apache下载jdk,这里官方文档没有谈到环境变量的问题,但我们应该配置上环境变量,因为其他组件,或者一些自己安装的软件会使用java
        ssh $ip "mkdir -p /usr/java/"
        ssh $ip "rm -rf  /usr/java/jdk-8u162*"
        ssh $ip "curl http://192.168.181.128/softwares/jdk-8u162-linux-x64.tar.gz -o /opt/jdk-8u162-linux-x64.tar.gz --progress"
        ssh $ip "tar -zxf /opt/jdk-8u162-linux-x64.tar.gz -C /usr/java/"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始卸载OPENJDK"
         # mini install 没有jdk,但不同的centos版本,要写在的软件包不同,下面列举的是centos7.4de1
        ssh $ip "rpm -e --nodeps java-1.8.0-openjdk-1.8.0.131-11.b12.el7.x86_64" # 强制卸载
        ssh $ip "rpm -e --nodeps java-1.7.0-openjdk-1.7.0.141-2.6.10.5.el7.x86_64"
        ssh $ip "rpm -e --nodeps java-1.7.0-openjdk-headless-1.7.0.141-2.6.10.5.el7.x86_64"
        ssh $ip "rpm -e --nodeps java-1.8.0-openjdk-headless-1.8.0.131-11.b12.el7.x86_64" 
        ssh $ip "rpm -e --nodeps tzdata-java-2017b-1.el7.noarch" 
        ssh $ip "rpm -e --nodeps icedtea-web-1.6.2-4.el7.x86_64" 
        #ssh $ip "yum -y install jline*" # ?????????????????
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始发送环境变量" # 如果要使用个命令,先要设置jdk环境变量
        scp /etc/profile root@$ip:/etc/
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始发送环境生效并检查jdk版本信息"
        ssh $ip "source /etc/profile && java -version" 
        #echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 检查JDK版本信息"
        #ssh $ip "java -version"
        
        ############################################## 参数调优部分结束 ####################################################
        
        #echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 修改系统限制"  
        #scp /etc/systemd/system.conf root@$ip:/etc/systemd/
        
        echo -e "\n\n\n"
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 关闭THP" 
        scp /etc/rc.d/rc.local root@$ip:/etc/rc.d/
        ssh $ip "chmod +x /etc/rc.d/rc.local"
        ssh $ip "echo never > /sys/kernel/mm/transparent_hugepage/enabled"
        ssh $ip "echo never > /sys/kernel/mm/transparent_hugepage/defrag"
        
        echo -e "\n\n\n"
        echo echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 关闭交换分区" 
        ssh $ip "swapoff -a" 
        
        echo -e "\n\n\n"
        echo echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 关闭tuned调优" 
        ssh $ip "systemctl start tuned" 
        ssh $ip "tuned-adm off" 
        ssh $ip "tuned-adm list"
        ssh $ip "systemctl stop tuned"
        ssh $ip "systemctl disable tuned"
        
        echo -e "\n\n\n"
        echo echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 开始优化内核参数"
        scp /etc/sysctl.conf root@$ip:/etc/
        ssh $ip "sysctl -p"
        #ssh $ip "ulimit –n 265535"
        
        ############################################# 参数调优部分结束 ##################################################
        
        echo `date "+%Y-%m-%d %H:%M:%S"`" $ip"" 处理结束"
        echo `date "+%Y-%m-%d %H:%M:%S"`" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
        
        
    done    
    echo `date "+%Y-%m-%d %H:%M:%S"`" step 03 修改hostname成功" 

    echo `date "+%Y-%m-%d %H:%M:%S"`"================================================"  
     ;;
N | n)
      echo "跳过对每台主机进行配置" 
      ;; 
esac 


}


main()
{

createhostfile $hostfilename
createssh $linuxuser $linuxpasswd $hostfilename
changeHostName $hostfilename
echo -e "\n\n\n处理完成\n\n\n"
}


main


```

hostsname.txt 内容如下:

```
192.168.181.128=foo-1.mycluster.com
192.168.181.129=foo-2.mycluster.com
192.168.181.130=foo-3.mycluster.com
```
