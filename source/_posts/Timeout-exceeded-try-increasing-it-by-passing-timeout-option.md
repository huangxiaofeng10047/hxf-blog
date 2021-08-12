---
title: 'Timeout exceeded: try increasing it by passing --timeout option'
date: 2021-08-12 13:25:11
tags: golang
---

ci里面配置了golangci-lint检查，但是偶尔总出现level=error msg="Timeout exceeded: try increasing it by passing --timeout option"这种错误， 重新执行一次就正常了，虽然几率小，但还是会造成困扰，于是找了下问题，分享下解决方案。
————————————————

### 解决方法

<!--more-->

在**golangci-lint**运行时，加上timeout的参数设置(默认是1分钟)

```
golangci-lint run ./... --timeout=10m

123
```

详细的信息可以通过命令行的help查看:`golangci-lint run -h`

