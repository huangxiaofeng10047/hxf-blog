---
title: k8s搭建
date: 2021-12-03 16:33:19
tags:
---

# k8s问题记录与解决

**一、问题：error: open /var/lib/kubelet/config.yaml: no such file or directory**  
  解决：关键文件缺失，多发生于没有做 kubeadm init就运行了systemctl start kubelet。 要先成功运行kubeadm init

**二、kubelet.service has more than one ExecStart= setting, which is only allowed for Type=oneshot services. Refusing.**  
  解决：打开/etc/systemd/system/kubelet.service.d/10-kubeadm.conf 中的配置：  
    \[root@k8s-master ~\]# cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf  
    # Note: This dropin only works with kubeadm and kubelet v1.11+  
    \[Service\]  
    Environment="KUBELET\_KUBECONFIG\_ARGS=--[bootstrap](https://so.csdn.net/so/search?from=pc_blog_highlight&q=bootstrap)\-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"  
    Environment="KUBELET\_CONFIG\_ARGS=--config=/var/lib/kubelet/config.yaml"  
    # This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET\_KUBEADM\_ARGS variable dynamically  
    EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env  
    # This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use  
    # the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET\_EXTRA\_ARGS should be sourced from this file.  
    EnvironmentFile=-/etc/sysconfig/kubelet  
    要打开注释此# ExecStart=  
    ExecStart=/usr/bin/kubelet $KUBELET\_KUBECONFIG\_ARGS $KUBELET\_CONFIG\_ARGS $KUBELET\_KUBEADM\_ARGS $KUBELET\_EXTRA\_ARGS

**三、journalctl -f -u kubelet （-f是 --follow, -u是过滤出kubelet日志）**  
    centos7 查看日志

**四、kubeadm安装的k8s，重新安装k8s-mst**  
    检查 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 中的配置  
    systemctl restart kubelet  
    kubeadm reset  
    kubeadm init --kubernetes-version=v1.13.4 --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors=Swap  
    其他节点执行  
    kubeadm reset  
    kubeadm join ...命令

**五、kubeadm 生成的token过期后，集群增加节点**  
    参考：https://www.jianshu.com/p/a5e379638577

**六、\[reset\] unmounting mounted directories in "/var/lib/kubelet" 卡主**  
    重启机器，重新执行命令

重启kubelet服务 ，重启containerd 服务



\-------------------20190518 update-------------------

**七、master所在虚机重启后，kube-master1 kubelet\[34770\]: E0419 13:52:09.511348   34770 kubelet.go:2266\] node "kube-master1" not found，并发现获取到的ip地址为空，ifconfig命令去查看网卡配置情况，却发现根本没有配置eth0/ens33网卡**

解决：依次systemctl stop kubelet、systemctl stop docker、systemctl restart network、systemctl restart docker、systemctl restart kubelet、ifconfig、kubectl get node

\-------------------20190614 update-------------------

**八、kubelet, k8s-node1  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "1b7fb9d83e89dbe2815cc10fb1daf342162cb74da30568c0a59585e1dc9329a4" network for pod "wxapp-redis-1": NetworkPlugin cni failed to set up pod "wxapp-redis-1\_pnup" network: failed to set bridge addr: "cni0" already has an IP address different from 10.244.1.1/24**

解决：到有问题的机器，执行如下命令：

**\[root@k8s-node1 redis\]# cd /var/lib/cni/flannel/**  
\[root@k8s-node1 flannel\]# ll  
total 32  
\-rw-------. 1 root root 206 Apr 19 11:30 0727fe1a742f28b9a5d5d3188496bdc0aec220599caf6ce8c28f1b9c8ef1b8d4  
\-rw-------. 1 root root 206 Apr 19 14:30 13776cebe870d3f58982a123e2e32a4a89780c421db1bc425f13f13756822f81  
\-rw-------. 1 root root 206 Apr 19 11:30 1f249dd31dae8177a4fa5d3009eec7a36a4dccd8a836975f1d798adf43afda51  
\-rw-------. 1 root root 206 Apr 19 14:34 317e1ce2f78fddd1b36879be5dff169d27fefd4ca191dcd9d85781ab65cc14d8  
\-rw-------. 1 root root 187 Jun 14 10:05 5b104d16ea2042bd67f8958b8042fff01de3ba6a69f1a62f4b3ded81955c24bb  
\-rw-------. 1 root root 206 Apr 23 15:30 5bfe39c5fb73ecb09b7343260b8fc2526bb99b7d00a216ab0c76d87d247f3bc0  
\-rw-------. 1 root root 187 Jun 14 10:05 85de9489e5a4b5091bc40b5dc216a9f15fdb9aa077a28df32cfef97f8abd0c81  
\-rw-------. 1 root root 206 Apr 19 11:30 db015f887bbedf2ad7731aaa4a321183594a1d2c9b95398bb25f61ad5b052092  
**\[root@k8s-node1 flannel\]# systemctl stop docker  
\[root@k8s-node1 flannel\]# systemctl stop kubelet  
\[root@k8s-node1 flannel\]# systemctl stop kube-proxy**  
Failed to stop kube-proxy.service: Unit kube-proxy.service not loaded.  
**\[root@k8s-node1 flannel\]# rm -rf /var/lib/cni/flannel/ && rm -rf /var/lib/cni/networks/cbr0/ && ip link delete cni0  
\[root@k8s-node1 flannel\]# rm -rf /var/lib/cni/networks/cni0/\*  
\[root@k8s-node1 flannel\]# systemctl start docker  
\[root@k8s-node1 flannel\]# systemctl start kubelet**

\-------------------20190622 update-------------------

**九、转（kubernetes --> kube-dns 安装 [https://blog.csdn.net/zhuchuangang/article/details/76093887](https://blog.csdn.net/zhuchuangang/article/details/76093887) [https://www.cnblogs.com/chimeiwangliang/p/8809280.html](https://blog.csdn.net/zhuchuangang/article/details/76093887)）**

**十、转（kubernetes中网络报错问题排查 [http://www.mamicode.com/info-detail-2315259.html](https://blog.csdn.net/zhuchuangang/article/details/76093887)）**

\-------------------20200523 update-------------------

**十一、May 23 06:21:59 master dockerd-current\[14690\]: time="2020-05-23T06:21:59.555312805-04:00" level=error** msg="Create container failed with error: oci runtime error: container\_linux.go:235: starting container process caused \\"process\_linux.go:258: applying cgroup configuration for process caused **\\\\\\"Cannot set property TasksAccounting, or unknown property.\\\\\\"\\"\\n"  
May 23 06:21:59 master kubelet\[21888\]: E0523 06:21:59.654065   21888 kubelet.go:2266\] node "master" not found**  
May 23 06:21:59 master kubelet\[21888\]: E0523 06:21:59.754397   21888 kubelet.go:2266\] node "master" not found  
May 23 06:21:59 master kubelet\[21888\]: E0523 06:21:59.855185   21888 kubelet.go:2266\] node "master" not found  
**Docker创建容器报错：Cannot set property TasksAccounting, or unknown property.**  
最近又新配了一个服务器，想用docker简单的配置一下mysql，没想到创建容器时报错：  
Error response from daemon: oci runtime error: container\_linux.go:235: starting container process caused “process\_linux.go:258: applying cgroup configuration for process caused “Cannot set property TasksAccounting, or unknown property.””  
问题原因：主要原因还是centos系统版本兼容性问题，如果将系统做更新升级，即可解决。  
**执行：yum update后在执行以下操作：**

```
Loaded plugins: fastestmirror, langpacks, product-id, search-disabled-repos, subscription-managercri-tools.x86_64                      1.13.0-0                       @kuberneteskubectl.x86_64                        1.13.4-0                       @kubernetesLoaded plugins: fastestmirror, langpacks, product-id, search-disabled-repos, subscription-managerLoaded plugins: fastestmirror, langpacks, product-id, search-disabled-repos, subscription-managercri-tools.x86_64                      1.13.0-0                       @kuberneteskubeadm.x86_64                        1.13.4-0                       @kuberneteskubectl.x86_64                        1.13.4-0                       @kuberneteskubelet.x86_64                        1.13.4-0                       @kuberneteskubernetes-cni.x86_64                 0.6.0-0                        @kubernetes
```

**十二、k8s使用kube-router网络插件并监控流量状态  
[https://www.jianshu.com/p/1a3caecc3b6b](https://www.jianshu.com/p/1a3caecc3b6b)**  
附：kubeadm-kuberouter-all-features.yaml

```
apiVersion: extensions/v1beta1        scheduler.alpha.kubernetes.io/critical-pod: ''      serviceAccountName: kube-router      serviceAccount: kube-router        image: docker.io/cloudnativelabs/kube-router        imagePullPolicy: IfNotPresent        - --run-service-proxy=true        - --kubeconfig=/var/lib/kube-router/kubeconfig        - name: KUBE_ROUTER_CNI_CONF_FILE          value: /etc/cni/net.d/10-kuberouter.conflist          mountPath: /etc/cni/net.d          mountPath: /var/lib/kube-routerif [ ! -f /etc/cni/net.d/10-kuberouter.conflist ]; thenif [ -f /etc/cni/net.d/*.conf ]; thenrm -f /etc/cni/net.d/*.conf;            TMP=/etc/cni/net.d/.tmp-kuberouter-cfg;cp /etc/kube-router/cni-conf.json ${TMP};mv ${TMP} /etc/cni/net.d/10-kuberouter.conflist;          mountPath: /etc/cni/net.d          mountPath: /etc/kube-router      - key: CriticalAddonsOnly        key: node-role.kubernetes.io/master        key: node.kubernetes.io/not-readyapiVersion: rbac.authorization.k8s.io/v1beta1apiVersion: rbac.authorization.k8s.io/v1beta1  apiGroup: rbac.authorization.k8s.io
```

**十三、k8s小知识点：如何安装指定版本的kubeadm  
[https://www.jianshu.com/p/4b22b5d2f69b](https://www.jianshu.com/p/4b22b5d2f69b)**

\-------------------20200523 update-------------------

文献：

    1.[kubernetes---CentOS7安装kubernetes1.11.2图文完整版](https://blog.csdn.net/zzq900503/article/details/81710319)
    
    [2.安装k8s 1.9.0 实践：问题集锦](https://yq.aliyun.com/articles/679699)

# error execution phase upload-config/kubelet: Error writing Crisocket information for the control-...

swapoff -a
kubeadm reset
systemctl daemon-reload
systemctl restart kubelet
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X 
------------------------------------------------
版权声明：本文为CSDN博主「不忘初心fight」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/weixin_41831919/article/details/118713869

卸载k8s步骤：

```shell
kubeadm reset -f
modprobe -r ipip
lsmod
rm -rf ~/.kube/
rm -rf /etc/kubernetes/
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/systemd/system/kubelet.service
rm -rf /usr/bin/kube*
rm -rf /etc/cni
rm -rf /opt/cni
rm -rf /var/lib/etcd
rm -rf /var/etcd
rm -rf /opt/cni 
rm -rf /var/lib/cni /var/log/calico/cni /opt/cni /rootfs/etc/service/enabled/cni /rootfs/host/etc/cni
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X 
ipvsadm --clear
rm -rf /var/lib/kubelet /var/lib/dockershim /var/run/kubernetes /var/lib/cni
yum clean all
yum remove kube*
```

```shell
sudo kubeadm reset -f
sudo rm -rvf $HOME/.kube
sudo rm -rvf ~/.kube/
sudo rm -rvf /etc/kubernetes/
sudo rm -rvf /etc/systemd/system/kubelet.service.d
sudo rm -rvf /etc/systemd/system/kubelet.service
sudo rm -rvf /usr/bin/kube*
sudo rm -rvf /etc/cni
sudo rm -rvf /opt/cni
sudo rm -rvf /var/lib/etcd
sudo rm -rvf /var/etcd
sudo apt-get remove kube*
```

————————————————
版权声明：本文为CSDN博主「NoOne-csdn」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/weixin_40161254/article/details/112004106

问题一:

```
MountVolume.SetUp failed for volume "etcd-certs" : secret "etcd-certs" not found
```

解决方案:

```
kubectl -n kube-system create secret generic etcd-certs --from-file=/etc/kubernetes/pki/etcd/server.crt --from-file=/etc/kubernetes/pki/etcd/server.key
然后重新启动
```

问题二:

```
cannot find cgroup mount destination: unknown
```

结果方案:

```
mkdir /sys/fs/cgroup/systemd
mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

如果上述方案不行,就启动终极方案: 重启
```

问题三:

```
部署harbor服务
docker login 10.3.131.2
Username: tiger
Password: 
Error response from daemon: Get https://10.3.131.2/v2/: dial tcp 10.3.131.2:443: connect: connection refused
```

出现这问题的原因是：Docker自从1.3.X之后docker registry交互默认使用的是HTTPS，但是搭建私有镜像默认使用的是HTTP服务，所以与私有镜像交时出现以上错误。

解决方案:

```
客户端
# cat /etc/docker/daemon.conf 
{
"insecure-registries": ["http://10.3.131.2"]
}

# cat /usr/lib/systemd/system/docker.service  |grep ExecStart
ExecStart=/usr/bin/dockerd -H fd://  --insecure-registry  10.3.131.2  --containerd=/run/containerd/containerd.sock

# systemctl daemon-reload
# systemctl restart docker


server端:
[root@docker1 harbor]# cat /etc/docker/daemon.conf 
{
"insecure-registries": ["http://10.3.131.2"]
}

[root@docker1 harbor]# cat /usr/lib/systemd/system/docker.service  |grep ExecStart
ExecStart=/usr/bin/dockerd -H fd:// --insecure-registry 10.3.131.2:5000 --containerd=/run/containerd/containerd.sock

# systemctl daemon-reload
#  systemctl restart docker
# docker-compose down -v 
# docker-compose up -d 


客户端测试
# docker login -u admin -p Harbor12345 http://10.3.131.2
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
docker login

Login Succeeded
原因
这是因为docker1.3.2版本开始默认docker registry使用的是https，我们设置Harbor默认http方式，所以当执行用docker login、pull、push等命令操作非https的docker regsitry的时就会报错。
```

问题四:

解决方案:

```
检查加速是否配置正确,如果配置正确但无法启动
将/etc/docker/daemon.json 改为/etc/docker/daemon.conf
重新启动,原因暂时未知
```

问题五:

```
 no matches for kind "Deployment" in version "apps/v1beta2"

集群报错 在部署k8s1.16.1的dashboard时:
[root@k8s-master dashboard]# /opt/kubernetes/bin/kubectl create -f dashboard-deployment.yaml
error: unable to recognize "dashboard-deployment.yaml": no matches for kind "Deployment" in version "apps/v1beta2"
```

解决方案:

```
原因:
这是因为 API 版本已正式发布，不再是 beta 了。

解决方法：

将 apps/v1beta1 改为 apps/v1
```

问题六:

```
dashboard 界面报错 
报错内容: namespaces is forbidden: User "system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard" cannot list resource "namespaces" in API group "" at the cluster scope
```

解决方案:

```
发现是dashboard的版本和kubernetes的版本不一致
从 https://github.com/kubernetes/dashboard/releases 找到对应版本的 dashboard 的 yaml 重新部署, 即可解决
```

问题七:

```
kubeadm初始化失败
报错:

主要内容
[kubelet-check] Initial timeout of 40s passed.
error execution phase upload-config/kubelet: 
Error writing Crisocket information for the control-plane node: timed out waiting for the condition
```

解决方案

```
swapoff -a && kubeadm reset  && systemctl daemon-reload && systemctl restart kubelet  && iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```









导入镜像



quay.io/calico/node:v3.21.2

 ctr --namespace k8s.io image import node.tar











# Impossible to create or start a container after reboot (OCI runtime create failed: expected cgroupsPath to be of format \"slice:prefix:name\" for systemd cgroups, got \"/kubepods/burstable/...")

This error is happening because kubelet is configured to use cgroupfs cgroup driver while containerd is configured to use sytemd cgroup driver.

To let containerd use cgroupfs driver, you need to remove `SystemdCgroup = true` line from `/etc/containerd/config.toml`.

To let kubelet use systemd driver, you need to set `cgroupDriver` in `KubeletConfiguration` to "systemd".
