harbor 服务正常，但无法访问排查

-   查看harbor服务是正常的

```
[root@k8s-server-4 harbor]# docker-compose ps
      Name                     Command                  State                 Ports
---------------------------------------------------------------------------------------------
harbor-core         /harbor/entrypoint.sh            Up (healthy)
harbor-db           /docker-entrypoint.sh            Up (healthy)   5432/tcp
harbor-jobservice   /harbor/entrypoint.sh            Up (healthy)
harbor-log          /bin/sh -c /usr/local/bin/ ...   Up (healthy)   127.0.0.1:1514->10514/tcp
harbor-portal       nginx -g daemon off;             Up (healthy)   8080/tcp
nginx               nginx -g daemon off;             Up (healthy)   0.0.0.0:1080->8080/tcp
redis               redis-server /etc/redis.conf     Up (healthy)   6379/tcp
registry            /home/harbor/entrypoint.sh       Up (healthy)   5000/tcp
registryctl         /home/harbor/start.sh            Up (healthy)
```

-   于是查看端口监听,也是正常的

```
[root@k8s-server-4 harbor]# lsof -i:1080
COMMAND     PID USER   FD   TYPE    DEVICE SIZE/OFF NODE NAME
docker-pr 16465 root    4u  IPv6 276635930      0t0  TCP *:socks (LISTEN)
```

-   于是开一下防火墙,关了

```
[root@k8s-server-4 harbor]# firewall-cmd --list-ports
FirewallD is not running
```

-   于是查看ip是否开启转发

```
[root@k8s-server-4 harbor]# sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
```

-   没有转发，打开就行

```
[root@k8s-server-4 harbor]# vim /etc/sysctl.conf
net.ipv4.ip_forward = 1 # 这个配置改成1，0是没打开
# 执行命令 service network restart
[root@k8s-server-4 harbor]# service network restart
```

-   重启network，服务正常