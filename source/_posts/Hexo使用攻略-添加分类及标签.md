---
title: Hexo使用攻略-添加分类及标签
date: 2021-08-13 09:21:34
tags:
- hexo
- shell
- 表单验证
categories: 
- web前端
---

### 1、创建“分类”选项

#### 1.1 生成“分类”页并添加tpye属性

打开命令行，进入博客所在文件夹。执行命令

```
$ hexo new page categories
```

成功后会提示：

```
INFO  Created: ~/Documents/blog/source/categories/index.md
```

![image-20210813092247207](https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210813092247207.png)

根据上面的路径，找到`index.md`这个文件，打开后默认内容是这样的：

```
---
title: categories
date: 2021-08-13 09:22:29
---
```

添加`type: "categories"`到内容中，添加后是这样的：

```
---
title: categories
date: 2021-08-13 09:22:29
type: "categories"
---

```

保存并关闭文件。



#### 1.2 给文章添加“categories”属性

打开需要添加分类的文章，为其添加categories属性。下方的`categories: web前端`表示添加这篇文章到“web前端”这个分类。注意：hexo一篇文章只能属于一个分类，也就是说如果在“- web前端”下方添加“-xxx”，hexo不会产生两个分类，而是把分类嵌套（即该文章属于 “- web前端”下的 “-xxx ”分类）。

```
---
title: Hexo使用攻略-添加分类及标签
date: 2021-08-13 09:21:34
tags:
categories: 
- web前端
```

至此，成功给文章添加分类，点击首页的“分类”可以看到该分类下的所有文章。当然，只有添加了`categories: xxx`的文章才会被收录到首页的“分类”中。

<img src="https://gitee.com/hxf88/imgrepo/raw/master/img/image-20210813092754872.png" alt="image-20210813092754872" style="zoom:50%;" />

### 2、创建“标签”选项

#### 2.1 生成“标签”页并添加tpye属性

打开命令行，进入博客所在文件夹。执行命令

```
$ hexo new page tags
```

成功后会提示：

```
INFO  Created: ~/Documents/blog/source/tags/index.md
```

根据上面的路径，找到`index.md`这个文件，打开后默认内容是这样的：

```
---
title: tags
date: 2021-08-13 09:28:50
---
```

添加`type: "tags"`到内容中，添加后是这样的：

```
---
title: tags
date: 2021-08-13 09:28:50
type: "tags"
---
```

保存并关闭文件。

#### 2.2 给文章添加“tags”属性

打开需要添加标签的文章，为其添加tags属性。下方的`tags:`下方的`- jQuery` `- 表格`
`- 表单验证`就是这篇文章的标签了

```
---
title: Hexo使用攻略-添加分类及标签
date: 2021-08-13 09:21:34
tags:
- hexo
- shell
- 表单验证
categories: 
- web前端
---
```

至此，成功给文章添加分类，点击首页的“标签”可以看到该标签下的所有文章。当然，只有添加了`tags: xxx`的文章才会被收录到首页的“标签”中。

细心的朋友可能已经发现，这两个的设置几乎一模一样！是的，没错，思路都是一样的。所以我们可以打开scaffolds/post.md文件，在tages:上面加入categories:,保存后，之后执行`hexo new 文章名`命令生成的文件，页面里就有`categories:`项了。

scaffolds目录下，是新建页面的模板，执行新建命令时，是根据这里的模板页来完成的，所以可以在这里根据你自己的需求添加一些默认值。

教程结束，赶紧去设置吧！
