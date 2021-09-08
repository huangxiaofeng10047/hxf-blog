---
title: Day22 了解 K8S 的 Service
date: 2021-09-08 13:34:55
tags:
  - devops
categories:
  - devops
---

好的~那麼先說說昨天應該要說的 `Service`，`Service` 是負責扮演對外溝通的腳色，每次建立時都會提供一組IP並對應到指定的 `Port`，另外 `Service` 本身提供了四種類型，分別是:

- ClusterIP: 提供 cluster 內部存取 (default value)

- NodePort: 提供一組外部IP存取

- LoadBalancer: 提供一組外部IP存取並做負載平衡 (但只限於支援雲供應商)

- ExternalName: 內部用戶端使用服務的 DNS 名稱做為外部 DNS 名稱的別名。

  <!--more-->

[參考資料](https://cloud.google.com/kubernetes-engine/docs/concepts/service?hl=zh-tw)

### 該如何實現 `Service` 與 `Pod` 溝通

![](https://i.imgur.com/OdmH7Em.png)

首先需要先撰寫 `Service yml`

```
## service.yml
apiVersion: v1                         ## k8s api 版本號
kind: Service                          ## 創立服務類型
metadata:
  name: hello-service                  ## 指定該Service的名稱
spec:
  type: NodePort                       ## 指定Service的型別，可以是NodePort或是LoadBalancer
  selector:
    app: my-app                        ## 對應那一個Pod的標籤
  ports:
  - port: 8099                         ## 容器外 Port
    targetPort: 80                     ## 容器內 Port
```

接著執行 `kubectl apply -f service.yml` 就完成 `Service`建立了

或這你也可以將兩個yml檔案合併成一支檔案，如下方範例(記得以虛線隔開):

```
## nginx.yml
apiVersion: v1                         ## k8s api 版本號
kind: Pod                              ## 創立服務類型
metadata:
  name: my-pod                         ## Pod 的名稱
  labels:
    app: my-app                        ## Pod 的標籤「app: my-app 」
spec:                                  ## spec 定義 container 資訊
  containers:
  - name: my-first-container           ## 設定 container 的名稱
    image: nginx                       ## 映像檔
    ports:                             ## 啟動哪些 port number 是允許外部資源存取
      - containerPort: 80

---
apiVersion: v1                         ## k8s api 版本號
kind: Service                          ## 創立服務類型
metadata:
  name: hello-service                  ## 指定該Service的名稱
spec:
  type: NodePort                       ## 指定Service的型別，可以是NodePort或是LoadBalancer
  selector:
    app: my-app                        ## 對應那一個Pod的標籤
  ports:
  - port: 8099                         ## 容器外 Port
    targetPort: 80                     ## 容器內 Port
```

上面說了 `Service` 與 `Pod`的溝通方式，但其實在應用上並不會這樣使用，原因是 `Pod` 本身無法「自行擴展(Scaling)」，這至少需要 `Replication Controller` 才能達到，另外一個原因是無法達到「系統升級(Rollout)」、「系統回朔(Rollback)」，這至少要 `Deployment` 才可以做到。

就上述的兩個原因，就可以知道 `Pod` 雖然是 `K8S` 建立服務的最小單位，但是實際上在應用時，透過 `Deployment` 自動產生 `Pod`，並且讓 `Service` 與 `Deployment` 溝通才是比較好的選擇，明天會說明 `Deployment` 是什麼。
