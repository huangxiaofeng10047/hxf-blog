---
title: eck部署1
description: 点击阅读前文前, 首页能看到的文章的简短描述
date: 2022-01-27 16:49:59
tags:
---

# Kuberentes 1.22.3搭建eck

# 前言：

kubernetes1.16版本的时候安装了elastic on kubernetes（ECK）1.0版本。存储用了local disk文档跑了一年多了。elasticsearch对应版本是7.6.2。现在已完成了kubernetes 1.20.5 containerd cilium hubble 环境的搭建（https://blog.csdn.net/saynaihe/article/details/115187298）并且集成了cbs腾讯云块存储（https://blog.csdn.net/saynaihe/article/details/115212770）。eck也更新到了1.5版本(我能说我前天安装的时候还是1.4.0吗.....还好我只是简单应用没有太复杂的变化无非版本变了....那就再来一遍吧)

最早部署的kubernetes1.16版本的eck安装方式https://duiniwukenaihe.github.io/2019/10/21/k8s-efk/多年前搭建的eck1.0版本。

## 关于eck  

elastic cloud on kubernetes是一种operator的安装方式，很大程度上简化了应用的部署。同样的还有promtheus-operator。

可参照https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-deploy-eck.html官方文档的部署方式。

# 1. 在kubernete集群中部署ECK

## 1. 安装[自定义资源定义](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)和操作员及其RBAC规则：

~~kubectl apply -f https://download.elastic.co/downloads/eck/1.5.0/all-in-one.yaml~~

```sh
kubectl create -f https://download.elastic.co/downloads/eck/1.9.1/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/1.9.1/operator.yaml
```

## 2. 监视操作日志：

kubectl -n elastic-system logs -f statefulset.apps/elastic-operator



-----------------------分隔符-----------------

我是直接把yaml下载到本地了。

```plain
###至于all-in-one.yaml.1后面的1可以忽略了哈哈，第二次加载文件加后缀了。
kubectl apply -f all-in-one.yaml
kubectl -n elastic-system logs -f statefulset.apps/elastic-operator
```

# 2. 部署elasticsearch集群

## 1. 定制化elasticsearch 镜像

增加s3插件，修改时区东八区，并添加腾讯云cos的秘钥，并重新打包elasticsearch镜像.

#### 1. DockerFile如下

```
 cat Dockerfile
FROM docker.elastic.co/elasticsearch/elasticsearch:7.12.0
ARG ENDPOINT=cos.ap-shanghai.myqcloud.com
ARG ES_VERSION=7.12.0

ARG PACKAGES="net-tools lsof"
ENV allow_insecure_settings 'true'
RUN rm -rf /etc/localtime && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN echo 'Asia/Shanghai' > /etc/timezone
RUN  if [ -n "${PACKAGES}" ]; then  yum install -y $PACKAGES && yum clean all && rm -rf /var/cache/yum; fi
```

#### 2.打包推送到私服

```
 docker build -t 192.168.20.50/kuboard/elasticsearch:7.12.0 .
 docker push 192.168.20.50/kuboard/elasticsearch:7.12.0
```

## 2. 创建elasticsearch部署yaml文件，部署elasticsearch集群

修改了自己打包 image tag ，使用了腾讯云cbs csi块存储。并定义了部署的namespace，创建了namespace logging.



### 1. 创建部署elasticsearch应用的命名空间

```plain
kubectl create ns logging
cat <<EOF > elastic.yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elastic
  namespace: logging
spec:
  version: 7.12.0
  image: ccr.ccs.tencentyun.com/XXXX/elasticsearch:7.12.0
  nodeSets:
  - name: laya
    count: 3
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          env:
          - name: ES_JAVA_OPTS
            value: -Xms2g -Xmx2g
          resources:
            requests:
              memory: 4Gi
              cpu: 0.5
            limits:
              memory: 4Gi
              cpu: 2
    config:
      node.master: true
      node.data: true
      node.ingest: true
      node.store.allow_mmap: false
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        storageClassName: cbs-csi 
        resources:
          requests:
            storage: 200Gi
EOF          
```

  2. 部署yaml文件并查看应用部署状态 



```
kubectl apply -f elastic.yaml
```

```
kubectl get elasticsearch -n logging
```

```
kubectl get elasticsearch -n logging
```

```
kubectl -n logging get pods --selector='elasticsearch.k8s.elastic.co/cluster-name=elastic'
```

  3. 获取elasticsearch凭据 

```
kubectl -n logging get secret elastic-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo
```

## 4. 直接安装kibana了

kibana的镜像

```
FROM docker.elastic.co/kibana/kibana:7.12.0
ARG ENDPOINT=cos.ap-shanghai.myqcloud.com
ARG KIB_VERSION=7.12.0

ARG PACKAGES="net-tools lsof"
ENV allow_insecure_settings 'true'
USER root
RUN rm -rf /etc/localtime &&  cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN  echo 'Asia/Shanghai' > /etc/timezone
RUN  if [ -n "${PACKAGES}" ]; then  yum install -y $PACKAGES && yum clean all && rm -rf /var/cache/yum; fi
USER kibana
```

修改了时区，和elasticsearch镜像一样都修改到了东八区，并将语言设置成了中文，关于selfSignedCertificate原因参照https://www.elastic.co/guide/en/cloud-on-k8s/1.4/k8s-kibana-http-configuration.html。

```
cat <<EOF > kibana.yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: elastic
  namespace: logging
spec:
  version: 7.12.0
  image: www.harbor.mobi/kuboard/kibana:7.12.0
  count: 1
  elasticsearchRef:
    name: elastic
  podTemplate:
    spec:
      containers:
      - name: kibana
        env:
        - name: I18N_LOCALE
          value: zh-CN
        resources:
          requests:
            memory: 1Gi
          limits:
            memory: 2Gi
        volumeMounts:
        - name: timezone-volume
          mountPath: /etc/localtime
          readOnly: true
      volumes:
      - name: timezone-volume
        hostPath:
          path: /usr/share/zoneinfo/Asia/Shanghai
EOF          
```

​          

```
kubectl apply kibana.yaml
```

## 5. 对外映射kibana 服务

对外暴露都是用traefik https 代理，命名空间添加tls secret。绑定内部kibana service.然后外部slb udp代理443端口。但是现在腾讯云slb可以挂载多个证书了，就把这层剥离了，直接http方式到80端口 。然后https 证书 都在slb负载均衡代理了。这样省心了证书的管理，还有一点是可以在slb层直接收集接入层日志到cos。并可使用腾讯云自有的日志服务。

```shell
❯ cat traefik-kibana-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-kb-http
  namespace: logging
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: kibana.saynaihe.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: elastic-kb-http
            port:
              number: 5601
```

输入 用户名elastic  密码为上面获取的elasticsearch的凭据，进入管理页面。新界面很是酷炫

![image-20220111093952816](https://s2.loli.net/2022/01/11/j3BlQAUDzp6HaIb.png)

```
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: monitor
  namespace: logging
spec:
  version: 7.6.2
  nodeSets:
  - name: mdi
    count: 3
    config:
      node.master: true
      node.data: true
      node.ingest: true
      node.store.allow_mmap: false
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 50Gi
        storageClassName: nfs-client
  http:
    service:
      spec:
        type: NodePort
---
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: monitor
  namespace: logging
spec:
  version: 7.6.2
  count: 1
  elasticsearchRef:
    name: "elastic"
  http:
    service:
      spec:
        type: NodePort
```

部署filebeat：

使用dockerhub中的镜像，版本改为7.6.2.

```
sed -i 's#docker.elastic.co/beats/filebeat:7.6.0#elastic/filebeat:7.6.2#g' 2_filebeat-kubernetes.yaml
kubectl apply -f 2_filebeat-kubernetes.yaml
```

查看创建的pods

```
[root@master01 beats]# kubectl -n beats get pods -l k8s-app=filebeat
NAME             READY   STATUS    RESTARTS   AGE
filebeat-dctrz   1/1     Running   0          9m32s
filebeat-rgldp   1/1     Running   0          9m32s
filebeat-srqf4   1/1     Running   0          9m32s
```

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: logging
  labels:
    k8s-app: filebeat
data:
  filebeat.yml: |-
    filebeat.autodiscover:
      providers:
        - type: kubernetes
          host: ${NODE_NAME}
          hints.enabled: true
          hints.default_config:
            type: container
            paths:
              - /var/log/containers/*${data.kubernetes.container.id}.log

    processors:
      - add_cloud_metadata:
      - add_host_metadata:

    output.elasticsearch:
      hosts: ['https://${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
      username: ${ELASTICSEARCH_USERNAME}
      password: ${ELASTICSEARCH_PASSWORD}
      ssl.certificate_authorities:
      - /mnt/elastic/tls.crt
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: logging
  labels:
    k8s-app: filebeat
spec:
  selector:
    matchLabels:
      k8s-app: filebeat
  template:
    metadata:
      labels:
        k8s-app: filebeat
    spec:
      serviceAccountName: filebeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:7.6.0
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: ELASTICSEARCH_HOST
          value: monitor-es-http
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: ELASTICSEARCH_USERNAME
          value: elastic
        - name: ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              key: elastic
              name: monitor-es-elastic-user
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
          # If using Red Hat OpenShift uncomment this:
          #privileged: true
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          readOnly: true
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: es-certs
          mountPath: /mnt/elastic/tls.crt
          readOnly: true
          subPath: tls.crt
      volumes:
      - name: config
        configMap:
          defaultMode: 0600
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: varlog
        hostPath:
          path: /var/log
      # data folder stores a registry of read status for all files, so we don't send everything again on a Filebeat pod restart
      - name: data
        hostPath:
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
      - name: es-certs
        secret:
          secretName: monitor-es-http-certs-public
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: logging
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: filebeat
  labels:
    k8s-app: filebeat
rules:
- apiGroups: [""] # "" indicates the core API group
  resources:
  - namespaces
  - pods
  verbs:
  - get
  - watch
  - list
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: logging
  labels:
    k8s-app: filebeat
---

```

遇到问题：

在内网部署时，filebeat启动失败，报错信息为：

registry file version 1 not supported。

这个报错的原因是对应的data目录下文件为旧版本文件，所以需要处理掉。

删除即可。

参考文档：

[https://www.cnblogs.com/leozhanggg/p/13036681.html]: https://www.cnblogs.com/leozhanggg/p/13036681.html	"filebeat启动报错"



部署metrics：

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-daemonset-config
  namespace: logging
  labels:
    k8s-app: metricbeat
data:
  metricbeat.yml: |-
    metricbeat.config.modules:
      # Mounted `metricbeat-daemonset-modules` configmap:
      path: ${path.config}/modules.d/*.yml
      # Reload module configs as they change:
      reload.enabled: false

    # To enable hints based autodiscover uncomment this:
    metricbeat.autodiscover:
      providers:
        - type: kubernetes
          host: ${NODE_NAME}
          hints.enabled: true

    processors:
      - add_cloud_metadata:

    output.elasticsearch:
      hosts: ['https://${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
      username: ${ELASTICSEARCH_USERNAME}
      password: ${ELASTICSEARCH_PASSWORD}
      ssl.certificate_authorities:
      - /mnt/elastic/tls.crt
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-daemonset-modules
  namespace: logging
  labels:
    k8s-app: metricbeat
data:
  system.yml: |-
    - module: system
      period: 10s
      metricsets:
        - cpu
        - load
        - memory
        - network
        - process
        - process_summary
        #- core
        #- diskio
        #- socket
      processes: ['.*']
      process.include_top_n:
        by_cpu: 5      # include top 5 processes by CPU
        by_memory: 5   # include top 5 processes by memory

    - module: system
      period: 1m
      metricsets:
        - filesystem
        - fsstat
      processors:
      - drop_event.when.regexp:
          system.filesystem.mount_point: '^/(sys|cgroup|proc|dev|etc|host|lib)($|/)'
  kubernetes.yml: |-
    - module: kubernetes
      metricsets:
        - node
        - system
        - pod
        - container
        - volume
      period: 10s
      host: ${NODE_NAME}
      hosts: ["https://${HOSTNAME}:10250"]
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      ssl.verification_mode: "none"
      # If using Red Hat OpenShift remove ssl.verification_mode entry and
      # uncomment these settings:
      #ssl.certificate_authorities:
        #- /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
    - module: kubernetes
      metricsets:
        - proxy
      period: 10s
      host: ${NODE_NAME}
      hosts: ["localhost:10249"]
---
# Deploy a Metricbeat instance per node for node metrics retrieval
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: metricbeat
  namespace: logging
  labels:
    k8s-app: metricbeat
spec:
  selector:
    matchLabels:
      k8s-app: metricbeat
  template:
    metadata:
      labels:
        k8s-app: metricbeat
    spec:
      serviceAccountName: metricbeat
      terminationGracePeriodSeconds: 30
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: metricbeat
        image: docker.elastic.co/beats/metricbeat:7.6.0
        args: [
          "-c", "/etc/metricbeat.yml",
          "-e",
          "-system.hostfs=/hostfs",
          "-d", "autodiscover",
          "-d", "kubernetes",
        ]
        env:
        - name: ELASTICSEARCH_HOST
          value: elastic-es-http
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: ELASTICSEARCH_USERNAME
          value: elastic
        - name: ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              key: elastic
              name: elastic-es-elastic-user
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/metricbeat.yml
          readOnly: true
          subPath: metricbeat.yml
        - name: modules
          mountPath: /usr/share/metricbeat/modules.d
          readOnly: true
        - name: dockersock
          mountPath: /var/run/docker.sock
        - name: proc
          mountPath: /hostfs/proc
          readOnly: true
        - name: cgroup
          mountPath: /hostfs/sys/fs/cgroup
          readOnly: true
        - name: es-certs
          mountPath: /mnt/elastic/tls.crt
          readOnly: true
          subPath: tls.crt
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: cgroup
        hostPath:
          path: /sys/fs/cgroup
      - name: dockersock
        hostPath:
          path: /var/run/docker.sock
      - name: config
        configMap:
          defaultMode: 0600
          name: metricbeat-daemonset-config
      - name: modules
        configMap:
          defaultMode: 0600
          name: metricbeat-daemonset-modules
      - name: data
        hostPath:
          path: /var/lib/metricbeat-data
          type: DirectoryOrCreate
      - name: es-certs
        secret:
          secretName: elastic-es-http-certs-public
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-deployment-config
  namespace: logging
  labels:
    k8s-app: metricbeat
data:
  metricbeat.yml: |-
    metricbeat.config.modules:
      # Mounted `metricbeat-daemonset-modules` configmap:
      path: ${path.config}/modules.d/*.yml
      # Reload module configs as they change:
      reload.enabled: false

    processors:
      - add_cloud_metadata:
    
    setup.dashboards.enabled: true

    setup.kibana:
      host: "https://${KIBANA_HOST:kibana}:${KIBANA_PORT:5601}"
      ssl.enabled: true
      ssl.certificate_authorities:
      - /mnt/kibana/ca.crt

    output.elasticsearch:
      hosts: ['https://${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
      username: ${ELASTICSEARCH_USERNAME}
      password: ${ELASTICSEARCH_PASSWORD}
      ssl.certificate_authorities:
      - /mnt/elastic/tls.crt

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metricbeat-deployment-modules
  namespace: logging
  labels:
    k8s-app: metricbeat
data:
  # This module requires `kube-state-metrics` up and running under `kube-system` namespace
  kubernetes.yml: |-
    - module: kubernetes
      metricsets:
        - state_node
        - state_deployment
        - state_replicaset
        - state_pod
        - state_container
        # Uncomment this to get k8s events:
        #- event
      period: 10s
      host: ${NODE_NAME}
      hosts: ["kube-state-metrics.kube-system:8080"]
---
# Deploy singleton instance in the whole cluster for some unique data sources, like kube-state-metrics
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metricbeat
  namespace: logging
  labels:
    k8s-app: metricbeat
spec:
  selector:
    matchLabels:
      k8s-app: metricbeat
  template:
    metadata:
      labels:
        k8s-app: metricbeat
    spec:
      serviceAccountName: metricbeat
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      containers:
      - name: metricbeat
        image: docker.elastic.co/beats/metricbeat:7.6.0
        args: [
          "-c", "/etc/metricbeat.yml",
          "-e",
          "-d", "autodiscover",
        ]
        env:
        - name: ELASTICSEARCH_HOST
          value: elastic-es-http
        - name: ELASTICSEARCH_PORT
          value: "9200"
        - name: ELASTICSEARCH_USERNAME
          value: elastic
        - name: ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              key: elastic
              name: elastic-es-elastic-user
        - name: KIBANA_HOST
          value: elastic-kb-http
        - name: KIBANA_PORT
          value: "5601"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 100Mi
        volumeMounts:
        - name: config
          mountPath: /etc/metricbeat.yml
          readOnly: true
          subPath: metricbeat.yml
        - name: modules
          mountPath: /usr/share/metricbeat/modules.d
          readOnly: true
        - name: es-certs
          mountPath: /mnt/elastic/tls.crt
          readOnly: true
          subPath: tls.crt
        - name: kb-certs
          mountPath:  /mnt/kibana/ca.crt
          readOnly: true
          subPath: ca.crt
      volumes:
      - name: config
        configMap:
          defaultMode: 0600
          name: metricbeat-deployment-config
      - name: modules
        configMap:
          defaultMode: 0600
          name: metricbeat-deployment-modules
      - name: es-certs
        secret:
          secretName: elastic-es-http-certs-public
      - name: kb-certs
        secret:
          secretName: elastic-kb-http-certs-public
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metricbeat
subjects:
- kind: ServiceAccount
  name: metricbeat
  namespace: logging
roleRef:
  kind: ClusterRole
  name: metricbeat
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: metricbeat
  labels:
    k8s-app: metricbeat
rules:
- apiGroups: [""]
  resources:
  - nodes
  - namespaces
  - events
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: ["extensions"]
  resources:
  - replicasets
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources:
  - statefulsets
  - deployments
  - replicasets
  verbs: ["get", "list", "watch"]
- apiGroups:
  - ""
  resources:
  - nodes/stats
  verbs:
  - get
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metricbeat
  namespace: logging
  labels:
    k8s-app: metricbeat
---

```

