---
title: elasticsearch获取mapping结构
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-16 10:44:59
tags:
---

 获取的命令为：

```
curl -XGET "https://192.168.20.5:39200/ddm/_mapping?pretty" 
```

返回的json字符串就是需要的结构。

修改mapping
如果想给product新增一个字段，那么需要修改mapping,尝试一下：

```shell
curl -XPOST "http://127.0.0.1:9200/productindex/product/_mapping?pretty" -d '{
     "product": {
                "properties": {
                     "amount":{
                        "type":"integer"
                   }
                }
            }
    }'
{
  "acknowledged" : true
}

```

新增成功。
如果要修改一个字段的类型呢，比如onSale字段的类型为boolean，现在想要修改为string类型，尝试一下：

```shell
 curl -XPOST "http://127.0.0.1:9200/productindex/product/_mapping?pretty" -d '{
     "product": {
                "properties": {
                 "onSale":{
                    "type":"string" 
               }
            }
        }
}'
```

返回错误：

```
{
  "error" : {
    "root_cause" : [ {
      "type" : "illegal_argument_exception",
      "reason" : "mapper [onSale] of different type, current_type [boolean], merged_type [string]"
    } ],
    "type" : "illegal_argument_exception",
    "reason" : "mapper [onSale] of different type, current_type [boolean], merged_type [string]"
  },
  "status" : 400
}
```

为什么不能修改一个字段的type？原因是一个字段的类型修改以后，那么该字段的所有数据都需要重新索引。Elasticsearch底层使用的是lucene库，字段类型修改以后索引和搜索要涉及分词方式等操作，不允许修改类型在我看来是符合lucene机制的。



为什么不能修改一个字段的type？原因是一个字段的类型修改以后，那么该字段的所有数据都需要重新索引。Elasticsearch底层使用的是lucene库，字段类型修改以后索引和搜索要涉及分词方式等操作，不允许修改类型在我看来是符合lucene机制的。
这里有一篇关于修改mapping字段的博客，叙述的比较清楚：Elasticsearch 的坑爹事——记录一次mapping field修改过程，可以

参考文档：

https://www.cnblogs.com/Creator/p/3722408.html
