---
title: Git-子模块
date: 2021-08-17 14:20:24
tags:
- git
categories: 
- tools
---

[官方指南](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E5%AD%90%E6%A8%A1%E5%9D%97)

-   添加子模块
-   初始化并更新子模块

默认情况下，子模块会将子项目放到当前工作目录下的一个与仓库同名的目录中，本例中是 repository-sub-one、repository-sub-two. 如果你想要放到其他地方，那么可以在命令结尾添加一个不同的路径。
<!--more-->



```
git submodule add git@gitee.com:yangzhaoyunfei/repository-sub-one.git
git submodule add git@gitee.com:yangzhaoyunfei/repository-sub-two.git
# 或
git submodule add git@gitee.com:yangzhaoyunfei/repository-sub-two.git path/to/dir
```

.gitmodules 文件。 该配置文件保存了项目 URL 与已经拉取的本地目录之间的映射：



```
[submodule "repository-sub-two"]
path = repository-sub-two
url = git@gitee.com:yangzhaoyunfei/repository-sub-two.git
[submodule "repository-sub-one"]
path = repository-sub-one
url = git@gitee.com:yangzhaoyunfei/repository-sub-one.git
```

Git 子模块允许你**将一个 Git 仓库作为另一个 Git 仓库的子目录**。 它能让你将另一个仓库克隆到自己的项目中，同时还保持提交的独立。

当你不在子模块那个目录中时，Git 并不会跟踪它的内容， 而是将它看作子模块仓库中的某个具体的提交。



```
# 默认会包含该子模块目录，但其中还没有任何文件.
git clone git@gitee.com:yangzhaoyunfei/repository-main

# 在子模块目录中初始化出本地git配置文件
cd ./repository-main/repository-sub-one
git submodule init

# 检出子模块文件
# 从该项目中抓取所有数据并检出到在父项目中列出的合适的提交(子模块自身有多个提交,但检出到父模块的只能有一个提交)
git submodule update

# 或者init update 可以合并为一个操作
git submodule update --init
```



```
# 会自动初始化并更新仓库中的每一个子模块， 包括可能存在的嵌套子模块
git clone --recurse-submodules git@gitee.com:yangzhaoyunfei/repository-main
```



```
# 在子模块目录操作, 主项目中的子模块提交记录会更新
git fetch && git merge origin/master
```


```
# 在主项目中操作, Git 将会自动进入**所有子模块**然后抓取并更新
# 默认master分支
git submodule update --remote

# 或(只更新某个模块)
git submodule update --remote repository-sub-one
```

在主模块中拉取更改只会获取子模块的提交记录,不会检出子模块更新后的文件.所以需要手动更新,



```
# 为防止在主模块中添加了新子模块,所以需要添加--init
git submodule update --init --recursive
```

与在普通仓库上工作无异。

子模块与父模块使用不同的远程仓库，互不影响,以下命令均在父模块根目录下操作


```
# 添加
git submodule add -b master https://github.com/username/reponame.git dirname
# 或
git submodule add -b master git@github.com:username/reponame.git dirname

# 移除
git rm submodule-name
```

Removing a submodule is useful when it is no longer required. The steps below outline the removal of a submodule.

Remove Submodule Delete the section referring to the submodule from the .gitmodules file Stage the changes via git add .gitmodules Delete the relevant section of the submodule from .git/config. Run git rm –cached path\_to\_submodule (no trailing slash) Run rm -rf .git/modules/path\_to\_submodule Commit the changes with \`\`\`git commit -m “Removed submodule " Delete the now untracked submodule files rm -rf path\_to\_submodule

-   [移除子模块](https://forum.freecodecamp.org/t/how-to-remove-a-submodule-in-git/13228)
