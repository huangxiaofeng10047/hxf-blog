---
title: 添加readmore
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:18:37
tags:
---
# Prometheus Operator 监控 Traefik V2.4

# 背景：

traefik搭建方式如下：

https://www.yuque.com/duiniwukenaihe/ehb02i/odflm7 。

Prometheus-oprator搭建方式如下：

https://www.yuque.com/duiniwukenaihe/ehb02i/tm6vl7。

Prometheus的文档写了grafana添加了traefik的监控模板。但是现在仔细一看。traefik的监控图是空的，Prometheus的 target也没有对应traefik的监控。

现在配置下添加traefik服务发现以及验证一下grafana的图表。

# 1. Prometheus Operator 监控 Traefik V2.4

## 1.1.  [Traefik 配置文件设置 Prometheus](http://www.mydlq.club/article/19/#一traefik-配置文件设置-prometheus)

参照https://www.yuque.com/duiniwukenaihe/ehb02i/odflm7。配置中默认开启了默认的Prometheus监控。

![img](https://s2.loli.net/2022/01/06/HzcONU3n9RVaieQ.png)

https://doc.traefik.io/traefik/observability/metrics/prometheus/可参照traefik官方文档。

## 1.2、Traefik Service 设置标签

### 1.2.1 查看traefik service

```plain
$  kubectl get svc -n kube-system
NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                        AGE
cilium-agent                  ClusterIP   None             <none>        9095/TCP                       15d
etcd-k8s                      ClusterIP   None             <none>        2379/TCP                       8d
hubble-metrics                ClusterIP   None             <none>        9091/TCP                       15d
hubble-relay                  ClusterIP   172.254.38.50    <none>        80/TCP                         15d
hubble-ui                     ClusterIP   172.254.11.239   <none>        80/TCP                         15d
kube-controller-manager       ClusterIP   None             <none>        10257/TCP                      8d
kube-controller-manager-svc   ClusterIP   None             <none>        10252/TCP                      6d
kube-dns                      ClusterIP   172.254.0.10     <none>        53/UDP,53/TCP,9153/TCP         15d
kube-scheduler                ClusterIP   None             <none>        10259/TCP                      8d
kube-scheduler-svc            ClusterIP   None             <none>        10251/TCP                      6d
kubelet                       ClusterIP   None             <none>        10250/TCP,10255/TCP,4194/TCP   8d
traefik                       ClusterIP   172.254.12.88    <none>        80/TCP,443/TCP,8080/TCP        11d
```

### 1.2.2、编辑该 Service 设置 Label

```plain
 kubectl edit service traefik -n kube-system
```

设置 Label “app: traefik”

![img](https://s2.loli.net/2022/01/06/NLX7qRcz46oaHD8.png)

参照的是traefik-deploy.yaml 中的app:traefik这个标签用了，当然了也可以自己定义下用下别的......

![img](https://s2.loli.net/2022/01/06/jJLDmoKpuqBU4xQ.png)

具体yaml文件如下所示：

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    meta.helm.sh/release-name: traefik
    meta.helm.sh/release-namespace: kube-system
  labels:
    app.kubernetes.io/instance: traefik
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: traefik
    helm.sh/chart: traefik-10.7.1
    k8s.kuboard.cn/name: traefik
  name: traefik
  namespace: kube-system
  resourceVersion: '238757'
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/instance: traefik
      app.kubernetes.io/name: traefik
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/restartedAt: '2021-12-31T10:21:18+08:00'
        prometheus.io/path: /metrics
        prometheus.io/port: '9100'
        prometheus.io/scrape: 'true'
      creationTimestamp: null
      labels:
        app.kubernetes.io/instance: traefik
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: traefik
        helm.sh/chart: traefik-10.7.1
    spec:
      containers:
        - args:
            - '--global.checknewversion'
            - '--global.sendanonymoususage'
            - '--entryPoints.metrics.address=:9100/tcp'
            - '--entryPoints.tcpep.address=:18081/tcp'
            - '--entryPoints.traefik.address=:8080/tcp'
            - '--entryPoints.udpep.address=:18080/udp'
            - '--entryPoints.web.address=:8000/tcp'
            - '--entryPoints.websecure.address=:8443/tcp'
            - '--api.dashboard=true'
            - '--ping=true'
            - '--metrics.prometheus=true'
            - '--metrics.prometheus.entrypoint=metrics'
            - '--providers.kubernetescrd'
            - '--providers.kubernetesingress'
            - '--serversTransport.insecureSkipVerify=true'
            - '--api.insecure=true'
            - '--api.dashboard=true'
          image: 'traefik:2.5.6'
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /ping
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 2
          name: traefik
          ports:
            - containerPort: 9100
              name: metrics
              protocol: TCP
            - containerPort: 18081
              hostPort: 18081
              name: tcpep
              protocol: TCP
            - containerPort: 8080
              hostPort: 8080
              name: traefik
              protocol: TCP
            - containerPort: 18080
              hostPort: 18080
              name: udpep
              protocol: UDP
            - containerPort: 8000
              hostPort: 8000
              name: web
              protocol: TCP
            - containerPort: 8443
              hostPort: 443
              name: websecure
              protocol: TCP
          readinessProbe:
            failureThreshold: 1
            httpGet:
              path: /ping
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 2
          resources: {}
          securityContext:
            capabilities:
              drop:
                - ALL
            readOnlyRootFilesystem: true
            runAsGroup: 65532
            runAsNonRoot: true
            runAsUser: 65532
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /data
              name: data
            - mountPath: /tmp
              name: tmp
      dnsPolicy: ClusterFirst
      nodeSelector:
        kubernetes.io/hostname: k8s-2-master
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 65532
      serviceAccount: traefik
      serviceAccountName: traefik
      terminationGracePeriodSeconds: 60
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
          operator: Equal
      volumes:
        - emptyDir: {}
          name: data
        - emptyDir: {}
          name: tmp
status:
  availableReplicas: 1
  conditions:
    - lastTransitionTime: '2022-01-06T08:27:16Z'
      lastUpdateTime: '2022-01-06T08:27:16Z'
      message: Deployment has minimum availability.
      reason: MinimumReplicasAvailable
      status: 'True'
      type: Available
    - lastTransitionTime: '2022-01-06T08:27:16Z'
      lastUpdateTime: '2022-01-06T09:10:07Z'
      message: ReplicaSet "traefik-6556745c69" has successfully progressed.
      reason: NewReplicaSetAvailable
      status: 'True'
      type: Progressing
  observedGeneration: 9
  readyReplicas: 1
  replicas: 1
  updatedReplicas: 1

---
apiVersion: v1
kind: Service
metadata:
  annotations:
    meta.helm.sh/release-name: traefik
    meta.helm.sh/release-namespace: kube-system
  labels:
    app.kubernetes.io/instance: traefik
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: traefik
    helm.sh/chart: traefik-10.7.1
  name: traefik
  namespace: kube-system
  resourceVersion: '238756'
spec:
  clusterIP: 10.96.222.151
  clusterIPs:
    - 10.96.222.151
  internalTrafficPolicy: Cluster
  ipFamilies:
    - IPv4
  ipFamilyPolicy: SingleStack
  ports:
    - name: traefik
      port: 8080
      protocol: TCP
      targetPort: traefik
    - name: metrics
      port: 9100
      protocol: TCP
      targetPort: metrics
    - name: web
      port: 80
      protocol: TCP
      targetPort: web
    - name: websecure
      port: 8443
      protocol: TCP
      targetPort: websecure
    - name: 8jewfb
      port: 18080
      protocol: UDP
      targetPort: 18080
  selector:
    app.kubernetes.io/instance: traefik
    app.kubernetes.io/name: traefik
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```



## 1.3、Prometheus Operator 配置监控规则



**traefik-service-monitoring.yaml**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name:  traefik
  namespace: kuboard
  labels:
     app: traefik
spec:
  jobLabel: traefik-metrics
  selector:
    matchLabels:
      app.kubernetes.io/name: traefik
  namespaceSelector:
    matchNames:
    - kube-system
  endpoints:
  - port: traefik
    path: /metrics
```

**创建该Service Monitor**

```plain
$ kubectl apply -f traefik-monitor.yaml
```



## 1.4、查看 Prometheus  target规则是否生效

![image-20220106173922788](https://s2.loli.net/2022/01/06/6rcuhg9VEWSUAl2.png)

## 1.5 查看grafana中的traefik仪表盘是否有数据生成图表

![img](https://s2.loli.net/2022/01/06/lBwbajO6eIk4CEg.png)

traefik2 监控模板为：

```json
{
  "__inputs": [
    {
      "name": "DS_SWB",
      "label": "Prometheus",
      "description": "Traefik2 prometheus metric endpoint",
      "type": "datasource",
      "pluginId": "prometheus",
      "pluginName": "Prometheus"
    }
  ],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "6.3.6"
    },
    {
      "type": "panel",
      "id": "grafana-piechart-panel",
      "name": "Pie Chart",
      "version": "1.3.9"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph",
      "version": ""
    },
    {
      "type": "datasource",
      "id": "prometheus",
      "name": "Prometheus",
      "version": "1.0.0"
    },
    {
      "type": "panel",
      "id": "singlestat",
      "name": "Singlestat",
      "version": ""
    }
  ],
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
  "gnetId": 10906,
  "graphTooltip": 0,
  "id": null,
  "iteration": 1569328089102,
  "links": [
    {
      "icon": "external link",
      "tags": [
        "link"
      ],
      "type": "dashboards"
    }
  ],
  "panels": [
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "#299c46",
        "rgba(237, 129, 40, 0.89)",
        "#d44a3a"
      ],
      "datasource": "${DS_SWB}",
      "format": "s",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 6,
        "w": 3,
        "x": 0,
        "y": 0
      },
      "id": 22,
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
          "expr": "time() - process_start_time_seconds{job=\"$job\"}",
          "format": "time_series",
          "intervalFactor": 2,
          "refId": "A"
        }
      ],
      "thresholds": "",
      "title": "Uptime",
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
      "colorValue": true,
      "colors": [
        "rgba(50, 172, 45, 0.97)",
        "rgba(26, 206, 22, 0.89)",
        "rgba(245, 54, 54, 0.9)"
      ],
      "datasource": "${DS_SWB}",
      "decimals": 0,
      "format": "none",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 6,
        "w": 3,
        "x": 3,
        "y": 0
      },
      "id": 26,
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
      "postfix": "",
      "postfixFontSize": "50%",
      "prefix": "",
      "prefixFontSize": "200%",
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
          "expr": "sum(increase(traefik_service_requests_total{code=\"404\",method=\"GET\",protocol=~\"$protocol\"}[$interval]))",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "",
          "metric": "traefik_requests_total",
          "refId": "A",
          "step": 60
        }
      ],
      "thresholds": "0,1",
      "title": "404 Error Count last $interval",
      "type": "singlestat",
      "valueFontSize": "200%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "max"
    },
    {
      "aliasColors": {},
      "breakPoint": "50%",
      "cacheTimeout": null,
      "combine": {
        "label": "Others",
        "threshold": 0
      },
      "datasource": "${DS_SWB}",
      "fontSize": "80%",
      "format": "short",
      "gridPos": {
        "h": 6,
        "w": 7,
        "x": 6,
        "y": 0
      },
      "id": 18,
      "interval": null,
      "legend": {
        "percentage": true,
        "show": true,
        "sort": null,
        "sortDesc": null,
        "values": true
      },
      "legendType": "Right side",
      "links": [],
      "maxDataPoints": 3,
      "nullPointMode": "connected",
      "options": {},
      "pieType": "pie",
      "strokeWidth": 1,
      "targets": [
        {
          "expr": "traefik_service_requests_total{protocol=~\"$protocol\"}",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{method}} : {{code}}",
          "refId": "A"
        }
      ],
      "title": "$protocol return code",
      "type": "grafana-piechart-panel",
      "valueName": "current"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "#299c46",
        "rgba(237, 129, 40, 0.89)",
        "#d44a3a"
      ],
      "datasource": "${DS_SWB}",
      "format": "ms",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 6,
        "w": 4,
        "x": 13,
        "y": 0
      },
      "id": 20,
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
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "expr": "sum(traefik_entrypoint_request_duration_seconds_sum) / sum(traefik_entrypoint_requests_total) * 1000",
          "format": "time_series",
          "intervalFactor": 2,
          "refId": "A"
        }
      ],
      "thresholds": "",
      "title": "Average response time",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_SWB}",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 7,
        "x": 17,
        "y": 0
      },
      "id": 14,
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
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(traefik_service_request_duration_seconds_sum{protocol=~\"$protocol\"}) / sum(traefik_entrypoint_requests_total{protocol=~\"$protocol\"}) * 1000",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "Average response time (ms)",
          "refId": "A",
          "step": 240
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Average response time",
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
          "format": "ms",
          "label": null,
          "logBase": 10,
          "max": null,
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
      "datasource": "${DS_SWB}",
      "decimals": 0,
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 0,
        "y": 6
      },
      "id": 10,
      "legend": {
        "alignAsTable": true,
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
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(increase(traefik_service_requests_total{code=\"404\",method=\"GET\",protocol=~\"$protocol\"}[$interval])) by (service)",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{service}} ",
          "refId": "A",
          "step": 240
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Bad Status Code Count $interval",
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
          "decimals": 0,
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
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_SWB}",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 12,
        "y": 6
      },
      "hideTimeOverride": false,
      "id": 4,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(rate(traefik_service_requests_total[$interval]))",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "Total requests",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Total requests over $interval",
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
          "decimals": 0,
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "decimals": 0,
          "format": "short",
          "label": "",
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
      "datasource": "${DS_SWB}",
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 10,
        "x": 0,
        "y": 12
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
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "process_open_fds{job=~\"$job\"}",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{ instance }}",
          "refId": "A",
          "step": 240
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Used sockets",
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
      "datasource": "${DS_SWB}",
      "decimals": 0,
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 14,
        "x": 10,
        "y": 12
      },
      "id": 24,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "max": false,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": true,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(rate(traefik_service_requests_total{protocol=~\"http|https\",code=\"200\"}[$interval])) by (service)",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{service}} {{method}} {{code}}",
          "refId": "A",
          "step": 240
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Access to backends",
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
          "decimals": 0,
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
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_SWB}",
      "fill": 7,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 18
      },
      "id": 30,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "max": true,
        "min": false,
        "rightSide": true,
        "show": true,
        "sort": "avg",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(traefik_entrypoint_open_connections) by (method)",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "{{ method }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "ENTRYPOINT - Open Connections",
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
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_SWB}",
      "fill": 7,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 18
      },
      "id": 28,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "max": true,
        "min": false,
        "rightSide": true,
        "show": true,
        "sort": "avg",
        "sortDesc": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(traefik_service_open_connections) by (method)",
          "format": "time_series",
          "intervalFactor": 1,
          "legendFormat": "{{ method }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "BACKEND - Open Connections",
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
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_SWB}",
      "decimals": 0,
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 25
      },
      "id": 12,
      "legend": {
        "alignAsTable": true,
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
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [
        {
          "alias": "/^[^234].*/",
          "transform": "negative-Y"
        }
      ],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "sum(increase(traefik_service_requests_total{protocol=~\"$protocol\"}[$interval])) by (code)",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{code}}",
          "refId": "A",
          "step": 120
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Status Code Count per $interval",
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
          "decimals": 0,
          "format": "short",
          "label": "",
          "logBase": 1,
          "max": null,
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
    }
  ],
  "refresh": "10s",
  "schemaVersion": 19,
  "style": "dark",
  "tags": [
    "traefik",
    "load-balancer",
    "docker",
    "prometheus",
    "link"
  ],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {},
        "datasource": "${DS_SWB}",
        "definition": "",
        "hide": 0,
        "includeAll": false,
        "label": "Job:",
        "multi": false,
        "name": "job",
        "options": [],
        "query": "label_values(job)",
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 2,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": "traefik",
        "current": {},
        "datasource": "${DS_SWB}",
        "definition": "",
        "hide": 0,
        "includeAll": false,
        "label": "Node:",
        "multi": false,
        "name": "node",
        "options": [],
        "query": "label_values(process_start_time_seconds, instance)",
        "refresh": 1,
        "regex": "/([^:]+):.*/",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "${DS_SWB}",
        "definition": "label_values(traefik_service_requests_total, protocol)",
        "hide": 0,
        "includeAll": true,
        "label": "Service:",
        "multi": true,
        "name": "protocol",
        "options": [],
        "query": "label_values(traefik_service_requests_total, protocol)",
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
        "auto": true,
        "auto_count": 30,
        "auto_min": "10s",
        "current": {
          "text": "30m",
          "value": "30m"
        },
        "hide": 0,
        "label": "Interval",
        "name": "interval",
        "options": [
          {
            "selected": false,
            "text": "auto",
            "value": "$__auto_interval_interval"
          },
          {
            "selected": false,
            "text": "1m",
            "value": "1m"
          },
          {
            "selected": false,
            "text": "10m",
            "value": "10m"
          },
          {
            "selected": true,
            "text": "30m",
            "value": "30m"
          },
          {
            "selected": false,
            "text": "1h",
            "value": "1h"
          },
          {
            "selected": false,
            "text": "6h",
            "value": "6h"
          },
          {
            "selected": false,
            "text": "12h",
            "value": "12h"
          },
          {
            "selected": false,
            "text": "1d",
            "value": "1d"
          },
          {
            "selected": false,
            "text": "7d",
            "value": "7d"
          },
          {
            "selected": false,
            "text": "14d",
            "value": "14d"
          },
          {
            "selected": false,
            "text": "30d",
            "value": "30d"
          }
        ],
        "query": "1m,10m,30m,1h,6h,12h,1d,7d,14d,30d",
        "refresh": 2,
        "skipUrlSync": false,
        "type": "interval"
      }
    ]
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Traefik2",
  "uid": "3ipsWfViz",
  "version": 13,
  "description": "Dashboard for Traefik2/Prometheus, based upon the one by ichasco.  Updated for Traefik2 metric names."
}
```

出现的问题：

## 解决Panel plugin not found: grafana-piechart-panel

在pod的shell中输入：

grafana-cli plugins install grafana-piechart-panel

然后删除pod重启即可。

下载traefik监控的json文件，地址为：

https://grafana.com/grafana/dashboards/4475

文件内容如下：

```json
{
  "__inputs": [
    {
      "name": "DS_PROMETHEUS",
      "label": "Prometheus",
      "description": "",
      "type": "datasource",
      "pluginId": "prometheus",
      "pluginName": "Prometheus"
    }
  ],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "7.5.5"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph",
      "version": ""
    },
    {
      "type": "panel",
      "id": "piechart",
      "name": "Pie chart v2",
      "version": ""
    },
    {
      "type": "datasource",
      "id": "prometheus",
      "name": "Prometheus",
      "version": "1.0.0"
    },
    {
      "type": "panel",
      "id": "singlestat",
      "name": "Singlestat",
      "version": ""
    }
  ],
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
  "description": "Traefik dashboard prometheus",
  "editable": true,
  "gnetId": 4475,
  "graphTooltip": 0,
  "id": null,
  "iteration": 1620932097756,
  "links": [],
  "panels": [
    {
      "datasource": null,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 10,
      "title": "$backend stats",
      "type": "row"
    },
    {
      "cacheTimeout": null,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "decimals": 0,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 1
      },
      "id": 2,
      "interval": null,
      "links": [],
      "maxDataPoints": 3,
      "options": {
        "displayLabels": [],
        "legend": {
          "calcs": [],
          "displayMode": "table",
          "placement": "right",
          "values": [
            "value",
            "percent"
          ]
        },
        "pieType": "pie",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "text": {}
      },
      "targets": [
        {
          "exemplar": true,
          "expr": "traefik_service_requests_total{service=\"$service\"}",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{method}} : {{code}}",
          "refId": "A"
        }
      ],
      "title": "$service return code",
      "type": "piechart"
    },
    {
      "cacheTimeout": null,
      "colorBackground": false,
      "colorValue": false,
      "colors": [
        "#299c46",
        "rgba(237, 129, 40, 0.89)",
        "#d44a3a"
      ],
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "format": "ms",
      "gauge": {
        "maxValue": 100,
        "minValue": 0,
        "show": false,
        "thresholdLabels": false,
        "thresholdMarkers": true
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 1
      },
      "id": 4,
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
        "show": true
      },
      "tableColumn": "",
      "targets": [
        {
          "exemplar": true,
          "expr": "sum(traefik_service_request_duration_seconds_sum{service=\"$service\"}) / sum(traefik_service_requests_total{service=\"$service\"}) * 1000",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "thresholds": "",
      "title": "$service response time",
      "type": "singlestat",
      "valueFontSize": "80%",
      "valueMaps": [
        {
          "op": "=",
          "text": "N/A",
          "value": "null"
        }
      ],
      "valueName": "avg"
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "hiddenSeries": false,
      "id": 3,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": false,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.5.5",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "exemplar": true,
          "expr": "sum(rate(traefik_service_requests_total{service=\"$service\"}[5m]))",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "Total requests $service",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Total requests over 5min $service",
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
      "collapsed": false,
      "datasource": null,
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 12,
      "panels": [],
      "title": "Global stats",
      "type": "row"
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 16
      },
      "hiddenSeries": false,
      "id": 5,
      "legend": {
        "alignAsTable": true,
        "avg": false,
        "current": true,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.5.5",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(traefik_entrypoint_requests_total{entrypoint=~\"$entrypoint\",code=\"200\"}[5m])",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{method}} : {{code}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Status code 200 over 5min",
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
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {},
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 16
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "alignAsTable": true,
        "avg": false,
        "current": true,
        "max": true,
        "min": true,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "alertThreshold": true
      },
      "percentage": false,
      "pluginVersion": "7.5.5",
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "rate(traefik_entrypoint_requests_total{entrypoint=~\"$entrypoint\",code!=\"200\"}[5m])",
          "format": "time_series",
          "intervalFactor": 2,
          "legendFormat": "{{ method }} : {{code}}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Others status code over 5min",
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
      "cacheTimeout": null,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "decimals": 0,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 0,
        "y": 23
      },
      "id": 7,
      "interval": null,
      "links": [],
      "maxDataPoints": 3,
      "options": {
        "displayLabels": [],
        "legend": {
          "calcs": [],
          "displayMode": "table",
          "placement": "right",
          "values": [
            "value"
          ]
        },
        "pieType": "pie",
        "reduceOptions": {
          "calcs": [
            "sum"
          ],
          "fields": "",
          "values": false
        },
        "text": {}
      },
      "targets": [
        {
          "exemplar": true,
          "expr": "sum(rate(traefik_service_requests_total[5m])) by (service) ",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{ service }}",
          "refId": "A"
        }
      ],
      "title": "Requests by service",
      "type": "piechart"
    },
    {
      "cacheTimeout": null,
      "datasource": "${DS_PROMETHEUS}",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "decimals": 0,
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 7,
        "w": 12,
        "x": 12,
        "y": 23
      },
      "id": 8,
      "interval": null,
      "links": [],
      "maxDataPoints": 3,
      "options": {
        "displayLabels": [],
        "legend": {
          "calcs": [],
          "displayMode": "table",
          "placement": "right",
          "values": [
            "value"
          ]
        },
        "pieType": "pie",
        "reduceOptions": {
          "calcs": [
            "sum"
          ],
          "fields": "",
          "values": false
        },
        "text": {}
      },
      "targets": [
        {
          "exemplar": true,
          "expr": "sum(rate(traefik_entrypoint_requests_total{entrypoint =~ \"$entrypoint\"}[5m])) by (entrypoint) ",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 2,
          "legendFormat": "{{ entrypoint }}",
          "refId": "A"
        }
      ],
      "title": "Requests by protocol",
      "type": "piechart"
    }
  ],
  "schemaVersion": 27,
  "style": "dark",
  "tags": [
    "traefik",
    "prometheus"
  ],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {},
        "datasource": "${DS_PROMETHEUS}",
        "definition": "label_values(service)",
        "description": null,
        "error": null,
        "hide": 0,
        "includeAll": false,
        "label": null,
        "multi": false,
        "name": "service",
        "options": [],
        "query": {
          "query": "label_values(service)",
          "refId": "StandardVariableQuery"
        },
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
        "current": {},
        "datasource": "${DS_PROMETHEUS}",
        "definition": "",
        "description": null,
        "error": null,
        "hide": 0,
        "includeAll": true,
        "label": null,
        "multi": true,
        "name": "entrypoint",
        "options": [],
        "query": {
          "query": "label_values(entrypoint)",
          "refId": "Prometheus-entrypoint-Variable-Query"
        },
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
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "5s",
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Traefik",
  "uid": "qPdAviJmz",
  "version": 10
}
```

效果如下所示：

![image-20220107090124990](https://s2.loli.net/2022/01/07/rTolkOpFvDnCSQt.png)
