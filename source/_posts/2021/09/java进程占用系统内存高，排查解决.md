---
title: java进程占用系统内存高，排查解决
date: 2021-09-24 16:52:12
tags:
---

**故障：最近收到生产服务器的报警短信以及邮件，报警内容为：内存使用率高于70%。**

1.  使用top命令查看系统资源的使用情况，**命令：****top**
    
    <!--more-->
    
    ![image-20210924165501893](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924165501893.png)
    
    如图可以看到java的进程内存使用率较高，java进程的内存使用率达到了70%+
    

2.定位线程问题（通过命令查看9718进程的线程情况），**命令：****ps p 9718 -L -o pcpu,pmem,pid,tid,time,tname,cmd**

  ![image-20210924165542199](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924165542199.png)

 由此可以看到这PID：9718的进程产生了很多线程。接下来就可以通过jstack查看内存使用的堆栈。

3\. 查看内存使用的堆栈：在这里我们挑选了TID=9720的线程进行分析，首先需要将9731这个id转换为16进制。需输入如下命令，

 **printf "%x\\n" 9731**

![image-20210924165600662](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210924165600662.png)

 接下需要使用16进制的2603

4\. 将PID为9718的堆栈信息打印到jstack.log中，**命令：****jstack -l 9718 > jstack.log**



**5\. 查看堆栈信息文件，命令：vim jstack.log**

 **在进行搜索TID为2603的相关信息。如图：**



   可以看到这个线程状态为：WAITING。通过查看文件分析 看到大量 Java Thread State。

   说明它在等待另一个条件的发生，来把自己唤醒，或者干脆它是调用了 sleep(N)。

   此时线程状态大致为以下几种：

   java.lang.Thread.State: WAITING (parking)：一直等那个条件发生；

   java.lang.Thread.State: TIMED\_WAITING (parking或sleeping)：定时的，那个条件不到来，也将定时唤醒自己。

6.代码优化：将文件发送给开发。优化下线程
