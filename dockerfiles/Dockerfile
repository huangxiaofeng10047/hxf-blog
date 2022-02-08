From alpine:latest

MAINTAINER techsharearea

RUN mkdir /install

COPY get-pip.py /install 

RUN apk update && \
    apk add curl && \
    apk add vim && \
    apk add tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk add python3 && \
    python3 /install/get-pip.py && \
    pip install sh requests
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
  apk update && \
  apk add openjdk8 busybox tzdata curl && \
  cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
WORKDIR /opt