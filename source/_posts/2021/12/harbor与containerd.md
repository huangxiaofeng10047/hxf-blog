![](https://csdnimg.cn/release/blogv2/dist/pc/img/original.png)

[石头-豆豆](https://blog.csdn.net/xjjj064) 2020-07-30 10:47:35 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/articleReadEyes.png) 5645 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/tobarCollect.png) 收藏  8 

版权声明：本文为博主原创文章，遵循 [CC 4.0 BY-SA](http://creativecommons.org/licenses/by-sa/4.0/) 版权协议，转载请附上原文出处链接和本声明。

## [k8s](https://so.csdn.net/so/search?q=k8s)搭配containerd：如何从harbor私有仓库pull镜像

[container](https://so.csdn.net/so/search?q=container)d 实现了 kubernetes 的 Container Runtime Interface (CRI) 接口，提供容器运行时核心功能，如镜像管理、容器管理等，相比 dockerd 更加简单、健壮和可移植。  
从[docker](https://so.csdn.net/so/search?q=docker)过度还是需要一点时间慢慢习惯的，今天来探讨containerd 如何从私有仓库harbor下载镜像！  
containerd 不能像docker一样 docker login harbor.example.com 登录到镜像仓库。无法从harbor拉取到镜像。  
解决办法：  
更改containerd 的config.toml文件  
可通过命令：containerd config default> /etc/containerd/config.toml 生成默认配置文件！  
文件路径：

```
[root@k8s02 containerd]
/etc/containerd
[root@k8s02 containerd]
config.toml  config.toml.rpmnew
[root@k8s02 containerd]
```

添加如下内容：

```
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.creditgogogo.com"]
      endpoint = ["https://harbor.creditgogogo.com"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.creditgogogo.com".tls]
      insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.creditgogogo.com".auth]
      username = "admin"
      password = "Harbor12345"
```

完整内容如下：

```
[root@k8s02 containerd]
version = 2
root = "/data/k8s/containerd/root"
state = "/data/k8s/containerd/state"

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.cn-beijing.aliyuncs.com/images_k8s/pause-amd64:3.1"
    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "/opt/k8s/bin"
      conf_dir = "/etc/cni/net.d"
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.creditgogogo.com"]
          endpoint = ["https://harbor.creditgogogo.com"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.creditgogogo.com".tls]
          insecure_skip_verify = true
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.creditgogogo.com".auth]
          username = "admin"
          password = "Harbor12345"
  [plugins."io.containerd.runtime.v1.linux"]
    shim = "containerd-shim"
    runtime = "runc"
    runtime_root = ""
    no_shim = false
    shim_debug = false
```

修改完之后重启containerd服务

```
systemctl status containerd.service
```

最后查看pod 状态，已成功拉取到harbor镜像！  
kubectl describe pod rabbitmq-0

```
[root@k8s01 containerd]
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  27m                default-scheduler  Successfully assigned default/rabbitmq-0 to k8s01
  Normal   Pulling    27m (x2 over 27m)  kubelet, k8s01     Pulling image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8"
  Warning  Failed     27m (x2 over 27m)  kubelet, k8s01     Failed to pull image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8": rpc error: code = Unknown desc = failed to pull and unpack image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8:latest": failed to resolve reference "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8:latest": failed to do request: Head https://harbor.creditgogogo.com/v2/ops/centos7.5-erlang-rabbitmq2.8/manifests/latest: x509: certificate signed by unknown authority
  Warning  Failed     27m (x2 over 27m)  kubelet, k8s01     Error: ErrImagePull
  Normal   BackOff    27m (x3 over 27m)  kubelet, k8s01     Back-off pulling image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8"
  Warning  Failed     27m (x3 over 27m)  kubelet, k8s01     Error: ImagePullBackOff
  Normal   Pulling    26m                kubelet, k8s01     Pulling image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8"
  Normal   Pulled     26m                kubelet, k8s01     Successfully pulled image "harbor.creditgogogo.com/ops/centos7.5-erlang-rabbitmq2.8"
  Normal   Created    26m                kubelet, k8s01     Created container rabbitmq
  Normal   Started    26m                kubelet, k8s01     Started container rabbitmq
```

参考连接：https://www.jianshu.com/p/aa0f49ad614f  
参考连接：https://blog.csdn.net/laomeng2019/article/details/90300866