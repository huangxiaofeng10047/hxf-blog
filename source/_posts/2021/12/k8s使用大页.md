Kubernetes 使用大页 -

### 什么是大页面？

当一个进程使用一些内存时，CPU标记该进程使用的RAM。为了 高效，CPU接4K字节按块分配（许多平台默认）。这些块成为页面。由于进程地址空间是虚拟的，因此CPU和OS必须记住那个页面属于哪个进程，使用了更多的内存，需要管理更多的页面。为了避免对页面进行繁重的调度，大多数当前的CPU体系结构都支持大于4KB的页面，在Linux上，它称为巨大页面。

### Kubernetes

如今，我们处于容器化领域，Kubernetes用一个基于自动化的部署，扩展和管理的开源容器编排系统。但是在我们的例子中，某些需要巨大页面能力的应用程序就是DPDK。

#### 那么我们可以在kubernetes中使用大页面吗？

根据官方描述，如果kubernetes版本>=1.10，则默认启动HugePages，否则你必须自己启用它。

登录到你的Kubernetes节点机器。打开并编辑`/etc/default/kubelet`此文件，找到`--feature-gates=`这些文本，添加一些文本以使其看起来像`--feature-gates=HugePages=true`。

```
systemctl daemon-reload
systemctl restart kubelet
```

然后进行下一步

```
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
```

现在登录master，并使用`kubectl describe nodes`检查是否启用了大页面。你可能会看到类似下面的内容

```
apiVersion: v1
kind: Node
metadata:
  name: node1

status:
  capacity:
    memory: 10Gi
    hugepages-2Mi: 1Gi
  allocatable:
    memory: 9Gi
    hugepages-2Mi: 1Gi

```

一个示例Pod

```
apiVersion: v1
kind: Pod
metadata:
  name: example
spec:
  containers:

    volumeMounts:
    - mountPath: /hugepages
      name: hugepage
    resources:
      requests:
        hugepages-2Mi: 1Gi
      limits:
        hugepages-2Mi: 1Gi
  volumes:
  - name: hugepage
    emptyDir:
      medium: HugePages
```

参考文档：

https://kubernetes.io/zh/docs/tasks/manage-hugepages/scheduling-hugepages/

https://github.com/FDio/govpp

https://www.its304.com/article/doujiangbear/112797481

https://eddycjy.com/posts/kubernetes/2020-05-10-api/

https://www.cxymm.net/article/cloudvtech/80408099

https://www.intel.cn/content/dam/technology-provider/public/documents/case-study/kubernetes-application-note.pdf

https://www.cnblogs.com/dream397/p/13964154.html

https://www.cxyzjd.com/article/cloudvtech/80505572

https://github.com/intel/userspace-cni-network-plugin#installing-vpp

https://gitee.com/mirrors/Kube-OVN/blob/master/docs/dpdk.md

https://www.cnblogs.com/halberd-lee/p/12802918.html