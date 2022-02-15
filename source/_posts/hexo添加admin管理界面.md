title: hexo添加admin管理界面
author: huangxiaofeng10047
date: 2022-02-15 16:45:46
description: 'hexo添加admin管理界面'
tags:
---
# 添加hexo-admin
```
npm install --save hexo-admin

```
# 启动
```
hexo s
```
访问web界面：
http://locathost:4000/admin
选择setting

输入对应的配置
输入用户名
输入密码
输入secret
```
admin:
  username: huangxiaofeng
  password_hash: $2a$10$RJeVWzJQvFn0bE8nDIRNpelBAdQiHPSGTJBkSrse7nQLXS54bd282
  secret: hxf18482
  deployCommand: './admin_script/hexo-generate.sh'    
```
重启即可。
# 通过pm2来启动服务

hexo_run.js
```
const { exec } = require('child_process')
exec('hexo server -p 8001 -d',(error, stdout, stderr) => {
if(error){
console.log('exec error: ${error}')
return
}
console.log('stdout: ${stdout}');
console.log('stderr: ${stderr}');
})
```
该脚本8001端口提供服务。
启动命令如下：
```
pm2 start hexo_run.js
```