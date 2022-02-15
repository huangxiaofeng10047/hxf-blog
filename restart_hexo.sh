#!/bin/bash
PROCESS=`ps -ef|grep hexo|grep -v grep|grep -v PPID|awk '{ print $2 }'`
PROC_NAME="pm2"
for i in $PROCESS
do
echo "Kill the $1 process [ $i ]"
kill -9 $i
done
hexo clean #清除数据
hexo generate #生成静态文件public文件夹
ProcNumber=`ps -ef |grep -w $PROC_NAME|grep -v grep|wc -l`
if [ $ProcNumber -le 0 ];then
pm2 start hexo_run.js
else
pm2 restart hexo_run.js
fi
service nginx restart
