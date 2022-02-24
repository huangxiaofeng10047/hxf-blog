---
title: 离线部署kubernets
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-18 09:09:00
tags:
---

1.设置hostname

```
hostnamectl set-hostname k8s_n1
echo "127.0.0.1   $(hostname)" >> /etc/hosts

hostnamectl set-hostname k8s_n2
echo "127.0.0.1   $(hostname)" >> /etc/hosts


hostnamectl set-hostname k8s_n3
echo "127.0.0.1   $(hostname)" >> /etc/hosts
```

2.通过docker启动kube-spray

```
docker run -d \
  --restart=unless-stopped \
  --name=kuboard-spray \
  -p 80:80/tcp \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/kuboard-spray-data:/data \
  eipwork/kuboard-spray:latest-amd64
```

- 在浏览器打开地址 `http://这台机器的IP`，输入默认密码 `Kuboard123`，即可登录 Kuboard-Spray 界面。

##  

![image-20220218093600514](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218093600514.png)

点击离线导入：

```
# 1. 在一台可以联网的机器上执行
docker pull registry.cn-shanghai.aliyuncs.com/kuboard-spray/kuboard-spray-resource:spray-v2.18.0a-2_k8s-v1.23.3_v1.6-amd64
docker save registry.cn-shanghai.aliyuncs.com/kuboard-spray/kuboard-spray-resource:spray-v2.18.0a-2_k8s-v1.23.3_v1.6-amd64 > kuboard-spray-resource.tar 

# 2. 将 kuboard-spray-resource.tar 复制到 kuboard-spray 所在的服务器（例如：10.99.0.11 的 /root/kuboard-spray-resource.tar）
scp ./kuboard-spray-resource.tar root@10.99.0.11:/root/kuboard-spray-resource.tar

# 3. 在 kuboard-spray 所在的服务器上执行，（例如：10.99.0.11）
docker load < /root/kuboard-spray-resource.tar
```

在离线导入页面输入一下：

```
downloadFrom: registry.cn-shanghai.aliyuncs.com/kuboard-spray/kuboard-spray-resource
metadata:
  version: spray-v2.18.0a-2_k8s-v1.23.3_v1.6-amd64
  type: kubernetes-offline-resource
  kuboard_spray_version:
    min: v1.0.0-beta.1
  available_at:
    - registry.cn-shanghai.aliyuncs.com/kuboard-spray/kuboard-spray-resource
    - swr.cn-east-2.myhuaweicloud.com/kuboard/kuboard-spray-resource
    - eipwork/kuboard-spray-resource
  issue_date: '2021-02-05'
  owner: shaohq@foxmail.com
  can_upgrade_from:
    include:
      - 'spray-v2.18.[0-9a-]*_k8s-v1.23.1_v[0-9.]*-amd64'
      - 'spray-master-8d9ed01_k8s-v1.23.1_v[0-9.]*-amd64'
    exclude: null
  can_replace_to:
    include:
      - spray-v2.18.0a-0_k8s-v1.23.3_v1.5-amd64
  supported_os:
    - distribution: Ubuntu
      versions:
        - '20.04'
    - distribution: CentOS
      versions:
        - '7.6'
        - '7.8'
        - '7.9'
    - distribution: openEuler
      versions:
        - '20.03'
data:
  kubespray_version: v2.18.0a-2
  supported_playbooks:
    install_cluster: pb_cluster.yaml
    remove_node: pb_remove_node.yaml
    add_node: pb_scale.yaml
    sync_nginx_config: pb_sync_nginx_config.yaml
    sync_etcd_address: pb_sync_etcd_address.yaml
    install_addon: pb_install_addon.yaml
    remove_addon: pb_remove_addon.yaml
    cluster_version_containerd: pb_cluster_version_containerd.yaml
    cluster_version_docker: pb_cluster_version_docker.yaml
    upgrade_cluster: pb_upgrade_cluster.yaml
  kubernetes:
    kube_version: v1.23.3
    image_arch: amd64
    gcr_image_repo: gcr.io
    kube_image_repo: k8s.gcr.io
  container_engine:
    - container_manager: containerd
      params:
        containerd_version: 1.5.9
    - container_manager: docker
      params:
        docker_version: '20.10'
        docker_containerd_version: 1.4.12
  vars:
    k8s_cluster:
      dns_min_replicas: '{{ [ 2, groups[''kube_control_plane''] | length ] | min }}'
      kuboardspray_extra_downloads:
        netcheck_etcd:
          container: true
          file: false
          enabled: '{{ deploy_netchecker }}'
          version: '{{ netcheck_etcd_image_tag }}'
          dest: >-
            {{ local_release_dir }}/etcd-{{ netcheck_etcd_image_tag }}-linux-{{
            image_arch }}.tar.gz
          repo: '{{ etcd_image_repo }}'
          tag: '{{ netcheck_etcd_image_tag }}'
          sha256: '{{ etcd_digest_checksum|d(None) }}'
          unarchive: false
          owner: root
          mode: '0755'
          groups:
            - k8s_cluster
        coredns:
          enabled: '{{ dns_mode in [''coredns'', ''coredns_dual''] }}'
          container: true
          repo: '{{ coredns_image_repo }}'
          tag: '{{ coredns_image_tag }}'
          sha256: '{{ coredns_digest_checksum|default(None) }}'
          groups:
            - k8s_cluster
  etcd:
    etcd_version: v3.5.1
    etcd_params: null
    etcd_deployment_type:
      - host
      - docker
  dependency:
    - name: crun
      version: 1.4
      target: crun_version
    - name: runc
      version: v1.0.3
      target: runc_version
    - name: cni-plugins
      version: v1.0.1
      target: cni_version
    - name: crictl
      version: v1.23.0
      target: crictl_version
    - name: nerdctl
      version: 0.16.0
      target: nerdctl_version
    - name: nginx_image
      version: 1.21.4
      target: nginx_image_tag
    - name: coredns
      target: coredns_version
      version: v1.8.6
    - name: cluster-proportional-autoscaler
      target: dnsautoscaler_version
      version: 1.8.5
    - name: pause
      target: pod_infra_version
      version: '3.3'
  network_plugin:
    - name: calico
      params:
        calico_version: v3.21.2
    - name: flannel
      params:
        flannel_version: v0.15.1
        flannel_cni_version: v1.0.0
  addon:
    - name: nodelocaldns
      target: enable_nodelocaldns
      lifecycle:
        install_by_default: true
        check:
          shell: kubectl get daemonset -n kube-system nodelocaldns -o json
          keyword: '"k8s-app": "kube-dns"'
        install_addon_tags:
          - download
          - upgrade
          - coredns
          - nodelocaldns
        downloads:
          - nodelocaldns
          - coredns
      params:
        nodelocaldns_version: 1.21.1
        enable_nodelocaldns_secondary: false
    - name: netchecker
      target: deploy_netchecker
      lifecycle:
        install_by_default: true
        check:
          shell: >-
            kubectl get deployment -n {{ netcheck_namespace | default('default')
            }} netchecker-server -o json
          keyword: k8s-netchecker-server
        install_addon_tags:
          - download
          - upgrade
          - netchecker
        remove_addon_tags:
          - upgrade
          - netchecker
        downloads:
          - netcheck_server
          - netcheck_agent
          - netcheck_etcd
      params:
        netcheck_version: v1.2.2
        netcheck_agent_image_repo: '{{ docker_image_repo }}/mirantis/k8s-netchecker-agent'
        netcheck_agent_image_tag: '{{ netcheck_version }}'
        netcheck_server_image_repo: '{{ docker_image_repo }}/mirantis/k8s-netchecker-server'
        netcheck_server_image_tag: '{{ netcheck_version }}'
        netcheck_etcd_image_tag: v3.5.1
    - name: metrics_server
      target: metrics_server_enabled
      lifecycle:
        install_by_default: true
        check:
          shell: kubectl get deployments -n kube-system metrics-server -o json
          keyword: k8s.gcr.io/metrics-server/metrics-server
        install_addon_tags:
          - download
          - upgrade
          - metrics_server
        remove_addon_tags:
          - upgrade
          - metrics_server
        downloads:
          - metrics_server
      params:
        metrics_server_version: v0.5.2

```

第三步安装集群：

![image-20220218093912802](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218093912802.png)

添加节点：

![image-20220218093938134](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218093938134.png)

![image-20220218094532024](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218094532024.png)

![image-20220218094614404](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218094614404.png)

安装进行中

![image-20220218094727842](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218094727842.png)

当出现以下界面时代表安装成功

![image-20220218103701185](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218103701185.png)

![image-20220218103719364](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220218103719364.png)

安装docker 1.18.4版本

```
yum remove docker  docker-common docker-selinux docker-engine

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://download.docker.com/linux/centos/docker-ce.repo

yum -y install docker-ce-18.03.1.ce

```

安装kuboad



```
hostnamectl set-hostname kuboard_manager
echo "127.0.0.1   $(hostname)" >> /etc/hosts
sudo docker run -d \
  --restart=unless-stopped \
  --name=kuboard \
  -p 80:80/tcp \
  -p 10081:10081/tcp \
  -e KUBOARD_ENDPOINT="http://192.168.20.71" \
  -e KUBOARD_AGENT_SERVER_TCP_PORT="10081" \
  -v /root/kuboard-data:/data \
  eipwork/kuboard:v3.3.0.6

```

安装kuboard-agent

```
 docker pull swr.cn-east-2.myhuaweicloud.com/kuboard/kuboard-agent:v3
 docker tag swr.cn-east-2.myhuaweicloud.com/kuboard/kuboard-agent:v3 www.harbor.mobi/kuboard/kuboard-agent:v3
 docker push www.harbor.mobi/kuboard/kuboard-agent:v3
```

安装traefik

需要安装helm

```
每个Helm 版本都提供了各种操作系统的二进制版本，这些版本可以手动下载和安装。

下载 需要的版本
解压(tar -zxvf helm-v3.0.0-linux-amd64.tar.gz)
在解压目中找到helm程序，移动到需要的目录中(mv linux-amd64/helm /usr/local/bin/helm)
```

helm install traefik -n kube-system  -f values-prod.yaml ./traefik/

安装nfs-server，所有节点需要安装。

```
yum install -y rpcbind nfs-utils

```

执行命令 `vim /etc/exports`，创建 exports 文件，文件内容如下

```
/home/nfs_root/ *(insecure,rw,sync,no_root_squash)

```

启动命令

```
systemctl enable rpcbind
systemctl enable nfs-server

systemctl start rpcbind
systemctl start nfs-server
exportfs -r
```

检查nfs

```
exportfs
```

部署web服务：

```
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: simpleingressroute
  namespace: bcs-dev
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`who.bcs.local`)
    kind: Rule
    services:
    - name: web
      port: 80
```

部署elastic-kibana服务

```
❯ cat traefik-kibana-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-kb-http
  namespace: logging
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: kibana.saynaihe.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: elastic-kb-http
            port:
              number: 5601
```

