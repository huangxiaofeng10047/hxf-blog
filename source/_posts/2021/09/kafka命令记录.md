---
title: kafka命令记录
date: 2021-09-26 17:28:20
tags:
- kafka
categories: 
- bigdata
---

```shell
##消费
kafka-console-consumer --bootstrap-server 10.11.5.11:9092,10.11.5.12:9092,10.11.5.13:9092 --topic kafka_sparkstreaming_kudu_topic -group flume-consumer   --from-beginning
##生产者
 kafka-console-producer --broker-list cdh2:9092,cdh3:9092,cdh4:9092 --topic flink_test
 ##查看topic
 kafka-topics --list --zookeeper 10.11.5.11:2181
```

