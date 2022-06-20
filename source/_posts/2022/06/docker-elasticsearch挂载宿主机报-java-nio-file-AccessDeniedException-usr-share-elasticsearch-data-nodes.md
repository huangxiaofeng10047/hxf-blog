---
title: >-
  docker elasticsearch挂载宿主机报 java.nio.file.AccessDeniedException:
  /usr/share/elasticsearch/data/nodes
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-17 11:30:30
tags:
---

```jsx
docker run --name elasticsearch -p 9200:9200 -p 9300:9300  -e "discovery.type=single-node" -e ES_JAVA_OPTS="-Xms64m -Xmx128m" -v /disk02/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml -v /disk02/elasticsearch/data:/usr/share/elasticsearch/data -v /disk02/elasticsearch/plugins:/usr/share/elasticsearch/plugins -it elasticsearch:7.6.2
```



抛出异常

```
ElasticsearchException[failed to bind service]; nested: AccessDeniedException[/usr/share/elasticsearch/data/nodes];
Likely root cause: java.nio.file.AccessDeniedException: /usr/share/elasticsearch/data/nodes
    at java.base/sun.nio.fs.UnixException.translateToIOException(UnixException.java:90)
    at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:111)
    at java.base/sun.nio.fs.UnixException.rethrowAsIOException(UnixException.java:116)
    at java.base/sun.nio.fs.UnixFileSystemProvider.createDirectory(UnixFileSystemProvider.java:389)
    at java.base/java.nio.file.Files.createDirectory(Files.java:693)
    at java.base/java.nio.file.Files.createAndCheckIsDirectory(Files.java:800)
    at java.base/java.nio.file.Files.createDirectories(Files.java:786)
    at org.elasticsearch.env.NodeEnvironment.lambda$new$0(NodeEnvironment.java:274)
    at org.elasticsearch.env.NodeEnvironment$NodeLock.<init>(NodeEnvironment.java:211)
    at org.elasticsearch.env.NodeEnvironment.<init>(NodeEnvironment.java:271)
    at org.elasticsearch.node.Node.<init>(Node.java:277)
    at org.elasticsearch.node.Node.<init>(Node.java:257)
    at org.elasticsearch.bootstrap.Bootstrap$5.<init>(Bootstrap.java:221)
    at org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:221)
    at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:349)
    at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:170)
    at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:161)
    at org.elasticsearch.cli.EnvironmentAwareCommand.execute(EnvironmentAwareCommand.java:86)
    at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:125)
    at org.elasticsearch.cli.Command.main(Command.java:90)
    at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:126)
    at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:92)
For complete error details, refer to the log at /usr/share/elasticsearch/logs/elasticsearch.log
```

解决办法：
chmod 777 /disk02/elasticsearch/data
