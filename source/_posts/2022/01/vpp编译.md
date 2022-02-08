---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
安装方式： 源码编译安装  
操作系统： [ubuntu](https://so.csdn.net/so/search?q=ubuntu&spm=1001.2101.3001.7020) 18.04  
系统配置: 8G 内存 、4 Core 、100G SATA

注意:  
a、 科学上网 。 b 、全新系统。

1.  设置代理

如果你的服务器本地可以连接互联网，则跳过设置代理的步骤。  
根据您所使用的环境，可能需要设置代理。运行以下代理命令以指定代理服务器名称和相应的端口号：

```
$ export http_proxy=http://<proxy-server-name>.com:<port-number>
$ export https_proxy=https://<proxy-server-name>.com:<port-number>
```

2.  下载 VPP 源码

a、 从gerrit.fd.io

```
$ git clone https://gerrit.fd.io/r/vpp
$ cd vpp
```

b、从GitHub，推进使用 github ，速度快很多。

```
$ git clone https://github.com/FDio/vpp
```

选择分支，我安装的是21.01版本

3.  安装 VPP 依赖、编译安装  
    在构建VPP映像之前，通过输入以下命令，确保没有安装FD.io VPP或DPDK软件包：

```
$ dpkg -l | grep vpp
$ dpkg -l | grep DPDK
```

运行上述命令后，应该没有输出或没有显示任何程序包。  
运行以下make命令以安装FD.io VPP的依赖项。

```
$ make install-dep
```

运行成功的日志如下：

```
Hit:1 http://us.archive.ubuntu.com/ubuntu xenial InRelease
Get:2 http://us.archive.ubuntu.com/ubuntu xenial-updates InRelease [109 kB]
Get:3 http://security.ubuntu.com/ubuntu xenial-security InRelease [107 kB]
Get:4 http://us.archive.ubuntu.com/ubuntu xenial-backports InRelease [107 kB]
Get:5 http://us.archive.ubuntu.com/ubuntu xenial-updates/main amd64 Packages [803 kB]
Get:6 http://us.archive.ubuntu.com/ubuntu xenial-updates/main i386 Packages [732 kB]
...
...
Update-alternatives: using /usr/lib/jvm/java-8-openjdk-amd64/bin/jmap to provide /usr/bin/jmap (jmap) in auto mode
Setting up default-jdk-headless (2:1.8-56ubuntu2) ...
Processing triggers for libc-bin (2.23-0ubuntu3) ...
Processing triggers for systemd (229-4ubuntu6) ...
Processing triggers for ureadahead (0.100.0-19) ...
Processing triggers for ca-certificates (20160104ubuntu1) ...
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
done.
```

4.  编译 VPP  
    此构建版本包含调试符号，这些调试符号对于修改VPP非常有用。下面的 make命令可构建VPP的调试版本。

```
$ make build-release
make[1]: Entering directory '/home/vagrant/vpp-master/build-root'
@@@@ Arch for platform 'vpp' is native @@@@
@@@@ Finding source for dpdk @@@@
@@@@ Makefile fragment found in /home/vagrant/vpp-master/build-data/packages/dpdk.mk @@@@
@@@@ Source found in /home/vagrant/vpp-master/dpdk @@@@
@@@@ Arch for platform 'vpp' is native @@@@
@@@@ Finding source for vpp @@@@
@@@@ Makefile fragment found in /home/vagrant/vpp-master/build-data/packages/vpp.mk @@@@
@@@@ Source found in /home/vagrant/vpp-master/src @@@@
...
...
-- tlsmbedtls plugin needs mbedcrypto library - found at /usr/lib/x86_64-linux-gnu/libmbedcrypto.so
-- Looking for SSL_set_async_callback
-- Looking for SSL_set_async_callback - not found
-- Looking for picotls
-- Found picotls in /home/forlinx/VPP/vpp/build-root/install-vpp-native/external/include and /home/forlinx/VPP/vpp/build-root/install-vpp-native/external/lib/libpicotls-core.a
-- Found PythonInterp: /usr/bin/python2.7 (found suitable version "2.7.17", minimum required is "2.7") 
-- Configuration:
VPP version         : 21.01.0-2~g2e591554b
VPP library version : 21.01.0
GIT toplevel dir    : /home/forlinx/VPP/vpp
Build type          : release
C flags             : -Wno-address-of-packed-member -g -fPIC -Werror -Wall -march=corei7 -mtune=corei7-avx -O2 -fstack-protector -DFORTIFY_SOURCE=2 -fno-common 
Linker flags (apps) : -pie
Linker flags (libs) : 
Host processor      : x86_64
Target processor    : x86_64
Prefix path         : /opt/vpp/external/x86_64;/home/forlinx/VPP/vpp/build-root/install-vpp-native/external
Install prefix      : /home/forlinx/VPP/vpp/build-root/install-vpp-native/vpp
-- Configuring done
-- Generating done
-- Build files have been written to: /home/forlinx/VPP/vpp/build-root/build-vpp-native/vpp
@@@@ Building vpp in /home/forlinx/VPP/vpp/build-root/build-vpp-native/vpp @@@@
[2404/2404] Creating library symlink lib/libvapiclient.so
@@@@ Installing vpp @@@@
[0/1] Install the project...
-- Install configuration: "release"
make[1]: Leaving directory '/home/forlinx/VPP/vpp/build-root'
```

5.  构建 软件包

(5.1) deb软件包、VPP要在Ubuntu上运行

```
$ make pkg-deb
..... 省略很多内容
make[3]: Leaving directory '/home/forlinx/VPP/vpp/build-root/build-vpp-native/vpp'
   dh_makeshlibs -O--buildsystem=pybuild
   dh_shlibdeps -O--buildsystem=pybuild
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/libvppinfra/usr/lib/x86_64-linux-gnu/libvppinfra.so.21.01.0 was not linked against libm.so.6 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: symbol clib_c11_violation used by debian/vpp/usr/lib/x86_64-linux-gnu/libvatclient.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol ip_prefix_validate used by debian/vpp/usr/lib/x86_64-linux-gnu/libvatclient.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol mspace_put used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol fib_table_get_table_id used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vec_resize_allocate_memory used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol clib_mem_main used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol __os_thread_index used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vlib_get_frame_to_node used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol clib_time_verify_frequency used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol clib_c11_violation used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vlib_thread_main used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol syslog_msg_add_sd_param used by debian/vpp/usr/lib/x86_64-linux-gnu/libnat.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: 14 other similar warnings have been skipped (use -v to see them all)
dpkg-shlibdeps: warning: symbol vl_socket_api_client_handle_to_registration used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol stat_segment_deregister_state_counter used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_msg_api_alloc_as_if_client used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_mem_api_client_index_to_registration used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_msg_api_config used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_msg_api_alloc used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol my_api_main used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_msg_api_send_shmem used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_msg_api_add_msg_name_crc used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vl_api_format_string used by debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: 18 other similar warnings have been skipped (use -v to see them all)
dpkg-shlibdeps: warning: symbol classify_get_trace_chain used by debian/vpp/usr/lib/x86_64-linux-gnu/libvlib.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol vnet_get_main used by debian/vpp/usr/lib/x86_64-linux-gnu/libvlib.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol stat_segment_register_gauge used by debian/vpp/usr/lib/x86_64-linux-gnu/libvlib.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol os_exit used by debian/vpp/usr/lib/x86_64-linux-gnu/libvlib.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: symbol os_panic used by debian/vpp/usr/lib/x86_64-linux-gnu/libvlib.so.21.01.0 found in none of the libraries
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp/usr/bin/vpp debian/vpp/usr/lib/x86_64-linux-gnu/libvnet.so.21.01.0 debian/vpp/usr/lib/x86_64-linux-gnu/libperfcore.so.21.01.0 were not linked against libssl.so.1.1 (they use none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libpthread.so.0 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libm.so.6 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libuuid.so.1 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libperfcore.so.21.01.0 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against librt.so.1 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libvppinfra.so.21.01.0 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libdl.so.2 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libvlib.so.21.01.0 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libvnet.so.21.01.0 (it uses none of the library's symbols)
dpkg-shlibdeps: warning: package could avoid a useless dependency if debian/vpp-plugin-core/usr/lib/x86_64-linux-gnu/vpp_plugins/perfmon_plugin.so was not linked against libsvm.so.21.01.0 (it uses none of the library's symbols)
   dh_installdeb -O--buildsystem=pybuild
   dh_gencontrol -O--buildsystem=pybuild
dpkg-gencontrol: warning: package vpp-api-python: unused substitution variable ${python:Versions}
   dh_md5sums -O--buildsystem=pybuild
   dh_builddeb -O--buildsystem=pybuild
dpkg-deb: building package 'libvppinfra' in '../libvppinfra_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp-plugin-dpdk' in '../vpp-plugin-dpdk_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp' in '../vpp_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'libvppinfra-dev' in '../libvppinfra-dev_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp-plugin-core' in '../vpp-plugin-core_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp-api-python' in '../vpp-api-python_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'python3-vpp-api' in '../python3-vpp-api_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp-dbg' in '../vpp-dbg_21.01.0-2~g2e591554b_amd64.deb'.
dpkg-deb: building package 'vpp-dev' in '../vpp-dev_21.01.0-2~g2e591554b_amd64.deb'.
make[2]: Leaving directory '/home/forlinx/VPP/vpp/build-root/build-vpp-native/vpp'
 dpkg-genbuildinfo --build=binary
 dpkg-genchanges --build=binary >../vpp_21.01.0-2~g2e591554b_amd64.changes
dpkg-genchanges: info: binary-only upload (no source code included)
 dpkg-source --after-build vpp
dpkg-buildpackage: info: binary-only upload (no source included)
make[1]: Leaving directory '/home/forlinx/VPP/vpp/build-root'

forlinx@ubuntu:~/VPP/vpp$ 
```

查看生成的 deb 软件包

```
root@ubuntu:~/VPP/vpp/build-root# ls -la *.deb
-rw-r--r-- 1 forlinx forlinx   132096 Mar 23 22:52 libvppinfra_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx   134460 Mar 23 22:52 libvppinfra-dev_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx    25596 Mar 23 22:52 python3-vpp-api_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx  4518616 Mar 23 22:52 vpp_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx    25512 Mar 23 22:52 vpp-api-python_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx 55805316 Mar 23 22:52 vpp-dbg_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx  1123740 Mar 23 22:53 vpp-dev_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx  4123952 Mar 23 22:52 vpp-plugin-core_21.01.0-2~g2e591554b_amd64.deb
-rw-r--r-- 1 forlinx forlinx  3859776 Mar 23 22:52 vpp-plugin-dpdk_21.01.0-2~g2e591554b_amd64.deb

```

UBUNTU 使用以下命令安装创建的软件包

```
$ sudo bash & cd build-root
# dpkg -i *.deb
省略部分内容
dpkg: dependency problems prevent configuration of python3-vpp-api:
 python3-vpp-api depends on python3-cffi; however:
  Package python3-cffi is not installed.
 python3-vpp-api depends on python3-pycparser; however:
  Package python3-pycparser is not installed.

dpkg: error processing package python3-vpp-api (--install):
 dependency problems - leaving unconfigured
Setting up vpp (21.01.0-2~g2e591554b) ...
* Applying /etc/sysctl.d/10-console-messages.conf ...
kernel.printk = 4 4 1 7
* Applying /etc/sysctl.d/10-ipv6-privacy.conf ...
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
* Applying /etc/sysctl.d/10-kernel-hardening.conf ...
kernel.kptr_restrict = 1
* Applying /etc/sysctl.d/10-link-restrictions.conf ...
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
* Applying /etc/sysctl.d/10-magic-sysrq.conf ...
kernel.sysrq = 176
* Applying /etc/sysctl.d/10-network-security.conf ...
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
* Applying /etc/sysctl.d/10-ptrace.conf ...
kernel.yama.ptrace_scope = 1
* Applying /etc/sysctl.d/10-zeropage.conf ...
vm.mmap_min_addr = 65536
* Applying /usr/lib/sysctl.d/50-default.conf ...
net.ipv4.conf.all.promote_secondaries = 1
net.core.default_qdisc = fq_codel
* Applying /etc/sysctl.d/80-vpp.conf ...
vm.nr_hugepages = 1024
vm.max_map_count = 3096
vm.hugetlb_shm_group = 0
kernel.shmmax = 2147483648
* Applying /etc/sysctl.d/99-sysctl.conf ...
* Applying /etc/sysctl.conf ...
Created symlink /etc/systemd/system/multi-user.target.wants/vpp.service → /lib/systemd/system/vpp.service.
dpkg: dependency problems prevent configuration of vpp-api-python:
 vpp-api-python depends on python-cffi; however:
  Package python-cffi is not installed.

dpkg: error processing package vpp-api-python (--install):
 dependency problems - leaving unconfigured
Setting up vpp-dbg (21.01.0-2~g2e591554b) ...
Setting up vpp-dev (21.01.0-2~g2e591554b) ...
Setting up vpp-plugin-core (21.01.0-2~g2e591554b) ...
Setting up vpp-plugin-dpdk (21.01.0-2~g2e591554b) ...
Processing triggers for libc-bin (2.27-3ubuntu1.2) ...
Errors were encountered while processing:
 python3-vpp-api
 vpp-api-python
root@ubuntu:~/VPP/vpp/build-root# 
```

此处安装出现错误 dpkg: error [processing](https://so.csdn.net/so/search?q=processing&spm=1001.2101.3001.7020) package vpp-api-python (–install):dependency problems - leaving unconfigured  
问题待查。

(5.2) RPM 软件包、VPP 要在 CentOS或Redhat上运行

```
$ make pkg-rpm
```

在这失败了，需要寻找方法编译出rpm包



对于Centos或Redhat，可以使用下面的命令安装我们构建的软件包：

```
$ sudo bash
# rpm -ivh *.rpm
```

6.  ubuntu 安装错误解决

看错误内容，可能是 python 的版本问题。  
解决方案:

第一步 安装 cffi

```
pip install cffi
```

第二步 安装

```
apt-get install vpp-api-python
# 报错误，
apt-get -f install
# apt-get会根据依赖关系自动安装相关组件，执行这个命令后安装vpp-api-python成功，
```

第三步 再次安装 \*.deb 包

```
dpkg -i *.deb
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210326133909279.png)