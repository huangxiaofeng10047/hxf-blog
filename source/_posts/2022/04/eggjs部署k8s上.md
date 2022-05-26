---
title: eggjs部署k8s上
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-04-21 14:56:12
tags:
---

前置条件：

k8s版本： 1.22.3

helm： 3.0

traefik：v2.4

参考代码github:

```
https://github.com/Hacker-Linner/k8s-eggjs
```

构建镜像

```
docker build -f docker/Dockerfile.prod -t k8s-eggjs-promethues:1.0.0 .  --no-cache
docker tag k8s-eggjs-promethues:1.0.0 huangxiaofenglogin/k8s-eggjs-promethues:1.0.0
docker push huangxiaofenglogin/k8s-eggjs-promethues:1.0.0
```

helm部署：

```
mkdir k8s-helm-charts && cd k8s-helm-charts
helm create k8seggjs
[root@master1 ~]# cd k8s-helm-charts/
[root@master1 k8s-helm-charts]# ll
total 4
drwxr-xr-x 4 root root   93 Apr 21 12:48 k8seggjs
-rw-r--r-- 1 root root 1281 Apr 21 12:48 values.yaml
replicaCount: 1 # 部署副本我用3个实例做负载均衡，保证服务可用

image:
  repository: www.harbor.mobi/k8s-eggjs-promethues # 镜像变为刚上传
  pullPolicy: Always # 镜像拉取策略可直接用默认`IfNotPresent`

# apiPort，metricsPort 默认模板没有，
# 这里我对 template 里面的 ingress.yaml service.yaml deployment.yaml 文件做了相应改动
service:
  type: ClusterIP
  apiPort: 7001 # 这个 API 服务的端口
  metricsPort: 7777 # 这个是 prometheus 所需的 metrics 端口

# Ingress Controller，根据你的环境决定，我这里用的是 traefik
ingress:
  enabled: true
  annotations:
    ingress.kubernetes.io/ssl-redirect: "true"
    ingress.kubernetes.io/proxy-body-size: "0"
    kubernetes.io/ingress.class: "traefik"
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
  hosts:
    - host: k8seggjs.hacker-linner.com
      paths:
        - path: /
          pathType: ImplementationSpecific

  tls:
    - secretName: hacker-linner-cert-tls
      hosts:

# 做资源限制，防止内存泄漏，交给 K8S 杀掉然后重启，保证服务可用
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
创建namespace
kubectl create ns k8seggjs
helm部署
helm install k8seggjs ./k8seggjs -f values.yaml -n k8seggjs
升级命令
helm upgrade  k8seggjs ./k8seggjs -f values.yaml -n k8seggjs
# 卸载：helm uninstall k8seggjs -n k8seggjs

```

通过ServiceMonitor可以注册到promethus监控

#RBAC设置

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleList
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: prometheus-k8s-k8seggjs
    namespace: k8seggjs
  rules:
  - apiGroups:
    - ""
    resources:
    - services
    - endpoints
    - pods
    verbs:
    - get
    - list
    - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBindingList
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: prometheus-k8s-k8seggjs
    namespace: k8seggjs
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: prometheus-k8s-k8seggjs
  subjects:
  - kind: ServiceAccount
    name: prometheus-k8s
    namespace: monitoring

```

指标service设定（通过7777采集）

```
apiVersion: v1
kind: Service
metadata:
  namespace: k8seggjs
  name: k8seggjs-metrics
  labels:
    k8s-app: k8seggjs-metrics
  annotations:
    prometheus.io/scrape: 'true'
    prometheus.io/scheme: http
    prometheus.io/path: /metrics
    prometheus.io/port: "7777"
spec:
  selector:
    app.kubernetes.io/name: k8seggjs
  ports:
  - name: k8seggjs-metrics
    port: 7777
    targetPort: 7777
    protocol: TCP

```

**ServiceMonitor 设置**

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: k8seggjs
  namespace: monitoring
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 5s
    port: k8seggjs-metrics
  jobLabel: k8s-app
  namespaceSelector:
    matchNames:
    - k8seggjs
  selector:
    matchLabels:
      k8s-app: k8seggjs-metrics

```

导入grafana

```
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "gnetId": null,
  "graphTooltip": 0,
  "id": 23,
  "iteration": 1575366573438,
  "links": [],
  "panels": [
    {
      "cacheTimeout": null,
      "datasource": "prometheus",
      "description": "满意值：小于 100ms，容忍值：100ms ~ 250ms。",
      "gridPos": {
        "h": 5,
        "w": 4,
        "x": 0,
        "y": 0
      },
      "id": 11,
      "links": [],
      "options": {
        "fieldOptions": {
          "calcs": ["mean"],
          "defaults": {
            "decimals": 2,
            "max": 1,
            "min": 0
          },
          "mappings": [],
          "override": {},
          "thresholds": [
            {
              "color": "red",
              "index": 0,
              "value": null
            },
            {
              "color": "#EAB839",
              "index": 1,
              "value": 50
            },
            {
              "color": "green",
              "index": 2,
              "value": 75
            }
          ],
          "values": false
        },
        "orientation": "auto",
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "6.2.5",
      "targets": [
        {
          "expr": "(\n  sum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"100\"}[1h]))\n+\n  ((sum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"250\"}[1h])) - sum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"100\"}[1h]))) / 2)\n) / sum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[1h]))",
          "format": "time_series",
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "worker",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "应用性能",
      "type": "gauge"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorPostfix": false,
      "colorValue": false,
      "colors": ["#299c46", "rgba(237, 129, 40, 0.89)", "#d44a3a"],
      "datasource": "prometheus",
      "description": "应用当前机器启动后处理请求总数量",
      "format": "none",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 5,
        "w": 4,
        "x": 4,
        "y": 0
      },
      "id": 7,
      "interval": null,
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "options": {},
      "pluginVersion": "6.2.5",
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": true,
        "lineColor": "rgb(31, 120, 193)",
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "expr": "sum(k8seggjs_http_request_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\",worker=\"app\"}) by(worker)",
          "format": "time_series",
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "1m平均值",
          "refId": "A"
        }
      ],
      "thresholds": "",
      "timeFrom": null,
      "timeShift": null,
      "title": "请求总数",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "current"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": ["#299c46", "rgba(237, 129, 40, 0.89)", "#d44a3a"],
      "datasource": "prometheus",
      "description": "同一机器节点处理中还未响应的请求总数",
      "format": "none",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 5,
        "w": 4,
        "x": 8,
        "y": 0
      },
      "id": 6,
      "interval": null,
      "links": [],
      "mappingType": 1,
      "mappingTypes": [
        {
          "name": "value to text",
          "value": 1
        },
        {
          "name": "range to text",
          "value": 2
        }
      ],
      "maxDataPoints": 100,
      "nullPointMode": "connected",
      "nullText": null,
      "options": {},
      "pluginVersion": "6.2.5",
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "50%",
      "rangeMaps": [
        {
          "from": "null",
          "text": "N/A",
          "to": "null"
        }
      ],
      "sparkline": {
        "fillColor": "rgba(31, 118, 189, 0.18)",
        "full": false,
        "lineColor": "rgb(31, 120, 193)",
        "show": false
      },
      "tableColumn": "",
      "targets": [
        {
          "expr": "sum(k8seggjs_http_all_request_in_processing_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}) by(worker)",
          "format": "time_series",
          "hide": false,
          "intervalFactor": 1,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": "",
      "timeFrom": null,
      "timeShift": null,
      "title": "处理中请求数",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "current"
    },
    {
      "aliasColors": {},
      "bars": false,
      "cacheTimeout": null,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "同一机器节点平均每分钟请求量",
      "fill": 1,
      "gridPos": {
        "h": 5,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 9,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": false,
        "min": false,
        "rightSide": false,
        "show": false,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null as zero",
      "options": {},
      "percentage": false,
      "pluginVersion": "6.2.5",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "(sum(k8seggjs_http_request_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}) by(worker)) - (sum(k8seggjs_http_request_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\"} offset 1m) by(worker))",
          "format": "time_series",
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "分钟请求数",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": false,
        "values": []
      },
      "yaxes": [
        {
          "decimals": null,
          "format": "none",
          "label": "",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "cacheTimeout": null,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "",
      "fill": 0,
      "gridPos": {
        "h": 5,
        "w": 12,
        "x": 0,
        "y": 5
      },
      "id": 12,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "hideEmpty": false,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 5,
      "links": [],
      "nullPointMode": "null",
      "options": {},
      "percentage": false,
      "pluginVersion": "6.2.5",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "k8seggjs_nodejs_version_info{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}",
          "format": "time_series",
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "{{worker}}-{{pid}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "进程存活周期",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "decimals": null,
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "cacheTimeout": null,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "500 错误请求占总请求数百分比。",
      "fill": 1,
      "gridPos": {
        "h": 5,
        "w": 12,
        "x": 12,
        "y": 5
      },
      "id": 8,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null as zero",
      "options": {},
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "((sum(irate(k8seggjs_http_all_errors_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\",worker=\"app\"}[1m])) by(worker))\n/\n(sum(irate(k8seggjs_http_request_total{stage=\"$stage\",app=\"$appname\",instance=\"$node\",worker=\"app\"}[1m])) by(worker))) * 100",
          "format": "time_series",
          "hide": false,
          "intervalFactor": 1,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "请求错误率",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {
        "app-66372": "super-light-orange"
      },
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "进程常驻内存",
      "fill": 1,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 0,
        "y": 10
      },
      "id": 2,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "hideEmpty": false,
        "hideZero": false,
        "max": false,
        "min": false,
        "rightSide": false,
        "show": true,
        "sideWidth": null,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {},
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [
        {
          "alias": "app-66372",
          "yaxis": 1
        }
      ],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "k8seggjs_process_resident_memory_bytes{stage=\"$stage\",app=\"$appname\",instance=\"$node\"} / 1024 / 1024",
          "format": "time_series",
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "{{worker}}-{{pid}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "常驻内存（rss）MB",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "5 分钟内平均响应时间占比",
      "fill": 1,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 12,
        "y": 10
      },
      "id": 10,
      "interval": "",
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null as zero",
      "options": {},
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "(\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"5\"}[5m]))\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "hide": false,
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "< 5ms (%)",
          "refId": "A"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"10\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"5\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "hide": false,
          "intervalFactor": 1,
          "legendFormat": "5 ~ 10ms (%)",
          "refId": "B"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"50\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"10\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "10 ~ 50ms (%)",
          "refId": "C"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"100\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"50\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "50 ~ 100ms (%)",
          "refId": "D"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"250\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"100\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "100 ~ 250ms (%)",
          "refId": "E"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"500\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"250\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "250 ~ 500ms (%)",
          "refId": "F"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"1000\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"500\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "500 ~ 1000ms(%)",
          "refId": "G"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"10000\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"1000\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "1000 ~ 10000ms(%)",
          "refId": "H"
        },
        {
          "expr": "((\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"+Inf\"}[5m]))\n-\nsum(irate(k8seggjs_http_request_duration_milliseconds_bucket{stage=\"$stage\",app=\"$appname\",instance=\"$node\",le=\"10000\"}[5m]))\n)\n/\nsum(irate(k8seggjs_http_request_duration_milliseconds_count{stage=\"$stage\",app=\"$appname\",instance=\"$node\"}[5m]))\n) * 100",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "> 10000ms or +Inf(%)",
          "refId": "I"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "响应时间占比",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": "100",
          "min": "0",
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "V8 管理的，绑定到 JavaScript 的 C++ 对象的内存使用情况",
      "fill": 1,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 0,
        "y": 19
      },
      "id": 3,
      "interval": "",
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {},
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "k8seggjs_nodejs_external_memory_bytes{stage=\"$stage\",app=\"$appname\",instance=\"$node\"} / 1024 / 1024",
          "format": "time_series",
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "{{worker}}-{{pid}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "外部内存（external）MB",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "prometheus",
      "description": "申请的堆内存，与已使用的堆内存。",
      "fill": 1,
      "gridPos": {
        "h": 9,
        "w": 12,
        "x": 12,
        "y": 19
      },
      "id": 4,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "hideEmpty": false,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {},
      "percentage": true,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "k8seggjs_nodejs_heap_size_total_bytes{stage=\"$stage\",app=\"$appname\",instance=\"$node\"} / 1024 / 1024",
          "format": "time_series",
          "hide": false,
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "{{worker}}/{{pid}}",
          "refId": "A"
        },
        {
          "expr": "k8seggjs_nodejs_heap_size_used_bytes{stage=\"$stage\",app=\"$appname\",instance=\"$node\"} / 1024 / 1024",
          "format": "time_series",
          "hide": false,
          "instant": false,
          "intervalFactor": 1,
          "legendFormat": "{{worker}}/{{pid}}",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "堆内存（heapTotal & heapUsed）MB",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": "5s",
  "schemaVersion": 18,
  "style": "dark",
  "tags": [],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {
          "text": "local",
          "value": "local"
        },
        "datasource": "prometheus",
        "definition": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\"},stage)",
        "hide": 0,
        "includeAll": false,
        "label": "环境",
        "multi": false,
        "name": "stage",
        "options": [],
        "query": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\"},stage)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {
          "text": "性能监控系统",
          "value": "性能监控系统"
        },
        "datasource": "prometheus",
        "definition": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\",stage=\"$stage\"},app)",
        "hide": 0,
        "includeAll": false,
        "label": "服务",
        "multi": false,
        "name": "appname",
        "options": [],
        "query": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\",stage=\"$stage\"},app)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {
          "text": "ssr.sv-0.hahhub.com:80",
          "value": "ssr.sv-0.hahhub.com:80"
        },
        "datasource": "prometheus",
        "definition": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\",stage=\"$stage\",app=\"$appname\"},instance)",
        "hide": 0,
        "includeAll": false,
        "label": "主机",
        "multi": false,
        "name": "node",
        "options": [],
        "query": "label_values(k8seggjs_nodejs_version_info{job=\"apm-metrics\",stage=\"$stage\",app=\"$appname\"},instance)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-5m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "30m", "1h", "2h", "1d"],
    "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
  },
  "timezone": "",
  "title": "K8SEGGJS Metrics",
  "uid": "IK1ElAxZk",
  "version": 131
}

```

需要修改变量

**修改面板 `Variables`**

**`$stage`**

- Query: `k8seggjs_nodejs_version_info{worker="app"}`
- Regex: `/.*stage="([^"]*).*/`

**`$appname`**

- Query: `k8seggjs_nodejs_version_info{worker="app"}`
- Regex: `/.*app="([^"]*).*/`

**`$node`**

- Query: `k8seggjs_nodejs_version_info{worker="app"}`
- Regex: `/.*instance="([^"]*).*/`

最终效果为：

![image-20220421151406966](C:/Users/Administrator/AppData/Roaming/Typora/typora-user-images/image-20220421151406966.png)

遇到的坑，健康检查时间太快了，导致容器被杀死。调大监控存活时间即可。
