---
title: kuboard的https配置
description: '点击阅读前文前, 首页能看到的文章的简短描述'
date: 2022-06-06 13:22:11
tags:
---

一键生成证书系列。
```

#!/bin/bash

# 在该目录下操作生成证书，正好供harbor.yml使用
mkdir -p /data/cert1
cd /data/cert1

openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=www.kuboard.mobi" -key ca.key -out ca.crt
openssl genrsa -out www.kuboard.mobi.key 4096
openssl req -sha512 -new -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=www.kuboard.mobi" -key www.kuboard.mobi.key -out www.kuboard.mobi.csr

cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1=www.kuboard.mobi
DNS.2=harbor
DNS.3=ks-allinone
EOF

openssl x509 -req -sha512 -days 3650 -extfile v3.ext -CA ca.crt -CAkey ca.key -CAcreateserial -in www.kuboard.mobi.csr -out www.kuboard.mobi.crt

openssl x509 -inform PEM -in www.kuboard.mobi.crt -out www.kuboard.mobi.cert

cp www.kuboard.mobi.crt /etc/pki/ca-trust/source/anchors/www.kuboard.mobi.crt
update-ca-trust

```

