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
COPY  . /usr/blog
# 安装hexo
RUN yarn \
    && yarn global add hexo-cli \
    && hexo g

FROM nginx:alpine
COPY --from=builder  /usr/blog/public /usr/share/nginx/html
RUN apk add --no-cache bash