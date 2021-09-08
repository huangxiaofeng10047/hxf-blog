---
title: Day21 了解 K8S & Pod 運行方式
date: 2021-09-08 13:26:46
tags:
- devops
categories: 
- devops
---

## 你需要知道的基本概念

-   kubectl:  
    如果你只是單純使用 `k8s CLI` 進行佈署，那麼你一定會使用到 `kubectl`，其主要的功能就是主節點代理，並且確保服務是正常的狀態，`Client` 用戶都是用 `kubectl` 命令在執行相關動作，例如：
    
    -   `kubectl create`: 建立服務
    -   `kubectl apply` : 建立服務
    -   `kubectl update`: 變更 yml 檔時，以不停服務的方式更新容器設定
    -   `kubectl delete`: 刪除服務
-   Master & Worker
    
    -   Master：負責控制所有 `Worker` 服務與處理工作節點的編排。
    -   Worker: 負責運行所有 `Container` 服務，隨時可以新增或者刪減機器。

![](https://i.imgur.com/66vWntO.png)

<!--more-->

-   Pod  
    在 Kubernetes 中最小的部署單位，一個 `Pod` 可以由單一 `Container` 或多個 `Container` 組成，在 `Pod` 內的 `Container` 本身是共享網路 `IP` 與存儲空間，所以 `Pod` 內的服務本身是可以直接透過 `localhost` 呼叫，但一般而言我們不會直接建立 `Pod`，而是建立 `Deployment` 並且指定該 `Deployment` 需要有幾個 `Pod` 服務，就如以下圖片單看 `Pod` 的架構應該是這樣的。

![](https://i.imgur.com/4oSDgFc.png)

## 該如何創立 Pod

```
apiVersion: v1                         
kind: Pod                              
metadata:
  name: my-pod                         
spec:                                  
  containers:
  - name: my-first-container           
    image: nginx                       
    ports:                             
      - containerPort: 80
```

完成以上 `yml` 檔案後，接著執行 `kubectl apply -f <檔案名稱>` 就完成 `Pod`建立了，今天就先說道這邊吧，明天會講解今天提到的 `Deployment` 以及尚未提及的 `Service`，今天就先這樣啦
