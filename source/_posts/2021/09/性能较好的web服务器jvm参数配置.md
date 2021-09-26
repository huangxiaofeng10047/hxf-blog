---
title: 性能较好的web服务器jvm参数配置
date: 2021-09-24 17:10:58
tags:
- jvm
categories: 
- jvm
---

jvm 性能参数配置如下所示：

<!--more-->


```
\-server//服务器模式  
\-Xmx2g //JVM最大允许分配的堆内存，按需分配  
\-Xms2g //JVM初始分配的堆内存，一般和Xmx配置成一样以避免每次gc后JVM重新分配内存。  
\-Xmn256m //年轻代内存大小，整个JVM内存=年轻代 + 年老代 + 持久代  
\-XX:PermSize=128m //持久代内存大小  
\-Xss256k //设置每个线程的堆栈大小  
\-XX:+DisableExplicitGC //忽略手动调用GC, System.gc()的调用就会变成一个空调用，完全不触发GC  
\-XX:+UseConcMarkSweepGC //并发标记清除（CMS）收集器  
\-XX:+CMSParallelRemarkEnabled //降低标记停顿  
\-XX:+UseCMSCompactAtFullCollection //在FULL GC的时候对年老代的压缩  
\-XX:LargePageSizeInBytes=128m //内存页的大小  
\-XX:+UseFastAccessorMethods //原始类型的快速优化  
\-XX:+UseCMSInitiatingOccupancyOnly //使用手动定义初始化定义开始CMS收集  
\-XX:CMSInitiatingOccupancyFraction=70 //使用cms作为垃圾回收使用70％后开始CMS收集
```

**说明：**

\-Xmn和-Xmx之比大概是1:9，如果把新生代内存设置得太大会导致young gc时间较长

一个好的Web系统应该是每次http请求申请内存都能在young gc回收掉，full gc永不发生，当然这是最理想的情况

xmn的值应该是保证够用（够http并发请求之用）的前提下设置得尽量小

web服务器和游戏服务器的配置思路不太一样，最重要的区别是对游戏服务器的xmn即年轻代设置比较大，和Xmx大概1:3的关系，因为游戏服务器一般是长连接，在保持一定的并发量后需要较大的年轻代堆内存，如果设置得大小了会经常引发young gc

**对JVM的简介**

![一个性能较好的jvm参数配置以及jvm的简介](https://gitee.com/hxf88/imgrepo/raw/master/img/wKioL1W4PMSwMO9tAABPze3Qu7Y415.jpg-wh_651x-s_543553940.jpg)

由上图可以看出[JVM堆内存](http://www.codeceo.com/article/jvm-stack-memory.html "JVM堆内存")的分类情况，JVM内存被分成多个独立的部分。

广泛地说，JVM堆内存被分为两部分——年轻代（Young Generation）和老年代（Old Generation）。

**年轻代**

年轻代是所有新对象产生的地方。当年轻代内存空间被用完时，就会触发垃圾回收。这个垃圾回收叫做Minor GC。年轻代被分为3个部分——Enden区和两个Survivor区。

**年轻代空间的要点：**

大多数新建的对象都位于Eden区。

当Eden区被对象填满时，就会执行Minor GC。并把所有存活下来的对象转移到其中一个survivor区。

Minor GC同样会检查存活下来的对象，并把它们转移到另一个survivor区。这样在一段时间内，总会有一个空的survivor区。

经过多次GC周期后，仍然存活下来的对象会被转移到年老代内存空间。通常这是在年轻代有资格提升到年老代前通过设定年龄阈值来完成的。

**年老代**

年老代内存里包含了长期存活的对象和经过多次Minor GC后依然存活下来的对象。通常会在老年代内存被占满时进行垃圾回收。老年代的垃圾收集叫做Major GC。Major GC会花费更多的时间。

**Stop the World事件**

所有的垃圾收集都是“Stop the World”事件，因为所有的应用线程都会停下来直到操作完成（所以叫“Stop the World”）。

因为年轻代里的对象都是一些临时（short-lived ）对象，执行Minor GC非常快，所以应用不会受到（“Stop the World”）影响。

由于Major GC会检查所有存活的对象，因此会花费更长的时间。应该尽量减少Major GC。因为Major GC会在垃圾回收期间让你的应用反应迟钝，所以如果你有一个需要快速响应的应用发生多次Major GC，你会看到超时错误。

垃圾回收时间取决于垃圾回收策略。这就是为什么有必要去监控垃圾收集和对垃圾收集进行调优。从而避免要求快速响应的应用出现超时错误。

**永久代**

永久代或者“Perm Gen”包含了JVM需要的应用元数据，这些元数据描述了在应用里使用的类和方法。注意，永久代不是Java堆内存的一部分。

永久代存放JVM运行时使用的类。永久代同样包含了Java SE库的类和方法。永久代的对象在full GC时进行垃圾收集。

**方法区**

方法区是永久代空间的一部分，并用来存储类型信息（运行时常量和静态变量）和方法代码和构造函数代码。

**内存池**

如果JVM实现支持，JVM内存管理会为创建内存池，用来为不变对象创建对象池。字符串池就是内存池类型的一个很好的例子。内存池可以属于堆或者永久代，这取决于JVM内存管理的实现。

**运行时常量池**

运行时常量池是每个类常量池的运行时代表。它包含了类的运行时常量和静态方法。运行时常量池是方法区的一部分。

**Java栈内存**

Java栈内存用于运行线程。它们包含了方法里的临时数据、堆里其它对象引用的特定数据。

[Java垃圾回收](http://www.codeceo.com/article/7-java-gc.html "Java垃圾回收")

Java垃圾回收会找出没用的对象，把它从内存中移除并释放出内存给以后创建的对象使用。Java程序语言中的一个最大优点是自动垃圾回收，不像其他的程序语言那样需要手动分配和释放内存，比如C语言。

垃圾收集器是一个后台运行程序。它管理着内存中的所有对象并找出没被引用的对象。所有的这些未引用的对象都会被删除，回收它们的空间并分配给其他对象。

**一个基本的垃圾回收过程涉及三个步骤**：

标记：这是第一步。在这一步，垃圾收集器会找出哪些对象正在使用和哪些对象不在使用。

正常清除：垃圾收集器清会除不在使用的对象，回收它们的空间分配给其他对象。

压缩清除：为了提升性能，压缩清除会在删除没用的对象后，把所有存活的对象移到一起。这样可以提高分配新对象的效率。

简单标记和清除方法存在两个问题：

效率很低。因为大多数新建对象都会成为“没用对象”。

经过多次垃圾回收周期的对象很有可能在以后的周期也会存活下来。

上面简单清除方法的问题在于Java垃圾收集的分代回收的，而且在堆内存里有年轻代和年老代两个区域。

**Java垃圾回收类型**

这里有五种可以在应用里使用的垃圾回收类型。

仅需要使用JVM开关就可以在我们的应用里启用垃圾回收策略。

Serial GC（-XX:+UseSerialGC）：Serial GC使用简单的标记、清除、压缩方法对年轻代和年老代进行垃圾回收，即Minor GC和Major GC。Serial GC在client模式（客户端模式）很有用，比如在简单的独立应用和CPU配置较低的机器。这个模式对占有内存较少的应用很管用。

Parallel GC（-XX:+UseParallelGC）：除了会产生N个线程来进行年轻代的垃圾收集外，Parallel GC和Serial GC几乎一样。这里的N是系统CPU的核数。我们可以使用 -XX:ParallelGCThreads=n 这个JVM选项来控制线程数量。并行垃圾收集器也叫throughput收集器。因为它使用了多CPU加快垃圾回收性能。Parallel GC在进行年老代垃圾收集时使用单线程。

Parallel Old GC（-XX:+UseParallelOldGC）：和Parallel GC一样。不同之处，Parallel Old GC在年轻代垃圾收集和年老代垃圾回收时都使用多线程收集。

并发标记清除（CMS）收集器（-XX:+UseConcMarkSweepGC)：CMS收集器也被称为短暂停顿并发收集器。它是对年老代进行垃 圾收集 的。CMS收集器通过多线程并发进行垃圾回收，尽量减少垃圾收集造成的停顿。CMS收集器对年轻代进行垃圾回收使用的算法和Parallel收集器一样。 这个垃圾收集器适用于不能忍受长时间停顿要求快速响应的应用。可使用 -XX:ParallelCMSThreads=n JVM选项来限制CMS收集器的线程数量。

G1垃圾收集器（-XX:+UseG1GC) G1（Garbage First）：垃圾收集器是在Java 7后才可以使用的特性，它的长远目标时代替CMS收集器。G1收集器是一个并行的、并发的和增量式压缩短暂停顿的垃圾收集器。G1收集器和其他的收集器运 行方式不一样，不区分年轻代和年老代空间。它把堆空间划分为多个大小相等的区域。当进行垃圾收集时，它会优先收集存活对象较少的区域，因此叫 “Garbage First”。
