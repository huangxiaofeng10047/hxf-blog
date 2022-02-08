---
title: minio的docker创建
date: 2021-11-18 09:53:44
tags:
- es
categories: 
- bigdata
---

➜ docker run -d -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -v /data/minio:/data \
  -e "MINIO_ROOT_USER=minioadmin" \
  -e "MINIO_ROOT_PASSWORD=minioadmin" \
  -e MINIO_DOMAIN="xxx.com" \
  --restart=always \
  minio/minio server /data --console-address ":9001"
2508ee6ba64294e45425da7afb3fffb2a31ff9d3fbc9887f5ae5fda705b7d0dc

