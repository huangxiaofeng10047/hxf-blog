---
title: Day29 Drone 結合 Kubernetes
date: 2021-09-08 14:04:59
tags:
 -devops
categories:
 - devops
---

在 [第18天](https://ithelp.ithome.com.tw/articles/10223275) 介紹過該如何透過 `Drone` 自動 `Build Image` 並推上 `Harbor` 私有庫，那麼今天介紹該如何透過`Drone` 更新線上環境的 `Image` 版本號。

首先在操作 `Drone` 更新 `K8S` 的 `Image` 版號前，必需先了解使用 `K8S` 達到滾動升級的三種方式

-   `set image`

```
#
$ kubectl set image nginx-deploy nginx=nginx:v0.0.2 --record
```

-   `replace`  
    修改 `deployment.yaml` 的容器版本號後，執行 `kubectl replace -f <filename>`
    
-   `edit`  
    透過編輯視窗直接更改 `yaml` 檔案內容，存檔後立即生效。
    

```
#
$ kubectl edit deployment nginx-deploy --record
```

> **注意:** `--record` 參數通知 k8s 把指令記錄起來以方便之後檢查  
> 執行 `kubectl rollout history deployment <deployment name>` 可以查看更新狀況\[color=red\]

以上這三種方式，第二種與第三種都是手動更改檔案，再透過指令的方式進行升版，且文件有可能發生更改錯誤，例如排版錯誤多了一個空白鍵，而第一種方式則是透過指令的方式進行升版，相對地比較單純，那麼了解了三種升版方式，看似第一種`kubectl set` 是最適合做為準動升級，只是每次更新程式都必需打指令更新蠻擾人的，那...不如交給 `Drone` 處理吧!

___

進入重頭戲，介紹一個 `Drone Plugin`: [Kubernetes Deployments](http://plugins.drone.io/mactynow/drone-kubernetes/)，這一個 `Plugin` 就是負責協助維運人員執行 `kubectl set image` 的指令，只需要提供對應的 `namespace`、`deployment`、`container name`以及相關驗證等資訊，接下來就交由自動化協助升級線上服務版本啦。

那們今天的目標就是除了讓 `Drone` 代替維運人員自動 `Build Image` 也需要協助維運人員自動更新線上程式本版，目標如以下流程圖。

![](https://i.imgur.com/W9GkTp0.png)

先來複習一下第18天的 `.drone.yaml` 內容

```

kind: pipeline
type: docker      
name: clone       

steps:
  - name: build-golang                                                
    image: neil605164/plugin-govendor                                 
    commands:                                                         
      - mkdir -p /usr/local/go/src/${DRONE_REPO_NAME}                 
      - ls -al vendor                                                 
      - rsync -r  /drone/src/* /usr/local/go/src/${DRONE_REPO_NAME}   
      - cd /usr/local/go/src/${DRONE_REPO_NAME}                       
      - govendor sync                                                 
      - rsync -r /usr/local/go/src/${DRONE_REPO_NAME}/* /drone/src    
      - ls -al vendor                                                 
  - name: build-image-push-harbor                                     
    image: plugins/docker                                             
    settings:
      username:                                                       
        from_secret: docker_username
      password:                                                       
        from_secret: docker_password
      repo: <harbor url>/library/golang-hello                         
      tags: latest                                                    
      registry: <harbor url>                                          
```

從上面的 `yaml` 檔案可以看到有兩個事件需要執行:

-   build-golang: 編譯 golang 程式
-   build-image-push-harbor: build image + push to harbor

接著如果需要自動更新線上版本，只需要再增加一個事件，如以下 `yaml` 內容:

```
  - name: k8s-deploy                                                  
    image: quay.io/honestbee/drone-kubernetes                         
    settings:
      kubernetes_server: <K8S server url>                             
      namespace: <namespace name>                                     
      deployment: <deployment name>                                   
      repo: <inmage repo path>                                        
      container:  <container name>                                    
      tag: latest-dev                                                 
      kubernetes_token:                                               
        from_secret: kubernetes_token
    debug: true                              
```

以上就是今天的內容，開發人員只需要簡單的 `git push` 指令，就可以達到後續自動佈署，若需要區分環境，也可以加上 `Drone` 內鍵功能的 `when.branch: master` 等其他分支或者 tag 作為條件，過濾何時該執行特定事件。

-   完整版 `yaml` 檔案

```

kind: pipeline
type: docker      
name: clone       

steps:
  - name: build-golang                                                
    image: neil605164/plugin-govendor                                 
    commands:                                                         
      - mkdir -p /usr/local/go/src/${DRONE_REPO_NAME}                 
      - ls -al vendor                                                 
      - rsync -r  /drone/src/* /usr/local/go/src/${DRONE_REPO_NAME}   
      - cd /usr/local/go/src/${DRONE_REPO_NAME}                       
      - govendor sync                                                 
      - rsync -r /usr/local/go/src/${DRONE_REPO_NAME}/* /drone/src    
      - ls -al vendor                                                 

  - name: build-image-push-harbor                                     
    image: plugins/docker                                             
    settings:
      username:                                                       
        from_secret: docker_username
      password:                                                       
        from_secret: docker_password
      repo: <harbor url>/library/golang-hello                         
      tags: latest                                                    
      registry: <harbor url>  
      
  - name: k8s-deploy                                                  
    image: quay.io/honestbee/drone-kubernetes                         
    settings:
      kubernetes_server: <K8S server url>                             
      namespace: <namespace name>                                     
      deployment: <deployment name>                                   
      repo: <inmage repo path>                                        
      container:  <container name>                                    
      tag: latest-dev                                                 
      kubernetes_token:                                               
        from_secret: kubernetes_token
    debug: true                                                       
```

**注意:**

-   `.drone.yml` 檔案內容的事件，若無指定平行處理，那麼會有順序性**由上至下**，在撰寫事件時需要注意
-   `Drone` 內鍵可以使用的全域變數 [參考文件](https://docker-runner.docs.drone.io/configuration/environment/variables/)
