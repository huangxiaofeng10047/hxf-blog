---

title: linux上开启k8s
date: 2021-08-26 10:46:14
tags:
- k8s
- linux
categories: 
- devops
---

linux running k8s locally！！！

<!--more-->

安装cfssl

```
wget http://***/cfssl/cfssl_linux-amd64 --no-check-certificate
wget http://***/cfssl/cfssljson_linux-amd64 --no-check-certificate
wget http://***/cfssl/cfssl-certinfo_linux-amd64 --no-check-certificate
chmod +x cfssl*
sudo mkdir -p /opt/kubernetes/bin
sudo mv cfssl-certinfo_linux-amd64 /opt/kubernetes/bin/cfssl-certinfo
sudo mv cfssljson_linux-amd64 /opt/kubernetes/bin/cfssljson
sudo mv cfssl_linux-amd64 /opt/kubernetes/bin/cfssl
```

[https://github.com/kubernetes/community/blob/master/contributors/devel/running-locally.mdhttps://github.com/kubernetes/community/blob/master/contributors/devel/running-locally.md](https://github.com/kubernetes/community/blob/master/contributors/devel/running-locally.mdhttps://github.com/kubernetes/community/blob/master/contributors/devel/running-locally.md)

```
cd kubernetes
./hack/local-up-cluster.sh
```

## Starting the cluster

In a separate tab of your terminal, run the following:

```
cd kubernetes
./hack/local-up-cluster.sh
```

报错：hostname not found

需要安装inetutils 包

```
sudo pacman -S inetutils 
```

Since root access is sometimes needed to start/stop Kubernetes daemons, `./hack/local-up-cluster.sh` may need to be run as root. If it reports failures, try this instead:

```
sudo ./hack/local-up-cluster.sh
```

This will build and start a lightweight local cluster, consisting of a master and a single node. Press Control+C to shut it down.

输出如下

```
WARNING : The kubelet is configured to not fail even if swap is enabled; production deployments should disable swap unless testing NodeSwap feature.
2021/08/26 17:20:13 [INFO] generate received request
2021/08/26 17:20:13 [INFO] received CSR
2021/08/26 17:20:13 [INFO] generating key: rsa-2048
2021/08/26 17:20:13 [INFO] encoded CSR
2021/08/26 17:20:13 [INFO] signed certificate with serial number 417253697465383426846224772590332215519008583643
2021/08/26 17:20:13 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
kubelet ( 63151 ) is running.
wait kubelet ready
No resources found
127.0.0.1   NotReady   <none>   0s    v0.0.0-master+$Format:%H$
2021/08/26 17:20:18 [INFO] generate received request
2021/08/26 17:20:18 [INFO] received CSR
2021/08/26 17:20:18 [INFO] generating key: rsa-2048
2021/08/26 17:20:18 [INFO] encoded CSR
2021/08/26 17:20:18 [INFO] signed certificate with serial number 338275530615461418742991706674701309771131565316
2021/08/26 17:20:18 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
Create default storage class for
storageclass.storage.k8s.io/standard created
Local Kubernetes cluster is running. Press Ctrl-C to shut it down.

Logs:
  /tmp/kube-apiserver.log
  /tmp/kube-controller-manager.log

  /tmp/kube-proxy.log
  /tmp/kube-scheduler.log
  /tmp/kubelet.log

To start using your cluster, you can open up another terminal/tab and run:

  export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
  cluster/kubectl.sh

Alternatively, you can write to the default kubeconfig:

  export KUBERNETES_PROVIDER=local

  cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt
  cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt
  cluster/kubectl.sh config set-context local --cluster=local --user=myself
  cluster/kubectl.sh config use-context local
  cluster/kubectl.sh

**Note:** If you've already compiled the Kubernetes components, you can avoid rebuilding them with the `-O` flag.
```



```
./hack/local-up-cluster.sh -O
```

You can use the `./cluster/kubectl.sh` script to interact with the local cluster. `./hack/local-up-cluster.sh` will print the commands to run to point kubectl at the local cluster.

## Running a container

Your cluster is running, and you want to start running containers!

You can now use any of the cluster/kubectl.sh commands to interact with your local setup.

```
./cluster/kubectl.sh get pods
./cluster/kubectl.sh get services
./cluster/kubectl.sh get replicationcontrollers
./cluster/kubectl.sh run my-nginx --image=nginx --port=80
```

While waiting for the provisioning to complete, you can monitor progress in another terminal with these commands.

```
docker images
# To watch the process pull the nginx image
docker ps
# To watch all Docker processes.
```

Once provisioning is complete, you can use the following commands for Kubernetes introspection.

```
./cluster/kubectl.sh get pods
./cluster/kubectl.sh get services
./cluster/kubectl.sh get replicationcontrollers
```

## Running a user defined pod

Note the difference between a [container](https://kubernetes.io/docs/user-guide/containers/) and a [pod](https://kubernetes.io/docs/user-guide/pods/). Since you only asked for the former, Kubernetes will create a wrapper pod for you. However, you cannot view the nginx start page on localhost. To verify that nginx is running, you need to run `curl` within the Docker container (try `docker exec`).

You can control the specifications of a pod via a user defined manifest, and reach nginx through your browser on the port specified therein:

```
./cluster/kubectl.sh create -f test/fixtures/doc-yaml/user-guide/pod.yaml
```

Congratulations!

## Troubleshooting

### I cannot reach service IPs on the network.

Some firewall software that uses iptables may not interact well with kubernetes. If you have trouble around networking, try disabling any firewall or other iptables-using systems, first. Also, you can check if SELinux is blocking anything by running a command such as `journalctl --since yesterday | grep avc`.

By default the IP range for service cluster IPs is 10.0.*.* - depending on your docker installation, this may conflict with IPs for containers. If you find containers running with IPs in this range, edit hack/local-cluster-up.sh and change the service-cluster-ip-range flag to something else.

### I cannot create a replication controller with replica size greater than 1! What gives?

You are running a single node setup. This has the limitation of only supporting a single replica of a given pod. If you are interested in running with larger replica sizes, we encourage you to try the local vagrant setup or one of the cloud providers.

### I changed Kubernetes code, how do I run it?

```
cd kubernetes
make
./hack/local-up-cluster.sh
```

### kubectl claims to start a container but `get pods` and `docker ps` don't show it.

One or more of the Kubernetes daemons might've crashed. Tail the logs of each in /tmp.

### The pods fail to connect to the services by host names

To start the DNS service, you need to set the following variables:

```
KUBE_ENABLE_CLUSTER_DNS=true
KUBE_DNS_SERVER_IP="10.0.0.10"
KUBE_DNS_DOMAIN="cluster.local"
```

To know more on DNS service you can check out the [docs](http://kubernetes.io/docs/admin/dns/).

出现报错：

The connection to the server localhost:8080 was refused - did you specify the right host or port?解决办法为：在root账户下加入以下设置。

当出现这个问题，最直观的解决方式，就是去搜索8080端口有没有开启，

通过netstat -apn|grep 8080 查询，发现无这个端口开启，这个时候，就开始借助强大的google来查找，查询好多信息，这个时候，需要过滤一下信息，为什么这个样子，那我们换个思路，看看kubectl get pod 查询什么，其实他是在查看kube-apiserver，首先查询kube-apiserver是否存在。发现存在，日志也很正常，这个时候，开始怀疑人生了，此时查询一下，端口，发现端口不是8080而是997717：

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210827103541651.png" alt="image-20210827103541651" style="zoom:80%;" />

这个时候我们应该会想到怎么去修改kubeapi-server的端口，这个时候，需要冷静，我想看应该是sudo账户时，查询的应该是root账户，在root账户下执行一下命令。

```
 export KUBERNETES_PROVIDER=local



 /mnt/d/k8s/rails6-k8s/kubernetes/cluster/kubectl.sh config set-cluster local --server=https://localhost:6443 --certificate-authority=/var/run/kubernetes/server-ca.crt

 /mnt/d/k8s/rails6-k8s/kubernetes/cluster/kubectl.sh config set-credentials myself --client-key=/var/run/kubernetes/client-admin.key --client-certificate=/var/run/kubernetes/client-admin.crt

 /mnt/d/k8s/rails6-k8s/kubernetes/cluster/kubectl.sh config set-context local --cluster=local --user=myself

 /mnt/d/k8s/rails6-k8s/kubernetes/cluster/kubectl.sh config use-context local
```

kubernetes on  master via 🐹 v1.17
➜ cluster/kubectl.sh get pods
error: unable to read client-key /var/run/kubernetes/client-admin.key for myself due to open /var/run/kubernetes/client-admin.key: permission denied

kubernetes on  master via 🐹 v1.17
❯ sudo cluster/kubectl.sh get pods
The connection to the server localhost:8080 was refused - did you specify the right host or port?

![image-20210827103715008](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210827103715008.png)

`error: unable to read client-key /var/run/kubernetes/client-admin.key for myself due to open /var/run/kubernetes/client-admin.key: permission denied`

这个时候也可以把该目录下所有文件修改成 777 保证可以访问。

![image-20210827103941099](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210827103941099.png)
