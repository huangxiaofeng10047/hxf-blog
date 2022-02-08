---
title: webpack压缩js文件
date: 2021-09-28 16:14:14
tags:
- hexo
categories: 
- hexo
---

**Webpack** 简称**模块打包机**  
在一个Web项目中 会引入很多文件 例如css文件 js文件 字体文件 图片文件 模板文件 等  
引入过多文件将导致网页加载速度变慢 而Webpack则可以解决各个包之间错综复杂的依赖关系

**Webpack**是前端的一个**项目构建工具** 基于**Node.js**开发  
因此 若要使用webpack **必须先安装Node.js**

<!--more-->

借助Webpack这个前端自动化构建工具 可以完美实现资源的合并 打包 压缩 混淆等诸多功能

_示意图：_  
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200423214931247.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1BpY29uam8=,size_16,color_FFFFFF,t_70)

官网：[https://webpack.github.io](https://webpack.github.io/)

___

在新版本中 需要分开安装**webpack**和**webpack-cli**

### 安装webpack：

-   方式一：运行`npm i webpack -g`全局安装webpack 这样就能全局使用webpack的命令了  
    ![在这里插入图片描述](https://img-blog.csdnimg.cn/20200423215936606.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1BpY29uam8=,size_16,color_FFFFFF,t_70)
    
-   方式二：在项目根目录运行`npm i webpack --save-dev`以安装到项目依赖中  
    ![在这里插入图片描述](https://img-blog.csdnimg.cn/20200423215838403.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1BpY29uam8=,size_16,color_FFFFFF,t_70)
    

(注：可能是我的webpack是最新版本的关系 我只有方式二可用 我用了方式一安装后还是提示未安装webpack 有了解的大佬可在评论留言解惑)

### 安装webpack-cli：

在项目根目录下输入`npm install webpack-cli -g` 进行全局安装  
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200423222926332.png)

___

用Webpack打包 可以实现**兼容性的转换**

不推荐直接在页面文件里引用任何包和任何css文件 这会拖慢项目的加载速度  
可在一个**单独的JS文件**里定义 这样 只需加载该JS文件即可

**示例目录**：

-   src 存放源代码
    
    -   css
    -   images
    -   js
    -   index.html 首页
    -   main.js 项目的JS入口文件
-   dist 项目发布目录
    

## 1、首先 初始化npm

![在这里插入图片描述](https://gitee.com/hxf88/imgrepo/raw/master/img/20200423222209662.png)

## 2、用npm安装所需的包

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200423222310479.png)

## 3、编写JS入口文件(被打包的文件)

使用Webpack之后 可以**在JS脚本文件里引入另外的JS脚本文件**  
**由Webpack来处理JS文件之间的互相依赖关系**  
这就使得 整个页面只引入一个JS文件成为可能

`import ... from ...`这种语法是ES6中**导入模块**的方式 会自动从node\_modules里导入指定的包

```
import $ from "jquery" 

$(function()
{
    $("li:odd").css("backgroundColor","red")
    $("li:even").css("backgroundColor","blue")
})
```

**由于ES6的代码过于高级 浏览器浏览器不识别 解析不了 因此在浏览器中该行的执行会报错**

此时 可在项目根目录下 输入`webpack ./src/main.js -o ./dist/bundle.js`  
这代表着 用webpack对src目录下的main.js进行**打包处理** 处理完毕后的文件是dist目录下的bundle.js

语法：`webpack 要打包的文件的路径 -o 输出的打包好的文件路径`  
![在这里插入图片描述](https://img-blog.csdnimg.cn/2020042322300889.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L1BpY29uam8=,size_16,color_FFFFFF,t_70)  
**经过Webpack的打包处理 解决了兼容性的问题 可在页面中直接引用**

## 4、在页面中引入经过webpack转换后的js文件：

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    
    <script src="../dist/bundle.js"></script>
</head>
<body>
    <ul>
        <li>1</li>
        <li>2</li>
        <li>3</li>
        <li>4</li>
    </ul>
</body>
</html>
```

___

每当修改js原文件 都需要重新进行一次webpack的打包  
然而 每次要指定原文件路径和输出文件路径  
通过修改Webpack的配置文件 可实现只输入`webpack`即可自动打包

### 在项目根目录下创建一个名为`webpack.config.js`的配置文件(该名称是固定的)：

由于webpack是基于Nodejs构建的 因此可使用Nodejs中的语法

```

const path=require("path")


module.exports={
    entry:path.join(__dirname,"./src/main.js"), 
    output:{
        path:path.join(__dirname,"./dist"), 
        filename:"bundle.js" 
    }
}
```

如此配置完毕之后 输入`webpack` 就相当于输入`webpack ./src/main.js -o ./dist/bundle.js`了

其执行顺序是：

-   **1**、webpack发现用户并没有在命令中指定打包入口和出口
-   **2**、随后 webpack就会去项目根目录中查找名为webpack.config.js的配置文件
-   **3**、当找到配置文件后 webpack会解析该配置文件 解析完毕之后 得到文件中配置的配置对象(即module.exports暴露的配置对象)
-   **4**、webpack拿到配置对象后 即可成功获得配置对象中指定的入口和出口 再根据该入口和出口进行打包构建

___

报错：

GitRevisionPlugin is not a constructor theme

按照webpack官网的教程进行学习时，安装`clean-webpack-plugin`插件后（版本为：`"^3.0.0"`），再build时，发现报错了，配置如下：

```
const CleanWebpackPlugin = require('clean-webpack-plugin')

module.exports = {
    ...
    plugins: [
        new CleanWebpackPlugin(['dist'])
    ],
    ...
}
复制代码
```

运行报错：

![image-20210928161735703](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210928161735703.png)



数的具体内容不多介绍，有兴趣的可以自己去[官网查看](https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fjohnagan%2Fclean-webpack-plugin%23options-and-defaults-optional)），参数是可选的，如果什么都不配置默认删除未使用的资源，我们采用默认的即可：



```
const { CleanWebpackPlugin } = require('clean-webpack-plugin')

module.exports = {
    ...
    plugins: [
        new CleanWebpackPlugin()
    ],
    ...
}
复制代码
```

这时再运行，可以正常build啦~~

