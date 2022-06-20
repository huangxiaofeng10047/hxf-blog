---
title: k8s运维
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-10 16:27:14
tags:
---

kuboard上报如下错误

```
Readiness probe errored: rpc error: code = Unknown desc = failed to exec in container: failed to start exec "54da3a02c62303bf98703ff2fffa622d2c3d3afbdcff4abd1c44fe3e2300b74c": OCI runtime exec failed: exec failed: cannot exec in a stopped container: unknown
```

```

error killing pod: [failed to "KillContainer" for "mysql" with KillContainerError: "rpc error: code = DeadlineExceeded desc = an error occurs during waiting for container \"0916e388251d5b5d0e4f751545268d8fdbec167c950b6d4da55cc96e6ad36e21\" to be killed: wait container \"0916e388251d5b5d0e4f751545268d8fdbec167c950b6d4da55cc96e6ad36e21\": context deadline exceeded", failed to "KillPodSandbox" for "0b648d5b-4f64-45cf-b3a1-6c437f5e7c60" with KillPodSandboxError: "rpc error: code = DeadlineExceeded desc = context deadline exceeded"]

```

