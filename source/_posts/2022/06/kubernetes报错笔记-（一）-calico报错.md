---
title: kubernetes报错笔记 （一） calico报错
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-17 17:13:28
tags:
---

calico报错

错误1
 read udp xxx:29270->169.169.0.10:53: i/o timeout   read    主机地址加端口  >>  169.169.0.10：53好像是这个
1.

```
解决方法

#错误原因
vi /etc/hosts 文件中缺少以下配置

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

#不知道谁给删的，排了一下午。。
```


错误2

错误2

```
unable to ensure pod container exists: failed to create container for [kubepods burstable pod174ffa0f-3c24-4481-9254-efce02b03001] :
 mkdir /sys/fs/cgroup/memory/kubepods/burstable/pod174ffa0f-3c24-4481-9254-efce02b03001: cannot allocate memory
```


解决方法

```
Cgroup泄漏，mark一下，此处使用网上的多数解决方案并米诶有解决，做一个小小的记录，在此需要对no space left的服务器进行 reboot重启，即可解决问题，出现问题的可能为段时间内删除大量的pod所致。

初步思路，可以在今后的集群管理汇总，对服务器进行维修，通过删除节点，并对节点进行reboot处理

```

错误3

错误3

```
#启动calico后发现控制器成功就绪
node为0/1  但是running   查看日志 后发现以下情况 
```


报错信息

calico/node is not ready: BIRD is not ready: BGP not established with 10.133

```
原因

#搜索一下得知没有匹配到正确的网卡，发现当前节点中存在多个相似的网卡
bond1
bond1.2
```

解决方法

```
在calico.yaml中修改匹配的节点为
bond1$  重启即可

#如果有节点在不同集群，网卡可能也不相同
#如，一个是eth1 一个是eth0
#可以配置为 (eth1|eth0)
```


错误4

错误4

```
#状态如下
[root@xxx calico-typha-v3.15.2]# kk get pod
NAME                                       READY   STATUS     RESTARTS   AGE
calico-kube-controllers-75d69d4b44-f4rv7   0/1     Pending    0          11m
calico-node-5dthc                          0/1     Init:0/3   0          11m
calico-node-7tw7c                          0/1     Init:0/3   0          11m
calico-node-bvvmv                          0/1     Init:0/3   0          11m
calico-node-cltbf                          0/1     Init:0/3   0          11m
calico-node-fwxs7                          0/1     Init:0/3   0          11m
calico-node-gchnf                          0/1     Init:0/3   0          11m
calico-node-p9wfc                          0/1     Init:0/3   0          11m
calico-node-wvcsz                          0/1     Init:0/3   0          11m
calico-node-xhljh                          0/1     Init:0/3   0          11m
calico-node-zg6hh                          0/1     Init:0/3   0          11m
calico-typha-588c8dbccd-gk4n5              0/1     Pending    0          11m
calico-typha-588c8dbccd-st6xm              0/1     Pending    0          11m
calico-typha-588c8dbccd-sxgzj              0/1     Pending    0          11m

```

 之前老有小伙伴喜欢去看污点，如下，然后想办法去去除污点，其实这不是污点的问题，下面就说名了网卡没就绪

```
[root@calico-typha-v3.15.2]# k describe node | grep Tain
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule
Taints:             node.kubernetes.io/not-ready:NoSchedule

```

我们已经得知pod在init阶段无法通过，查看describe得到如下信息

查看node信息

```


----     ------                  ----                  ----                   -------

Normal   Scheduled               <unknown>             default-scheduler      Successfully assigned kube-system/calico-node-5dthc to 192.168.1.20
Warning  FailedCreatePodSandBox  35s (x10 over 7m56s)  kubelet, 192.168.1.20  Failed to create pod sandbox: rpc error: code = Unknown desc = failed pulling image "192.168.1.20:80/google_containers/pause:3.1": Error response from daemon: Get http://192.168.1.20:80/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)

#我们得知
failed pulling image "192.168.1.20:80/google_containers/pause:3.1"
#在创建pod时，没有成功拉取到pause的基础镜像
#发现仓库里面忘记上传了，已解决

```

错误5

错误5

```
calico 状态异常（0/1）修复
  Warning  Unhealthy  33s        kubelet, 10.252.205.100  Readiness probe failed: 2021-06-28 07:48:22.019 [INFO][222] confd/health.go 180: Number of node(s) with BGP peering established = 22
calico/node is not ready: BIRD is not ready: BGP not established with 
  Warning  Unhealthy  23s  kubelet, 10.252.205.100  Readiness probe failed: 2021-06-28 07:48:32.013 [INFO][275] confd/health.go 180: Number of node(s) with BGP peering established = 36
calico/node is not ready: BIRD is not ready: BGP not established with 10.252.205.197
  Warning  Unhealthy  13s  kubelet, 10.252.205.100  Readiness probe failed: 2021-06-28 07:48:42.014 [INFO][332] confd/health.go 180: Number of node(s) with BGP peering established = 36
calico/node is not ready: BIRD is not ready: BGP not established with 10.252.205.197
  Warning  Unhealthy  3s  kubelet, 10.252.205.100  Readiness probe failed: 2021-06-28 07:48:52.009 [INFO][380] confd/health.go 180: Number of node(s) with BGP peering established = 36
calico/node is not ready: felix is not ready: readiness probe reporting 404
  Warning  Unhealthy  2s (x3 over 22s)  kubelet, 10.252.205.100  Liveness probe failed: calico/node is not ready: Felix is not live: liveness probe reporting 404



#修复方法
[ecip@cmpaas-core-new-mpp-b-11 ~]$ cd /opt/cni/bin/
[ecip@cmpaas-core-new-mpp-b-11 bin]$ ls
bandwidth  calico  calico-ipam  flannel  host-local  loopback  portmap  tuning

#备份以下配置
mv * linshi


#备份挂载文件
[ecip@cmpaas-core-new-mpp-b-11 bin]$ cd /var/run/calico/
[ecip@cmpaas-core-new-mpp-b-11 calico]$ ls
bird6.ctl  bird.ctl  cgroup

#mv * linshi

#重启该节点kubelet

到master上delete pod 该calico解决
```

错误6  生产环境有一个calico pod容器起不来

```
#通过describe 得到的事件信息

 Readiness probe failed: calico/node is not ready: BIRD is not ready: Error querying 
BIRD: unable to connect to BIRDv4 socket: dial unix /var/run/bird/bird.ctl: connect:
 no such file or directory

 Liveness probe failed: calico/node is not ready: bird/confd is not live: exit status 1
```

日志

```
Jul 27 10:17:27 cmpaas-core-new-mpp-j-1 kubelet[47192]: E0727 10:17:27.076332  
47192 kuberuntime_manager.go:674] killPodWithSyncResult failed: failed to 
"KillPodSandbox" for "d49635fa-a070-469d-9228-d64a900e4403" with KillPodSandboxError:
"rpc error: code = Unknown desc = networkPlugin cni failed to teardown pod \"kong-
migrations-pqwll_kong\" network: error getting ClusterInformation: Get 
https://[169.169.0.1]:443/apis/crd.projectcalico.org/v1/clusterinformations/default:
dial tcp 169.169.0.1:443: i/o timeout"
```

其实结尾的这个错误已经很明显了，tcp 169.169.0.1:443: i/o timeout"

9成是kube-proxy导致的跑不了

再次查看calico pod日志（等一会）

```
[ecip@cmpaas-core-new-mpp-b-11 ~]$ kk logs calico-node-xm5qz 

2021-07-27 02:52:28.597 [INFO][8] startup/startup.go 374: Hit error connecting to 
datastore - retry error=Get https://169.169.0.1:443/api/v1/nodes/foo: dial tcp 
169.169.0.1:443: i/o timeout
```

```
k8s.io/client-go/informers/factory.go:135: Failed to list *v1.Service: Get
https://192.168.1.20:6443/api/v1
/services?labelSelector=%21service.kubernetes.io%2Fheadless
%2C%21service.kubernetes.io%2Fservice-proxy-name&limit=500&resourceVersion=0: dial tcp 
192.168.1.21:6443: connect: connection refused]()

##发现该节点kube-proxy无法连接apiserver
```

得知这个节点之前是其他集群的，我在想是否有可能是因为集群证书 漏掉了，

没有替换新的导致的，替换证书，重启节点服务，delete pod恢复
-----------------------------------
©著作权归作者所有：来自51CTO博客作者默子昂1的原创作品，请联系作者获取转载授权，否则将追究法律责任
kubernetes报错笔记 （一） calico报错
https://blog.51cto.com/u_14205795/4560662
