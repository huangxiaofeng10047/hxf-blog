---
title: Linux 性能监控工具命令大全
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-16 16:59:25
tags:
---

1.top

top命令是一个优秀的交互式实用工具，用于监视性能。它提供关于整体Linux性能的几个概要行，但是报告进程信息才是top真正的长处。可以广泛自定义进程显示，也可以添加字段，按照不同指标排序进程列表，甚至从top注销进程。

top $(ps -e | grep GeoAddrSrv | awk '{print $1}' | sed 's/^/-p/')
top -p $(pgrep -f -d, GeoAddrSrv)
top -p 32272,32275,32278,32281,32285,32288,32292,32296,32300,32304,32307,32312,32316,32319,32323,32327,32331,32454
top -p 32336,32340,32343,32348,32352,32355,32359,32362,32366,32370,32373,32376,32380,32383,32386,32390,32393,32396
1
2
3
4
2.sar - sar 1

sar实用工具提供监视每一事件的能力。它至少有15个单独的报告类别，包括CPU、磁盘、网络、进程、交换区等等。

3.vmstat - vmstat 1

vmstat命令报告关于内存和交换区使用的广泛信息。它也报告CPU和一些I/O信息
r b swpd free buff cache si so bi bo in cs us sy id wa
r表示运行队列的大小；
b表示由于IO等待而block的线程数量；
in表示中断的数量；
cs表示上下文切换的数量；
us表示用户CPU时间；
sys表示系统CPU时间；
wa表示由于IO等待而是CPU处于idle状态的时间；
id表示CPU处于idle状态的总时间；
swpd表示已使用的swap空间大小，kb为单位；
free表示可用的物理内存大小，kb为单位；
buff表示物理内存用来缓存读写操作的buffer大小，kb为单位；
cache表示物理内存用来缓存进程地址空间的cache大小，kb为单位；
si表示数据从 SWAP 读取到 RAM（swap in）的大小，KB 为单位；
so表示数据从 RAM 写到 SWAP（swap out）的大小，KB 为单位；
bi表示磁盘块从文件系统或 SWAP 读取到 RAM（blocks in）的大小，block 为单位；
bo表示磁盘块从 RAM 写到文件系统或 SWAP（blocks out）的大小，block 为单位；

说明：
in非常高，cs比较低，说明这个CPU一直在不停的请求资源；
us一直保持在 80％ 以上，而且上下文切换较低cs，说明某个进程可能一直霸占着CPU；
cs比in要高得多，说明内核不得不来回切换进进程；
sy很高，us很低，且cs很高，说明正在运行的应用程序调用了大量的system call；
物理可用内存 free 基本没什么显著变化，swapd 逐步增加，说明最小可用的内存始终保持在 256MB(物理内存大小) * 10％ = 2.56MB 左右，当脏页达到10％的时候（vm.dirty_background_ratio ＝ 10）就开始大量使用 swap；
buff 稳步减少说明系统知道内存不够了，kwapd 正在从 buff 那里借用部分内存；
kswapd 持续把脏页面写到 swap 交换区（so），并且从 swapd 逐渐增加看出确实如此。根据上面讲的 kswapd 扫描时检查的三件事，如果页面被修改了，但不是被文件系统修改的，把页面写到 swap，所以这里 swapd 持续增加。

4.iostat

iostat报告存储输入/输出（I/O）统计资料

iops = wkB/s 除以 w/s

5.free

free命令报告内存信息

6.mpstat

mpstat查看多线程处理情况

7.iptraf - iptraf -d eth0

iptraf实时网络状况监测

8.tcpdump

tcpdump抓取网络数据包，详细分析

9.tcptrace

tcptrace数据包分析工具，源码安装

10.netperf

netperf网络带宽工具

11.dstat

dstat综合工具，综合了 vmstat, iostat, ifstat, netstat 等多个信息

12.NetHogs-监视每个进程使用的网络带宽

NetHogs是一个开放源源代码的很小程序（与Linux下的top命令很相似），它密切监视着系统上每个进程的网络活动。同时还追踪着每个程序或者应用所使用的实时网络带宽。
安装 rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/nethogs-0.8.0-1.el6.i686.rpm

13.iftop-监视网络带宽

iftop是另一个在控制台运行的开放源代码系统监控应用，它显示了系统上通过网络接口的应用网络带宽使用（源主机或者目的主机）的列表，这个列表 定期更新。iftop用于监视网络的使用情况，而’top’用于监视CPU的使用情况。iftop是’top’工具系列中的一员，它用于监视所选接口，并 显示两个主机间当前网络带宽的使用情况。

14 Monitorix-系统和网络监控

Monitorix 是一个免费的轻量级应用工具，它的设计初衷是运行和监控Linux/Unix服务器系统和资源等。它有一个HTTP 网络服务器，这个服务器有规律的收集系统和网络的信息并以图形化的形式展示出来。它监控系统的平均负载和使用，内存分配、磁盘健康状况、系统服务、网络端 口、邮件统计（Sendmail，Postfix,Dovecot等），MySQL统计，等等。它就是用来监控系统的总体性能，帮助发现失误、瓶颈和异常 活动的

yum install monitorix 

或者先安装依赖包：
yum install rrdtool rrdtool-perl perl-libwww-perl perl-MailTools perl-MIME-Lite perl-CGI perl-DBI perl-XML-Simple perl-Config-General perl-HTTP-Server-Simple perl-IO-Socket-SSL 

然后安装：
rpm -ivh http://www.monitorix.org/monitorix-n.n.n-1.noarch.rpm (where n.n.n is the latest version)

启动：
chkconfig --level 35 monitorix on 
service monitorix start 

在/etc/httpd/conf/httpd.conf 添加下列信息：
Alias /monitorix/ "/usr/share/monitorix/" 
<Directory "/usr/share/monitorix"> 
DirectoryIndex index.php index.html index.htm 
Options Indexes FollowSymLinks 
AllowOverride None 
Order allow,deny 
Allow from all 
</Directory> 
<Directory /usr/share/monitorix/cgi-bin/> 
DirectoryIndex monitorix.cgi 
Options ExecCGI 
order deny,allow 
deny from all 
allow from all 
</Directory> 


赋予权限： 
chcon -R -u system_u -r object_r -t httpd_sys_content_t /usr/share/monitorix
chcon -R -u system_u -r object_r -t httpd_sys_content_t /var/lib/monitorix
重启httpd服务：
service httpd restart 
监控：
http://localhos/monitorix/ 
监控多个linux主机， 修改/etc/monitorix.conf，将将MULTIHOST改成y ，REMOTEHOST_LIST 添加列表 
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
15. Arpwatch – 以太网活动监视器

安装：yum install arpwatch
Arpwatch被设计用来监控Linux上的以太网地址解析 (MAC和IP地址的变化)。他在一段时间内持续监控以太网活动并输出IP和MAC地址配对变动的日志。它还可以向管理员发送邮件通知，对地址配对的增改发出警告。这对于检测网络上的ARP攻击很有用。?

16. Suricata – 网络安全监控

Suricata?是一个开源的高性能网络安全、入侵检测和反监测工具，可以运行Linux、FreeBSD和Windows上。非营利组织OISF?(Open Information Security Foundation)开发并拥有其版权。
安装：rpm -Uvh http://www6.atomicorp.com/channels/atomic/centos/6/i386/RPMS/suricata-2.0.1-1.el6.art.i686.rpm

17. VnStat PHP – 网络流量监控

VnStat PHP?是流行网络工具”vnstat”的基于web的前端呈现。VnStat PHP?将网络使用情况呈现在漂亮的图形界面中。他可以显示以小时、日、月计的上传和下载流量并输出总结报告。

18. Nagios – 网络/服务器监控

Nagios是领先而强大的开源监控系统，他可以让网络/系统管理员在问题影响到正常的业务之前发现并解决它们。有了Nagios系统，管理员可以 在单个窗口内远程检测Linux、Windows、开关、路由器和打印机。它可以危险警告并指出系统/服务器是否有异常，这可以间接帮助你在问题发生之前 采取抢救措施。
安装：yum -y install nagios nagios-nrpe nagios-plugins nagios-plugins-nrpe check_logfiles
测试配置是否有错误： /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
启动服务：service nagios start

19.Lsof-列出打开的文件

在许多Linux或者类Unix系统里都有lsof命令，它常用于以列表的形式显示所有打开的文件和进程。打开的文件包括磁盘文件、网络套接字、管 道、设备和进程。使用这条命令的主要情形之一就是在无法挂载磁盘和显示正在使用或者打开某个文件的错误信息的时候。使用这条命令，你可以很容易地看到正在 使用哪个文件。

20. Htop – Linux进程监控

Htop?是一个非常高级的交互式的实时linux进程监控工具。 它和top命令十分相似，但是它具有更丰富的特性，例如用户可以友好地管理进程，快捷键，垂直和水平方式显示进程等等。 Htop是一个第三方工具，它不包含在linux系统中，你需要使用YUM包管理工具去安装它。 关于安装的更多信息，请阅读下文.

21.Iotop-监控Linux磁盘I/O

Iotop命令同样也非常类似于top命令和Htop程序，不过它具有监控并显示实时磁盘I/O和进程的统计功能。在查找具体进程和大量使用磁盘读写进程的时候，这个工具就非常有用。

22. psacct 或者 acct - 监视用户活动

psacct或者acct工具用于监视系统里每个用户的活动状况。这两个服务进程运行在后台，它们对系统上运行的每个用户的所有活动进行近距离监视，同时还监视这些活动所使用的资源情况。
系统管理员可以使用这两个工具跟踪每个用户的活动，比如用户正在做什么，他们提交了那些命令，他们使用了多少资源，他们在系统上持续了多长时间等等。
安装：yum install psacct
状态：/etc/init.d/psacct status
启动：chkconfig psacct on
/etc/init.d/psacct start
命令： ac sa lastcomm等

23.Monit - Linux进程和服务监控工具

Monit是一个免费的开源软件，也是一个基于网络的进程监控工具。它能自动监控和管理系统进程，程序，文件，文件夹，权限，总和验证码和文件系统。
这个软件能监控像Apache, MySQL, Mail, FTP, ProFTP, Nginx, SSH这样的服务。你可以通过命令行或者这个软件提供的网络借口来查看系统状态。

24.tsar- Linux进程和服务监控工具

tsar是淘宝自己开发的一个采集工具，主要用来收集服务器的系统信息（如cpu，io，mem，tcp等），以及应用数据（如squid haproxy nginx等）。收集到的数据存储在磁盘上，可以随时查询历史信息，输出方式灵活多样，另外支持将数据存储到MySQL中，也可以将数据发送到nagios报警服务器。tsar在展示数据时，可以指定模块，并且可以对多条信息的数据进行merge输出，带–live参数可以输出秒级的实时信息。

https://github.com/alibaba/tsar
------------------------------------------------
版权声明：本文为CSDN博主「xlxxcc」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/xlxxcc/article/details/52058596
