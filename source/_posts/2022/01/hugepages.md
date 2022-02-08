---
title: hugepages
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
```
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages


```

上面的步骤会开启hugepages

```
systemctl daemon-reload && systemctl restart kubelet
```

**需要重新挂载参数才能生效，一定注意。**