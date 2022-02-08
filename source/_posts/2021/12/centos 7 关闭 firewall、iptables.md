

systemctl是CentOS7的服务管理工具中主要的工具，它融合之前service和chkconfig的功能于一体。

1、关闭firewall

```
systemctl status firewalld.service 
systemctl stop firewalld.service 
systemctl disable firewalld.service 
firewall-cmd --state
```

2、关闭iptables

```
yum install iptables-services
systemctl status iptables.service 
systemctl stop iptables.service 
systemctl disable iptables.service
cd /etc/sysconfig
mv /etc/sysconfig/iptables  /etc/sysconfig/iptables.bak
mv /etc/sysconfig/iptables-config /etc/sysconfig/iptables-config.bak
touch /etc/sysconfig/iptables
touch /etc/sysconfig/iptables-config
reboot
```