---
title: JVM随笔分类（JVM堆的内存回收）
date: 2021-09-24 16:47:22
tags:
- jvm
categories: 
- jvm
---

1. 标记/清除算法

2. 标记/复制算法

3. 标记/整理算法

   <!--more-->

4. 其中上诉三种算法都先具备，标记阶段，通过标记阶段，得到当前存活的对象，然后再将非标记的对象进行清除，而对象内存中对象的标记过程，则是使用的 

5. “根搜索算法”，通过遍历整个堆中的GC ROOTS，将所有可到达的对象标记为存活的对象的一种方式，则是 “根搜索算法”，其中根是指的“GC ROOTS”，在JAVA中，充当GC ROOTS的对象分别有：“虚拟机栈中的引用对象”，“方法区中的类静态属性引用的对象”，“方法区中的常量引用对象”，“本地方法栈中JNI的引用对象”，凡是于上述对象存在可到达对象时，则该对象将标记为可存活对象，否则则为不可达对象，即可回收对象。在根搜索算法之前，还存在一个“引用计数算法”，即根据对象的被引用次数来进行计算，凡是对象的引用次数为0时，则表示为可回收对象，但对于互相引用的对象，如果不手动将互相引用的对象置空时，则该对象的引用次数永远将不会为0，则永久不会回收，则必然是错误，可参考：[https://www.cnblogs.com/zuoxiaolong/p/jvm3.html](https://app.yinxiang.com/OutboundRedirect.action?dest=https%3A%2F%2Fwww.cnblogs.com%2Fzuoxiaolong%2Fp%2Fjvm3.html)

6. 根据上述所提到的算法，可知：“根搜索算法”解决了标记那些对象是可回收，那些是不可回收对象的一个作用，但是对于具体在标记后的，回收行为，则是上述前三个算法的具体应用了，分别是“标记后清除”，以及“标记后复制”，及“标记后整理”，

7. “标记清除算法”的优势以及劣势：由于标记清除算法只需要两种动作行为，分别是：1.通过根搜索算法，标记可到达的存活对象，2.清除不可到达的对象内存；通过使用前面的两步，则将对应的不可达内存对象，进行了快速的清理，但是对于被回收后剩余的空闲内存的空间则是不连续的，因为被回收对象都是随机存在于内存的各个角落，在被回收后，内存的空间自然是存活的对象各自占据在各自原有的对象内存位置中，而并没有将剩余的存活对象进行相关的内存空间的整理，所以对于后续 分配数组对象时，寻找一个连续的内存空间则是一个较为麻烦的事情，。故："标记/清除"的优势则是，内存空间的整理快速，效率较高，但劣势则是：对应的清理后空间则是不连续的内存空间。

8. “标记/复制算法”：通过维护一份空闲内存的方式，来进行对象的回收，如：当前内存分为两份，分别为活动内存T1和非活动内存T2，在使用中时使用活动内存，当活动内存满的时候，进行 对象的标记，得到当前的存活对象，此时将对应的存活对象，复制到对应的非活动内存T2当中，且严格按照对象内存地址进行依次排列，与此同时，GC线程将更新存活对象的内存引用地址指向新的内存地址； 对象复制的同时T1内存中的对象全部进行清除，此时的T2则扮演着活动内存的角色，而T1则是非活动内存，通过上述可知，使用复制算法的方式避免了“标记/清除”算法对于空间连续性的弊端，但复制算法的劣势则是，一直保留着一份空闲的内存，作为对应的备用内存，这整整浪费了一半的内存，相对来时还是比较浪费的。

9. “标记/整理算法”：1. 标记：它的第一个阶段与标记/清除算法是一模一样的，均是遍历GC Roots，然后将存活的对象标记。2.  移动所有存活的对象，且按照内存地址次序依次排列，然后将末端内存地址以后的内存全部回收。因此，第二阶段才称为整理阶段。 可以看出标记整理算法，是通过标记所有的存活对象，然后再严格按照内存地址移动对应的存活对象后，再将末端的内存地址全部回收的方式，来进行的内存的空间整理，，所以，标记整理算法，并非是单单的：标记/清除/整理的方式，而是通过整理存活对象的连续性地址后，再进行末端地址回收的方式进行的内存的整理。；通过上述也可以看出 标记整理算法，弥补了标记清除对于不连续空间的内存整理的特性，也避免了复制算法对于一半空闲内存的浪费的特性。尽管标记整理拥有较好的特性，但没有特别完美的算法，所以，在劣势上：标记整理算法的整体执行效率是要低于标记复制算法的。

10. 此处想要说明一下：JVM对于内存的清理上来看：标记整理算法，分别是先通过扫描GC ROOT得到存活对象，然后 移动对应的存活对象的地址，使其进行以此排列，然后将 依次进行排列的内存地址，往后的所有的末端内存，直接进行回收 的方式来进行具体的操作的。所以，“标记整理算法”实际上的操作方式可以分为三步，分别是：1. 标记 2. 移动对象所在内存地址，3.  将末尾内存直接全部清除。而，“复制算法”则是：1. 标记存活对象，2. 移动存活对象所在地址，将其移动到空闲内存中即可。相同操作的情况下，可以看出：复制算法的效率是大于标记整理算法的。毕竟整理算法除了和复制算法都操作了具体的内存地址的移动以外，还比复制算法多出了一个末尾清除的步骤，所以：复制算法的效率>整理算法，，而“标记清除算法”，1. 标记所有存活对象，2. 清除所有“不连续的”空间内存。通过对比一些时间复杂度和执行效率上来看，JVM对于不连续的内存空间的清理的执行时间，似乎是要大于整理算法直接将末尾内存直接清除的执行时间的，所以简单的去看执行效率和时间复杂度上来看：标记复制算法>标记整理算法>标记清除算法(也可能是由于标记清除算法是比较老的算法的缘故，导致标记清除算法的执行效率对于其余的两种算法，但实际情况则不见得一定是这样，此处的效率只是简单的对比了时间复杂度来看，实际情况lz总还是觉得标记清除算法的执行时间和效率是大于整理算法的，毕竟单单从执行步骤来看，标记清除算法的执行是占据优势的，除非jvm对于非连续内存的清除方式真的是过于较低而导致，此处先做一下简单的记录罢了)

11. 最终的算法，分代收集算法，通过将jvm的内存区域进行划分所进行执行的一直算法方式：


1.  JVM中运行时内存区域分别有：堆，栈，本地栈，方法区，寄存器；其中栈和寄存器指针，是线程执行时的私有内存，线程结束后则栈内存同步释放， 所以JVM的内存回收，则共需关注的是堆以及方法区的内存回收，其中堆是各个对象创建时的内存区域，而方法区则包含类的calss以及常量，静态资源所对应的各个内存的存储区域。所以集中在堆中的不存活对象以及方法区的对象的回收，便是整体GC内存回收时的重点，；
    
2.  “分代收集算法”：JVM中将堆划分为不同的区域，分别是 新生代，老年代，以及永久代，根据对象的声明周期不同，所以针对不同生命周期的对象的回收方式也不同，以此来增加回收效率。
    
3.  在Java堆中：大多数对象是在新生代中被创建，当新生代中的对象在经历过多次Minor GC后，且仍然为存活对象的数据，则将会晋升到老年代，（其中包含了晋升阀值和JVM自动调节晋升阀值的一个概念），当简单了接了上述概念后，则已经基本了接了新生代以及老年代的作用，下面详细进行下相关的介绍：
    
1.  在Java中，新创建的对象数据则都是在新生代中进行创建，一般表现特征为生命周期较短，通过新生代的垃圾回收后只要少量的对象存活，所以新生代更加适合 执行效率较高的复制算法，针对复制算法的执行特征，所以要存在一份备用的内存区域来作为新生代在内存回收后的临时对象的存储场地，于是 新生代中便又划分为了对应的内存区域分别为：Eden区，以及 两个 Survivor区域，其中Eden区域的内存特征和新生代最初的内存特征不变，是用于存放对象在初始创建时的内存区域，当Eden区中的新生代对象占满了对应的Eden区域内存空间时，便会发生对应的Minor GC，即对应的内存回收，由于Eden 区域中的对象生命周期普遍较短，在经历第一次的Minor GC后，则将对应的存活对象，移动到对应的Survivor区域，其中两个Survivor区域中，选择任意一个，作为存活对象的新的存储空间，所以此处由此可知，Survivor作为Eden GC后的备用仓库，Survivor的大小设置只需要可以存储下Eden区的存活对象即可，一般推荐，Survivor区域的内存大小占整个年轻代的1/6即可，即：-XX:SuvrivorRatio=4，当然，所有的内存值的设置，都可以在后续根据项目的具体情况进行对应的GC的优化，当第一个from Survivor区域空间满时，则将会把对应的对象转移到对应的to Survivor中，然后清空对应的from Survivor区域，然后依次进行复制算法的循环，在对象不断的从From Suvrivor转移到to Survivor以及从to Survivor转移到from Suivivor的同时，Survivor的作用除了是Eden区的备用仓库外，还具备筛选“老对象”的作用，当Survivor中的对象在经历过多次的Minor GC时，还没有被清除时，则便可以晋升为“老年代”，老年代一般用于存储存活时间更长的对象数据，而如何识别对象具备晋升为“老年代”的数值，则可以通过MaxTenuringThrehold进行设置，默认阀值为15，即年轻代中的对象在经历过15次的Minor GC还存在于对象空间的数据，则可以晋升到年老代，，，，但：如果年轻代的对象数据不断增长，而Survivor区域的对象还迟迟不满足MaxTenuringThrehold所设置的晋升阀值，此时一旦Survivor内存溢出，则无论对象的年龄阀值是多大，则都会全部晋升到年老代中，这对于年老代来说是个噩梦，因为这将导致不断的Full GC，且会不断降低程序的执行性能，，，，所以为了不存在MaxTenuringThrehold设置过大，而导致的晋升失败的情况，JVM则引入了动态的年龄计算，当累计的某个年龄大小的对象，超过了Survivor的一半时，则取当前的对象年龄作为新的对象晋升阀值，可参考：[https://mp.weixin.qq.com/s/t1Cx1n6irN1RWG8HQyHU2w](https://app.yinxiang.com/OutboundRedirect.action?dest=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2Ft1Cx1n6irN1RWG8HQyHU2w)
    
2.  上面简单介绍了下相关的年轻代的回收的一些知识和问题后，后面陆续再分析下当前常用的GC的收集器分别有哪些：，以及各收集器的作用和各个参数的调节及注意事项等。
    
3.  ___
    
    首先；常用的收集器分别是：串行，并行，并发 收集器，其中串行一般用于Cliend模式，即当前代码开发过程调试过程时所设置的模式，串行收集器分别包含：Serial Garbage Collector 串行年轻代收集器（复制算法），和 Serial Old Garbage Collector 串行老年代收集器（标记/整理算法），
    
4.  而并行收集器：则包括：ParNew Garbage Collector ，Paraller Scavenge，这两个是专门为年轻代设计的并行收集器，皆为复制算法，其中Paraller Scavenge则是-Server模式下的默认年轻代收集器，除此之外，并行收集器还剩余：Paraller Old，此收集器是老年代的并行收集器为 标记/整理算法，也是-Server模式下的默认老年代收集器。
    
5.  唯一的一个并发收集器：是专门用于年老代回收时的并发收集器：concurrent mark sweep(简称CMS），真正做到了GC程序和应用程序并发执行，不会暂停应用的执行程序的一款收集器。（所使用的执行算法为：标记/清除算法）。
    
6.  \---------------------------- 注：所有的GC收集器在执行过程当中，都会暂停应用线程，只是一般年轻代使用并行收集器的GC，由于并行执行，则应用的停顿时间则相对较短，所以感受不到对应的应用暂停的特征，但其实的确是先暂停对应的应用线程在GC执行过后，再唤醒对应的应用线程继续执行，可以通过查看GC日志，来查看当前GC时的实际耗费时间，。，，，，而CMS则是唯一一个，在GC收集时和应用程序线程同步进行的一款收集器，只是只适用于年老代的并发收集，，所以合适的收集器的组合，才可以出现更优的效果；，并且，在HotSport 中，除了CMS之外，其他的老年代收集器，在执行的过程中，都会同时收集整个GC堆，包括新生代，（此处是需要注意的）。
    
13.  合适的收集器的选择：


1.  对于对响应时间有较高的要求的系统，可以选择ParNew 作为新生代并行收集器，& CMS 作为对应的老年代收集器， 由于ParNew是并行收集，因此新生代的GC速度会非常快，停顿时间很短。而年老代的GC采用并发搜集，大部分垃圾搜集的时间里，GC线程都是与应用程序并发执行的，因此造成的停顿时间依然很短。
    
2.  对于对系统吞吐量有要求的系统，可选择Paraller Scavenge作为 年轻代的并行收集器，使用Paraller Old 作为年老代的并行收集器，由于年轻代和年老代都是使用并行收集器，所以对系统停顿时间较短，且Paraller Scavenge收集器可以更加精准的控制GC的停顿时间和吞吐量的设置，所以对于在单位时间对系统可完成的指令数（吞吐量）有要求，但是对系统的响应时间没有过大要求的系统可以使用上述的两种结合处理器；（要想在单位时间内处理的请求更多，即系统的吞吐量更高，则设置相关的年轻代的大小，可以有效的增加系统的吞吐量和处理时间。）
    
15.  JVM的可参考配置：


1.  ParNew & CMS：
    
2.  Paraller Scavenge & Paraller Old：
    

首先按照JVM基本的配置比例，配置出基本的比例内存参数，

假设当前项目所部属服务器内存为8G，且总活跃对象数据为1G（1G的活跃对象数据已经很大了），

则当前总堆的对象数据设置为：(初始jvm默认内存设置与 总的JVM堆的可分配内存Xmx一致，可避免JVM GC后堆的重新分配)；

堆的大小设置：-Xms8192m，-Xmx8192m

新生代的设置比例为：-Xmn1536m，

老年代的设置比例为：\-XX:NewRatio用于设置年轻代与年老代所占比例值，当上述新生代采用Xmn进行设置时，此处NewRatio可以不用设置，则默认为 总堆内存-新生代内存 = 老年代内存；

永久代设置比例为：\-XX:PermSize=1536m，-XX:MaxPermSize=1536m

新生代中Eden与from to内存区的比例：\-XX:SurvivorRatio=4，表示当前Eden区和两个From区的比值为：4：2，则当前eden区占整个年轻代的4/6；（说明一下：JVM中的动态年龄计算，则是根据对应的From区的大小和对象的年龄进行阀值的计算的）

新生代对象晋升年龄阀值的设置：\-XX:MaxTenuringThreshold=15，默认情况下对象的晋升年龄阀值为15，上面已经提到过了JVM则会根据新生代中幸存区Survivor（及From 和to区域）的大小以及幸存区中对象的年龄动态计算晋升阀值的数值，那么？是不是此处设置XX:MaxTenuringThreshold则无效了吗？错！，JVM在设置晋升阀值是根据所计算出的年龄值和XX:MaxTenuringThreshold的年龄值进行对比，那个值越小，则使用当前更小的年龄值作为新的晋升阀值，所以如果设置XX:MaxTenuringThreshold的值为0，或者更小的值1,2，等，则将更快的增加新生代进入老年代的频率，（举个例子，对于年老代比较多的应用可以直接将对象晋升到年老代，且由于CMS的年老代回收是只回收年老代且并发收集过程中不影响应用线程的运行，所以直接晋升年老代，对于GC的回收的时间和效率似乎也是个不错的选择，不过目前没有遇到过这种类似的情况的应用），

以上，基本是一个默认在不配置GC收集器前对堆内存空间比例的基本设置，需要了接的是关于新生代中Eden和Suivivo的比例设置，在不进行配置的情况下JVM实际也是会给一个默认的自动参数配置的，并且以上关于JVM配置的比例参数皆是设置对JDK1.6的比例设置，所以对于永久代的设置并非是占用的整个堆的内存比例进行设置的，而是使用的操作系统的内存进行的相关永久代内存的设置，\------

\---- 设置对应的GC收集器的参数配置：

\---- ParNewGC  + CMS 收集器的配置 

 -XX:+UseParNewGC \-XX:ParallelGCThreads=4  

\-XX:+UseCMSCompactAtFullCollection      \-XX:CMSFullGCsBeforeCompaction=0        \-XX:CMSInitiatingOccupancyFraction=80                      \-XX:+CMSScavengeBeforeRemark 

设置当前CMS后执行碎片整理                             设置多少次FULL GC后进行碎片整理                    表示老年代内存达到使用率的80%时，则进行CMS GC           设置每次CMS GC的Remark前执行下Minor GC 

\-XX:+UseConcMarkSweepGC \-XX:ParallelCMSThreads=4                                         \-XX:MaxDirectMemorySize=256M       -XX:+CMSParallelRemarkEnabled

此处设置-XX:CMSInitiatingOccupancyFraction=80 的原因为：1. 每次CMS GC后，都设置了清理内存碎片，CMSFullGCsBeforeCompaction=0，所以不存在 晋升对象没有连续的内存空间存储而引起的CMS GC并发清理失败的问题(CMS清理失败将会使用serial old来进行STW全局的FULL GC)，2.每次CMS执行Remark阶段时已经提前执行了Minor GC，所以新生代空间满了以后的再次晋升一般不会特别快，第二，Remark阶段时的Minor GC，尽管可能会存在新生代的对象的晋升，但老年代剩余的20%比例，应该是足足可以存放下的，所以设置80%时触发CMS的GC一般是OK的，当然80%的该值,也可以通过每次Minor GC晋升对象的大小取其平均值得到对应的大小，然后留下相对较为充足的空间比例也是合适的，。

另外：Full GC 和CMS的GC是不同的，CMS 的GC是单纯的老年代GC，在GC日志中对应的标识为：CMS-inital-mak，CMS-concurrent-mark-start，等CMS的日志标识，

\-XX:+PrintTenuringDistribution 开启jvm对象晋升年龄的打印 Desired survivor size 107347968 bytes, new threshold 1 (max 30)

可参考推荐GC为：

\-Xmn512M -Xms1024M -Xmx1024M -XX:MaxPermSize=250M -Xss256k -Xconcurrentio -XX:SurvivorRatio=4 -XX:TargetSurvivorRatio=90 -XX:MaxTenuringThreshold=15 -XX:MaxDirectMemorySize=256M -XX:+UseParNewGC -XX:ParallelGCThreads=4 -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:CMSInitiatingOccupancyFraction=80 -XX:+CMSScavengeBeforeRemark -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.EPollSelectorProvider -[Dsun.net.inetaddr.ttl=60](http://dsun.net.inetaddr.ttl%3D60/) -Dorg.mortbay.jetty.Request.maxFormContentSize=-1 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/ftdq\_kbase/ibot\_core\_8013/logs  -XX:+PrintGCDetails  -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -Xloggc:/app/ftdq\_kbase/ibot\_core\_8013/logs/gc.log

\-Xmn512M -Xms1024M -Xmx1024M -XX:MaxPermSize=250M -Xss256k -Xconcurrentio -XX:SurvivorRatio=4 -XX:TargetSurvivorRatio=90 -XX:MaxTenuringThreshold=15 -XX:MaxDirectMemorySize=256M -XX:+UseParNewGC -XX:ParallelGCThreads=4 -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:CMSInitiatingOccupancyFraction=80 -XX:+CMSScavengeBeforeRemark -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.EPollSelectorProvider -[Dsun.net.inetaddr.ttl=60](http://dsun.net.inetaddr.ttl%3D60/) -Dorg.mortbay.jetty.Request.maxFormContentSize=-1 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/ftdq\_kbase/ibot\_core\_8013/logs  -XX:+PrintGCDetails -XX:+PrintTenuringDistribution -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -Xloggc:/app/ftdq\_kbase/ibot\_core\_8013/logs/gc.log  -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=22223

JAVA\_OPTIONS="-Xmn1000M -Xms3000M -Xmx3000M -XX:MaxPermSize=512M -Xss128k -Xconcurrentio -XX:SurvivorRatio=5 -XX:TargetSurvivorRatio=90 -XX:+UseCMSInitiatingOccupancyOnly -XX:+CMSParallelRemarkEnabled -XX:+CMSPermGenSweepingEnabled -XX:MaxTenuringThreshold=31 -XX:CMSInitiatingOccupancyFraction=90 -Xloggc:/opt/jetty\_kbase-search-7661/logs/gc.log -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+PrintGCDetails -XX:+PrintHeapAtGC -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+PrintTenuringDistribution -XX:+UseParNewGC -XX:+CMSParallelRemarkEnabled -XX:+UseConcMarkSweepGC -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.EPollSelectorProvider -[Dsun.net.inetaddr.ttl=60](http://dsun.net.inetaddr.ttl%3D60/) -Dorg.mortbay.jetty.Request.maxFormContentSize=-1 -Djava.rmi.server.hostname=172.16.9.55 -Dcom.sun.management.jmxremote.port=17661 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dsolr.solr.home=/opt/jetty\_kbase-search-7661/solr\_home/solr -Dsolr.library.home=/opt/jetty\_kbase-search-7661/solr\_home"

由于系统中使用\-XX:MaxDirectMemorySize=256M（上面提到的堆外内存的设置，用于文件读取拷贝时增加效率），但是堆外内存的设置后，发现每隔一小时会进行一次Full GC，但此时FUll GC时，老年代根本没有用满，且永久代也没有用满（方太上便是这种情况，也是一个小时触发一次Full GC），根据上述的参考链接可知：触发Full GC的目的主要是想要回收 堆外内存的回收，即Native所使用内存的回收，但Young GC时，不具备回收堆外内存的情况，所以会主动触发Full GC进行内存回收，此处使用 ExplicitGCInvokesConcurrentAndUnloadsClasses  参数，可以将回收堆外内存的任务交给 CMS进行处理，CMS 的回收好处相比于Fulll GC的好处，此处则不再做累赘，通过使用CMS回收堆外内存的情况，则可以避免频繁的Full GC，（FUll GC 期间对系统是有影响的，且是STW的，所以对于使用CMS和Full GC进行回收堆外内存，此处也应该根据实际需调整，因为CMS 在并发预清理阶段也是STW的，不过合理的配置CMS，则回收时间应该也是最佳的），另外，提一下上述的一个问题，上述的 \-XX:+CMSParallelRemarkEnabled 表示在CMS，Remark之前，进行一个可中断的并发预清理，（此处其实可以不开启，因为此处已经使用CMSScavengeBeforeRemark ，表示每次CMS前进行一次年轻代的回收，那么 此时则没有必要等待5秒或怎样的一个中断的预清理了，此处做已备注，可考虑测试去除等操作）

1.  并发收集的参数默认 -XX:UseAdaptiveSizePolicy的开启，将会全权管理内存分配，此时所设置的新生代的eden和survivor的比例配置将会失效，等，。
    
2.  CMS的设置，可以设置FUll GC前先进行下相关的Minor GC的回收，以及可以设置是否开启对永久代的回收，（因为如果应用中存在较多的动态类，或使用String.inten()等将数据都放置到了对应的常量池中，则对永久代Perm的回收则也是有必要的， ）除此之外，可以参考美团，或者jvm参数设置中对CMS的一些配置的说明，也是较为清晰和详细的。
    
3.  对象每经历一次Minor GC，年龄加1，达到“晋升年龄阈值”后，被放到老年代，这个过程也称为“晋升”。显然，“晋升年龄阈值”的大小直接影响着对象在新生代中的停留时间，在Serial和ParNew GC两种回收器中，“晋升年龄阈值”通过参数MaxTenuringThreshold设定，默认值为15。
