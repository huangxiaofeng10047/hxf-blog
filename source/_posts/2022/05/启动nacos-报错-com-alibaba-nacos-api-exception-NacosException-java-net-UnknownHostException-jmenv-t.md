---
title: >-
  启动nacos 报错 com.alibaba.nacos.api.exception.NacosException:
  java.net.UnknownHostException: jmenv.t.
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-05-27 13:12:02
tags:
---

启动报错如下

```
2022-05-27 13:02:47,987 INFO The server IP list of Nacos is []
2022-05-27 13:02:48,987 INFO Nacos is starting...
2022-05-27 13:02:50,010 INFO Nacos is starting...
2022-05-27 13:02:51,101 INFO Nacos is starting...
2022-05-27 13:02:52,193 INFO Nacos is starting...
2022-05-27 13:02:53,211 INFO Nacos is starting...
2022-05-27 13:02:54,211 INFO Nacos is starting...
2022-05-27 13:02:54,444 INFO Nacos Log files: /home/nacos/logs
2022-05-27 13:02:54,445 INFO Nacos Log files: /home/nacos/conf
2022-05-27 13:02:54,445 INFO Nacos Log files: /home/nacos/data
2022-05-27 13:02:54,448 ERROR Startup errors : 
org.springframework.context.ApplicationContextException: Unable to start web server; nested exception is org.springframework.boot.web.server.WebServerException: Unable to start embedded Tomcat
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.onRefresh(ServletWebServerApplicationContext.java:156)
        at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:544)
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.refresh(ServletWebServerApplicationContext.java:141)
        at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:744)
        at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:391)
        at org.springframework.boot.SpringApplication.run(SpringApplication.java:312)
        at org.springframework.boot.SpringApplication.run(SpringApplication.java:1215)
        at org.springframework.boot.SpringApplication.run(SpringApplication.java:1204)
        at com.alibaba.nacos.Nacos.main(Nacos.java:35)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at org.springframework.boot.loader.MainMethodRunner.run(MainMethodRunner.java:49)
        at org.springframework.boot.loader.Launcher.launch(Launcher.java:108)
        at org.springframework.boot.loader.Launcher.launch(Launcher.java:58)
        at org.springframework.boot.loader.PropertiesLauncher.main(PropertiesLauncher.java:467)
Caused by: org.springframework.boot.web.server.WebServerException: Unable to start embedded Tomcat
        at org.springframework.boot.web.embedded.tomcat.TomcatWebServer.initialize(TomcatWebServer.java:124)
        at org.springframework.boot.web.embedded.tomcat.TomcatWebServer.<init>(TomcatWebServer.java:86)
        at org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory.getTomcatWebServer(TomcatServletWebServerFactory.java:416)
        at org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory.getWebServer(TomcatServletWebServerFactory.java:180)
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.createWebServer(ServletWebServerApplicationContext.java:180)
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.onRefresh(ServletWebServerApplicationContext.java:153)
        ... 16 common frames omitted
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'distroFilterRegistration' defined in class path resource [com/alibaba/nacos/naming/web/NamingConfig.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.boot.web.servlet.FilterRegistrationBean]: Factory method 'distroFilterRegistration' threw exception; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'distroFilter': Unsatisfied dependency expressed through field 'distroMapper'; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'distroMapper' defined in URL [jar:file:/home/nacos/target/nacos-server.jar!/BOOT-INF/lib/nacos-naming-2.0.3.jar!/com/alibaba/nacos/naming/core/DistroMapper.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'serverMemberManager' defined in URL [jar:file:/home/nacos/target/nacos-server.jar!/BOOT-INF/lib/nacos-core-2.0.3.jar!/com/alibaba/nacos/core/cluster/ServerMemberManager.class]: Bean instantiation via constructor failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [com.alibaba.nacos.core.cluster.ServerMemberManager]: Constructor threw exception; nested exception is ErrCode:500, ErrMsg:jmenv.tbsite.net
        at org.springframework.beans.factory.support.ConstructorResolver.instantiate(ConstructorResolver.java:627)
        at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:456)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.instantiateUsingFactoryMethod(AbstractAutowireCapableBeanFactory.java:1318)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1158)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:554)
        at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:514)
        at org.springframework.beans.factory.support.AbstractBeanFactory.lambda$doGetBean$0(AbstractBeanFactory.java:321)
        at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:234)
        at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:319)
        at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:204)
        at org.springframework.boot.web.servlet.ServletContextInitializerBeans.getOrderedBeansOfType(ServletContextInitializerBeans.java:211)
        at org.springframework.boot.web.servlet.ServletContextInitializerBeans.getOrderedBeansOfType(ServletContextInitializerBeans.java:202)
        at org.springframework.boot.web.servlet.ServletContextInitializerBeans.addServletContextInitializerBeans(ServletContextInitializerBeans.java:96)
        at org.springframework.boot.web.servlet.ServletContextInitializerBeans.<init>(ServletContextInitializerBeans.java:85)
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.getServletContextInitializerBeans(ServletWebServerApplicationContext.java:253)
        at org.springframework.boot.web.servlet.context.ServletWebServerApplicationContext.selfInitialize(ServletWebServerApplicationContext.java:227)
        at org.springframework.boot.web.embedded.tomcat.TomcatStarter.onStartup(TomcatStarter.java:53)
        at org.apache.catalina.core.StandardContext.startInternal(StandardContext.java:5128)
        at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183)
        at org.apache.catalina.core.ContainerBase$StartChild.call(ContainerBase.java:1384)
        at org.apache.catalina.core.ContainerBase$StartChild.call(ContainerBase.java:1374)
        at java.util.concurrent.FutureTask.run(FutureTask.java:266)
        at org.apache.tomcat.util.threads.InlineExecutorService.execute(InlineExecutorService.java:75)
        at java.util.concurrent.AbstractExecutorService.submit(AbstractExecutorService.java:134)
        at org.apache.catalina.core.ContainerBase.startInternal(ContainerBase.java:909)
        at org.apache.catalina.core.StandardHost.startInternal(StandardHost.java:843)
        at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183)
        at org.apache.catalina.core.ContainerBase$StartChild.call(ContainerBase.java:1384)
        at org.apache.catalina.core.ContainerBase$StartChild.call(ContainerBase.java:1374)
        at java.util.concurrent.FutureTask.run(FutureTask.java:266)
        at org.apache.tomcat.util.threads.InlineExecutorService.execute(InlineExecutorService.java:75)
        at java.util.concurrent.AbstractExecutorService.submit(AbstractExecutorService.java:134)
        at org.apache.catalina.core.ContainerBase.startInternal(ContainerBase.java:909)
        at org.apache.catalina.core.StandardEngine.startInternal(StandardEngine.java:262)
        at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183)
        at org.apache.catalina.core.StandardService.startInternal(StandardService.java:421)
        at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183)
        at org.apache.catalina.core.StandardServer.startInternal(StandardServer.java:930)
        at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183)
        at org.apache.catalina.startup.Tomcat.start(Tomcat.java:486)
        at org.springframework.boot.web.embedded.tomcat.TomcatWebServer.initialize(TomcatWebServer.java:105)
        ... 21 common frames omitted
Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [org.springframework.boot.web.servlet.FilterRegistrationBean]: Factory method 'distroFilterRegistration' threw exception; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'distroFilter': Unsatisfied dependency expressed through field 'distroMapper'; nested exception is org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'distroMapper' defined in URL [jar:file:/home/nacos/target/nacos-server.jar!/BOOT-INF/lib/nacos-naming-2.0.3.jar!/com/alibaba/nacos/naming/core/DistroMapper.class]: Unsatisfied dependency expressed through constructor parameter 0; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'serverMemberManager' defined in URL [jar:file:/home/nacos/target/nacos-server.jar!/BOOT-INF/lib/nacos-core-2.0.3.jar!/com/alibaba/nacos/core/cluster/ServerMemberManager.class]: Bean instantiation via constructor failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [com.alibaba.nacos.core.cluster.ServerMemberManager]: Constructor threw exception; nested exception is ErrCode:500, ErrMsg:jmenv.tbsite.net
        at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:185)
        at org.springframework.beans.factory.support.ConstructorResolver.instantiate(ConstructorResolver.java:622)
        ... 61 common frames omitted
```

出现这个原因是，因为nacos的conf下缺少cluster.conf文件。

[root@nacos-2 nacos]# cd conf/
[root@nacos-2 conf]# ls
1.4.0-ipv6_support-update.sql  application.properties  cluster.conf  nacos-logback.xml  schema.sql
[root@nacos-2 conf]# ll
total 52
-rw-r--r--. 1  502 games  1224 Jun 18  2021 1.4.0-ipv6_support-update.sql
-rw-r--r--. 1 root root   2532 Jul 31  2021 application.properties
-rw-r--r--. 1 root root      0 May 27 13:05 cluster.conf
-rw-r--r--. 1  502 games 31156 Jul 15  2021 nacos-logback.xml
-rw-r--r--. 1  502 games  8795 Jun 18  2021 schema.sql

其实这个是通过以下获取配置信息，存到cluster.conf

```
root        12    11  0 14:27 ?        00:00:00 ./peer-finder -on-start=/home/nacos/plugins/peer-finder/on-start.sh -on-change=/home/nacos/plugins/peer-finder/on-change.sh -service=nacos-headless -domain=cluster.local
```

其中on-start.sh

```
[root@nacos-1 peer-finder]# cat on-start.sh 
#!/bin/bash


NACOS_APPLICATION_PORT=${NACOS_APPLICATION_PORT:-8848}

while read -ra LINE; do
    PEERS=("${PEERS[@]}" $LINE)
done

echo "" > "${CLUSTER_CONF}"


for peer in "${PEERS[@]}"; do
 echo "${peer}:$NACOS_APPLICATION_PORT" >> "${CLUSTER_CONF}"
done


[root@nacos-1 peer-finder]# 
```

当不生成文件时，很可能是dns出错了，造成了配置不生成

对应的服务应该是kube-system下的nodelocaldns的服务不可用，造成的。

