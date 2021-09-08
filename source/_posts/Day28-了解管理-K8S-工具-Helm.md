---
title: Day28 了解管理 K8S 工具 Helm
date: 2021-09-08 14:01:49
tags:
- devops
categories: 
- devops
---

![](https://i.imgur.com/ZBrSjD8.png)

如果說 `K8S` 是有效管理 `Docker Container` 的工具，那麼 `Helm` 就是有效管理 `K8S Yaml` 的工具， `Helm` 會將 `K8S` 的服務中的各種 `yaml` 檔案打包成一個叫做 `chart` 的集合，並且接受帶入參數的方式管理 `K8S yaml` 檔案，讓 `K8S` 在管理上更加彈性。

試著想像一下當你完成一份 `Yaml` 後，並且沒有透過 `Helm` 工具，該如何讓一份 `Yaml` 符合 `DEV`、`QA`、`PROD` 三個環境呢?

-   情境一:  
    撰寫了一份 `ingress.yaml` 檔案，但是 `host` 的部分每個環境都不一樣，如果沒有透過 `Helm`，那麼在佈署個環境時就必須要調整 `host` 的 `value`，或者寫不同環境的 `yaml` 檔案。
    
-   情境二:  
    撰寫了一份 `deployment.yml` 檔案，但是每個環境產生的 `Pod` 數量不一樣，該如何紀錄每個環境的 `Pod` 數量呢?
    

### Helm 安裝方式 (Linux 環境)

簡單的四個步驟: [Helm cli 安裝方式](https://helm.sh/docs/using_helm/#using-helm)

1.  下載壓縮檔
2.  解壓縮壓縮檔
3.  將 `linux-amd64/hel` 指令搬移到 `/usr/local/bin/helm`
4.  執行 `helm version` 測試看能不能執行

**注意:**

-   開始使用 `helm cli` 建置 `K8S` 環境時，需要先初始化 `helm init`
-   安裝完 `Helm` 後，還不算能透過 `Helm cli` 執行 `K8S API`，必需創立 `Tiller` 用戶，並賦予該用戶可以操控 `K8S API` 的權限。[官方建立 Tiller 文件](https://helm.sh/docs/using_helm/#role-based-access-control)

### Helm 的架構

先來看看當我們執行了`helm create <project name>` 後產生的架構

├── charts  
├── Chart.yaml  
├── templates  
│   ├── deployment.yaml  
│   ├── \_helpers.tpl  
│   ├── ingress.yaml  
│   ├── NOTES.txt  
│   ├── service.yaml  
│   └── tests  
│   └── test-connection.yaml  
└── values.yaml

看完上方範例結構後，該來詳細說明一下:

```
demo/
  Chart.yaml              # 必需: 定義 chart 資訊，包刮名稱、版本、敘述...
  values.yaml             # 必需:  負責提供 yaml 需要的參數，在 templates 中可被引用
  templates/              # 必需:  負責存放 + 定義 k8s yaml 檔案
  LICENSE                 # 可選擇: 一份文檔紀錄 License 信息
  README.md               # 可選擇: 一份文檔紀錄介绍信息，跟 git 的 README.md 相同
  requirements.yaml       # 可選擇: 定義 chart 依賴關係(方法一)
  charts/                 # 可選擇: 定義 chart 依賴關係(方法二)
  templates/_helpers.tpl  # 可選擇: 可以將 chart.yml 或 value.yml 加工後變成新變數
  templates/NOTES.txt     # 可選擇: 一份文檔，通常被用於顯示 install 後被帶入的參數值
```

### Helm 示範

以下示範透過 `helm` 建立 `deployment`，在 chart 路徑底下執行以下命令  
`helm install --set=<Your ENV> --name=<Your Release Name> --namespace=<Your Namespace> .`

**注意:**

-   `.Values.containerPortName`: 表示在 `value.yml` 取得 `containerPortName` 的值
-   `.Chart.name`: 表示在 `chart.yml` 取得 `name` 值
-   可以自行於 `templates/_helpers.tpl` 定義新變數名稱 + 提供該變數值，EX: 以下範例的 `repo`，2; 當需要使用時透過 `{{ include "repo" . }}` 呼叫即可

```

apiVersion: v1
appVersion: "1.0"
description: A Helm chart for example
name: example
version: 0.1.0
```

```



env: ""


containerPortName: "nginx-port"


containerPort: 80


readInitialDelaySeconds: 5


readPeriodSeconds: 60


liveInitialDelaySeconds: 5


liveperiodSeconds: 60


healthCheckPath: /


dev:
  
  tag: latest-dev
  
  imageRepo: myharbor.com/library/
  
  image: example-image

qa:
  tag: latest-qa
  imageRepo: myharbor.com/library/
  image: example-image

prod:
  tag: latest-prod
  imageRepo: myharbor-prod.com/library/
  image: example-image

```

```
#
{{/* 定義各環境的 image repo + tag version */}}
{{- define "repo" -}}
  {{ $env := required "env required" .Values.env }}

  {{- if and .Values.dev (eq $env "develop") -}}
    {{- printf "%s%s:%s" .Values.dev.imageRepo .Values.dev.image .Values.dev.tag }}
  {{- end -}}

  {{- if and .Values.qa (eq $env "qatest") -}}
    {{- printf "%s%s:%s" .Values.qa.imageRepo .Values.qa.image .Values.qa.tag }}
  {{- end -}}

  {{- if and .Values.prod (eq $env "prod") -}}
    {{- printf "%s%s:%s" .Values.prod.imageRepo .Values.prod.image .Values.prod.tag }}
  {{- end -}}

{{- end -}}

{{/* 定義各環境服務名稱 */}}
{{- define "chartName" -}}
  {{ $env := required "env required" .Values.env }}

  {{- if and .Values.dev (eq $env "develop") -}}
    {{ printf "dev-%s" .Chart.Name }}
  {{- end -}}

  {{- if and .Values.qa (eq $env "qatest") -}}
    {{ printf "qa-%s" .Chart.Name -}}
  {{- end -}}

  {{- if and .Values.prod (eq $env "prod") -}}
    {{ printf "prod-%s" .Chart.Name }}
  {{- end -}}

{{- end -}}
```

```

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chartName" . }}-deployment
  labels:
    app: {{ include "chartName" . }}-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ include "chartName" . }}-pod
  template:
    metadata:
      labels:
        app: {{ include "chartName" . }}-pod
    spec:
      containers:
      - name:  {{ include "chartName" . }}
        image: {{ include "repo" . }}
        imagePullPolicy: Always
        ports:
        - name: {{ .Values.containerPortName }}
          containerPort: {{ .Values.containerPort }}
        readinessProbe:
          tcpSocket:
            port: {{ .Values.containerPortName }}
          initialDelaySeconds: {{ .Values.readInitialDelaySeconds }}
          periodSeconds: {{ .Values.readPeriodSeconds }}
        livenessProbe:
          httpGet:
            path: {{ .Values.healthCheckPath }}
            port: {{ .Values.containerPortName }}
          initialDelaySeconds: {{ .Values.liveInitialDelaySeconds }}
          periodSeconds: {{ .Values.liveperiodSeconds }}
```
