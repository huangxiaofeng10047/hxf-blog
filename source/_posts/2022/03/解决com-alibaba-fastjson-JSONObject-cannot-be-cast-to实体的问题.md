---
title: 解决com.alibaba.fastjson.JSONObject cannot be cast to实体的问题
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-03-09 10:14:32
tags:
---

```
String jsonStr =
    "{\n"
        + "    \"date\": 1646641925543,\n"
        + "    \"method\": \"Nms.DdmStatus\",\n"
        + "    \"params\": [\n"
        + "        {\n"
        + "            \"handoverIn\": 100,\n"
        + "            \"handoverOut\": 100,\n"
        + "            \"remoteInline\": 100,\n"
        + "            \"remoteCross\": 100,\n"
        + "            \"ddmId\": \"1\",\n"
        + "            \"networkId\": \"100\"\n"
        + "        }\n"
        + "    ],\n"
        + "    \"id\": \"54\"\n"
        + "}";
UdpStaticRequest<DdmStatistics> udpStaticRequest1 =
    JSON.parseObject(jsonStr, UdpStaticRequest.class);
List<DdmStatistics> ddmStatusList =
    JSON.parseArray(JSON.parseObject(jsonStr).getString("params"), DdmStatistics.class);
```

==这里的一个问题，是*转化的对象*和需要的对象不一样，为什么还能转化成功。==
