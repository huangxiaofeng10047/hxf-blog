#!/usr/bin/env bash
 
NAME=registry.cn-hangzhou.aliyuncs.com/terminus
TAG=apline:python3.8
 
TAG_LOCAL=${NAME}/${TAG}

docker build -t ${TAG_LOCAL} .

docker push ${TAG_LOCAL}	# 推送至dockerhub镜像仓库