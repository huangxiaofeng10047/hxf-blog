---
title: macos设置
date: 2021-04-28 15:49:27
tags:
---

### 必要姿势: 允许安装任何来源程序

打开终端 -> `sudo spctl --master-disable` . 滴滴答答,输入你的管理员密码就解开了

当提示资源已损坏，请移入回收站，请用以下方式

**`运行“终端”，然后复制这段代码“- [ ] sudo xattr -r -d com.apple.quarantine”，然后上“访达”找到“应用程序”里有问题的那个软件，把它拖到“终端”这段代码的页面，然后输入本机密码（密码不显示，输入完回车就可以），接下来就是见证奇迹的时刻了~`**

## 工作流(花样姿势)



> 有了基础的包管理和服务管理,我们才能耍的更好



### 必要姿势: 允许安装任何来源程序



在 macos 10.12+开始,这个允许安装任何来源的应用功能就给安全机制(官方说为了安全,你信么!!)给屏蔽了...



但是有木有法子解开呢...我列出来肯定有了啦..姿势如下!



打开终端 -> `sudo spctl --master-disable` . 滴滴答答,输入你的管理员密码就解开了



### 姿势1: 快速预览



快速预览是 Macos内置的一个功能,就是你选中一个文件的时候,直接空格键(`space`)可以看到一些信息.

比如图片,文档!



但是内置的往往不够强大..万能的基友的社区就有人做了这么些插件来丰富快速预览;



传送门: [quick-look-plugins](https://github.com/sindresorhus/quick-look-plugins);



装了这个可预览的功能起码丰富了一倍不止. 代码高亮,Markdown生成预览,excel,zip 包等等...



### 姿势2: 终端强化



内置的`terminal`说实在的,真不够友好...所以社区就造就了一个`iterm2`



传送门 :[ iterm2 : 提供了多套内置主题,可定制的东西多了](https://www.iterm2.com/).



你觉得我在推崇这个? 不不不,作为一个伪前端,有什么比用前端搞的终端更来的贴心....



这个,大佬们我推崇的是这个,看下面



传送门:[**Hyper**: 基于 electron搞得,高度自定义,配置就是一个 js(热更新),插件都是 npm 包,各种花样 style](https://hyper.is/)



1.x系列还有一些中文输入的 bug ,但是2.x 简直好用!!可以花时间去折腾下.用过都说好!



**好吧,丰富的定制化只是外在的..那么内在呢?** 



我推崇的是这个(`ZSH`),有人说 `fishshell`!萝卜青菜各有所爱哈!



传送门: [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh);



**zsh推荐启用的几个插件(没有的都可以用 brew 安装)**:[**插件列表及介绍**](https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins)



打开`.zshrc`,找到 plugins 启用,名字就是插件,插件之间空格隔开



```
#必备的两个插件
brew install zsh-autosuggestions
brew install zsh-completions
```



```
plugins=(git autojump node npm brew osx extract redis-cli autopep8 history last-working-dir

 pip python sudo web-search)
```



前几个属于必备的:



1. git : 提供了丰富的 git `alias`
2. autojump : 还在一直 `cd xxx`? 只要访问过的(会索引缓存路径),一键直达:`j(autojump) xxx`
3. node : 打开 node api 文档
4. npm : npm 智能提示
5. brew: brew 的智能提示和补全



后面一些看着装了.有 python 和 redis,也有访问目录的,也有直接打开搜索引擎的



### 姿势3: 你喜欢 vim?



但又发现去配置一个成型的 vim 工作量太大,找各种各样的插件...



那么你可以试试这个...基于 `neovim(自命是 vim 与时俱进的继承者)` 基础上的傻瓜包



传送门: [spacevim : 社区驱动的 vim 工作环境](https://github.com/SpaceVim/SpaceVim)



### 姿势4: Alfred



> 肯定会有人说系统内置的`Spotlight`不够用么? 能索引快速跳转的地方也很多



但是Alfred 的强大不仅仅文件的索引...而是可拓展性`workflows`;



传送门:[workflows](https://www.alfredapp.com/workflows/);



这货让`Alfred`的使用效率大大的提高;



这里我就推荐几个;



- Dash : 快速索引跳转到 dash 手册的
- CalireSearch : 索引 calibre 里面的书籍进行跳转
- Github repos : 快速跳转到自己的一些 github 仓(需要配置 token)
- NpmSearch : 快速搜索 npmjs.org 上的某个包,直接浏览器打开
- StackOverflow: .so + question 筛选出问题列表,浏览器打开
- Colors: 颜色处理



之前掘金还有人写了个搜索知乎的... 你动手能力够强也可以自己写一个工作流.



### 姿势5: 编辑器?IDE?



- 首推:[`VSCode`(开源免费)](https://code.visualstudio.com/download) : 非常强大的编辑器
- 其次[`Sublime Text 3`(付费,但可免费使用)](https://www.sublimetext.com/) 或者 [`Atom`(开源免费)](https://atom.io/)
- 最后[`Webstorm`(付费)](https://www.jetbrains.com/webstorm/download/#section=mac)



若是兼顾混合开发,**安卓开发**首选`Android Studio`, **IOS开发**首选`XCode`。



具体可以参考[Flutter for MacOS](https://flutter.io/docs/get-started/install/macos)



### 姿势6: 想看个本地视频,有什么播放器推荐!



足够强大,格式也丰富,功能比 `appstore` 一些付费的还多,除了稳定性还有待完善,其他完美了



传送门: [IINA](https://github.com/lhc70000/iina) , 可以用`brew cask`安装`brew cask install iina`



### 姿势7: 修改 hosts?



会命令行的直接粗暴;



- `sudo vim /etc/hosts` : 然后保存就行



那么有木有可视化工具管理!!有的..



传送门:[SwitchHosts](https://github.com/oldj/SwitchHosts)



### 姿势8: 快捷键有点多,有没有方便记忆的工具



有的,[**CheatSheet**](https://www.mediaatelier.com/CheatSheet/): 长按 Command 键即可调出应用程序的部分快捷键表(为什么是局部!因为有些 APP 的快捷键它读取不到)



### 姿势9: 如何远程控制协助!Mac QQ 木有这功能!



有时候遇到困难要抱好心大佬的大腿,怎么办!!



亦或者有时候看到一些菜鸟,心血来潮想"指点江山",怎么破!



这时候就需要这个闻名已久的软件了;



[teamviewer](https://www.teamviewer.com/zhCN/): 全平台的远程会议或协助软件,非商用免费!!!!!!(你懂的)



`mac`与`mac`之间可以通过内置的远程控制来协助



### 姿势10: 让 MAC 更像 GNU ,命令行更加丰富



> Coreutils - GNU core utilities
>
> The GNU Core Utilities are the basic file, shell and text manipulation utilities of the GNU operating system.
>
> These are the core utilities which are expected to exist on every operating system.



```
brew install coreutils
```



### 姿势11: `exa`:更现代化的`ls`命令,用`Rust`写的`



> A modern version of ‘ls’. https://the.exa.website/



```
brew install exa
```



### 姿势12: 免费好用的系统维护工具



> 很多人去找什么`clean`的付费版,其实国内的鹅厂还是挺良心的



-[Tencent Lemon Cleaner](https://mac.gj.qq.com/) : 监控和清除垃圾,省了两个`app`的钱



## 软件推荐



> 可以用 `brew cask` 用 `#` , 付费用 `$` 表示 , 免费则没有任何符号, `$$`代表付费服务



- [motrix](https://github.com/agalwood/Motrix) : 全平台的下载工具,底层用的`aria`,速度贼快
- [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake): 很赞的一个小工具,让你的本本不被睡眠(时间可控)
- [VS Code - #](https://code.visualstudio.com/Download): 非常棒的代码编辑器
- [MindNode2 - $](https://mindnode.com/): 思维导图软件,很简洁,官方计划年末升级到5
- [VMware Fusion- $/#](https://www.vmware.com/products/fusion/fusion-evaluation.html): 非常好用的虚拟机软件
- [FileZilla - #](https://filezilla-project.org/): 开源免费好用的 FTP 软件(全平台)
- [DBeaver -$/#](https://dbeaver.io/download/) : 非常实用的GUI数据库管理,支持多种数据库
- [VirtualBox - #](https://www.virtualbox.org/wiki/Downloads) : 开源全平台的虚拟机
- [Camtasia - $](https://www.techsmith.com/video-editor.html): 知名的屏幕录制工具,用来做视频教程妥妥的
- [Magnet - $](http://magnet.crowdcafe.com/):窗口快速排版工具
- [eagle - $](https://eagle.cool/macOS): 设计师必备,素材管理工具,很强大
- [Navicat permium - $](https://www.navicat.com/en/download/navicat-premium): 全平台的多数据库管理工具(很强大)
- [SourceTree](https://www.sourcetreeapp.com/): 全平台的 GUI git 管理客户端
- [智图](https://zhitu.isux.us/) : 腾讯出品的图片压缩平台,有客户端!!
- [Robo 3T](https://robomongo.org/): MongoDB数据库的本地管理工具
- [微信开发者工具](https://mp.weixin.qq.com/debug/wxadoc/dev/devtools/download.html):基于`nw.js` 的,但是只打包了 win 和 mac 端!!不解
- [Trello - #/$$](https://trello.com/) : 办公协助软件,用过都说好..我单纯用来做个人列表清单规划(个人免费),有客户端
- [Dr.Unarchive](https://www.drcleaner.com/dr-unarchiver/): 解压缩软件,类似 win 上的好压,就是不知道有没有后x(appstore 有)
- [wiznote - $$](https://www.wiz.cn/):全平台的笔记软件,十多年的国产老牌..值得信赖
- [Calibre - #](https://calibre-ebook.com/): 很强大的图书管理(全平台),可以用来建立一个本地图书库
- [Gifox](https://gifox.io/ - $): 很喜欢这个 GIF 录制工具,小巧美观,也很便宜
- [Dash - $$](https://kapeli.com/dash) : 很全面的手册汇总
- [charles - $$](https://www.charlesproxy.com/) : http 的抓包分析



对于**PS 全家桶**和**ms office 全家桶**这些就看人下载了.网上也有和谐的姿势(你懂的!)



像**QQ,优酷,腾讯视频,有道词典,QQ音乐,网易云音乐**这些,



在`App store`也有(部分应用可以直接`brew cask`),



但是啊,这里的版本可能不如他们推送的快.还有会有部分的功能限制(商店的限制比较多).



官网自家提供的有些需要用到**管理员**特权或者一些系统级的服务!!!



**macos 也可以编译安装一些软件的**!!!!



**Q: 也有可能想说 `markdown`这些的工具呢?**



`VSCode` 或者 `Atom`结合插件来写 markdown 我感觉已经很不错了,



可以做到各种高亮,快捷键补全,导出 PDF 等.



有人说我喜欢做事有安排!有没有清单类的应用!有挺多的,但是感觉毫无卵用.

内置的待办事项(适合当天)+邮件里面的日程安排(重复,未来,整天的行程安排)已经完美了..



## 总结



哦,对了,有人可能也想知道 `Linux`或者 `unix` 的命令能不能直接在 `macos` 使用;

早期的 mac 是基于 bsd 搞的,所以有一定的 unix 血统...

虽有部分命令相同,但是还有一些参数上的差异.



还有一些需要额外去安装,比如 `wget`,`htop`这些



双方都有的命令(`mv`,`cp`,`history`,`file`,`more`....)这些,

功能大同小异(更多的是参数上的区别!!!)



软件不在多,够用就好...

有一些比较敏感的就不推荐了(世界那么大,你不想看看!知识怎么学习的快!)

倘若盲目的去找工具,装那么一大坨很少用或者基本不会用到.纯属浪费生命和电脑磁盘空间

软件推荐：

git-fork

命令推荐：

kafkacat

安装命令

`brew install kafkacat`

# 查看过滤出来的文件
$ find . -name '.DS_Store'
# 删除
$ find . -name '.DS_Store' -type f -exec rm -f {} \;
# 再次检查
$ find . -name '.DS_Store'

maven 4个线程执行

```
mvn -T 4 clean install
```