---
title: Day25 了解 K8S 的 ConfigMap & Secret
date: 2021-09-08 13:51:58
tags:
- devops
categories: 
- devops
---

「敏感資料」、「設定檔」...每次更改設定檔都需要重新包成映像檔，覺得很麻煩嗎?那麼你該了解一下 `Config` 與 `Secret` 的用法了，學會這個用法可以省去許多麻煩，甚至可以僅更改外層資料便能夠影響容器內的世界，接下來就來看看什麼是 `ConfigMap` 與 `Secret` 吧!

<!--more-->

### 什麼是 ConfigMap

在 `Kubernetes` 中，`ConfigMap` 可以是扮演著字典檔的角色，以「Key」、「Values」的方式存放著「非敏感」，以不需要加密的資訊，例如：

-   當前環境是否開啟`Debug`模式
-   當前 `Log` 等級

```

apiVersion: v1               
kind: ConfigMap              
metadata:
  name: special-config       
  namespace: default         
data:
  special.how: very          
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: env-config
  namespace: default
data:
  log_level: INFO
```

```

apiVersion: v1               
kind: Pod                    
metadata:
  name: dapi-test-pod        
spec:
  containers:
    - name: test-container                  
      image: k8s.gcr.io/busybox             
      command: [ "/bin/sh", "-c", "env" ]   
      env:                                  
        - name: SPECIAL_LEVEL_KEY           
          valueFrom:                        
            configMapKeyRef:
              name: special-config
              key: special.how
        - name: LOG_LEVEL                   
          valueFrom:
            configMapKeyRef:                
              name: env-config
              key: log_level
  restartPolicy: Never
```

**當啟動服務後，可以看見Pod的輸出包括環境變量`SPECIAL_LEVEL_KEY=very`和`LOG_LEVEL=INFO`**

另外也可以扮演設定檔掛載的角色，例如：

-   nginx.conf 設定檔
-   redis.conf 設定檔
-   程式內需要用的 `env` 檔案

```

apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-map
data:
  test.conf: |
    server {
      listen       80;
      server_name  zxc.com;
  
      location / {
          root  /home/nginx_html ;
          index index.html index.htm;
      }
    }
  test1.conf: |
    server {
      listen       80;
      server_name  abc.com;
  
      location / {
          root  /home/nginx_html ;
          index index1.html index1.htm;
      }
    }
---
## 佈署容器服務，此時服務尚未對外，僅供容器內彼此溝通
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      service: http-server
  template:
    metadata:
      labels:
        service: http-server
    spec:
      containers:
      - name: nginx
        image: 10.28.16.107:8899/library/demo-nginx:0.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /etc/nginx/conf.d 
          readOnly: true
          name: deployment-nginx-conf
      volumes:
        - name: deployment-nginx-conf
          configMap:
            name: nginx-map 

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    service: http-server
  ports:
  - port: 80
    targetPort: 80
```

### 什麼是 Secret

`Secret` 跟 `ConfigMap` 相同用法，只是對象類型適用於保護「敏感資料」，例如：

-   DB 帳號密碼
-   OAuth 令牌
-   SSH Key
-   Redis 密碼資料統一由 `Secret`作為保存，在放置容器服務內提供程式做使用

這些敏感資料都將由 Secret 保存著，在提供 Container 使用。

```

apiVersion: v1               
kind: Secret                 
metadata:
  name: mysecret             
type: Opaque                 
data:                        
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
```

```

apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: mycontainer
    image: redis
    env:
      - name: SECRET_USERNAME
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: username
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: password
  restartPolicy: Never
```

以上就是 `ConfigMap` 與 `Secret` 的說明與示範
