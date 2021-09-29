---
title: Flink_1.15 Master 详解
date: 2021-09-29 08:39:10
tags:
- flink
categories: 
- bigdata
---

从这篇开始会向大家介绍一下 Flink Runtime 中涉及到的分布式调度相关的内容。Flink 本身也是 Master/Slave 架构（当前的架构是在 [FLIP-6 - Flink Deployment and Process Model - Standalone, Yarn, Mesos, Kubernetes, etc](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=65147077) 中实现的），这个 Master 节点就类似于 Storm 中 Nimbus 节点，它负责整个集群的一些协调工作，Flink 中 Master 节点主要包含三大组件：Flink Resource Manager、Flink Dispatcher 以及为每个运行的 Job 创建一个 JobManager 服务，本篇文章主要给大家介绍一下 Flink 中 Master 节点相关内容。

这里要说明的一点是：通常我们认为 Flink 集群的 master 节点就是 JobManager，slave 节点就是 TaskManager 或者 TaskExecutor（见：[Distributed Runtime Environment](https://ci.apache.org/projects/flink/flink-docs-master/concepts/runtime.html)），这本身是没有什么问题的。但这里需要强调一下，在本文中集群的 Master 节点暂时就叫做 Master 节点，而负责每个作业调度的服务，这里叫做 JobManager/JobMaster（现在源码的实现中对应的类是 JobMaster）。集群的 Master 节点的工作范围与 JobManager 的工作范围还是有所不同的，而且 Master 节点的其中一项工作职责就是为每个提交的作业创建一个 JobManager 对象，用来处理这个作业相关协调工作，比如：task 的调度、Checkpoint 的触发及失败恢复等，JobManager 的内容将会在下篇文章单独讲述，本文主要聚焦 Master 节点除 JobManager 之外的工作。

<!--more-->

## [](http://matt33.com/2019/12/23/flink-master-5/#Flink-Master-%E7%AE%80%E4%BB%8B "Flink Master 简介")Flink Master 简介

Flink 的 Master 节点包含了三个组件: Dispatcher、ResourceManager 和 JobManager。其中:

1.  **Dispatcher**: 负责接收用户提供的作业，并且负责为这个新提交的作业拉起一个新的 JobManager 服务；
2.  **ResourceManager**: 负责资源的管理，在整个 Flink 集群中只有一个 ResourceManager，资源相关的内容都由这个服务负责；
3.  **JobManager**: 负责管理具体某个作业的执行，在一个 Flink 集群中可能有多个作业同时执行，每个作业都会有自己的 JobManager 服务。

[![Flink 的架构图（来自官网）](https://gitee.com/hxf88/imgrepo/raw/master/img/1-3.png)](http://matt33.com/images/flink/1-3.png "Flink 的架构图（来自官网）")Flink 的架构图（来自官网）

根据上面的 Flink 的架构图（等把 runtime 的内容介绍完，届时会画一张更细的 Flink 的架构图，现在先以官方的图来看），当用户开始提交一个作业，首先会将用户编写的代码转化为一个 JobGraph（参考这个系列前面的文章），在这个过程中，它会进行一些检查或优化相关的工作（比如：检查配置，把可以 Chain 在一起算子 Chain 在一起）。然后，Client 再将生成的 JobGraph 提交到集群中执行。此时有两种情况（对于两种不同类型的集群）：

1.  类似于 Standalone 这种 Session 模式（对于 YARN 模式来说），这种情况下 Client 可以直接与 Dispatcher 建立连接并提交作业；
2.  是 Per-Job 模式，这种情况下 Client 首先向资源管理系统 （如 Yarn）申请资源来启动 ApplicationMaster，然后再向 ApplicationMaster 中的 Dispatcher 提交作业。

当作业到 Dispatcher 后，Dispatcher 会首先启动一个 JobManager 服务，然后 JobManager 会向 ResourceManager 申请资源来启动作业中具体的任务。ResourceManager 选择到空闲的 Slot （[Flink 架构-基本概念](http://matt33.com/2019/11/23/flink-learn-start-1/#Flink-%E6%9E%B6%E6%9E%84)）之后，就会通知相应的 TM 将该 Slot 分配给指定的 JobManager。

## [](http://matt33.com/2019/12/23/flink-master-5/#Master-%E5%90%AF%E5%8A%A8%E6%95%B4%E4%BD%93%E6%B5%81%E7%A8%8B "Master 启动整体流程")Master 启动整体流程

Flink 集群 Master 节点在初始化时，会先调用 ClusterEntrypoint 的 `runClusterEntrypoint()` 方法启动集群，其整体流程如下图所示：

[![Flink Master 启动的整体流程](http://matt33.com/images/flink/5-flink-master.png)](http://matt33.com/images/flink/5-flink-master.png "Flink Master 启动的整体流程")Flink Master 启动的整体流程

上图流程中 `runCluster()` 方法的实现如下：

```
private void runCluster(Configuration configuration, PluginManager pluginManager)
            throws Exception {
        synchronized (lock) {
        #启动服务
            initializeServices(configuration, pluginManager);

            // write host information into configuration
            configuration.setString(JobManagerOptions.ADDRESS, commonRpcService.getAddress());
            configuration.setInteger(JobManagerOptions.PORT, commonRpcService.getPort());

            final DispatcherResourceManagerComponentFactory
                    dispatcherResourceManagerComponentFactory =
                            createDispatcherResourceManagerComponentFactory(configuration);

            clusterComponent =
                    dispatcherResourceManagerComponentFactory.create(
                            configuration,
                            ioExecutor,
                            commonRpcService,
                            haServices,
                            blobServer,
                            heartbeatServices,
                            metricRegistry,
                            executionGraphInfoStore,
                            new RpcMetricQueryServiceRetriever(
                                    metricRegistry.getMetricQueryServiceRpcService()),
                            this);

            clusterComponent
                    .getShutDownFuture()
                    .whenComplete(
                            (ApplicationStatus applicationStatus, Throwable throwable) -> {
                                if (throwable != null) {
                                    shutDownAsync(
                                            ApplicationStatus.UNKNOWN,
                                            ShutdownBehaviour.STOP_APPLICATION,
                                            ExceptionUtils.stringifyException(throwable),
                                            false);
                                } else {
                                    // This is the general shutdown path. If a separate more
                                    // specific shutdown was
                                    // already triggered, this will do nothing
                                    shutDownAsync(
                                            applicationStatus,
                                            ShutdownBehaviour.STOP_APPLICATION,
                                            null,
                                            true);
                                }
                            });
        }
    }
```

这个方法主要分为下面两个步骤：

1.  `initializeServices()`: 初始化相关的服务，都是 Master 节点将会使用到的一些服务；
2.  `create DispatcherResourceManagerComponent`: 这里会创建一个 `DispatcherResourceManagerComponent` 对象，这个对象在创建的时候会启动 `Dispatcher` 和 `ResourceManager` 服务。

下面来详细看下具体实现。

### [](http://matt33.com/2019/12/23/flink-master-5/#initializeServices "initializeServices")initializeServices

`initializeServices()` 初始化一些基本的服务，具体的代码实现如下：

```java
protected void initializeServices(Configuration configuration, PluginManager pluginManager)
            throws Exception {

        LOG.info("Initializing cluster services.");

        synchronized (lock) {
            rpcSystem = RpcSystem.load(configuration);
           #创建rpc服务
            commonRpcService =
                    RpcUtils.createRemoteRpcService(
                            rpcSystem,
                            configuration,
                            configuration.getString(JobManagerOptions.ADDRESS),
                            getRPCPortRange(configuration),
                            configuration.getString(JobManagerOptions.BIND_HOST),
                            configuration.getOptional(JobManagerOptions.RPC_BIND_PORT));

            JMXService.startInstance(configuration.getString(JMXServerOptions.JMX_SERVER_PORT));

            // update the configuration used to create the high availability services
            configuration.setString(JobManagerOptions.ADDRESS, commonRpcService.getAddress());
            configuration.setInteger(JobManagerOptions.PORT, commonRpcService.getPort());

            ioExecutor =
                    Executors.newFixedThreadPool(
                            ClusterEntrypointUtils.getPoolSize(configuration),
                            new ExecutorThreadFactory("cluster-io"));
            haServices = createHaServices(configuration, ioExecutor, rpcSystem);
            blobServer = new BlobServer(configuration, haServices.createBlobStore());
            blobServer.start();
            heartbeatServices = createHeartbeatServices(configuration);
            metricRegistry = createMetricRegistry(configuration, pluginManager, rpcSystem);

            final RpcService metricQueryServiceRpcService =
                    MetricUtils.startRemoteMetricsRpcService(
                            configuration, commonRpcService.getAddress(), rpcSystem);
            metricRegistry.startQueryService(metricQueryServiceRpcService, null);

            final String hostname = RpcUtils.getHostname(commonRpcService);

            processMetricGroup =
                    MetricUtils.instantiateProcessMetricGroup(
                            metricRegistry,
                            hostname,
                            ConfigurationUtils.getSystemResourceMetricsProbingInterval(
                                    configuration));

            executionGraphInfoStore =
                    createSerializableExecutionGraphStore(
                            configuration, commonRpcService.getScheduledExecutor());
        }
    }
```

上述流程涉及到服务有：

1.  RpcService: 创建一个 rpc 服务；
2.  HighAvailabilityServices: HA service 相关的实现，它的作用有很多，比如：处理 ResourceManager 的 leader 选举、JobManager leader 的选举等；
3.  BlobServer: 主要管理一些大文件的上传等，比如用户作业的 jar 包、TM 上传 log 文件等（Blob 是指二进制大对象也就是英文 Binary Large Object 的缩写）；
4.  HeartbeatServices: 初始化一个心跳服务；
5.  MetricRegistryImpl: metrics 相关的服务；
6.  ExecutionGraphStore: 存储 execution graph 的服务，默认有两种实现，`MemoryExecutionGraphStore` 主要是在内存中缓存，`FileExecutionGraphStore` 会持久化到文件系统，也会在内存中缓存。

这些服务都会在前面第二步创建 `DispatcherResourceManagerComponent` 对象时使用到。

### [](http://matt33.com/2019/12/23/flink-master-5/#create-DispatcherResourceManagerComponent "create DispatcherResourceManagerComponent")create DispatcherResourceManagerComponent

创建 `DispatcherResourceManagerComponent` 对象的实现如下：

1  

  

```
//DefaultDispatcherResourceManagerComponentFactory
//note 注意创建对象
 @Override
    public DispatcherResourceManagerComponent create(
            Configuration configuration,
            Executor ioExecutor,
            RpcService rpcService,
            HighAvailabilityServices highAvailabilityServices,
            BlobServer blobServer,
            HeartbeatServices heartbeatServices,
            MetricRegistry metricRegistry,
            ExecutionGraphInfoStore executionGraphInfoStore,
            MetricQueryServiceRetriever metricQueryServiceRetriever,
            FatalErrorHandler fatalErrorHandler)
            throws Exception {

        LeaderRetrievalService dispatcherLeaderRetrievalService = null;
        LeaderRetrievalService resourceManagerRetrievalService = null;
        WebMonitorEndpoint<?> webMonitorEndpoint = null;
        ResourceManagerService resourceManagerService = null;
        DispatcherRunner dispatcherRunner = null;

        try {
            dispatcherLeaderRetrievalService =
                    highAvailabilityServices.getDispatcherLeaderRetriever();

            resourceManagerRetrievalService =
                    highAvailabilityServices.getResourceManagerLeaderRetriever();

            final LeaderGatewayRetriever<DispatcherGateway> dispatcherGatewayRetriever =
                    new RpcGatewayRetriever<>(
                            rpcService,
                            DispatcherGateway.class,
                            DispatcherId::fromUuid,
                            new ExponentialBackoffRetryStrategy(
                                    12, Duration.ofMillis(10), Duration.ofMillis(50)));

            final LeaderGatewayRetriever<ResourceManagerGateway> resourceManagerGatewayRetriever =
                    new RpcGatewayRetriever<>(
                            rpcService,
                            ResourceManagerGateway.class,
                            ResourceManagerId::fromUuid,
                            new ExponentialBackoffRetryStrategy(
                                    12, Duration.ofMillis(10), Duration.ofMillis(50)));

            final ScheduledExecutorService executor =
                    WebMonitorEndpoint.createExecutorService(
                            configuration.getInteger(RestOptions.SERVER_NUM_THREADS),
                            configuration.getInteger(RestOptions.SERVER_THREAD_PRIORITY),
                            "DispatcherRestEndpoint");

            final long updateInterval =
                    configuration.getLong(MetricOptions.METRIC_FETCHER_UPDATE_INTERVAL);
            final MetricFetcher metricFetcher =
                    updateInterval == 0
                            ? VoidMetricFetcher.INSTANCE
                            : MetricFetcherImpl.fromConfiguration(
                                    configuration,
                                    metricQueryServiceRetriever,
                                    dispatcherGatewayRetriever,
                                    executor);

            webMonitorEndpoint =
                    restEndpointFactory.createRestEndpoint(
                            configuration,
                            dispatcherGatewayRetriever,
                            resourceManagerGatewayRetriever,
                            blobServer,
                            executor,
                            metricFetcher,
                            highAvailabilityServices.getClusterRestEndpointLeaderElectionService(),
                            fatalErrorHandler);

            log.debug("Starting Dispatcher REST endpoint.");
            webMonitorEndpoint.start();

            final String hostname = RpcUtils.getHostname(rpcService);

            resourceManagerService =
                    ResourceManagerServiceImpl.create(
                            resourceManagerFactory,
                            configuration,
                            rpcService,
                            highAvailabilityServices,
                            heartbeatServices,
                            fatalErrorHandler,
                            new ClusterInformation(hostname, blobServer.getPort()),
                            webMonitorEndpoint.getRestBaseUrl(),
                            metricRegistry,
                            hostname,
                            ioExecutor);

            final HistoryServerArchivist historyServerArchivist =
                    HistoryServerArchivist.createHistoryServerArchivist(
                            configuration, webMonitorEndpoint, ioExecutor);

            final PartialDispatcherServices partialDispatcherServices =
                    new PartialDispatcherServices(
                            configuration,
                            highAvailabilityServices,
                            resourceManagerGatewayRetriever,
                            blobServer,
                            heartbeatServices,
                            () ->
                                    JobManagerMetricGroup.createJobManagerMetricGroup(
                                            metricRegistry, hostname),
                            executionGraphInfoStore,
                            fatalErrorHandler,
                            historyServerArchivist,
                            metricRegistry.getMetricQueryServiceGatewayRpcAddress(),
                            ioExecutor);

            log.debug("Starting Dispatcher.");
            dispatcherRunner =
                    dispatcherRunnerFactory.createDispatcherRunner(
                            highAvailabilityServices.getDispatcherLeaderElectionService(),
                            fatalErrorHandler,
                            new HaServicesJobGraphStoreFactory(highAvailabilityServices),
                            ioExecutor,
                            rpcService,
                            partialDispatcherServices);

            log.debug("Starting ResourceManagerService.");
            resourceManagerService.start();

            resourceManagerRetrievalService.start(resourceManagerGatewayRetriever);
            dispatcherLeaderRetrievalService.start(dispatcherGatewayRetriever);

            return new DispatcherResourceManagerComponent(
                    dispatcherRunner,
                    resourceManagerService,
                    dispatcherLeaderRetrievalService,
                    resourceManagerRetrievalService,
                    webMonitorEndpoint,
                    fatalErrorHandler);

        } catch (Exception exception) {
            // clean up all started components
            if (dispatcherLeaderRetrievalService != null) {
                try {
                    dispatcherLeaderRetrievalService.stop();
                } catch (Exception e) {
                    exception = ExceptionUtils.firstOrSuppressed(e, exception);
                }
            }

            if (resourceManagerRetrievalService != null) {
                try {
                    resourceManagerRetrievalService.stop();
                } catch (Exception e) {
                    exception = ExceptionUtils.firstOrSuppressed(e, exception);
                }
            }

            final Collection<CompletableFuture<Void>> terminationFutures = new ArrayList<>(3);

            if (webMonitorEndpoint != null) {
                terminationFutures.add(webMonitorEndpoint.closeAsync());
            }

            if (resourceManagerService != null) {
                terminationFutures.add(resourceManagerService.closeAsync());
            }

            if (dispatcherRunner != null) {
                terminationFutures.add(dispatcherRunner.closeAsync());
            }

            final FutureUtils.ConjunctFuture<Void> terminationFuture =
                    FutureUtils.completeAll(terminationFutures);

            try {
                terminationFuture.get();
            } catch (Exception e) {
                exception = ExceptionUtils.firstOrSuppressed(e, exception);
            }

            throw new FlinkException(
                    "Could not create the DispatcherResourceManagerComponent.", exception);
        }
    }
```

在上面的方法实现中，Master 中的两个重要服务就是在这里初始化并启动的：

1.  `Dispatcher`: 初始化并启动这个服务，如果 JM 启动了 HA 模式，这里会竞选 leader，只有是 leader 的 `Dispatcher` 才会真正对外提供服务（参考前面图中的流程）；
2.  `ResourceManager`: 这个跟 `Dispatcher` 有点类似。

### Master 各个服务详解

这里，我们来详细看下 Master 使用到各个服务组件，并做下详细的介绍。

### DefaultDispatcherRunner

**DefaultDispatcherRunner** 主要是用于作业的提交、并把它们持久化、为作业创建对应的 JobManager 等，Client 端提交的 JobGraph 就是提交给了 Dispatcher 服务，这里先看一下一个 Dispatcher 对象被选举为 leader 后是如何初始化的，如果当前的 Dispatcher 被选举为 leader，则会调用其 `grantLeadership()` 方法，该方法实现如下：

1  

```
//DefaultDispatcherRunner


 // ---------------------------------------------------------------
    // Leader election
    // ---------------------------------------------------------------

    @Override
    public void grantLeadership(UUID leaderSessionID) {
        runActionIfRunning(
                () -> {
                    LOG.info(
                            "{} was granted leadership with leader id {}. Creating new {}.",
                            getClass().getSimpleName(),
                            leaderSessionID,
                            DispatcherLeaderProcess.class.getSimpleName());
                    startNewDispatcherLeaderProcess(leaderSessionID);
                });
    }

    private void startNewDispatcherLeaderProcess(UUID leaderSessionID) {
        stopDispatcherLeaderProcess();

        dispatcherLeaderProcess = createNewDispatcherLeaderProcess(leaderSessionID);

        final DispatcherLeaderProcess newDispatcherLeaderProcess = dispatcherLeaderProcess;
        FutureUtils.assertNoException(
                previousDispatcherLeaderProcessTerminationFuture.thenRun(
                        newDispatcherLeaderProcess::start));
    }
```

Dispatcher 被选举为 leader 后，它主要的操作步骤如下：

1. forwardShutDownFuture
2. forwardConfirmLeaderSessionFuture
3. SessionDispatcherLeaderProcess中取恢复之前的job

我们这里再详细看下 Dispatcher 对外提供了哪些 API 实现（这些接口主要还是 `DispatcherGateway` 中必须要实现的接口），通过这些 API，其实就很容易看出它到底对外提供了哪些功能，提供的 API 有：

1.  `listJobs()`: 列出当前提交的作业列表；
2.  `submitJob()`: 向集群提交作业；
3.  `getBlobServerPort()`: 返回 blob server 的端口；
4.  `requestJob()`: 根据 jobId 请求一个作业的 ArchivedExecutionGraph（它是这个作业 ExecutionGraph 序列化后的形式）；
5.  `disposeSavepoint()`: 清理指定路径的 savepoint 状态信息；
6.  `cancelJob()`: 取消一个指定的作业；
7.  `requestClusterOverview()`: 请求这个集群的全局信息，比如：集群有多少个 slot，有多少可用的 slot，有多少个作业等等；
8.  `requestMultipleJobDetails()`: 返回当前集群正在执行的作业详情，返回对象是 JobDetails 列表；
9.  `requestJobStatus()`: 请求一个作业的作业状态（返回的类型是 `JobStatus`）；
10.  `requestOperatorBackPressureStats()`: 请求一个 Operator 的反压情况；
11.  `requestJobResult()`: 请求一个 job 的 `JobResult`；
12.  `requestMetricQueryServiceAddresses()`: 请求 MetricQueryService 的地址；
13.  `requestTaskManagerMetricQueryServiceAddresses()`: 请求 TaskManager 的 MetricQueryService 的地址；
14.  `triggerSavepoint()`: 使用指定的目录触发一个 savepoint；
15.  `stopWithSavepoint()`: 停止当前的作业，并在停止前做一次 savepoint；
16.  `shutDownCluster()`: 关闭集群；

通过 Dispatcher 提供的 API 可以看出，Dispatcher 服务主要有功能有：

1.  提交/取消作业；
2.  触发/取消/清理 一个作业的 savepoint；
3.  作业状态/列表查询；

Dispatcher 这里主要处理的还是 Job 相关的请求，对外提供了统一的接口。

###  ResourceManagerServiceImpl

ResourceManagerServiceImpl 从名字就可以看出，它主要是资源管理相关的服务，如果其被选举为 leader，实现如下，它会清除缓存中的数据，然后启动 SlotManager 服务：

```
//LeaderContender
//
@Override
    public void grantLeadership(UUID newLeaderSessionID) {
        handleLeaderEventExecutor.execute(
                () -> {
                    synchronized (lock) {
                        if (!running) {
                            LOG.info(
                                    "Resource manager service is not running. Ignore granting leadership with session ID {}.",
                                    newLeaderSessionID);
                            return;
                        }

                        LOG.info(
                                "Resource manager service is granted leadership with session id {}.",
                                newLeaderSessionID);

                        try {
                            startNewLeaderResourceManager(newLeaderSessionID);
                        } catch (Throwable t) {
                            fatalErrorHandler.onFatalError(
                                    new FlinkException("Cannot start resource manager.", t));
                        }
                    }
                });
    }

@GuardedBy("lock")
    private void startNewLeaderResourceManager(UUID newLeaderSessionID) throws Exception {
        stopLeaderResourceManager();

        this.leaderSessionID = newLeaderSessionID;
        this.leaderResourceManager =
                resourceManagerFactory.createResourceManager(
                        rmProcessContext, newLeaderSessionID, ResourceID.generate());

        final ResourceManager<?> newLeaderResourceManager = this.leaderResourceManager;

        previousResourceManagerTerminationFuture
                .thenComposeAsync(
                        (ignore) -> {
                            synchronized (lock) {
                                return startResourceManagerIfIsLeader(newLeaderResourceManager);
                            }
                        },
                        handleLeaderEventExecutor)
                .thenAcceptAsync(
                        (isStillLeader) -> {
                            if (isStillLeader) {
                                leaderElectionService.confirmLeadership(
                                        newLeaderSessionID, newLeaderResourceManager.getAddress());
                            }
                        },
                        ioExecutor);
    }

    /**
     * Returns a future that completes as {@code true} if the resource manager is still leader and
     * started, and {@code false} if it's no longer leader.
     */
    @GuardedBy("lock")
    private CompletableFuture<Boolean> startResourceManagerIfIsLeader(
            ResourceManager<?> resourceManager) {
        if (isLeader(resourceManager)) {
            resourceManager.start();
            forwardTerminationFuture(resourceManager);
            return resourceManager.getStartedFuture().thenApply(ignore -> true);
        } else {
            return CompletableFuture.completedFuture(false);
        }
    }

    private void forwardTerminationFuture(ResourceManager<?> resourceManager) {
        resourceManager
                .getTerminationFuture()
                .whenComplete(
                        (ignore, throwable) -> {
                            synchronized (lock) {
                                if (isLeader(resourceManager)) {
                                    if (throwable != null) {
                                        serviceTerminationFuture.completeExceptionally(throwable);
                                    } else {
                                        serviceTerminationFuture.complete(null);
                                    }
                                }
                            }
                        });
    }

    @GuardedBy("lock")
    private boolean isLeader(ResourceManager<?> resourceManager) {
        return running && this.leaderResourceManager == resourceManager;
    }
```

这里也来看下 ResourceManager 对外提供的 API（`ResourceManagerGateway` 相关方法的实现）：

1.  `registerJobManager()`: 在 ResourceManager 中注册一个 `JobManager` 对象，一个作业启动后，JobManager 初始化后会调用这个方法；
2.  `registerTaskExecutor()`: 在 ResourceManager 中注册一个 `TaskExecutor`（`TaskExecutor` 实际上就是一个 TaskManager），当一个 TaskManager 启动后，会主动向 ResourceManager 注册；
3.  `sendSlotReport()`: TM 向 ResourceManager 发送 `SlotReport`（`SlotReport` 包含了这个 TaskExecutor 的所有 slot 状态信息，比如：哪些 slot 是可用的、哪些 slot 是已经被分配的、被分配的 slot 分配到哪些 Job 上了等）；
4.  `heartbeatFromTaskManager()`: 向 ResourceManager 发送来自 TM 的心跳信息；
5.  `heartbeatFromJobManager()`: 向 ResourceManager 发送来自 JM 的心跳信息；
6.  `disconnectTaskManager()`: TM 向 ResourceManager 发送一个断开连接的请求；
7.  `disconnectJobManager()`: JM 向 ResourceManager 发送一个断开连接的请求；
8.  `requestSlot()`: JM 向 ResourceManager 请求 slot 资源；
9.  `cancelSlotRequest()`: JM 向 ResourceManager 发送一个取消 slot 申请的请求；
10.  `notifySlotAvailable()`: TM 向 ResourceManager 发送一个请求，通知 ResourceManager 某个 slot 现在可用了（TM 端某个 slot 的资源被释放，可以再进行分配了）；
11.  `deregisterApplication()`: 向资源管理系统（比如：yarn、mesos）申请关闭当前的 Flink 集群，一般是在关闭集群的时候调用的；
12.  `requestTaskManagerInfo()`: 请求当前注册到 ResourceManager 的 TM 的详细信息（返回的类型是 `TaskManagerInfo`，可以请求的是全部的 TM 列表，也可以是根据某个 `ResourceID` 请求某个具体的 TM）；
13.  `requestResourceOverview()`: 向 ResourceManager 请求资源概况，返回的类型是 `ResourceOverview`，它包括注册的 TM 数量、注册的 slot 数、可用的 slot 数等；
14.  `requestTaskManagerMetricQueryServiceAddresses()`: 请求 TM MetricQueryService 的地址信息；
15.  `requestTaskManagerFileUpload()`: 向 TM 发送一个文件上传的请求，这里上传的是 TM 的 LOG/STDOUT 类型的文件，文件会上传到 Blob Server，这里会拿到一个 BlobKey（Blobkey 实际上是文件名的一部分，通过 BlobKey 可以确定这个文件的物理位置信息）；

从上面的 API 列表中，可以看出 ResourceManager 的主要功能是：

1.  JobManager/TaskManager 资源的注册/心跳监控/连接断开的处理；
2.  处理/取消 JM 资源（slot）的申请；
3.  提供资源信息查询；
4.  向 TM 发送请求，触发其 LOG/STDOUT 文件上传到 BlobServer；

ResourceManager 在启动的时候，也会启动一个 SlotManager 服务，TM 相关的 slot 资源都是在 SlotManager 中维护的。

#### SlotManager

SlotManager 会维护所有从 TaskManager 注册过来的 slot（包括它们的分配情况）以及所有 pending 的 SlotRequest（所有的 slot 请求都会先放到 pending 列表中，然后再去判断是否可以满足其资源需求）。只要有新的 slot 注册或者旧的 slot 资源释放，SlotManager 都会检测 pending SlotRequest 列表，检查是否有 SlotRequest 可以满足，如果可以满足，就会将资源分配给这个 SlotRequest；如果没有足够可用的 slot，SlotManager 会尝试着申请新的资源（比如：申请一个 worker 启动）。

当然，为了资源及时释放和避免资源浪费，空转的 task manager（它当前已经分配的 slot 并未使用）和 pending slot request 在 timeout 之后将会分别触发它们的释放和失败（对应的方法实现是 `checkTaskManagerTimeouts()` 和 `checkSlotRequestTimeouts()`）。

SlotManager 对外的提供的 API 如下（`SlotManager` 中必须要实现的接口，实现类是 `SlotManagerImpl`）：

1.  `getNumberRegisteredSlots()`: 获取注册的 slot 的总数量；
2.  `getNumberRegisteredSlotsOf()`: 获取某个 TM 注册的 slot 的数量；
3.  `getNumberFreeSlots()`: 获取当前可用的（还未分配的 slot） slot 的数量；
4.  `getNumberFreeSlotsOf()`: 获取某个 TM 当前可用的 slot 的数量；
5.  `getNumberPendingTaskManagerSlots()`: 获取 `pendingSlots` 中 slot 的数量（`pendingSlots` 记录的是 SlotManager 主动去向资源管理系统申请的资源，该系统在一些情况下会新启动 worker 来创建资源，但这些slot 还没有主动汇报过来，就会暂时先放到 `pendingSlots` 中，如果 TM 过来注册的话，该 slot 就会从 pendingSlots 中移除，存储到其他对象中）；
6.  `getNumberPendingSlotRequests()`: 获取 `pendingSlotRequests` 列表的数量，这个集合中存储的是收到的、还没分配的 SlotRequest 列表，当一个 SlotRequest 发送过来之后，会先存储到这个集合中，当分配完成后，才会从这个集合中移除；
7.  `registerSlotRequest()`: JM 发送一个 slot 请求（这里是 ResourceManager 通过 `requestSlot()` 接口调用的）；
8.  `unregisterSlotRequest()`: 取消或移除一个正在排队（可能已经在处理中）的 SlotRequest；
9.  `registerTaskManager()`: 注册一个 TM，这里会将 TM 中所有的 slot 注册过来，等待后面分配；
10.  `unregisterTaskManager()`: 取消一个 TM 的注册（比如：关闭的时候可能会调用），这里会将这个 TM 上所有的 slot 都移除，会先从缓存中移除，然后再通知 JM 这个 slot 分配失败；
11.  `reportSlotStatus()`: TM 汇报当前 slot 分配的情况，SlotManager 会将其更新到自己的缓存中；
12.  `freeSlot()`: 释放一个指定的 slot，如果这个 slot 之前已经被分配出去了，这里会更新其状态，将其状态改为 `FREE`；
13.  `setFailUnfulfillableRequest()`: 遍历 `pendingSlotRequests` 列表，如果这些 slot 请求现在还分配不到合适的资源，这里会将其设置为 fail，会通知 JM slot 分配失败。

同样，从上面的 API 列表中，总结一下 SlotManager 的功能：

1.  提供 slot 相关的信息查询；
2.  处理/取消 JM 发送的 SlotRequest；
3.  注册/取消 一个 TM（该 TM 涉及到的所有 slot 都会被注册或取消）；
4.  Slot 资源的释放；

### 其他服务

Master 除了上面的服务，还启动了其他的服务，这里简单列一下：

1.  `BlobServer`: 它是 Flink 用来管理二进制大文件的服务，Flink JobManager 中启动的 BlobServer 负责监听请求并派发线程去处理（这个将会在下篇文章中讲述）；
2.  `JobManager`: Dispatcher 会为每个作业创建一个 JobManager 对象，它用来处理这个作业相关的协调工作，比如：task 的调度、Checkpoint 的触发及失败恢复等（这个也会在下篇文章中讲述）；
3.  `HA service`: Flink HA 的实现目前是依赖了 ZK，使用 `curator` 这个包来实现的，有兴趣的可以看下 [Curator leader 选举(一)](https://www.cnblogs.com/francisYoung/p/5464789.html) 这篇文章。

## 小节

到这里，终于就把 Flink Master 相关内容的一部分梳理完了，这里简单总结一下：

1.  **Dispatcher**: 负责接收用户提供的作业，并且负责为这个新提交的作业拉起一个新的 JobManager 组件，它主要还是处理 Job 相关的请求，对外提供了统一的接口抽象；
2.  **ResourceManager**: 负责资源的管理，所有资源相关的请求都是 ResourceManager 中处理的；
3.  **JobManager**: 负责管理具体作业的执行；

Flink Master 这部分的抽象还是比较好的，三大组件各司其职。当然还有一些需要改善的地方，比如：为什么不抽象一个 Master 类，然后把这些子服务全都放到 Master 类里，这样代码看起来会清晰舒服很多，现在的代码对初学者其实并不友好。

___

参考

-   [Jobs and Scheduling](https://ci.apache.org/projects/flink/flink-docs-release-1.9/internals/job_scheduling.html)；
-   [FLIP-6 - Flink Deployment and Process Model - Standalone, Yarn, Mesos, Kubernetes, etc](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=65147077)；
-   [Apache Flink 进阶（一）：Runtime 核心机制剖析](https://mp.weixin.qq.com/s/TBzzGTNFTzVLjFQdzz-LuQ)；
-   [FLINK 高可用服务概览与改造](https://zhuanlan.zhihu.com/p/89537466?utm_source=wechat_session&utm_medium=social&utm_oi=1052584028930203648);
-   [Flink JobManager 基本组件](http://chenyuzhao.me/2017/02/08/jobmanager%E5%9F%BA%E6%9C%AC%E7%BB%84%E4%BB%B6/)；

