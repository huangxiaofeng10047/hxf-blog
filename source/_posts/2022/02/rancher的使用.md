---
title: rancher的使用
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-02-14 10:46:36
tags:
---
rancher界面无法登录，ui打开无法访问：
查看log ，docker logs -f rancher ，报错如下：

2022/02/14 00:02:38 [INFO] Waiting for server to become available: Get https://127.0.0.1:6443/version?timeout=30s: x509: certificate has expired or is not yet valid
2022/02/14 00:02:40 [INFO] Waiting for server to become available: Get https://127.0.0.1:6443/version?timeout=30s: x509: certificate has expired or is not yet valid

```
rancher_server_id=<rancher_server_container_id>
docker exec -it ${rancher_server_id} /bin/bash
cd k3s/server/tls
## 查看所有证书文件的期限

for i in `ls *.crt` ;do openssl x509 -in $i -noout -dates;echo $i;done
出现如下结果：
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-admin.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-auth-proxy.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Nov 10 02:57:23 2030 GMT
client-ca.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-cloud-controller.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-controller.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-k3s-controller.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-kube-apiserver.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-kube-proxy.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
client-scheduler.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Nov 10 02:57:23 2030 GMT
request-header-ca.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Nov 10 02:57:23 2030 GMT
server-ca.crt
notBefore=Nov 12 02:57:23 2020 GMT
notAfter=Sep  4 07:04:00 2022 GMT
serving-kube-apiserver.crt
```
解决办法，删除相关key，重启即可
```
#第一步，进入到容器内部
docker exec -it rancher /bin/bash
#第二步，执行删除操作
kubectl --insecure-skip-tls-verify -n kube-system delete secrets k3s-serving
kubectl --insecure-skip-tls-verify delete secret serving-cert -n cattle-system
rm -f /var/lib/rancher/k3s/server/tls/dynamic-cert.json
第三步：退出rancher容器，执行docker命令即可。
docker restart ${rancher_server_id}
```

rancher部署成功后界面如下：

![image-20220214144934916](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20220214144934916.png)
