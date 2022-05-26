containerd配置harbor私服

因为k8s开始启用docker使用containerd来运行容器了，所以支持私服，需要配置私服处理器：





 vi /etc/containerd/config.toml

扎到添加地方，一般在docker.io后面




```toml
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry.cn-hangzhou.aliyuncs.com"]#在这行后面添加的
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."www.harbor.mobi"]
                        endpoint = ["https://www.harbor.mobi"]
   [plugins."io.containerd.grpc.v1.cri".registry.configs]
                 [plugins."io.containerd.grpc.v1.cri".registry.configs."www.harbor.mobi".tls]
                        insecure_skip_verify = true
         [plugins."io.containerd.grpc.v1.cri".registry.configs."www.harbor.mobi".auth]
                        username = "admin"
                        password = "Harbor12345"
```

重启服务：

`systemctl restart containerd`