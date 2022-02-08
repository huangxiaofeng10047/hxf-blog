---
title: Day23 了解 K8S 的 Deployment
date: 2021-09-08 13:37:21
tags:
- devops
categories: 
- devops
---

昨天提到了 `Deployment` 與 `Pod` 之間的差異，今天再來仔細的說一下什麼是 `Deployment` 元件，`Deployment` 可以算是 `Kubernetes` 中最常用到的元件之一，`Deployment` 跟 `Pod` 相同但卻更強大，通常在建立新的 `Deployment` 時，會同時建立 `ReplicaSet` ， 接著 `ReplicaSet` 會在建立 `Pod`，在建立的過程中 `Deployment` 會一併檢查是否能正常啟動，例如：「image 是否存在」、「yaml 檔案規則是否正確」

另外，每次透過 `Deployment` 在更新服務版本時，也會觸發檢查機制，若檢查不通過 `Deployment` 不會讓新服務上線，繼續維持舊版服務，確保服務正常。

<!--more-->

### `Deployment` 可以達成以下幾件事情：

-   擴展(Scaling) `Pod` 服務，滿足更高負載
-   佈署服務
-   服務升版
-   服務降版(Rollback)
-   檢查服務是否健康 (Health Check)

### 建置 Deployment

執行 `kubectl apply -f deployment.yml`

```

apiVersion: extensions/v1beta1 
kind: Deployment               
metadata:                      
  name: nginx                  
  labels:                      
    service: http-server
spec:
  replicas: 3                  
  selector:                    
    matchLabels:               
      service: http-server
  template:
    metadata:                  
      labels:
        service: http-server
    spec:
      containers:              
      - name: nginx-deploy     
        image: nginx           
        ports:                 
        - containerPort: 80
```

[更多 Deployment 撰寫規則](https://jimmysong.io/posts/kubernetes-concept-deployment/)

### 建立 `Service` 與 `Deployment` 溝通

```

apiVersion: v1            
kind: Service             
metadata:                 
  name: nginx-service     
spec:
  type: NodePort          
  selector:
    service: http-server  
  ports:
  - port: 80              
    targetPort: 80        
```
