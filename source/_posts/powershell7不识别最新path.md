---
title: powershell7不识别最新path
date: 2021-07-30 09:39:28
tags: powershell7 
---

# 问题

使用不用方式启动的 Powershell 得到的环境是不同的。通过以下命令查看。可将系统路径（Machine）和用户路径合并后设置未当前的环境变量

```powershell
>> $env:path
```
<!--more-->

# 解决

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::Get
```

