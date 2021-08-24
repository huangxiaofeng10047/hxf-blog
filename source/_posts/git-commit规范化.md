---

title: git commit规范化
date: 2021-08-24 08:36:47
tags:
- git
categories: 
- tools
---

## 用什么规范？

受到市面上主流的`约定式提交规范`和`Angular提交准则`的启发，结合前端团队的实际情况（虽然可以通过配置`commitizen`工具来进行强制检查约束，但涉及项目太多，操作较为复杂，且涉及到原生项目和老项目时，需采用别的解决方案，故建议团队采用自觉遵守规范的方法来实现），暂拟定如下格式的 commit 规范

```
// <类型>(影响的作用域): <简要描述>
<type>(<scope>): <subject>
复制代码
```

## type 类型

type 类型只能从以下 7 种类型中，结合实际情况选取

#### 主要 type

-   **feat: 增加新功能**
-   **fix: 修复 bug**

#### 特殊 type

-   **dosc: 只改动了文档/注释相关的内容**
-   **style: 不影响代码运行和含义的改动，例如改变缩进，增删分号**
-   **chore: 构造工具或者外部依赖的改动，例如 webpack,npm,yarn**
-   **refactor: 代码重构（即不是新增功能，也不是修改 bug 的代码变动）**

#### 暂不使用的 type

-   **test: 添加测试或者修改现有测试**

## scope

scope 也为必填项，用于描述改动的范围，例如：路由/组件/工具类/模块。

## subject

本次提交的简短描述，以动词开头

## 其他注意事项

-   建议一次提交只涉及一个模块，如果实在涉及多个模块，建议拆分成多次提交或者编写多行符合上述规范的 message
-   git commit -m 'XXXX' 为编写一行 message 的命令
-   git commit 可以编写多行 message
-   可以为 git 设置 commit 模板，时刻提醒自己

### 设置 git commit 模板方法

1.  修改~/.gitconfig 或者 项目里.git/.gitconfig,添加

```
[commit]
template = ~/.gitmessage
复制代码
```

2.  新建~/.gitmessage 内容可以如下:

```
# head: <type>(<scope>): <subject>
# - type: feat(新功能), fix(修复bug), docs, style, refactor, test, chore
# - scope: 本次提交影响的范围，例如：路由/组件/工具类/模块
# - subject: 本次提交的简短描述，动词开头
#
# 建议一次提交只涉及一个模块，如果实在涉及多个模块，建议拆分成多次提交或者编写多行符合上述规范的message
复制代码
```

### demo

```
feat(baseURL.js): 增加演示环境配置

fix(request.js): 屏蔽公参中的token

feat(购物车模块): 增加清空购物车功能
复制代码
```

```
npm i husky -D
npm i validate-commit-msg -D
```

```
{
  "types": ["feat", "fix", "docs", "style", "refactor", "test", "chore", "revert"],
  "scope": {
    "required": false,
    "allowed": ["*"],
    "validate": false,
    "multiple": false
  },
  "warnOnFail": false,
  "maxSubjectLength": 100,
  "subjectPattern": ".+",
  "subjectPatternErrorMsg": "subject does not match subject pattern!",
  "helpMessage": "",
  "autoFix": false
}

```

```
yarn add validate-git-commit-msg -D
```



```
  "commitmsg": "validate-git-commit-msg"
```

上面方式都不好使：

## Installation

```
$ npm install validate-commit-message
```

## Usage

You can activate the hook from the command line of your project.

```
$ node ./node_modules/.bin/validate-commit-msg
```

A more consistent way is to add a script in your `package.json`.

```
"scripts": {
  "init": "validate-commit-msg"
}
```

Then execute `$ npm run init`.

-   Git代码提交规范

-   前言
-   一、安装插件
-   二、插件使用
-   三、插件讲解

-   1、Header

-   1.1 type
-   1.2 scope
-   1.3 subject

-   2、Body
-   3、Footer

-   四、git hooks校验

## 前言

**为什么要注重代码提交规范？**

在团队协作开发时，每个人提交代码时都会写 commit message。  
每个人都有自己的书写风格，翻看我们组的git log, 可以说是五花八门，十分不利于阅读和维护。  
一般来说，大厂都有一套的自己的提交规范，尤其是在一些大型开源项目中，commit message 都是十分一致的。  
因此，我们需要制定统一标准，促使团队形成一致的代码提交风格，更好的提高工作效率，成为一名有追求的工程师。

一般项目开发都是多分支共存，master、develop、feature、hotfix、release等分支，如下图所示，在这么多分支中，我们会有一个稳定的master分支，但是我们需要将分支代码进行merge。存在规范的commit message可以帮助我们很轻松的合并代码以及发现问题。例如使用Jenkins自动化部署时，我们可以根据jenkins拉取commit message中的Closes issues验证BUG等。  
[![后端必备的 Git Commit Message规范指南-直接食用_第1张图片](https://img.it610.com/image/info8/4dc347e319ee441e993511771408bb39.jpg)](https://img.it610.com/image/info8/4dc347e319ee441e993511771408bb39.jpg)  
下面详细讲解Idea中如果进行规范的提交Git Commit Message。

## 一、安装插件

在开发工具idea中安装**Git Commit Message Plugins**插件

## 二、插件使用

在Commit代码处，选择使用**Git Commit Message Plugins**插件，如下图所示，填写项详细含义请查看《插件详解》总共分为3大部分，Header， Body，Footer详细讲解请看下节。  
[![后端必备的 Git Commit Message规范指南-直接食用_第3张图片](https://gitee.com/hxf88/imgrepo/raw/master/img/23bd329da5364bce991a3a8f6e5be62a.jpg)]

## 三、插件讲解

主要分为下面三个部分： Header， Body，Footer。

```
(): 
// 空一行

// 空一行
```

下面详细解释下个个部分的含义。

### 1、Header

Header的部分只有一行,包括三个字段: type(必需), scope(可选), subject(必需)

对应到idea插件上图的配置分别为 Header部分的:

type(必需)

Type of change

commit类别

**scope(可选)**

**Scope of this change**

commint影响的范围

subject(必需)\*\*\*\*

**Short description**

简短的描述

#### 1.1 type

type用于说明 commit 的类别，只允许使用下面标识

-   feat：新功能（feature）
-   fix：修补bug
-   docs：文档（documentation）
-   style： 格式（不影响代码运行的变动,空格,格式化,等等）
-   refactor：重构（即不是新增功能，也不是修改bug的代码变动）
-   perf: 性能 (提高代码性能的改变)
-   test：增加测试或者修改测试
-   build: 影响构建系统或外部依赖项的更改(maven,gradle,npm 等等)
-   ci: 对CI配置文件和脚本的更改
-   chore：对非 src 和 test 目录的修改
-   revert: Revert a commit

#### 1.2 scope

`scope`用于说明 commit 影响的范围，比如数据层、控制层、视图层等等，视项目不同而不同。

#### 1.3 subject

`subject`是 commit 目的的简短描述，不超过50个字符。

```
以动词开头，使用第一人称现在时，比如change，而不是changed或changes
第一个字母小写
结尾不加句号（.）
```

### 2、Body

Body 部分是对本次 commit 的详细描述，可以分成多行。下面是一个范例。

```
如有必要，更详细的说明文本。包装它
大概72个字左右。

后面的段落在空行之后。

-要点也可以
-使用悬挂缩进
```

有一个注意点。

（1）应该说明代码变动的动机，以及与以前行为的对比。

### 3、Footer

Footer 部分只用于两种情况。

**（1）不兼容变动**

如果当前代码与上一个版本不兼容，则 Footer 部分以`BREAKING CHANGE`开头，后面是对变动的描述、以及变动理由和迁移方法。

**（2）关闭 Issue**

如果当前 commit 针对某个issue，那么可以在 Footer 部分关闭这个 issue 。

```
Closes #234
```

也可以一次关闭多个 issue 。

```
Closes #123, #245, #992
```

最后, 一个完整的commit message示例可能如下:  
[![后端必备的 Git Commit Message规范指南-直接食用_第4张图片](https://gitee.com/hxf88/imgrepo/raw/master/img/a0dcaf9b031a49b6aec8b32b8c8f0dba.jpg)](https://img.it610.com/image/info8/a0dcaf9b031a49b6aec8b32b8c8f0dba.jpg)

## 四、git hooks校验

由于使用idea插件`只防君子，不防小人`。**Git Commit Message Plugins**只能起到模板的作用，开发人员如果误操作或者忘记使用任提交不规范的Commit Message。因此使用git hooks强制开发人员使用以上格式提交。具体操作如下：

在项目目录`.git/hooks`目录下有很多钩子，我们可以根据需要自定义不同的内容，这里我们只需要修改`commit-msg`即可。

首先将`commit-msg.sample` 改为 `commit-msg`，也就是去掉后缀。将里面的内容修改为下面内容。

```
#!/bin/sh

MSG=`awk '{printf("%s",$0)}' $1`
if [[ $MSG =~ ^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)\(.*\):.*$ ]]
then
echo -e "\033[32m commit success! \033[0m"
else
    echo -e "\033[31m Error: the commit message is irregular \033[m"
echo -e "\033[31m Error: type must be one of [feat,fix,docs,style,refactor,perf,test,build,ci,chore,revert] \033[m"
    echo -e "\033[31m eg: feat(user): add the user login \033[m"
exit 1
fi
```

