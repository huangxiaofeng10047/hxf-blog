---
title: 如何使用Flume采集Kafka数据写入Kudu
date: 2021-09-26 17:08:25
tags:
- bigdata
categories: 
- java
---

- 前置条件

1.Flume已安装

2.Kudu与Impala服务已安装

3.Kudu与Impala已集成

4.集群未启用Kerberos

**2.环境准备**

___

1.下载kudu-flume-sink依赖包，地址如下

https://repository.cloudera.com/artifactory/cloudera\-repos/org/apache/kudu/kudu\-flume\-sink/1.4.0\-cdh5.12.1/kudu\-flume\-sink\-1.4.0\-cdh5.12.1.jar

（可左右滑动）

<!--more-->

2.将下载的依赖包部署在集群所有节点的/opt/cloudera/parcels/CDH/lib/flume-ng/lib/目录下

\[root@cdh01 shell\]\# sh bk\_cp.sh node.list /root/kudu\-flume\-sink\-1.4.0\-cdh5.12.1.jar /opt/cloudera/parcels/CDH/lib/flume\-ng/lib/

（可左右滑动）

3.准备向Kafka发送数据的脚本

![image-20210926171549035](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926171549035.png)

这里脚本Fayson就不在详细说明了，前面的文章及Github上均有说明：

https://github.com/fayson/cdhproject/tree/master/kafkademo/0283\-kafka\-shell

（可左右滑动）

4.通过Hue创建Kudu测试表

```
CREATE TABLE ods\_deal\_daily\_kudu (
  id STRING COMPRESSION snappy,
  name STRING COMPRESSION snappy,
  sex STRING COMPRESSION snappy,
  city STRING COMPRESSION snappy,
  occupation STRING COMPRESSION snappy,
  mobile\_phone\_num STRING COMPRESSION snappy,
  fix\_phone\_num STRING COMPRESSION snappy,
  bank\_name STRING COMPRESSION snappy,
  address STRING COMPRESSION snappy,
  marriage STRING COMPRESSION snappy,
  child\_num INT COMPRESSION snappy,
  PRIMARY KEY (id)
)
  PARTITION BY HASH PARTITIONS 6
STORED AS KUDU;
```

（可左右滑动）

![image-20210926171802108](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926171802108.png)

**请注意，一定要是impala引擎。**

**3.开发KuduSink**

___

在kudu的官网默认支持KuduSink，但KuduSink不是特别灵活，像Fayson的这个示例中，向Kafka发送的是JSON数据，但默认KuduOperationsProducer支持的数据解析有限，支持正则表达式的方式，但对于Fayson来说写正则表达式比较头疼，因此这里写一个自定义的JsonKuduOperationsProducer。

1\. 创建一个Maven工程flume-sink

2.添加flume-sink工程依赖

```
<properties\>
    <project.build.sourceEncoding\>UTF\-8</project.build.sourceEncoding\>
    <maven.compiler.source\>1.7</maven.compiler.source\>
    <maven.compiler.target\>1.7</maven.compiler.target\>
    <avro.version\>1.8.1</avro.version\>
    <flume.version\>1.6.0</flume.version\>
    <hadoop.version\>2.6.0\-cdh5.11.2</hadoop.version\>
    <kudu.version\>1.4.0\-cdh5.12.1</kudu.version\>
    <slf4j.version\>1.7.12</slf4j.version\>
</properties\>
<dependencies\>
    <dependency\>
        <groupId\>org.apache.kudu</groupId\>
        <artifactId\>kudu\-client</artifactId\>
        <version\>${kudu.version}</version\>
    </dependency\>
    <dependency\>
        <groupId\>org.apache.flume</groupId\>
        <artifactId\>flume\-ng\-core</artifactId\>
        <version\>${flume.version}</version\>
        <scope\>provided</scope\>
    </dependency\>
    <dependency\>
        <groupId\>org.apache.flume</groupId\>
        <artifactId\>flume\-ng\-configuration</artifactId\>
        <version\>${flume.version}</version\>
        <scope\>provided</scope\>
    </dependency\>
    <dependency\>
        <groupId\>org.apache.avro</groupId\>
        <artifactId\>avro</artifactId\>
        <version\>${avro.version}</version\>
        <scope\>provided</scope\>
    </dependency\>
    <dependency\>
        <groupId\>org.apache.hadoop</groupId\>
        <artifactId\>hadoop\-client</artifactId\>
        <version\>${hadoop.version}</version\>
        <scope\>provided</scope\>
    </dependency\>
    <dependency\>
        <groupId\>org.slf4j</groupId\>
        <artifactId\>slf4j\-api</artifactId\>
        <version\>${slf4j.version}</version\>
        <scope\>provided</scope\>
    </dependency\>
    <dependency\>
        <groupId\>org.apache.kudu</groupId\>
        <artifactId\>kudu\-flume\-sink</artifactId\>
        <version\>1.4.0\-cdh5.12.1</version\>
    </dependency\>
</dependencies\>
```

（可左右滑动）

3.新建JSON字符串解析工具类JsonStr2Map.java，将Json字符串解析为Map对象

```
package com.cloudera.utils;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class JsonStr2Map {
    public static Map<String, String\> jsonStr2Map(String jsonStr) {
        Map<String, String\> resultMap \= new HashMap<\>();
        Pattern pattern \= Pattern.compile("(\\"\\\\w+\\"):(\\"\[^\\"\]+\\")");
        Matcher m \= pattern.matcher(jsonStr);
        String\[\] strs \= null;
        while (m.find()) {
            strs \= m.group().split(":");
            if(strs != null && strs.length \== 2) {
                resultMap.put(strs\[0\].replaceAll("\\"", "").trim(), strs\[1\].trim().replaceAll("\\"", ""));
            }
        }
        return resultMap;
}
}
```

（可左右滑动）

4.创建JsonKuduOperationsProducer.java用于处理Json字符串写入Kudu

```
package com.cloudera.kudu;
import com.google.common.collect.Lists;
import com.cloudera.utils.JsonStr2Map;
import com.google.common.base.Preconditions;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.FlumeException;
import org.apache.flume.annotations.InterfaceAudience;
import org.apache.flume.annotations.InterfaceStability;
import org.apache.kudu.ColumnSchema;
import org.apache.kudu.Schema;
import org.apache.kudu.Type;
import org.apache.kudu.client.KuduTable;
import org.apache.kudu.client.Operation;
import org.apache.kudu.client.PartialRow;
import org.apache.kudu.flume.sink.KuduOperationsProducer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.nio.charset.Charset;
import java.util.List;
import java.util.Map;

@InterfaceAudience.Public
@InterfaceStability.Evolving
public class JsonKuduOperationsProducer implements KuduOperationsProducer {
    private static final Logger logger \= LoggerFactory.getLogger(JsonKuduOperationsProducer.class);
    private static final String INSERT \= "insert";
    private static final String UPSERT \= "upsert";
    private static final List<String\> validOperations \= Lists.newArrayList(UPSERT, INSERT);
    public static final String ENCODING\_PROP \= "encoding";
    public static final String DEFAULT\_ENCODING \= "utf-8";
    public static final String OPERATION\_PROP \= "operation";
    public static final String DEFAULT\_OPERATION \= UPSERT;
    public static final String SKIP\_MISSING\_COLUMN\_PROP \= "skipMissingColumn";
    public static final boolean DEFAULT\_SKIP\_MISSING\_COLUMN \= false;
    public static final String SKIP\_BAD\_COLUMN\_VALUE\_PROP \= "skipBadColumnValue";
    public static final boolean DEFAULT\_SKIP\_BAD\_COLUMN\_VALUE \= false;
    public static final String WARN\_UNMATCHED\_ROWS\_PROP \= "skipUnmatchedRows";
    public static final boolean DEFAULT\_WARN\_UNMATCHED\_ROWS \= true;
    private KuduTable table;
    private Charset charset;
    private String operation;
    private boolean skipMissingColumn;
    private boolean skipBadColumnValue;
    private boolean warnUnmatchedRows;
    public JsonKuduOperationsProducer() {
    }
    @Override
    public void configure(Context context) {
        String charsetName \= context.getString(ENCODING\_PROP, DEFAULT\_ENCODING);
        try {
            charset \= Charset.forName(charsetName);
        } catch (IllegalArgumentException e) {
            throw new FlumeException(
                    String.format("Invalid or unsupported charset %s", charsetName), e);
        }
        operation \= context.getString(OPERATION\_PROP, DEFAULT\_OPERATION).toLowerCase();
        Preconditions.checkArgument(
                validOperations.contains(operation),
                "Unrecognized operation '%s'",
                operation);
        skipMissingColumn \= context.getBoolean(SKIP\_MISSING\_COLUMN\_PROP,
                DEFAULT\_SKIP\_MISSING\_COLUMN);
        skipBadColumnValue \= context.getBoolean(SKIP\_BAD\_COLUMN\_VALUE\_PROP,
                DEFAULT\_SKIP\_BAD\_COLUMN\_VALUE);
        warnUnmatchedRows \= context.getBoolean(WARN\_UNMATCHED\_ROWS\_PROP,
                DEFAULT\_WARN\_UNMATCHED\_ROWS);
    }
    @Override
    public void initialize(KuduTable table) {
        this.table \= table;
    }
    @Override
    public List<Operation\> getOperations(Event event) throws FlumeException {
        String raw \= new String(event.getBody(), charset);
        Map<String, String\> rawMap \= JsonStr2Map.jsonStr2Map(raw);
        Schema schema \= table.getSchema();
        List<Operation\> ops \= Lists.newArrayList();
        if(raw != null && !raw.isEmpty()) {
            Operation op;
            switch (operation) {
                case UPSERT:
                    op \= table.newUpsert();
                    break;
                case INSERT:
                    op \= table.newInsert();
                    break;
                default:
                    throw new FlumeException(
                            String.format("Unrecognized operation type '%s' in getOperations(): " +
                                    "this should never happen!", operation));
            }
            PartialRow row \= op.getRow();
            for (ColumnSchema col : schema.getColumns()) {
                logger.error("Column:" + col.getName() + "----" + rawMap.get(col.getName()));
                try {
                    coerceAndSet(rawMap.get(col.getName()), col.getName(), col.getType(), row);
                } catch (NumberFormatException e) {
                    String msg \= String.format(
                            "Raw value '%s' couldn't be parsed to type %s for column '%s'",
                            raw, col.getType(), col.getName());
                    logOrThrow(skipBadColumnValue, msg, e);
                } catch (IllegalArgumentException e) {
                    String msg \= String.format(
                            "Column '%s' has no matching group in '%s'",
                            col.getName(), raw);
                    logOrThrow(skipMissingColumn, msg, e);
                } catch (Exception e) {
                    throw new FlumeException("Failed to create Kudu operation", e);
                }
            }
            ops.add(op);
        }
        return ops;
    }
    

    private void coerceAndSet(String rawVal, String colName, Type type, PartialRow row)
            throws NumberFormatException {
        switch (type) {
            case INT8:
                row.addByte(colName, Byte.parseByte(rawVal));
                break;
            case INT16:
                row.addShort(colName, Short.parseShort(rawVal));
                break;
            case INT32:
                row.addInt(colName, Integer.parseInt(rawVal));
                break;
            case INT64:
                row.addLong(colName, Long.parseLong(rawVal));
                break;
            case BINARY:
                row.addBinary(colName, rawVal.getBytes(charset));
                break;
            case STRING:
                row.addString(colName, rawVal\==null?"":rawVal);
                break;
            case BOOL:
                row.addBoolean(colName, Boolean.parseBoolean(rawVal));
                break;
            case FLOAT:
                row.addFloat(colName, Float.parseFloat(rawVal));
                break;
            case DOUBLE:
                row.addDouble(colName, Double.parseDouble(rawVal));
                break;
            case UNIXTIME\_MICROS:
                row.addLong(colName, Long.parseLong(rawVal));
                break;
            default:
                logger.warn("got unknown type {} for column '{}'-- ignoring this column", type, colName);
        }
    }
    private void logOrThrow(boolean log, String msg, Exception e)
            throws FlumeException {
        if (log) {
            logger.warn(msg, e);
        } else {
            throw new FlumeException(msg, e);
        }
    }
    @Override
    public void close() {
    }

}
```

（可左右滑动）

5.将开发好的代码使用mvn命令打包

`mvn clean package`

将打包好的flume-sink-1.0-SNAPSHOT.jar部署到集群所有节点的/opt/cloudera/parcels/CDH/lib/flume-ng/lib目录下（需要放在flume推荐的目录下）如下图

所示

![image-20210926172243775](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926172243775.png)

只有上面的方式，flume才能识别到自定义的jar包：

`[root@cdh01 shell]# sh bk_cp.sh node.list /root/flume-sink-1.0-SNAPSHOT.jar /usr/lib/flume-ng/plugins.d/custom-source-1/lib`

（可左右滑动）

**4.配置Flume Agent**

___

1.登录CM，进flume服务界面，点击“配置”

2.在Agent类别的“配置文件”中输入如下内容：

```
kafka.sources  = source1
kafka.channels = channel1
kafka.sinks = sink1
kafka.sources.source1.type = org.apache.flume.source.kafka.KafkaSource
kafka.sources.source1.kafka.bootstrap.servers = cdh01.fayson.com:9092,cdh02.fayson.com:9092,cdh03.fayson.com:9092
kafka.sources.source1.kafka.topics = kafka_sparkstreaming_kudu_topic
kafka.sources.source1.kafka.consumer.group.id = flume-consumer
kafka.sources.source1.channels = channel1
kafka.channels.channel1.type = memory
kafka.channels.channel1.capacity = 10000
kafka.channels.channel1.transactionCapacity = 1000
kafka.sinks.sink1.type = org.apache.kudu.flume.sink.KuduSink
kafka.sinks.sink1.masterAddresses = cdh01.fayson.com,cdh02.fayson.com,cdh03.fayson.com
kafka.sinks.sink1.tableName = impala::default.ods_deal_daily_kudu
kafka.sinks.sink1.channel = channel1
kafka.sinks.sink1.batchSize = 50
kafka.sinks.sink1.producer = com.cloudera.kudu.JsonKuduOperationsProducer
```

（可左右滑动）

![image-20210926172433410](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926172433410.png)

3.保存flume配置，并重启Flume服务

**5.流程测试**

___

1.进入0283-kafka-shell目录执行命令向Kafka的kafka\_sparkstreaming\_kudu\_topic发送消息

\[root@cdh01 0283\-kafka\-shell\]\# sh run.sh ods\_user\_600.txt

2.通过Hue查看ods\_deal\_daily\_kudu表

![image-20210926172519641](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926172519641.png)

可以看到数据已写入到Kudu表，查看表总数与发送Kafka数量一致

![image-20210926172545008](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210926172545008.png)

**6.总结**

___

1.Flume默认没有KuduSink的依赖包，需要将kudu-flume-sink-1.4.0-cdh5.12.1.jar包添加到集群所有节点的/opt/cloudera/parcels/CDH/lib/flume-ng/lib目录下。

2.在KuduSink支持的数据解析方式比少，所以Fayson自己写了JsonKuduOperationsProducer类用于解析JSON数据。

3.需要将自定义开发的Jar包部署到${ FLUME\_HOME} /lib/conf.d/lib目录下，这样才行

4.注意在指定KuduSink的tableName时，如果Kudu表是通过impala创建的则需要在表名前添加impala::，如果是通过Kudu API创建则不需要添加。

GitHub地址：

https://github.com/fayson/cdhproject/blob/master/flumesink/src/main/java/com/cloudera/kudu/JsonKuduOperationsProducer.java

https://github.com/fayson/cdhproject/blob/master/flumesink/src/main/java/com/cloudera/utils/JsonStr2Map.java

https://github.com/fayson/cdhproject/blob/master/flumesink/pom.xml

> 提示：代码块部分可以左右滑动查看噢
>
> 为天地立心，为生民立命，为往圣继绝学，为万世开太平。 温馨提示：要看高清无码套图，请使用手机打开并单击图片放大查看。
