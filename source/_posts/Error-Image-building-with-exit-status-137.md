---
title: 'Error: Image building with exit status 137'
date: 2021-09-10 11:53:23
tags:
- jvm
categories: 
- java
---
Building a native image with graalvm ce rc11 & rc12, I occasionally see the following error;

Error: Image building with exit status 137

This occurs if the system runs out of ram (including free swap pages) and the OOM Killer terminates the native image build process.

The error message seen by users is not very informative. Could we capture the exit code of the native-image process, and if equal to 137, display a more helpful message to users?
解决办法：
This appears to be related to memory available to build native image. The native-image tool used to report an OutOfMemory exception, but in recent graal release it appears that a build can fail with exit status 137 if there is insufficient memory to complete a native image build
+1 for improvement. Capturing these error codes and providing an actual verbose and useful error message would remove a lot of frustration, saving businesses and employees time and money.
总之解决办法为：增加内存