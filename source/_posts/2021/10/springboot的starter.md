---
title: springboot的starter
date: 2021-10-12 10:06:44
tags: 
- springboot
categories: 
- java
---

通过starter，可以让springboot开箱即用，遵循的就是约定大于配置，这个概念。下面写一个集成zk的starter。

#### Spring Boot starter原理

从总体上来看，无非就是将Jar包作为项目的依赖引入工程。而现在之所以增加了难度，是因为我们引入的是Spring Boot Starter，所以我们需要去了解Spring Boot对Spring Boot Starter的Jar包是如何加载的？下面我简单说一下。

SpringBoot 在启动时会去依赖的 starter 包中寻找 /META-INF/spring.factories 文件，然后根据文件中配置的 Jar 包去扫描项目所依赖的 Jar 包，这类似于 Java 的 SPI 机制。

细节上可以使用@Conditional 系列注解实现更加精确的配置加载Bean的条件。

JavaSPI 实际上是“基于接口的编程＋策略模式＋配置文件”组合实现的动态加载机制。

<!--more-->

#### 自定义starter的条件

如果想自定义Starter，首选需要实现自动化配置，而要实现自动化配置需要满足以下两个条件：

1. 能够自动配置项目所需要的配置信息，也就是自动加载依赖环境；
2. 能够根据项目提供的信息自动生成Bean，并且注册到Bean管理容器中；

#### 实现自定义starter

pom.xml依赖

```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example</groupId>
    <artifactId>springboot-zk</artifactId>
    <version>1.0-SNAPSHOT</version>


    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.0.1.RELEASE</version>
    </parent>

    <properties>
        <maven.compiler.target>1.8</maven.compiler.target>
        <maven.compiler.source>1.8</maven.compiler.source>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-framework</artifactId>
            <version>5.2.0</version>
        </dependency>
        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-recipes</artifactId>
            <version>5.2.0</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

    </dependencies>



</project>
```

starter的结构如下：

![image-20211012101524155](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012101524155.png)

定义XxxProperties类，属性配置类，完成属性配置相关的操作，比如设置属性前缀，用于在application.properties中配置。

TianProperties代码：

```
@ConfigurationProperties(prefix = "spring.tian")
public class TianProperties {
    private int retryCount;
    private int elapseTimeMs;
    private String connectString;
```

创建service类

```
public class ZkService {
    private static Logger logger= LoggerFactory.getLogger(ZkService.class);
    private final static String ROOT_PATH_LOCK="zklock";
    private CountDownLatch countDownLatch=new CountDownLatch(1);

    private CuratorFramework curatorFramework;

    public ZkService(CuratorFramework curatorFramework) {
        this.curatorFramework=curatorFramework;
    }


    public void getLock(String path){
        String keyPath="/"+ROOT_PATH_LOCK+"/"+path;
        while (true){
            try{
                curatorFramework.create().creatingParentContainersIfNeeded().withMode(CreateMode.EPHEMERAL).withACL(
                    Ids.OPEN_ACL_UNSAFE).forPath(keyPath);
                logger.info("success to acquire lock for path:{}",keyPath);
                break;
            }catch (Exception e){
                logger.info("fail to acquire locker path ：{}",keyPath);
                try {
                    if (countDownLatch.getCount()<=0){
                        countDownLatch=new CountDownLatch(1);
                    }
                    countDownLatch.await();

                }catch (Exception e1){
                    e1.printStackTrace();
                }finally {
                }
            }
        }
    }
    public boolean release(String path) {
        String keyPath="/"+ROOT_PATH_LOCK+"/"+path;
        try {
            if (curatorFramework.checkExists().forPath(keyPath)!=null){
                curatorFramework.delete().forPath(keyPath);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return  false;
        }
        return true;
    }
    private void addWatcher(String path){
        String keyPath;
        if (path.equals(ROOT_PATH_LOCK)){
            keyPath="/"+path;
        }else {
            keyPath="/"+ROOT_PATH_LOCK+"/"+path;
        }
        final CuratorCache cacheEvent= CuratorCache.build(curatorFramework,keyPath, Options.SINGLE_NODE_CACHE);
        cacheEvent.start();
        cacheEvent.listenable().addListener(new CuratorCacheListener() {
            @Override
            public void event(Type type, ChildData oldData, ChildData data) {
                if (type.name().equals("NODE_CREATED")){

                }else if (type.name().equals("NODE_CHANGED")){

                }else{
                    String oldPath=oldData.getPath();
                    if (oldPath.contains(path)){
                        countDownLatch.countDown();
                    }
                }
            }
        });

    }
    public void afterPropertiesSet() throws Exception {
        curatorFramework=curatorFramework.usingNamespace("lock-namespace");
        String path="/"+ROOT_PATH_LOCK;
        if (curatorFramework.checkExists().forPath(path)==null){
            curatorFramework.create().creatingParentContainersIfNeeded().withMode(CreateMode.PERSISTENT).withACL(Ids.OPEN_ACL_UNSAFE).forPath(path);

        }
        addWatcher(ROOT_PATH_LOCK);
    }
}
```

定义XxxConfigurationProperties类，自动配置类，用于完成Bean创建等工作。

ZkAutoConfiguration代码：

```
@Configuration
@EnableConfigurationProperties(TianProperties.class)
@ConditionalOnClass(ZkService.class)
@ConditionalOnProperty(prefix = "spring.tian", value = "enabled", matchIfMissing = true)
public class ZkAutoConfiguration {
    @Autowired
    private TianProperties properties;
    @Bean(initMethod = "start")
    public CuratorFramework curatorFramework(){

        return CuratorFrameworkFactory.newClient(
            properties.getConnectString(),
            properties.getSessionTimeoutMs(),
            properties.getConnectTimeoutMs(),
            new RetryNTimes(properties.getRetryCount(), properties.getElapseTimeMs())
        );
    }
    @Bean
    @ConditionalOnMissingBean(ZkService.class)
    public ZkService tianService() throws Exception {
        ZkService zkService= new ZkService(curatorFramework());
        zkService.afterPropertiesSet();
        return zkService;
    }


}
```

在resources下创建目录META-INF，在 META-INF 目录下创建 spring.factories，在SpringBoot启动时会根据此文件来加载项目的自动化配置类。

「spring.factories中配置」

```
org.springframework.boot.autoconfigure.EnableAutoConfiguration=com.springboot.zk.ZkAutoConfiguration
```

把上面这个starter工程打成jar包：

#### 使用自定义starter

创建一个Spring Boot项目test，项目整体如下图：

![image-20211012101855586](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012101855586.png)

在项目中把自定义starter添加pom依赖

![image-20211012101920527](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012101920527.png)

application.properties中配置



![image-20211012101957615](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012101957615.png)

这就成功的现实了自定义的starter。

关键词：`开箱即用、减少大量的配置项、约定大于配置`。

#### 使用注解开启 Starter 自动构建

很多时候我们不想在引入 Starter 包时就执行初始化的逻辑，而是想要由用户来指定是否要开启 Starter 包的自动配置功能，比如常用的 @EnableAsync 这个注解就是用于开启调用方法异步执行的功能。

同样地，我们也可以通过注解的方式来开启是否自动配置，如果用注解的方式，那么 spring.factories 就不需要编写了，下面就来看一下怎么定义启用自动配置的注解，代码如下所示。


```less
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@Import({ZkAutoConfiguration.class})
public @interface EnableUserClient {

}
```

这段代码的核心是 @Import（{UserAutoConfigure.class}），通过导入的方式实现把 UserAutoConfigure 实例加入 SpringIOC 容器中，这样就能开启自动配置了。

使用方式就是在启动类上加上该注解，代码如下所示。

```typescript
@SpringBootApplication
public class SpringBootDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpringBootDemoApplication.class, args);
    }
}
```

#### 使用配置开启 Starter 自动构建

在某些场景下，UserAutoConfigure 中会配置多个对象，对于这些对象，如果不想全部配置，或是想让用户指定需要开启配置的时候再去构建对象，这个时候我们可以通过 @ConditionalOnProperty 来指定是否开启配置的功能，代码如下所示。


```less
   @Bean
    @ConditionalOnMissingBean(ZkService.class)
    @ConditionalOnProperty(prefix = "spring.tian",value = "enabled",havingValue = "true")
    public ZkService tianService() throws Exception {
        ZkService zkService= new ZkService(curatorFramework());
        zkService.afterPropertiesSet();
        return zkService;
    }
```

通过上面的配置，只有当启动类加了 @EnableUserClient 并且配置文件中 spring.user.enabled=true 的时候才会自动配置 UserClient。

![image-20211012104448828](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012104448828.png)

![image-20211012104530890](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20211012104530890.png)



