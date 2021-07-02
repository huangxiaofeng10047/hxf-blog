FROM node:15.7.0-alpine3.10
MAINTAINER wanf3ng <wanf3ng@gmail.com>

WORKDIR /usr/blog

# 切换中科大源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
# 安装bash git openssh 以及c的编译工具
RUN apk add bash git openssh

# 设置容器时区为上海，不然发布文章的时间是国际时间，也就是比我们晚8个小时
RUN apk add tzdata && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone \
&& apk del tzdata

# 安装hexo
RUN \ 
npm config set registry https://registry.npm.taobao.org \
&&npm install \
&&npm install hexo-cli -g \
&& npm install hexo-server --save \
&& npm install hexo-asset-image --save \
&& npm install hexo-wordcount --save \
&& npm install hexo-generator-sitemap --save \
&& npm install hexo-generator-baidu-sitemap --save \
&& npm install hexo-deployer-git --save

EXPOSE 4000