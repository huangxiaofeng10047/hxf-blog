---
title: Day26 了解 K8S 的 Volumes & StorageClass
date: 2021-09-08 13:57:15
tags:
- devops
categories: 
- devops
---

`Container` 的硬碟空間是短暫的，隨著 `Container` 生命一同消失，那麼重要的資料該如何保存? 今天會說明 `Volumes` 與 `Storage Class` 是什麼，以及該如何使用

### 什麼是 `Volumes` ?

`kubernetes` 中的 `Volumes` 跟 `Docker` 的 `Volumes` 是相同的，都是為了解決檔案在 `Container` 中無法永續存活問題，在 `Kubernetes` 中 `Valume` 具有多種[類型](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)，以下挑幾個本機練習可使用到的進行講解:

<!--more-->

-   [emptyDir](https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath)  
    當服務創立後，該掛載空間也會一併被建立，並賦予讀寫的權限，但當服務被移除後該空間一併會被移除，適合存放不重要資料。

**注意:** 容器異常時並不會導致 `Pod` 服務被移除，故 `emptyDir` 的數據是安全的，需等到 `Pod` 完全被移除才會一併刪除 `emptyDir` 資料。

```

apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: k8s.gcr.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

-   [hostPath](https://kubernetes.io/zh/docs/concepts/storage/volumes/#hostpath)  
    負責將機器上「特定路徑」的文件掛載到 `Container` 內，且當服務因某些原因重新啟動，或者需要重新建置，檔案仍保存在 `Node` 上，直到該文件被移除或者該 `Node` 被移除 `Kubernetes Cluster`。

```

apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: k8s.gcr.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    hostPath:
      
      path: /data
      
      type: Directory
```

### 什麼是 `StorageClass` ?

如果要說明什麼是 `StorageClass` ，應該一併說明 `PersistentVolume` 與 `PersistentVolumeClaim`

當用戶在建立 `Pod` 服務使用到 `PVC(PersistentVolumeClaim)`，這時會自動找一個符合的 `PV(PersistentVolume)`進行批配，若有批配到就直接逕行綁定(此時表示與`PV`進行「靜態」批配)，但是如果沒有符合的 `PV`，則會透過`StorageClass`建立一個新的`PV`再和`PVC`綁定(此時表示與`PV`進行「動態」批配)。

`PersistentVolume` 概念也是跟 `Volume` 差不多，用意都是在協助保存資料，將資料永久化，只是開發人員不需要再為了檔案要保留在哪個空間而感到困擾，試著想像一下如果有1個Nginx服務，我們需要將 `nginx.conf` 掛載，偏偏 `kubernetes` 又會協助將服務建置在 `Loading` 輕的 `Node`上，為了讓服務能正常啟動，每台 `Node` 上都需要掛載 `nginx.conf`，又或者當服務越來越多時，掛載數量也會越來越多...相對的就比較不容易管理，這時當然就是推薦使用 `PersistentVolume` 啦，請看看下方圖片：

![](https://i.imgur.com/151XzHT.png)  
(圖片取自網路)

系統管理人員負責建置 `PV` ，而開發人員則是負責建立 `PVC`與 `Storage Class`，並交由 `PVC` 自動尋找合適的 `PV`進行綁定，或者透過`StorageClass`建立一個新的`PV`再和`PVC`綁定

那麼 `PersistentVolume` 數量這麼多，該如何找到適合的呢？ 這時候當然是要由系統管理人員對 `PersistentVolume` 進行分類，也就是說在建立 `PersistentVolume` 同時必須賦予有意義的 `Label`或者 `storgeClassName` 做為識別證，另外也需要規範[回收策略](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming)，例如：

-   Delete: 當不再使用 `Storage Class` 時，一併移除資料(default)
-   Retain: 當不再使用 `Storage Class` 時，資料會保留等待手動刪除

### 什麼是 `PersistentVolume`?

`PersistentVolume` 是存放資源的地方，簡單想像的話就是個 `Disk` 空間， `PersistentVolume` 分為兩種：

-   靜態：手動建立 `PersistentVolume` 稱為「靜態」綁定
-   動態：`PVC`在批配 `PV`時，若不符合規則會透過 `StorageClass` 自動建立新的`PV`，此時`PV`我們會稱為「動態」綁定，並且繼承 `StorageClass` 規定的回收政策。

`PV` 建立時，可以設定以下內容：

-   PV的屬性.比如,存儲類型,Volume的大小等.
-   創建這種PV需要用到的存儲插件

**相對的 `StorageClass` 也可以加入此兩項設定，當 `PVC` 無法批配符合的 `PV` 時，才可以透過 `StorageClass` 協助動態建置 `PV`**

### 什麼是 `PersistentVolumeClaim`?

`PVC(PersistentVolumeClaim)```` 負責批配符合條件的`PV`，並與該`PV\`\`\` 進行綁定。

`PVC`提供三種與`PV`中的檔案存取模式：

-   ReadWriteOnce：只可以掛載在同一個 Node 上提供讀寫功能。
-   ReadOnlyMany ：可以在多個 Node 上提供讀取功能。
-   ReadWriteMany：可以在多個 Node 上提供讀寫功能。

`PVC` 該如何與 `PV` 進行綁定：

-   透過 `storageClassName` 名稱，找到相同 `PV`。
-   透過 `Label` 標籤，找到相同 `PV`。

範例：(下方案例為手動建置 `PV`)

### 建立 `StorageClass`、`PVC`、`PV`

```

apiVersion: storage.k8s.io/v1            
kind: StorageClass                       
metadata:
  name: ssd                              
provisioner: kubernetes.io/gce-pd        
parameters:                              
  type: pd-ssd
reclaimPolicy: Retain                    
```

```

apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ssd
  hostPath:
    path: /tmp
```

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-master-storage
spec:
  storageClassName: ssd
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
