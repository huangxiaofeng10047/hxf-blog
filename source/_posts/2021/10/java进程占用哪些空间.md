---
title: java进程占用哪些空间
date: 2021-10-21 08:56:31
tags:
---

一个java进程具体占用哪些空间可以开启nmat来查看，通过在启动参数上加上“-XX:NativeMemoryTracking=detail”即可

通过命令“  jcmd 3722963 VM.native_memory summary”查询，输出结果如下

```
3722963:

Native Memory Tracking:

Total: reserved=2588819KB, committed=1324807KB
-                 Java Heap (reserved=1048576KB, committed=1048576KB)
                            (mmap: reserved=1048576KB, committed=1048576KB)

-                     Class (reserved=1126342KB, committed=87750KB)
                            (classes #14707)
                            (malloc=1990KB #29574)
                            (mmap: reserved=1124352KB, committed=85760KB)

-                    Thread (reserved=34635KB, committed=34635KB)
                            (thread #83)
                            (stack: reserved=34272KB, committed=34272KB)
                            (malloc=267KB #423)
                            (arena=96KB #164)

-                      Code (reserved=274671KB, committed=49251KB)
                            (malloc=8431KB #11733)
                            (mmap: reserved=266240KB, committed=40820KB)

-                        GC (reserved=22765KB, committed=22765KB)
                            (malloc=20197KB #412)
                            (mmap: reserved=2568KB, committed=2568KB)

-                  Compiler (reserved=317KB, committed=317KB)
                            (malloc=186KB #424)
                            (arena=131KB #3)

-                  Internal (reserved=21018KB, committed=21018KB)
                            (malloc=20986KB #21011)
                            (mmap: reserved=32KB, committed=32KB)

-                    Symbol (reserved=19372KB, committed=19372KB)
                            (malloc=17062KB #175335)
                            (arena=2310KB #1)

-    Native Memory Tracking (reserved=3989KB, committed=3989KB)
                            (malloc=202KB #3176)
                            (tracking overhead=3787KB)

-               Arena Chunk (reserved=199KB, committed=199KB)
                            (malloc=199KB)

-                   Unknown (reserved=36936KB, committed=36936KB)
                            (mmap: reserved=36936KB, committed=36936KB)
```

解释一下：

### JVM部件（主要通过本机内存跟踪显示）

1. Java堆

   最明显的部分。这是Java对象所在的位置。堆占用了`-Xmx`大量的内存。

2. 垃圾收集器

   GC结构和算法需要额外的内存用于堆管理。这些结构是Mark Bitmap，Mark Stack（用于遍历对象图），Remembered Sets（用于记录区域间引用）等。其中一些是直接可调的，例如`-XX:MarkStackSizeMax`，其他一些依赖于堆布局，例如，较大的是G1区域（`-XX:G1HeapRegionSize`），较小的是记忆集。

   GC内存开销因GC算法而异。`-XX:+UseSerialGC`并且`-XX:+UseShenandoahGC`开销最小。G1或CMS可以轻松使用总堆大小的10％左右。

3. 代码缓存

   包含动态生成的代码：JIT编译的方法，解释器和运行时存根。它的大小受限于`-XX:ReservedCodeCacheSize`（默认为240M）。关闭`-XX:-TieredCompilation`以减少编译代码的数量，从而减少代码缓存的使用。

4. 编译器

   JIT编译器本身也需要内存来完成它的工作。通过关闭分层编译或减少编译器线程的数量，可以再次减少这种情况：`-XX:CICompilerCount`。

5. 类加载

   类元数据（方法字节码，符号，常量池，注释等）存储在称为Metaspace的堆外区域中。加载的类越多 - 使用的元空间就越多。总使用量可以受限`-XX:MaxMetaspaceSize`（默认为无限制）和`-XX:CompressedClassSpaceSize`（默认为1G）。

6. 符号表

   JVM的两个主要哈希表：Symbol表包含名称，签名，标识符等，String表包含对实习字符串的引用。如果本机内存跟踪指示String表占用大量内存，则可能意味着应用程序过度调用`String.intern`。

7. 主题

   线程堆栈也负责占用RAM。堆栈大小由`-Xss`。每个线程的默认值是1M，但幸运的是事情并没有那么糟糕。操作系统懒惰地分配内存页面，即在第一次使用时，因此实际内存使用量将低得多（通常每个线程堆栈80-200 KB）。我编写了一个[脚本](https://github.com/apangin/jstackmem)来估计RSS有多少属于Java线程堆栈。

   还有其他JVM部件可以分配本机内存，但它们通常不会在总内存消耗中发挥重要作用。

### 直接缓冲

应用程序可以通过调用显式请求堆外内存`ByteBuffer.allocateDirect`。默认的堆外限制等于`-Xmx`，但可以用它覆盖`-XX:MaxDirectMemorySize`。Direct ByteBuffers包含在`Other`NMT输出部分（或`Internal`JDK 11之前）。

通过JMX可以看到使用的直接内存量，例如在JConsole或Java Mission Control中：

除了直接的ByteBuffers，还可以有`MappedByteBuffers`- 映射到进程虚拟内存的文件。NMT不跟踪它们，但MappedByteBuffers也可以占用物理内存。而且没有一种简单的方法来限制它们可以承受多少。您可以通过查看进程内存映射来查看实际使用情况：`pmap -x <pid>`

```
Address Kbytes    RSS    Dirty Mode Mapping ... 00007f2b3e557000 39592 32956 0 r--s- some-file-17405-Index.db 00007f2b40c01000 39600 33092 0 r--s- some-file-17404-Index.db                            ^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^
```

### 本地图书馆

加载的JNI代码`System.loadLibrary`可以根据需要分配尽可能多的堆外内存，而无需JVM端的控制。这也涉及标准的Java类库。特别是，未封闭的Java资源可能成为本机内存泄漏的来源。典型的例子是`ZipInputStream`或`DirectoryStream`。

JVMTI代理，特别是`jdwp`调试代理 - 也可能导致过多的内存消耗。

此答案描述了如何使用[async-profiler](https://github.com/jvm-profiling-tools/async-profiler/)配置本机内存分配。

### 分配器问题

进程通常直接从OS（通过`mmap`系统调用）或使用`malloc`- 标准libc分配器请求本机内存。反过来，`malloc`要求OS使用大块内存`mmap`，然后根据自己的分配算法管理这些块。问题是 - 该算法可能导致碎片和[过多的虚拟内存使用](https://www.ibm.com/developerworks/community/blogs/kevgrig/entry/linux_glibc_2_10_rhel_6_malloc_may_show_excessive_virtual_memory_usage?lang=en)。

[`jemalloc`](http://jemalloc.net/)，替代分配器，通常看起来比常规libc更智能`malloc`，因此切换到`jemalloc`可能导致更小的空闲。

### 结论

没有保证估计Java进程的完整内存使用量的方法，因为有太多因素需要考虑。

```
Total memory = Heap + Code Cache + Metaspace + Symbol tables + Other JVM structures + Thread stacks + Direct buffers + Mapped files + Native Libraries + Malloc overhead + ...
```

可以通过JVM标志缩小或限制某些内存区域（如代码缓存），但许多其他内存区域完全不受JVM控制。

设置Docker限制的一种可能方法是在进程的“正常”状态下观察实际内存使用情况。有研究Java内存消耗问题的工具和技术：[Native Memory Tracking](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr007.html)，[pmap](http://man7.org/linux/man-pages/man1/pmap.1.html)，[jemalloc](http://jemalloc.net/)，[async-profiler](https://github.com/jvm-profiling-tools/async-profiler)。

我的java进程的配置参数如下：

启动两个java进程

```shell
nohup java -server -Xms1g -Xmx1g -Xmn768m -Xss256k -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256M -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=5 -XX:GCTimeRatio=19 -Xnoclassgc -XX:+DisableExplicitGC -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=70 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:NativeMemoryTracking=detail -XX:MaxDirectMemorySize=128m -XX:ReservedCodeCacheSize=256M  -XX:CICompilerCount=2 -jar /home/sangda/tau/tr069-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod > /dev/null 2>&1 &

nohup java -server -Xms1g -Xmx1g -Xmn768m -Xss256k -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256M -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=5 -XX:GCTimeRatio=19 -Xnoclassgc -XX:+DisableExplicitGC -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=70 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:NativeMemoryTracking=detail -XX:MaxDirectMemorySize=128m -XX:ReservedCodeCacheSize=256M -XX:CICompilerCount=2 -jar /home/sangda/tau/tau-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev  > /dev/null 2>&1 &
```

这里的 [mmap](https://link.zhihu.com/?target=https%3A//man7.org/linux/man-pages/man2/mmap.2.html)，[malloc](https://link.zhihu.com/?target=https%3A//man7.org/linux/man-pages/man3/malloc.3.html) 是两种不同的内存申请分配方式，例如：

```
-                  Internal (reserved=21018KB, committed=21018KB)
                            (malloc=20986KB #21011)
                            (mmap: reserved=32KB, committed=32KB)
```





代表 `Internal` 一共占用 `21018KB`，其中`20986KB`是通过 malloc 方式，`32KB` 是通过 mmap 方式。 arena 是通过 malloc 方式分配的内存但是代码执行完并不释放，放入 arena chunk 中之后还会继续使用，参考：[MallocInternals](https://link.zhihu.com/?target=https%3A//sourceware.org/glibc/wiki/MallocInternals)

可以看出，Java 进程内存包括：

- Java Heap: 堆内存，即`-Xmx`限制的最大堆大小的内存。
- Class：加载的类与方法信息，其实就是 metaspace，包含两部分： 一是 metadata，被`-XX:MaxMetaspaceSize`限制最大大小，另外是 class space，被`-XX:CompressedClassSpaceSize`限制最大大小
- Thread：线程与线程栈占用内存，每个线程栈占用大小受`-Xss`限制，但是总大小没有限制。
- Code：JIT 即时编译后（C1 C2 编译器优化）的代码占用内存，受`-XX:ReservedCodeCacheSize`限制
- GC：垃圾回收占用内存，例如垃圾回收需要的 CardTable，标记数，区域划分记录，还有标记 GC Root 等等，都需要内存。这个不受限制，一般不会很大的。
- Compiler：C1 C2 编译器本身的代码和标记占用的内存，这个不受限制，一般不会很大的
- Internal：命令行解析，JVMTI 使用的内存，这个不受限制，一般不会很大的
- Symbol: 常量池占用的大小，字符串常量池受`-XX:StringTableSize`个数限制，总内存大小不受限制
- Native Memory Tracking：内存采集本身占用的内存大小，如果没有打开采集（那就看不到这个了，哈哈），就不会占用，这个不受限制，一般不会很大的
- Arena Chunk：所有通过 arena 方式分配的内存，这个不受限制，一般不会很大的
- Tracing：所有采集占用的内存，如果开启了 JFR 则主要是 JFR 占用的内存。这个不受限制，一般不会很大的
- Logging，Arguments，Module，Synchronizer，Safepoint，Other，这些一般我们不会关心。

除了 Native Memory Tracking 记录的内存使用，还有两种内存 **Native Memory Tracking 没有记录**，那就是：

- Direct Buffer：直接内存，请参考：[JDK核心JAVA源码解析（4） - Java 堆外内存、零拷贝、直接内存以及针对于NIO中的FileChannel的思考](https://zhuanlan.zhihu.com/p/161939673)
- MMap Buffer：文件映射内存，请参考：[JDK核心JAVA源码解析（5） - JAVA File MMAP原理解析](https://zhuanlan.zhihu.com/p/258934554)

# jvm 在docker中内存占用问题探索

## 问题背景

最近有个项目在PRD上部署，因为涉及到读取大量数据，会出现内存占用。为了避免因为该项目影响线上其他服务，所以设置了-m=2048，结果发现运行会超过这个值，docker 进程即将该container killed.

随后设置了好几个级别，直到-m=6048,依然无法避免container 被干掉。但是在本地测试和在同事机器上测试，不会出现内存飙升。同样的数据，同样的容器，唯一不同的就是机器物理配置的不同。

## 问题原因

线上机器是128g内存，目前制作的jre image 是1.8版本，未设置堆栈等jvm 配置，那么jvm 会字节分配一个默认堆栈大小，这个大小是根据物理机配置分配的。这样就会造成越高的配置，默认分配（**使用1/4的物理内存**）的堆内存就越大，而docker设置限制内存大小，jvm却无法感知，不知道自己在容器中运行。目前存在该问题的不止jvm,一些linux 命令也是如此，例如：top,free,ps等。

因此就会出现container 被docker killed情况。这是个惨痛教训。。。

## 问题复现

略…

有个不错的[文章](http://www.linux-ren.org/thread/89699.html)，可以查看一下。

## 解决方案

- **Dockerfile增加jvm参数**

在调用java 可以增加jvm 参数，控制堆栈大小。

```
CMD java  $JAVA_OPTIONS -jar java-container.jar
$ docker run -d --name mycontainer8g -p 8080:8080 -m 800M -e JAVA_OPTIONS='-Xmx300m' rafabene/java-container:openjdk-env
```

- **选用Fabric8 docker image**

镜像fabric8/java-jboss-openjdk8-jdk使用了脚本来计算容器的内存限制，并且使用50%的内存作为上限。也就是有50%的内存可以写入。你也可以使用这个镜像来开/关调试、诊断或者其他更多的事情

```
➜ docker stats --no-stream 46c96c561701
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT   MEM %     NET I/O       BLOCK I/O   PIDS
46c96c561701   mycontainer8g   0.13%     190.5MiB / 800MiB   23.81%    1.65kB / 0B   0B / 0B     37
```

于是Google之，发现大致的原因是从glibc2.11版本开始，linux为了解决多线程下内存分配竞争而引起的性能问题，增强了动态内存分配行为，使用了一种叫做arena的memory pool,在64位系统下面缺省配置是一个arena大小为64M，一个进程可以最多有cpu cores * 8个arena。假设机器是8核的，那么最多可以有8 * 8 = 64个arena，也就是会使用64 * 64 = 4096M内存。

然而我们可以通过设置系统环境变量来改变arena的数量：

 export MALLOC_ARENA_MAX=8（一般建议配置程序cpu核数）

配置环境变量使其生效，再重启该jvm进程，VIRT比之前少了快2个G:

之前：

![image-20211021111430141](C:\Users\hxf\AppData\Roaming\Typora\typora-user-images\image-20211021111430141.png)

之后：![image-20211021111353233](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211021111353233.png)

虚拟内存省了4g

