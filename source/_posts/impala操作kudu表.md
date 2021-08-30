---
title: impala操作kudu表
date: 2021-08-30 11:36:20itags:
- impala
- kudu
categories: 
- bigdatampala
---

1.通过impala操作kudu表

<!--more-->

### 内部表

内部表由Impala管理，当您从Impala中删除时，数据和表确实被删除。当您使用Impala创建新表时，它通常是内部表。

使用impala创建内部表：

```sql
CREATE TABLE test.user(
id BIGINT,
name STRING,
sex INT DEFAULT 1,
PRIMARY KEY(id)
)
PARTITION BY HASH(id) PARTITIONS 2
STORED AS KUDU
TBLPROPERTIES (
  'kudu.master_addresses' = 'bigdata2:7051,bigdata3:7051,bigdata4:7051'
);
```

在impala-shell中输入上面的命令：当看到如下命令时，则表示创建表格成功。

![image-20210830114537950](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830114537950.png)

2. kudu-springboot-starter

   代码地址在：http://10.11.2.29:3000/hxf01/kudu-spring-boot-starter.git

   项目界面如图所示：

   ![image-20210830114950583](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830114950583.png)

   配置文件在config/application.yml中：

   ![image-20210830115041819](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830115041819.png)

   ![image-20210830115157786](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830115157786.png)

运行KuduImpalaTemplateTest即可查看表中增加一条数据，通过impala查看：

![image-20210830115251024](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210830115251024.png)



### 外部表

外部表（创建者CREATE EXTERNAL TABLE）不受Impala管理，并且删除此表不会将表从其源位置（此处为Kudu）丢弃。相反，它只会去除Impala和Kudu之间的映射。这是Kudu提供的用于将现有表映射到Impala的语法。

使用java创建一个kudu表：

[![复制代码](https://gitee.com/hxf88/imgrepo/raw/master/img/copycode.gif)](javascript:void(0);)

```
public class CreateTable {
    private static ColumnSchema newColumn(String name, Type type, boolean iskey) {
        ColumnSchema.ColumnSchemaBuilder column = new ColumnSchema.ColumnSchemaBuilder(name, type);
        column.key(iskey);
        return column.build();
    }
    public static void main(String[] args) throws KuduException {
        // master地址
        final String masteraddr = "hadoop01,hadoop02,hadoop03";
        // 创建kudu的数据库链接
        KuduClient client = new KuduClient.KuduClientBuilder(masteraddr).defaultSocketReadTimeoutMs(6000).build();
        // 设置表的schema
        List<ColumnSchema> columns = new LinkedList<ColumnSchema>();
        columns.add(newColumn("CompanyId", Type.INT32, true));
        columns.add(newColumn("WorkId", Type.INT32, false));
        columns.add(newColumn("Name", Type.STRING, false));
        columns.add(newColumn("Gender", Type.STRING, false));
        columns.add(newColumn("Photo", Type.STRING, false));
        Schema schema = new Schema(columns);
        //创建表时提供的所有选项
        CreateTableOptions options = new CreateTableOptions();
        // 设置表的replica备份和分区规则
        List<String> parcols = new LinkedList<String>();
        parcols.add("CompanyId");
        //设置表的备份数
        options.setNumReplicas(1);
        //设置range分区
        options.setRangePartitionColumns(parcols);
        //设置hash分区和数量
        options.addHashPartitions(parcols, 3);
        try {
            client.createTable("PERSON", schema, options);
        } catch (KuduException e) {
            e.printStackTrace();
        }
        client.close();
    }
}
```

[![复制代码](https://gitee.com/hxf88/imgrepo/raw/master/img/copycode.gif)](javascript:void(0);)

使用impala创建外部表 ， 将kudu的表映射到impala上：

[![复制代码](https://gitee.com/hxf88/imgrepo/raw/master/img/copycode.gif)](javascript:void(0);)

```
CREATE EXTERNAL TABLE my_mapping_table
STORED AS KUDU
TBLPROPERTIES (
  'kudu.master_addresses' = 'hadoop01:7051,hadoop02:7051,hadoop03:7051', 
  'kudu.table_name' = 'PERSON'
);
```

[![复制代码](https://gitee.com/hxf88/imgrepo/raw/master/img/copycode.gif)](javascript:void(0);)

