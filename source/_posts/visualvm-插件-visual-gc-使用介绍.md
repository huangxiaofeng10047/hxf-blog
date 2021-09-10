---
title: visualvm 插件 visual gc 使用介绍
date: 2021-09-10 11:49:38
tags:
- jvm
categories: 
- java
---

visual gc 是 visualvm 中的图形化查看 gc 状况的插件。

具体详细介绍可参照： http://www.oracle.com/technetwork/java/visualgc-136680.html

本文也是在此基础上进行的整理归纳。

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171108160915638-1259396529.png)

## OUTPUT FORMAT

visual gc 工具分成三大块

-   -   　作者 对 eclipse 监控，这个选项是不可用的，需要调查原因
    

## Visual GC Window

我们看到上方图片中的 Spaces 就是 Visual GC window 了。它会分成 3 个竖直的部分，分别是 Perm 永生代，  Old 老年代和新生代。

新生代又分成 3 个部分 Eden 区， S0 survivor 区， S1 survivor 区.

每个方框中都使用不同的颜色表示，其中有颜色的区域是占用的空间，空白的部分是指剩余的空间。

当程序正在运行时，该部分区域就会动态显示，以直观的形式显示各个分区的动态情况。

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171108165116763-11520902.png)

## Graph Window

该区域包含多个以时间为横坐标的状态面板。

### `Compile Time`

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109144835247-768276628.png)

 编译时间表示虚拟机的 JIT 编译器编译热点代码的耗时。

 Java 语言为了实现跨平台特性， Java 代码编译出来后形成的 class 文件中存储的是 byte code，jvm 通过解释的方式形成字节码命令，这种方式与 C/C++ 编译成二进制的方式　　相比要慢不少。

 为了解决程序解释执行的速度问题， jvm 中内置了两个运行时编译器，如果一段 Java 代码被调用达到一定次数，就会判定这段代码为热点代码（hot spot code），并将这段代　　码交给 JIT 编译器编译成本地代码，从而提高运行速度。所以随着代码被编译的越来越彻底，运行速度应当是越来越快。

 而 Java 运行器编译的最大缺点就是它进行编译时需要消耗程序正常的运行时间，也就是 compile time.

### `Class Loader Time`

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109144719434-520181707.png)

表示 class 的 load 和 unload 时间

### `GC Time`

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109144917278-2094290894.png)

22 collections 表示自监视以来一共经历了 22 次GC, 包括 Minor GC 和 Full GC

2.030s 表示 gc 共花费了 2.030s

Last Cause: Allocation Failure 表示上次发生 gc 的原因： 内存分配失败

### `Eden Space`

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109145332684-2073237401.png)

Eden Space (340.500M,185.000M): 91.012M

表示 Eden Space 最大可分配空间  340.500M

Eden Space 当前分配空间 185.000M

Eden Space 当前占用空间 91.012M

21 collections， 1.012s

表示当前新生代发生 GC 的次数为 21 次, 共占用时间 1.012s

#### `Survivor 0 and Survivor 1`

![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109152427294-1771847281.png)

S0 和 S1 肯定有一个是空闲的，这样才能方便执行 minor GC 的操作，但是两者的最大分配空间是相同的。并且在 minor GC 时，会发生 S0 和S1 之间的切换。

Survivor 1 (113.500M, 75.000M) : 36.590M

表示 S1 最大分配空间 113.500M, 当前分配空间 75.000M, 已占用空间 36.590M  

### `Old Gen`

　　![](https://gitee.com/hxf88/imgrepo/raw/master/img/1202311-20171109152922716-1418649494.png)

　　Old Gen (682.500M, 506.500M) : 233.038M, 1 collections, 1.018s

  (682.500M, 506.500M) : 233.038M

表示 OldGen 最大分配空间 682.500M， 当前空间  506.500M， 已占用空间 233.038M

1 collections, 1.018s 表示老年代共发生了 1次 GC， 耗费了 1.018s 的时间。

老年代 GC 也叫做 Full GC， 因为在老年代 GC 时总是会伴随着 Minor GC， 合起来就称为 Full GC。

### `Perm Gen`

　　![](https://images2017.cnblogs.com/blog/1202311/201711/1202311-20171109153928028-1978755818.png)

　　Perm Gen (256.000M, 227.500M) : 122.800M

　　256.000M 表示最大可用空间，可以使用 \-XX:MaxPermSize 指定永久代最大上限  
