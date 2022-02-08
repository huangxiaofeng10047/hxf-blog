---
title: 'JAVA服务内存占用太高,并不减少'
date: 2021-09-23 14:06:08
tags:
- jvm
categories: 
- jvm
---

某天，运维老哥突然找我：“你们的某 JAVA 服务内存占用太高，告警了！G后也没释放，内存只增不减，是不是内存泄漏了！”

然后我赶紧看了下监控，一切正常，距离上次发版好几天了，FULL GC 一次没有，YoungGC，十分钟一次，堆空闲也很充足。

运维：“你们这个服务现在堆内存 used 才 800M，但这个 JAVA 进程已经占了 6G 内存了，是不是你们程序出啥内存泄露的 bug 了！”

我想都没想，直接回了一句：“不可能，我们服务非常稳定，不会有这种问题！”

不过说完之后，内心还是自我质疑了一下：会不会真有什么bug？难道是堆外泄露？线程没销毁？导致内存泄露了？？？

然后我很“镇定”的补了一句：“我先上服务器看看啥情况”，被打脸可就不好了，还是不要装太满的好……

迅速上登上服务器又仔细的查看了各种指标，Heap/GC/Thread/Process 之类的，发现一切正常，并没有什么“泄漏”的迹象。

<!--more-->

**和运维的“沟通”**

我们这个服务很正常啊，各个指标都ok，什么内存只增不减，在哪呢

运维：你看你们这个 JAVA 服务，堆现在 used 才 400MB，但这个进程现在内存占用都 6G 了，还说没问题？肯定是内存泄露了，锅接好，赶紧回去查问题吧

然后我指着监控信息，让运维看：“大哥你看这监控历史，堆内存是达到过 6G 的，只是后面 GC 了，没问题啊！”

运维：“回收了你这内存也没释放啊，你看这个进程 Res 还是 6G，肯定有问题啊”

我心想这运维怕不是个der，JVM GC 回收和进程内存又不是一回事，不过还是和得他解释一下，不然一直baba个没完

“JVM 的垃圾回收，只是一个的回收，回收的只是 JVM 申请的那一块逻辑堆区域，将数据标记为空闲之类的操作，不是调用 free 将内存归还给操作系统”

运维顿了两秒后，突然脸色一转，开始笑起来：“咳咳，我可能没注意这个。你再给我讲讲 JVM 的这个内存管理/回收和进程上内存的关系呗”

虽然我内心是拒绝的，但得罪谁也不能得罪运维啊，想想还是给大哥解释解释，“增进下感情”

**操作系统 与 JVM的内存分配**

JVM 的自动内存管理，其实只是先向操作系统申请了一大块内存，然后自己在这块已申请的内存区域中进行“自动内存管理”。JAVA 中的对象在创建前，会先从这块申请的一大块内存中划分出一部分来给这个对象使用，在 GC 时也只是这个对象所处的内存区域数据清空，标记为空闲而已

运维：“原来是这样，那按你的意思，JVM 就不会将 GC 回收后的空闲内存还给操作系统了吗？”

**为什么不把内存归还给操作系统？**

JVM 还是会归还内存给操作系统的，只是因为这个代价比较大，所以不会轻易进行。而且不同垃圾回收器 的内存分配算法不同，归还内存的代价也不同。

比如在清除算法（sweep）中，是通过空闲链表（free-list）算法来分配内存的。简单的说就是将已申请的大块内存区域分为 N 个小区域，将这些区域同链表的结构组织起来，就像这样：

每个 data 区域可以容纳 N 个对象，那么当一次 GC 后，某些对象会被回收，可是此时这个 data 区域中还有其他存活的对象，如果想将整个 data 区域释放那是肯定不行的。

所以这个归还内存给操作系统的操作并没有那么简单，执行起来代价过高，JVM 自然不会在每次 GC 后都进行内存的归还。

**怎么归还？**

虽然代价高，但 JVM 还是提供了这个归还内存的功能。JVM 提供了和 两个参数，用于配置这个归还策略。

MinHeapFreeRatio 代表当空闲区域大小下降到该值时，会进行扩容，扩容的上限为

MaxHeapFreeRatio 代表当空闲区域超过该值时，会进行“缩容”，缩容的下限为

不过虽然有这个归还的功能，不过因为这个代价比较昂贵，所以 JVM 在归还的时候，是线性递增归还的，并不是一次全部归还。

但是但是但是，经过实测，这个归还内存的机制，在不同的垃圾回收器，甚至不同的 JDK 版本中还不一样！

**不同版本&垃圾回收器下的表现不同**

下面是我之前跑过的测试结果：

![img](https://gitee.com/hxf88/imgrepo/raw/master/img/1000)

测试结果刷新了我的认知。，MaxHeapFreeRatio 这个参数好像并没有什么用，无论我是配置40，还是配置90，回收的比例都有和实际的结果都有很大差距。但是文档中，可不是这么说的……

而且 ZGC 的结果也是挺意外的，JEP 351 提到了 ZGC 会将未使用的内存释放，但测试结果里并没有。

除了以上测试结果，stackoverflow 上还有一些其他的说法，我就没有再一一测试了

JAVA 9 后参数，可以让 JVM 已非线性递增的方式归还内存

JAVA 12 后的 G1，再应用空闲时，可以自动的归还内存

所以，官方文档的说法，也只能当作一个参考，JVM 并没有过多的透露这个实现细节。

不过这个是否归还的机制，除了这位“热情”的运维老哥，一般人也不太会去关心，巴不得 JVM 多用点内存，少 GC 几回……

而且别说空闲自动归还了，我们希望的是一启动就分配个最大内存，避免它运行中扩容影响服务；所以一般 JAVA 程序还会将 和配置为相等的大小，避免这个扩容的操作。

听到这里，运维老哥若有所思的说到：“那是不是只要我把 Xms 和 Xmx 配置成一样的大小，这个 JAVA 进程一启动就会占用这个大小的内存呢？”

我接着答到：“不会的，哪怕你 Xms6G，启动也只会占用实际写入的内存，大概率达不到 6G，这里还涉及一个操作系统内存分配的小知识”

**Xms6G，为什么启动之后 used 才 200M？**

进程在申请内存时，并不是直接分配物理内存的，而是分配一块虚拟空间，到真正堆这块虚拟空间写入数据时才会通过缺页异常（Page Fault）处理机制分配物理内存，也就是我们看到的进程 Res 指标。

可以简单的认为操作系统的内存分配是“惰性”的，分配并不会发生实际的占用，有数据写入时才会发生内存占用，影响 Res。

所以，哪怕配置了，启动后也不会直接占用 6G 内存，只是 JVM 在启动后会 6G 而已，但实际占用的内存取决于你有没有往这 6G 内存区域中写数据的。

运维：“卧槽，还有惰性分配这种东西！长知识了”

我：“这下明白了吧，这个内存情况是正常的，我们的服务一点问题都没有”

运维：“牛，是我理解错了，你们这个服务没啥问题”

我：“嗯呐，没事那我先去忙（摸鱼）了”

**总结**

对于大多数服务端场景来说，并不需要JVM 这个手动释放内存的操作。至于 JVM 是否归还内存给操作系统这个问题，我们也并不关心。而且基于上面那个测试结果，不同 JAVA 版本，不同垃圾回收器版本区别这么大，更是没必要去深究了。

综上，JVM 虽然可以释放空闲内存给操作系统，但是不一定会释放，在不同 JAVA 版本，不同垃圾回收器版本下表现不同，知道有这个机制就行。

需要注意的地方：

***Xms和Xmx必须不一样，jvm才会归还内存。***

公司有一个系统使用的是CMS垃圾回收器，JVM初始堆内存不等于最大堆内存，但通过监控信息发现：在经过一次FullGC之后，服务器物理内存剩余空间并未提升，按照我之前的理解FullGC之后JVM进程会释放的内存一部分还给物理内存，下面通过几个实验来对比验证一下CMS和G1的物理内存归还机制

测试代码

```
public class MemoryRecycleTest {

    static volatile List<OOMobject> list = new ArrayList<>();

    public static void main(String[] args) {
        //指定要生产的对象大小为512M
        int count = 512;

        //新建一条线程,负责生产对象
        new Thread(() -> {
            try {
                for (int i = 1; i <= 10; i++) {
                    System.out.println(String.format("第%s次生产%s大小的对象", i, count));
                    addObject(list, count);
                    //休眠40秒
                    Thread.sleep(i * 10000);
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }).start();

        //新建一条线程,负责清理List,回收JVM内存
        new Thread(() -> {
            for (; ; ) {
                //当List内存到达512M,就通知GC回收堆
                if (list.size() >= count) {
                    System.out.println("清理list.... 回收jvm内存....");
                    list.clear();
                    //通知GC回收
                    System.gc();
                    //打印堆内存信息
                    printJvmMemoryInfo();
                }
            }
        }).start();

        //阻止程序退出
        try {
            Thread.currentThread().join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public static void addObject(List<OOMobject> list, int count) {
        for (int i = 0; i < count; i++) {
            OOMobject ooMobject = new OOMobject();
            //向List添加一个1M的对象
            list.add(ooMobject);
            try {
                //休眠100毫秒
                Thread.sleep(100);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static class OOMobject {
        //生成1M的对象
        private byte[] bytes = new byte[1024 * 1024];
    }

    public static void printJvmMemoryInfo() {
        //虚拟机级内存情况查询
        long vmFree = 0;
        long vmUse = 0;
        long vmTotal = 0;
        long vmMax = 0;
        int byteToMb = 1024 * 1024;
        Runtime rt = Runtime.getRuntime();
        vmTotal = rt.totalMemory() / byteToMb;
        vmFree = rt.freeMemory() / byteToMb;
        vmMax = rt.maxMemory() / byteToMb;
        vmUse = vmTotal - vmFree;
        System.out.println("");
        System.out.println("JVM内存已用的空间为：" + vmUse + " MB");
        System.out.println("JVM内存的空闲空间为：" + vmFree + " MB");
        System.out.println("JVM总内存空间为：" + vmTotal + " MB");
        System.out.println("JVM总内存最大堆空间为：" + vmMax + " MB");
        System.out.println("");
    }
}

```

### JDK8 CMS

**JVM参数**：

```
-Xms128M -Xmx2048M -XX:+UseConcMarkSweepGC
```

**控制台打印的内容**：

```
第1次生产512大小的对象
清理list.... 回收jvm内存....

JVM内存已用的空间为：6 MB
JVM内存的空闲空间为：1202 MB
JVM总内存空间为：1208 MB
JVM总内存最大堆空间为：1979 MB

第2次生产512大小的对象
清理list.... 回收jvm内存....

JVM内存已用的空间为：3 MB
JVM内存的空闲空间为：1097 MB
JVM总内存空间为：1100 MB
JVM总内存最大堆空间为：1979 MB

第3次生产512大小的对象
清理list.... 回收jvm内存....

JVM内存已用的空间为：3 MB
JVM内存的空闲空间为：706 MB
JVM总内存空间为：709 MB
JVM总内存最大堆空间为：1979 MB

第4次生产512大小的对象
清理list.... 回收jvm内存....

JVM内存已用的空间为：3 MB
JVM内存的空闲空间为：120 MB
JVM总内存空间为：123 MB
JVM总内存最大堆空间为：1979 MB
```

**VisualVM监控的堆内存情况**：

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20201205095434213.png)

从图中堆内存的情况可以看出，在JDK8+CMS的配置下，JVM并不是立马归还内存给到操作系统，而是随着FullGC次数的增多逐渐归还，最终会全部归还

### JDK8 G1

**JVM参数**：

```
-Xms128M -Xmx2048M -XX:+UseG1GC
```

**VisualVM监控的堆内存情况**：

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20201205095458362.png)

在JDK8+G1的配置下，JVM都是在每一次FullGC后全部归还物理内存

### JDK11 CMS

**JVM参数**：

```
-Xms128M -Xmx2048M -XX:+UseConcMarkSweepGC
```

**VisualVM监控的堆内存情况**：

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20201205095523473.png)

在JDK11+CMS的配置下和JDK8+CMS的情况相同（JVM并不是立马归还内存给到操作系统，而是随着FullGC次数的增多逐渐归还，最终会全部归还）

JDK11提供了一个JVM参数`ShrinkHeapInSteps` 。通过这个参数，可以在GC之后渐进式的归还内存给到操作系统。JDK11下，此参数默认开启。可以把此参数关闭，看下堆内存的变化情况：

```
-Xms128M -Xmx2048M -XX:+UseConcMarkSweepGC -XX:-ShrinkHeapInSteps
```

**VisualVM监控的堆内存情况**：

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20201205095538239.png)

在JDK11+CMS的配置下，关闭`ShrinkHeapInSteps`参数后，JVM都是在每一次FullGC后全部归还物理内存

### JDK11 G1

由于JDK11默认使用的是G1垃圾回收器，所以这里只设置了初始堆内存和最大堆内存

**JVM参数**：

```
-Xms128M -Xmx2048M
```

**VisualVM监控的堆内存情况**：

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20201205095557786.png)

1）JDK11默认的`ShrinkHeapInSteps`是默认开启的，但这里看堆内存变化并不是渐进的缩小的。 所以在G1回收器下，`ShrinkHeapInSteps`是无效的。 如果我们手动关闭`ShrinkHeapInSteps`参数，发现堆内存变化和上面这个类似

2）JDK11下的G1和JDK8下的G1对内存的响应是不一样的。 从堆内存变化来看， **JDK11下G1更加倾向于尽可能的利用内存，不着急回收**。 而JDK8下G1则是倾向于尽可能的先回收内存。 从图中看，JDK8下G1的实际使用的堆内存大小基本是JDK11下G1的一半

### 小结

如果代码保持不变，但是JVM参数中设置Xms和Xmx相同的话，不管是否有FullGC，堆内存大小都不发生变化，也就不释放内存给操作系统

GC后如何归还内存给操作系统：

-   能不能归还，主要依赖于Xms和Xmx是否相等
-   何时归还，主要依赖于JDK版本和垃圾回收器类型

只有FullGC的时候才能真正触发堆内存收缩归还OS。YGC是不能使JVM主动归还内存给操作系统的

尽量保持Xms和Xmx一致，这样可以减少堆内存调整带来的性能损耗，也可以减少堆内存调整带来的无内存风险

参考：

https://segmentfault.com/a/1190000019856974

https://www.cnblogs.com/androidsuperman/p/11743103.html

http://blog.dutycode.com/archives/jvmjvm%E7%9A%84xms%E5%8F%82%E6%95%B0%E5%92%8Clinuxtop%E5%91%BD%E4%BB%A4%E7%9A%84res%E5%85%B3%E7%B3%BB

___

### ps aux命令执行结果的几个列的信息的含义

```
USER    进程所属用户
PID     进程ID 
%CPU    进程占用CPU百分比
%MEM    进程占用内存百分比
VSZ     虚拟内存占用大小 单位：kb（killobytes）
RSS     实际内存占用大小 单位：kb（killobytes）
TTY     终端类型
STAT    进程状态
START   进程启动时刻
TIME    进程运行时长,进程已经消耗的CPU时间
COMMAND 启动进程的命令的名称和参数
```

### top 命令 VSZ,RSS,TTY,STAT, VIRT,RES,SHR,DATA的含义

```
VIRT：virtual memory usage 虚拟内存
1、进程“需要的”虚拟内存大小，包括进程使用的库、代码、数据等
2、假如进程申请100m的内存，但实际只使用了10m，那么它会增长100m，而不是实际的使用量

RES：resident memory usage 常驻内存
1、进程当前使用的内存大小，但不包括swap out
2、包含其他进程的共享
3、如果申请100m的内存，实际使用10m，它只增长10m，与VIRT相反
4、关于库占用内存的情况，它只统计加载的库文件所占内存大小

SHR：shared memory 共享内存
1、除了自身进程的共享内存，也包括其他进程的共享内存
2、虽然进程只使用了几个共享库的函数，但它包含了整个共享库的大小
3、计算某个进程所占的物理内存大小公式：RES – SHR
4、swap out后，它将会降下来

DATA
1、数据占用的内存。如果top没有显示，按f键可以显示出来。
2、真正的该程序要求的数据空间，是真正在运行中要使用的。

top 运行中可以通过 top 的内部命令对进程的显示方式进行控制。内部命令如下：
s – 改变画面更新频率
l – 关闭或开启第一部分第一行 top 信息的表示
t – 关闭或开启第一部分第二行 Tasks 和第三行 Cpus 信息的表示
m – 关闭或开启第一部分第四行 Mem 和 第五行 Swap 信息的表示
N – 以 PID 的大小的顺序排列表示进程列表
P – 以 CPU 占用率大小的顺序排列进程列表
M – 以内存占用率大小的顺序排列进程列表
h – 显示帮助
n – 设置在进程列表所显示进程的数量
q – 退出 top
s – 改变画面更新周期

序号 列名 含义
a PID 进程id
b PPID 父进程id
c RUSER Real user name
d UID 进程所有者的用户id
e USER 进程所有者的用户名
f GROUP 进程所有者的组名
g TTY 启动进程的终端名。不是从终端启动的进程则显示为 ?
h PR 优先级
i NI nice值。负值表示高优先级，正值表示低优先级
j P 最后使用的CPU，仅在多CPU环境下有意义
k %CPU 上次更新到现在的CPU时间占用百分比
l TIME 进程使用的CPU时间总计，单位秒
m TIME+ 进程使用的CPU时间总计，单位1/100秒
n %MEM 进程使用的物理内存百分比
o VIRT 进程使用的虚拟内存总量，单位kb。VIRT=SWAP+RES
p SWAP 进程使用的虚拟内存中，被换出的大小，单位kb。
q RES 进程使用的、未被换出的物理内存大小，单位kb。RES=CODE+DATA
r CODE 可执行代码占用的物理内存大小，单位kb
s DATA 可执行代码以外的部分(数据段+栈)占用的物理内存大小，单位kb
t SHR 共享内存大小，单位kb
u nFLT 页面错误次数
v nDRT 最后一次写入到现在，被修改过的页面数。
w S 进程状态。（D=不可中断的睡眠状态，R=运行，S=睡眠，T=跟踪/停止，Z=僵尸进程）
x COMMAND 命令名/命令行
y WCHAN 若该进程在睡眠，则显示睡眠中的系统函数名
z Flags 任务标志，参考 sched.h

默认情况下仅显示比较重要的 PID、USER、PR、NI、VIRT、RES、SHR、S、%CPU、%MEM、TIME+、COMMAND 列。可以通过下面的快捷键来更改显示内容。

通过 f 键可以选择显示的内容。按 f 键之后会显示列的列表，按 a-z 即可显示或隐藏对应的列，最后按回车键确定。
按 o 键可以改变列的显示顺序。按小写的 a-z 可以将相应的列向右移动，而大写的 A-Z 可以将相应的列向左移动。最后按回车键确定。
按大写的 F 或 O 键，然后按 a-z 可以将进程按照相应的列进行排序。而大写的 R 键可以将当前的排序倒转。
```

### jmap命令

```
jmap -heap 进程ID

Attaching to process ID 17775, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.121-b13

using thread-local object allocation.
Parallel GC with 2 thread(s)           parallel并发垃圾回收器

Heap Configuration:
   MinHeapFreeRatio         = 0
   MaxHeapFreeRatio         = 100
   MaxHeapSize              = 1006632960 (960.0MB)  当前JVM最大堆大小
   NewSize                  = 20971520 (20.0MB)
   MaxNewSize               = 335544320 (320.0MB)
   OldSize                  = 41943040 (40.0MB)
   NewRatio                 = 2
   SurvivorRatio            = 8
   MetaspaceSize            = 21807104 (20.796875MB)  当前元空间大小
   CompressedClassSpaceSize = 1073741824 (1024.0MB)   
   MaxMetaspaceSize         = 17592186044415 MB       元空间最大大小
   G1HeapRegionSize         = 0 (0.0MB)

Heap Usage:
PS Young Generation
Eden Space:
   capacity = 25165824 (24.0MB)
   used     = 15424152 (14.709617614746094MB)
   free     = 9741672 (9.290382385253906MB)
   61.29007339477539% used
From Space:
   capacity = 1572864 (1.5MB)
   used     = 1013016 (0.9660873413085938MB)
   free     = 559848 (0.5339126586914062MB)
   64.40582275390625% used
To Space:
   capacity = 1572864 (1.5MB)
   used     = 0 (0.0MB)
   free     = 1572864 (1.5MB)
   0.0% used
PS Old Generation
   capacity = 84934656 (81.0MB)
   used     = 62824456 (59.91407012939453MB)
   free     = 22110200 (21.08592987060547MB)
   73.96798781406733% used
```

### ps命令

```
ps -p 进程ID -o vsz,rss

   VSZ   RSS
3701784 413924

VSZ是指已分配的线性空间大小，这个大小通常并不等于程序实际用到的内存大小，产生这个的可能性很多，比如内存映射，共享的动态库，或者向系统申请了更多的堆，都会扩展线性空间大小。

RSZ是Resident Set Size，常驻内存大小，即进程实际占用的物理内存大小
```

### pmap命令

```
pmap -x 进程ID
Address           Kbytes     RSS   Dirty Mode   Mapping
0000000000400000       4       4       0 r-x--  java
0000000000600000       4       4       4 rw---  java
00000000017f8000    2256    2136    2136 rw---    [ anon ]
00000000c4000000   82944   63488   63488 rw---    [ anon ]
00000000c9100000  572416       0       0 -----    [ anon ]
00000000ec000000   27648   27136   27136 rw---    [ anon ]
00000000edb00000  300032       0       0 -----    [ anon ]
......
total kB         3701784  413924  400716

Address: 内存分配地址
Kbytes:  实际分配的内存大小
RSS:     程序实际占用的内存大小
Mapping: 分配该内存的模块的名称

anon，这些表示这块内存是由mmap分配的
```

### JAVA应用内存分析

> JAVA进程内存 = JVM进程内存+heap内存+ 永久代内存+ 本地方法栈内存+线程栈内存 +堆外内存 +socket 缓冲区内存+元空间
>
> linux内存和JAVA堆中的关系
>
> RES = JAVA正在存活的内存对象大小 + 未回收的对象大小 + 其它
>
> VIART= JAVA中申请的内存大小，即 -Xmx -Xms + 其它
>
> 其它 = 永久代内存+ 本地方法栈内存+线程栈内存 +堆外内存 +socket 缓冲区内存 +JVM进程内存

![](https://gitee.com/hxf88/imgrepo/raw/master/img/4639175-602049f4a711b8f6.png)

xxx.png

### JVM内存模型（1.7与1.8之间的区别）

![](https://upload-images.jianshu.io/upload_images/4639175-e2c83712ad7e9349.png?imageMogr2/auto-orient/strip|imageView2/2/w/1156/format/webp)

xxx.png

```
算一下求和可以得知前者总共给Java环境分配了128M的内存，而ps输出的VSZ和RSS分别是3615M和404M。
RSZ和实际堆内存占用差了276M，内存组成分别为:

JVM本身需要的内存，包括其加载的第三方库以及这些库分配的内存

NIO的DirectBuffer是分配的native memory

内存映射文件，包括JVM加载的一些JAR和第三方库，以及程序内部用到的。上面 pmap 输出的内容里，有一些静态文件所占用的大小不在Java的heap里

JIT， JVM会将Class编译成native代码，这些内存也不会少，如果使用了Spring的AOP，CGLIB会生成更多的类，JIT的内存开销也会随之变大

JNI，一些JNI接口调用的native库也会分配一些内存，如果遇到JNI库的内存泄露，可以使用valgrind等内存泄露工具来检测

线程栈，每个线程都会有自己的栈空间，如果线程一多，这个的开销就很明显
当前jvm线程数统计：jstack 进程ID |grep ‘tid’|wc –l  (linux 64位系统中jvm线程默认栈大小为1MB)
ps huH p 进程ID|wc -l   ps -Lf 进程ID | wc -l
top -H -p 进程ID
cat /proc/{pid}/status

jmap/jstack 采样，频繁的采样也会增加内存占用，如果你有服务器健康监控，这个频率要控制一下
```

### jstat命令

```
JVM的几个GC堆和GC的情况，可以用jstat来监控，例如监控某个进程每隔1000毫秒刷新一次，输出20次

jstat -gcutil 进程ID 1000 20

  S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT   
  0.00  39.58  95.63  74.66  98.35  96.93    815    4.002     3    0.331    4.333
  0.00  39.58  95.76  74.66  98.35  96.93    815    4.002     3    0.331    4.333
 41.67   0.00   1.62  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 41.67   0.00   1.67  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 41.67   0.00   3.12  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 41.67   0.00   3.12  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 41.67   0.00   8.39  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 41.67   0.00   9.85  74.67  98.35  96.93    816    4.006     3    0.331    4.337
 
S0    年轻代中第一个survivor(幸存区)已使用的占当前容量百分比
S1    年轻代中第二个survivor(幸存区)已使用的占当前容量百分比
E     年轻代中Eden(伊甸园)已使用的占当前容量百分比
O     old代已使用的占当前容量百分比
P     perm代已使用的占当前容量百分比
YGC   从应用程序启动到采样时年轻代中gc次数
YGCT  从应用程序启动到采样时年轻代中gc所用时间(s)
FGC   从应用程序启动到采样时old代(全gc)gc次数
FGCT  从应用程序启动到采样时old代(全gc)gc所用时间(s)
GCT   从应用程序启动到采样时gc用的总时间(s)
```

### 总结

> 正常情况下jmap输出的内存占用远小于 RSZ，可以不用太担心，除非发生一些严重错误，比如PermGen空间满了导致OutOfMemoryError发生，或者RSZ太高导致引起系统公愤被OOM Killer给干掉，就得注意了，该加内存加内存，没钱买内存加交换空间，或者按上面列的组成部分逐一排除。
>
> 这几个内存指标之间的关系是：VSZ >> RSZ >> Java程序实际使用的堆大小
