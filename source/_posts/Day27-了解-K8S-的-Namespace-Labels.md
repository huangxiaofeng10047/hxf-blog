---
title: Day27 了解 K8S 的 Namespace & Labels
date: 2021-09-08 14:00:07
tags:
- devops
categories: 
- devops
---

今天要介紹好用的分類用法`Namespace`與 `Label`，試著想像一個情境，當你有100個服務且有三個不同環境(`DEV`、`QA`、`PROD`)，為了節省成本你將 `QA` 與 `DEV` 的服務放在相同的 `K8S Cluster`，那麼你至少就會有 `200` 個服務在`K8S Cluster`上，這麼多的服務該怎麼管理，今天第一個介紹的管理方式 `Namespace` 。

### 什麼是 `Namespace` ?

`Namespace` 可以用於分類以及管理服務，常用分類方式有 「`ENV` 環境」、「專案名稱」，例如以下方式:

-   依據「`ENV` 環境」分類:
    -   dev-frontend
    -   dev-backend
    -   qa-frontend
    -   qa-backend
-   依據「專案名稱」分類:
    -   web01
    -   web02
    -   web03
-   結合「`ENV` 環境」、「專案名稱」分類:
    -   dev-web01
    -   qa-web01
    -   dev-web01
    -   qa-web02

**注意:** `Kubernetes` 在起後服務後會有初始的三個 `Namespace:` 分別是:

-   `default`: 當服務不指定 `Namespace` 都會被分派到該 `Namespace`。
-   `kube-system`: 該 `Namespace` 用於存放與系統相關的服務。
-   `kube-public`: 該 `Namespace` 保留給 `K8S` 群集使用，並提供所有人都可以看(包含未經過身分驗證人員)，所以應避免將服務放置該 `Namespace` 。

### 示範將服務歸類在特定 `Namespace`

```

apiVersion: v1
kind: Namespace
metadata:
  name:  apple

---

apiVersion: extensions/v1beta1 
kind: Deployment               
metadata:                      
  name: nginx                  
  namespace: apple             
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

---

apiVersion: v1                 
kind: Service                  
metadata:                      
  name: nginx-service          
  namespace: apple             
spec:
  type: NodePort               
  selector:
    service: http-server       
  ports:
  - port: 80                   
    targetPort: 80             
```

### 什麼是 `Label`?

`Label` 是以 「`Key`/`Value`」的形式附加到任何的元件上，像是:`Pod`、`Deployment`、`Service`、`Node`，那麼定義 `Label` 功用呢? 請看以下範例:

#### 範例一:

有兩台 `Node`，一台硬碟為 `ssd`，一台為「一般硬碟」，所以我們可以為這兩台 `Node` 加上 `Label`:

-   disk: ssd
-   disk: sas

若今天有服務需要使用到 `ssd`，就可以透過 `yaml` 檔案指定服務必須包含 「`disk: ssd`」的標籤才可以建立服務。

#### 範例二:

於新建的 `Pod` 上面新增 `Label` 「`service`: `nginx`」，接著當我們建立 `Deploymant` 並告至該元件必須管理含有`service: nginx` 標籤的 `Pod`，如以下 `yaml` 示範:

```
apiVersion: extensions/v1beta1 
kind: Deployment               
metadata:                      
  name: nginx                  
  namespace: apple             
  labels:
    service: nginx-deployment  
spec:
  replicas: 3                  
  selector:                    
    matchLabels:               
      service: nginx
  template:
    metadata:                  
      labels:
        service: nginx
    spec:
      containers:              
      - name: nginx-deploy     
        image: nginx           
        ports:                 
        - containerPort: 80
```

以上就是今天要介紹的內容，那麼今天內容就寫到這邊，明天會介紹有效管理 `K8S` 的工具。
