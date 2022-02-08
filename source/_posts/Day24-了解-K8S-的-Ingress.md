---
title: Day24 了解 K8S 的 Ingress
date: 2021-09-08 13:40:13
tags:
- devops
categories: 
- devops
---

### 什麼是 `Ingress`?

`Ingress` 負責給 `Service` 提供外部訪問的 `URL`、`SSL` 驗證、負載平衡、`HTTP`路由過濾等行為，如果還不了解他你可以先暫時將 `Ingress` 想成 `Nginx` 或 `Apache`，原本在`Nginx` 或 `Apache`上設定的規則都搬移到 `Ingress` 執行，允許只透過某個 `URL` 可以進到服務，且碰到某些 `Route` 能夠 `Proxy Pass` 到指定服務，當然在這過程可能會經過 `SSL` 驗證或者 `Rewrite` 規則。

<!--more-->

### `Service` 與 `Ingress` 比較

筆者解釋一下為什麼透過 `Ingress` 進入服務，會比透過 `Service`進入服務來的好，請先看看下方流程圖:

-   **Service:**

![](https://i.imgur.com/rlPiACE.png)

上方流程圖中，可以看到使用者正在透過瀏覽器瀏覽網頁，且有三個 `URL` 分別對應到三個服務，每個服務都有特殊 `Port`，所以如果只有使用 `Service` 管理服務，那麼使用者就必需管理 `Port` 跟 `URL` ，當服務越來越多需要管理的 `Port` 也會越來越多，另外比較嚴重的問題是，每次 `Service` 被建立時，都會自動產生一組對外 `IP`，若下次再重新建立 `IP` 就不會在相同了，這時 `URL` 找不到對應的 `IP`，服務就會發生異常。

-   **Ingress:**

![](https://i.imgur.com/5SgnVaX.png)

接著在瀏覽器與 `Service` 中間插入了 `Ingress`， `Ingress` 只需要負責檢查網址是否有在規則中，以及是否有需要進行 `SSL` 驗證，好處是只需要對外開放一個 Port ，其餘的設定可以藉由 `Ingress` 控制使用者送來的請求應該被導向哪個 `Service` 服務。

### `Ingress` 範例

**注意:**

-   在使用 `Ingress` 之前，**一定需要先運行 [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)**，筆者本身習慣使用 [Nginx](https://www.nginx.com/products/nginx/kubernetes-ingress-controller) 作為平常使用的 `Ingress Controller`
    
-   `Ingress Controller` 扮演著與 `K8S API` 溝通的腳色，並隨時注意 `Ingress` 規則是否有變化、如果有變化則自行更新規則。
    

**範例:**

1.  當使用者於瀏覽器開啟 `zxc.com URL` ，會透過 `Ingress` 導向 `web01-service` 服務。
2.  當使用者於瀏覽器開啟 `abcabc.com URL` ，會透過 `Ingress` 導向 `web02-service` 服務。

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: zxc.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web01-service
          servicePort: 80
  - host: abcabc.com
    http:
      paths:
      - path: /
        backend:
          serviceName: web02-service
          servicePort: 80
```

以上是今天 `ingress` 內容，那今天就先這樣啦。
