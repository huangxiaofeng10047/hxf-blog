---
title: linux上开启k8s
date: 2021-08-26 10:46:14
tags:
- k8s
- linux
categories: 
- devops
---

linuxrunning k8s locally

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

**Note:** If you've already compiled the Kubernetes components, you can avoid rebuilding them with the `-O` flag.

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
