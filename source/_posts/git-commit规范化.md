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

