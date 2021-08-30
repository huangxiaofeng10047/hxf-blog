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



