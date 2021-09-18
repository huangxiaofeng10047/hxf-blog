---
title: jmap 命令使用
date: 2021-09-18 15:24:31
tags:
- jvm
categories: 
- jvm
---

jdk 自带的命令用来 dump heap info，或者查看 ClassLoader info，等等。

## 命令格式

```
jmap [OPTION] PID
```

## 使用实例

### 不加任何参数

直接使用命令

```
jmap pid
```

查看 pid 内存信息。

### 查看堆信息

```
jmap -heap pid
```

### 查看堆对象信息

统计对象 count ，live 表示在使用

```
jamp -histo pid
jmap -histo:live pid
```

### 查看 classLoader

```
jmap -clstats pid
```

### 生成堆快照

```
jmap -dump:format=b,file=heapdump.phrof pid
```

hprof 二进制格式转储 Java 堆到指定 filename 的文件中，live 选项将堆中活动的对象转存。

> 执行的过程中为了保证 dump 的信息是可靠的，所以会暂停应用， 线上系统慎用

文件可以用 jhat 分析。
