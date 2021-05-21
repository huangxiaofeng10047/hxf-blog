---
title: helm安装gitlab-ce
date: 2021-05-19 17:19:39
tags:
---
第一步添加stablehelm源
helm repo add stable https://charts.helm.sh/stable
第二步修改values.yaml文件
```
## GitLab CE image
## ref: https://hub.docker.com/r/gitlab/gitlab-ce/tags/
##
image: gitlab/gitlab-ce:9.4.1-ce.0

## Specify a imagePullPolicy
## 'Always' if imageTag is 'latest', else set to 'IfNotPresent'
## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
##
# imagePullPolicy:

## The URL (with protocol) that your users will use to reach the install.
## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-the-external-url-for-gitlab
##
externalUrl: http://my.gitlab.com/

## Change the initial default admin password if set. If not set, you'll be
## able to set it when you first visit your install.
##
gitlabRootPassword: "123456"

## For minikube, set this to NodePort, elsewhere use LoadBalancer
## ref: http://kubernetes.io/docs/user-guide/services/#publishing-services---service-types
##
serviceType: NodePort

## Ingress configuration options
##
ingress:
  annotations:
      # kubernetes.io/ingress.class: nginx
      # kubernetes.io/tls-acme: "true"
  enabled: false
  tls:
      # - secretName: gitlab.cluster.local
      #   hosts:
      #     - gitlab.cluster.local
  url: gitlab.cluster.local

## Configure external service ports
## ref: http://kubernetes.io/docs/user-guide/services/
sshPort: 22
httpPort: 80
httpsPort: 443
## livenessPort Port of liveness probe endpoint
livenessPort: http
## readinessPort Port of readiness probe endpoint
readinessPort: http

## Configure resource requests and limits
## ref: http://kubernetes.io/docs/user-guide/compute-resources/
##
resources:
  ## GitLab requires a good deal of resources. We have split out Postgres and
  ## redis, which helps some. Refer to the guidelines for larger installs.
  ## ref: https://docs.gitlab.com/ce/install/requirements.html#hardware-requirements
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1

## Enable persistence using Persistent Volume Claims
## ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
## ref: https://docs.gitlab.com/ce/install/requirements.html#storage
##
persistence:
  ## This volume persists generated configuration files, keys, and certs.
  ##
  gitlabEtc:
    enabled: true
    size: 1Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce
  ## This volume is used to store git data and other project files.
  ## ref: https://docs.gitlab.com/omnibus/settings/configuration.html#storing-git-data-in-an-alternative-directory
  ##
  gitlabData:
    enabled: true
    size: 10Gi
    ## If defined, volume.beta.kubernetes.io/storage-class: <storageClass>
    ## Default: volume.alpha.kubernetes.io/storage-class: default
    ##
    # storageClass:
    accessMode: ReadWriteOnce

## Configuration values for the postgresql dependency.
## ref: https://github.com/kubernetes/charts/blob/master/stable/postgresql/README.md
##
postgresql:
  # 9.6 is the newest supported version for the GitLab container
  imageTag: "9.6"
  cpu: 1000m
  memory: 1Gi

  postgresUser: gitlab
  postgresPassword: gitlab
  postgresDatabase: gitlab

  persistence:
    size: 10Gi

## Configuration values for the redis dependency.
## ref: https://github.com/kubernetes/charts/blob/master/stable/redis/README.md
##
redis:
  redisPassword: "gitlab"

  resources:
    requests:
      memory: 1Gi

  persistence:
    size: 10Gi
```
执行helm命令安装

`gitlab-helm helm install --namespace gitlab --generate-name -f values.yaml stable/gitlab-ce`
`WARNING: This chart is deprecated`
`Error: Kubernetes cluster unreachable: an error on the server ("") has prevented the request from succeeding`

解决办法下载下来进行文件修改，

```
➜  gitlab-helm helm search repo gitlab
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION
aliyun/gitlab-ce             	0.2.1        	           	GitLab Community Edition
aliyun/gitlab-ee             	0.2.1        	           	GitLab Enterprise Edition
gitlab/gitlab                	4.11.4       	13.11.4    	Web-based Git-repository manager with wiki and ...
gitlab/gitlab-omnibus        	0.1.37       	           	GitLab Omnibus all-in-one bundle
gitlab/gitlab-runner         	0.28.0       	13.11.0    	GitLab Runner
gitlab/kubernetes-gitlab-demo	0.1.29       	           	GitLab running on Kubernetes suitable for demos
stable/gitlab-ce             	0.2.3        	9.4.1      	GitLab Community Edition
stable/gitlab-ee             	0.2.3        	9.4.1      	GitLab Enterprise Edition
gitlab/apparmor              	0.2.0        	0.1.0      	AppArmor profile loader for Kubernetes
gitlab/auto-deploy-app       	0.8.1        	           	GitLab's Auto-deploy Helm Chart
gitlab/elastic-stack         	3.0.0        	7.6.2      	A Helm chart for Elastic Stack
gitlab/fluentd-elasticsearch 	6.2.8        	2.8.0      	A Fluentd Helm chart for Kubernetes with Elasti...
gitlab/knative               	0.10.0       	0.9.0      	A Helm chart for Knative
gitlab/plantuml              	0.1.17       	1.0        	PlantUML server
➜  gitlab-helm ls
values.yaml
➜  gitlab-helm helm pull aliyun/gitlab-ce
➜  gitlab-helm ls
gitlab-ce-0.2.1.tgz values.yaml
➜  gitlab-helm tar xf gitlab-ce-0.2.1.tgz
➜  gitlab-helm cd gitlab-ce
➜  gitlab-ce ls
Chart.yaml        requirements.yaml
README.md         templates
charts            values.yaml
```

修改文件：

 grep -irl "extensions/v1beta1" gitlab-ce | grep deployment

grep -irl "extensions/v1beta1" gitlab-ce | grep deploy | xargs sed -i 's#extensions/v1beta1#apps/v1#g'

这个是解决

错误解决2.1 版本问题Error: unable to build kubernetes objects from release manifest: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1”

接下会遇到第二个问题：

deployment错误原因是现有 k8s不支持gitlab-ce的deployment specError: unable to build kubernetes objects from release manifest: error validating "": error validating data: ValidationError(Deployment.spec): missing required field "selector" in io.k8s.api.apps.v1.DeploymentSpec解决:

 grep -irl "apps/v1" gitlab-ce | grep deployment
gitlab-ce/charts/redis/templates/deployment.yaml
gitlab-ce/charts/postgresql/templates/deployment.yaml
gitlab-ce/templates/deployment.yaml


​      
​      
​    
  依次修改三个配置文件
​    
    vim gitlab-ce/templates/deployment.yaml

添加：

  replicas: 1
  selector:
    matchLabels:
      app: {{ template "gitlab-ce.fullname" . }}

接下来进行安装：

`➜  gitlab-ce kubectl create namespace devops`
`namespace/devops created`
`➜  gitlab-ce helm install gitlab -n devops .`
`WARNING: This chart is deprecated`
`NAME: gitlab`
`LAST DEPLOYED: Thu May 20 13:41:08 2021`
`NAMESPACE: devops`
`STATUS: deployed`
`REVISION: 1`
`TEST SUITE: None`
`NOTES:`
`##############################################################################`
`This chart has been deprecated in favor of the official GitLab chart:`
`http://docs.gitlab.com/ce/install/kubernetes/gitlab_omnibus.html`
`##############################################################################`

1. `Get your GitLab URL by running:`

  `NOTE: It may take a few minutes for the LoadBalancer IP to be available.`
        `Watch the status with: 'kubectl get svc -w gitlab-gitlab-ce'`

  `export SERVICE_IP=$(kubectl get svc --namespace devops gitlab-gitlab-ce -o jsonpath='{.status.loadBalancer.ingress[0].ip}')`
  `echo http://$SERVICE_IP/`

2. `Login as the root user:`

  `Username: root`
  `Password: 123456`


3. `Point a DNS entry at your install to ensure that your specified`
   `external URL is reachable:`

   `http://mymygitlab.cegitlab.ce.com/`
   `➜  gitlab-ce kubectl get svc -n devops`
   `NAME                TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                   AGE`
   `gitlab-gitlab-ce    LoadBalancer   10.104.15.253   localhost     22:31327/TCP,80:32437/TCP,443:32012/TCP   2m39s`
   `gitlab-postgresql   ClusterIP      10.98.50.53     <none>        5432/TCP                                  2m39s`
   `gitlab-redis        ClusterIP      10.98.114.78    <none>        6379/TCP                                  2m39s`

下面开始安装ingress暴露这个gitlab的服务：

​    subl git-ingress-route.yaml

```
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: nginx-test
  namespace: devops
spec:
  entryPoints:
    # 指定入口点为web。这里的web就是traefik静态配置(启动参数)中的 --entryPoints.web.address=:8000,通过仪表盘也可以看到
    - web
  routes:
    - kind: Rule
      match: Host(`git.test.com`) # 匹配规则,第三部分说明
      services:
        - name: gitlab-gitlab-ce
          port: 80
```

安装traefik服务

`➜  gitlab-ce helm install --namespace=devops traefik traefik/traefik`

暴露traefik服务

 `kubectl port-forward --address=0.0.0.0 -n devops $(kubectl get pods -n devops --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000`

`Forwarding from 0.0.0.0:9000 -> 9000`

安装trafik controller

kubectl create -f  git-ingress-route.yaml

在本地配置127.0.0.1 git.test.com

kubectl port-forward --address=0.0.0.0 -n devops $(kubectl get pods -n devops --selector "app.kubernetes.io/name=traefik" --output=name) 9001:8000

访问git.test.com:9001即可。