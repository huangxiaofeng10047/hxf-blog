---
title: Day17 Drone Plugin
date: 2021-09-08 11:02:54
tags:
- devops
categories: 
- devops
---

> [Bash 建置 plugin 參考文件](https://docs.drone.io/plugins/tutorials/bash/)

有時候官方提供的 `plugin` 並不適合團隊使用或者不存在團隊需要用到的 `plugin` ，你可以透過原有的 `plugin` 進行加工，或者為自己團隊打造一個屬於自己全新的 `plugin` ，今天將會介紹該如何客製化屬於自己團隊的 `plugin` ，透過自己封裝的 `Image` 達到建置環境、編譯程式、發布至各環境、發送通知等...

那麼在客製化之前你需要先了解一個概念， `Drone Plugin` 其實說白了就是封裝後的 `Docker Images`，具有以下特性:

<!--more-->

-   共享: 可用於公司不同團隊，或提供開源使用。
-   重複使用。

目標: 客製化個人 `Drone Plugin`，並帶入自定義的 `HELLO` 參數，取代原本的 `default` 值。 [GitHub 範例](https://github.com/neil605164/CI-CD/tree/master/plugin-example)

-   Step1: 建立 update.sh

```
#
if [ -z ${PLUGIN_HELLO} ]; then
  PLUGIN_HELLO="default"
fi
```

-   Step2: Build Image

```

FROM alpine:3.4


RUN apk --no-cache add bash


COPY update.sh /bin/


CMD ["/bin/update.sh"]
```

執行以下指令

```
#
$ docker build -t neil605164/drone-plugin-ex .
```

-   Step3: Push Image

```
#
$ docker push neil605164/drone-plugin-ex
```

-   Step4: Drone yaml 撰寫方式 [Github 範例](https://github.com/neil605164/CI-CD/tree/master/demo2)

當 `yaml` 內需要帶入參數時，只需要引用 `hello`，而不是 `plugin_hello`，另外 `Drone` 1.0 後的版本，自定義的參數需要寫在 `settings` 底下， 而 `Drone` 0.8 的版本可以直接呼叫使用，如以下範例:

```

kind: pipeline
type: docker      
name: default       

steps:
  - name: self-plugin                    
    image: neil605164/drone-plugin-ex    
    settings:
      hello: "Wow"                       
    commands:                            
    - echo $PLUGIN_HELLO                 
    when:                                
      branch:
      - master
trigger:     
  branch: 
  - master
  event:
  - push
```

```
#
clone:
  git:
    image: plugins/git

pipeline:
  self-plugin:                           # 事件一：可自行定義的名稱
    image: neil605164/drone-plugin-ex    # 使用 neil605164/drone-plugin-ex  容器
    hello: "Wow"                         # 提供 hello 值為「Wow」，若不提供則為「default」值
    commands:                            # 驗證是否有接收到帶入的值
    - echo $PLUGIN_HELLO          
    when: 
      branch: [ master ]                 # 當觸發條件為 master 分支時會執行的動作
      
branches:                                # 觸發 pipeline 條件，分支為 master
  include: [ master ]
```

-   Step5: Push drone.yml  
    撰寫完 `drone.yml` 檔後，當然要 `tigger` 確認撰寫是否正常，如果撰寫正確可以看見以下測試結果:

![](https://i.imgur.com/uq90Hjs.png)
