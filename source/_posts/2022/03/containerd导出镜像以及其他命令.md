---
title: containerd导出镜像以及其他命令
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-29 17:31:45
tags: 
---

### 一、ctr 命令使用

Container命令ctr,crictl的用法
版本：ctr containerd.io 1.4.3
containerd 相比于docker , 多了namespace概念, 每个image和container 都会在各自的namespace下可见, 目前k8s会使用k8s.io 作为命名空间~~

1.1、查看ctr image可用操作

1. ctr image list, ctr i list , ctr i ls

1.2、镜像标记tag

1. ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2

注意: 若新镜像reference 已存在, 需要先删除新reference, 或者如下方式强制替换

1. ctr -n k8s.io i tag --force registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2

1.3、删除镜像

1. ctr -n k8s.io i rm k8s.gcr.io/pause:3.2

1.4、拉取镜像

1. ctr -n k8s.io i pull -k k8s.gcr.io/pause:3.2

1.5、推送镜像

1. ctr -n k8s.io i push -k k8s.gcr.io/pause:3.2

1.6、导出镜像

1. ctr -n k8s.io i export pause.tar k8s.gcr.io/pause:3.2

1.7、导入镜像

1. *# 不支持 build,commit 镜像*
2. 
3. 
4. ctr -n k8s.io i import pause.tar

1.8、查看容器相关操作

1. ctr c

1.9、运行容器
–null-io: 将容器内标准输出重定向到/dev/null
–net-host: 主机网络
-d: 当task执行后就进行下一步shell命令,如没有选项,则会等待用户输入,并定向到容器内
–mount 挂载本地目录或文件到容器
–env 环境变量

1. ctr -n k8s.io run --null-io --net-host -d \

–env PASSWORD=”123456″
–mount type=bind,src=/etc,dst=/host-etc,options=rbind:rw

1.10、容器日志
注意: 容器默认使用fifo创建日志文件, 如果不读取日志文件,会因为fifo容量导致业务运行阻塞
如要创建日志文件,建议如下方式创建:

1. ctr -n k8s.io run --log-uri file:///var/log/xx.log

### 二、ctr和docker命令比较

| Containerd命令                 | Docker命令                           | 描述               |
| ------------------------------ | ------------------------------------ | ------------------ |
| ctr task ls                    | docker ps                            | 查看运行容器       |
| ctr image ls                   | docker images                        | 获取image信息      |
| ctr image pull pause           | docker pull pause                    | pull 应该pause镜像 |
| ctr image push pause-test      | docker push pause-test               | 改名               |
| ctr image import pause.tar     | docker load 镜像                     | 导入本地镜像       |
| ctr run -d pause-test pause    | docker run -d –name=pause pause-test | 运行容器           |
| ctr image tag pause pause-test | docker tag pause pause-test          | tag应该pause镜像   |

### 三、crictl 命令

3.1、crictl 配置

1. *# 通过在配置文件中设置端点 --config=/etc/crictl.yaml*
2. root@k8s-node-0001:~$ cat /etc/crictl.yaml
3. runtime-endpoint: unix:///run/containerd/containerd.sock

3.2、列出业务容器状态

1. crictl inspect ee20ec2346fc5

3.3、查看运行中容器

1. root@k8s-node-0001:~$ crictl pods
2. POD ID              CREATED             STATE               NAME                                                     NAMESPACE           ATTEMPT             RUNTIME
3. b39a7883a433d       10 minutes ago      Ready               canal-server-quark-b477b5d79-ql5l5                       mbz-alpha           0                   (default)

3.4、打印某个固定pod

1. root@k8s-node-0001:~$ crictl pods --name canal-server-quark-b477b5d79-ql5l5
2. POD ID              CREATED             STATE               NAME                                 NAMESPACE           ATTEMPT             RUNTIME
3. b39a7883a433d       12 minutes ago      Ready               canal-server-quark-b477b5d79-ql5l5   mbz-alpha           0                   (default)

3.5、打印镜像

1. root@k8s-node-0001:~$ crictl images
2. IMAGE                                                          TAG                             IMAGE ID            SIZE
3. ccr.ccs.tencentyun.com/koderover-public/library-docker         stable-dind                     a6e51fd179fb8       74.6MB
4. ccr.ccs.tencentyun.com/koderover-public/library-nginx          stable                          588bb5d559c28       51MB
5. ccr.ccs.tencentyun.com/koderover-public/nsqio-nsq              v1.0.0-compat                   2714222e1b39d       22MB

3.6、只打印镜像 ID

1. root@k8s-node-0001:~$ crictl images -q
2. sha256:a6e51fd179fb849f4ec6faee318101d32830103f5615215716bd686c56afaea1
3. sha256:588bb5d559c2813834104ecfca000c9192e795ff3af473431497176b9cb5f2c3
4. sha256:2714222e1b39d8bd6300da72b0805061cabeca3b24def12ffddf47abd47e2263
5. sha256:be0f9cfd2d7266fdd710744ffd40e4ba6259359fc3bc855341a8c2adad5f5015

3.7、打印容器清单

1. root@k8s-node-0001:~$ crictl ps -a
2. CONTAINER           IMAGE               CREATED             STATE               NAME                     ATTEMPT             POD ID
3. ee20ec2346fc5       c769a1937d035       13 minutes ago      Running             canal-server             0                   b39a7883a433d
4. 76226ddb736be       cc0c524d64c18       34 minutes ago      Running             mbz-rescue-manager       0                   2f9d48c49e891
5. e2a19ff0591b4       eb40a52eb437d       About an hour ago   Running             export                   0                   9844b5ea5fdbc

 

3.8、打印正在运行的容器清单

1. root@k8s-node-0001:~$ crictl ps
2. CONTAINER           IMAGE               CREATED             STATE               NAME                   ATTEMPT             POD ID
3. ee20ec2346fc5       c769a1937d035       13 minutes ago      Running             canal-server           0                   b39a7883a433d

3.9、容器上执行命令

1. root@k8s-node-0001:~$ crictl exec -i -t ee20ec2346fc5 ls
2. app.sh  bin  canal-server  health.sh  node_exporter  node_exporter-0.18.1.linux-arm64

3.10、获取容器的所有日志

1. root@k8s-node-0001:~$ crictl logs ee20ec2346fc5
2. DOCKER_DEPLOY_TYPE=VM
3. ==> INIT /alidata/init/02init-sshd.sh
4. ==> EXIT CODE: 0
5. ==> INIT /alidata/init/fix-hosts.py

3.11、获取最近的 N 行日志

1. root@k8s-node-0001:~$ crictl logs --tail=2 ee20ec2346fc5
2. start canal successful
3. ==> START SUCCESSFUL ...

3.12、拉取镜像

1. crictl pull busybox
