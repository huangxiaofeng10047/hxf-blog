---
title: k8s安装flink
date: 2021-11-18 16:30:26
tags:
- es
categories: 
- bigdata
---

flink部署在k8s：

本操作中将采用helm来安装：

```
➜ k3d cluster create flink-k3d
INFO[0000] Prep: Network
INFO[0000] Created network 'k3d-flink-k3d' (ec752fd76b3ba73af2ea2f42962da5c3c8ced5018e3a74b929d2e38f9781ab65)
INFO[0001] Created volume 'k3d-flink-k3d-images'
INFO[0002] Creating node 'k3d-flink-k3d-server-0'
INFO[0004] Creating LoadBalancer 'k3d-flink-k3d-serverlb'
INFO[0005] Starting cluster 'flink-k3d'
INFO[0005] Starting servers...
INFO[0005] Starting Node 'k3d-flink-k3d-server-0'
INFO[0017] Starting agents...
INFO[0017] Starting helpers...
INFO[0017] Starting Node 'k3d-flink-k3d-serverlb'
INFO[0020] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
INFO[0028] Successfully added host record to /etc/hosts in 2/2 nodes and to the CoreDNS ConfigMap
INFO[0028] Cluster 'flink-k3d' created successfully!
INFO[0028] --kubeconfig-update-default=false --> sets --kubeconfig-switch-context=false
INFO[0028] You can now use it like this:
kubectl config use-context k3d-flink-k3d
kubectl cluster-info

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0 took 29s
➜ helm repo add riskfocus https://riskfocus.github.io/helm-charts-public
"riskfocus" has been added to your repositories

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0
➜  helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "pingcap" chart repository
...Successfully got an update from the "riskfocus" chart repository
...Successfully got an update from the "nginx-stable" chart repository
...Successfully got an update from the "traefik" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "apphub" chart repository
...Successfully got an update from the "presslabs" chart repository
...Successfully got an update from the "drone" chart repository
Update Complete. ⎈Happy Helming!⎈

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0 took 15s
➜ helm install --name my-flink --namespace flink riskfocus/flink
Error: unknown flag: --name

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0
❯ helm install  my-flink --namespace flink riskfocus/flink
Error: create: failed to create: namespaces "flink" not found

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0 took 9s
❯ kubectl create namespace flink
namespace/flink created

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0 took 13s
➜ helm install  my-flink --namespace flink riskfocus/flink
NAME: my-flink
LAST DEPLOYED: Thu Nov 18 16:15:54 2021
NAMESPACE: flink
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace flink -l "app.kubernetes.io/name=flink,app.kubernetes.io/instance=my-flink" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8081 to use your application"
  kubectl port-forward $POD_NAME 8081:8081

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0 took 13s
➜   export POD_NAME=$(kubectl get pods --namespace flink -l "app.kubernetes.io/name=flink,app.kubernetes.io/instance=my-flink" -o jsonpath="{.items[0].metadata.name}")

flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0
➜   kubectl port-forward $POD_NAME 8081:8081
Error from server (NotFound): pods "my-flink-jobmanager-67fbf68486-tsknt" not found


flomesh-bookinfo-demo/kubernetes on  master [🏎💨 ] via  v10.0.0
❯ kubectl port-forward my-flink-jobmanager-67fbf68486-tsknt 8081:8081 -n flink

Forwarding from 127.0.0.1:8081 -> 8081
Forwarding from [::1]:8081 -> 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
```

