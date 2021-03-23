---
title: "如何搭建Hugo博客并部署到Github Page"
date: 2020-09-30
draft: false
toc: true
categories: ["技术小文"]
tags: ["Hugo", "Github page"]
---

因为Hexo博客又一次出现了问题, 在推油的推荐下, 我把个人博客迁移到了Hugo上. 我会根据复习的进度慢慢地把相关的笔记迁移到这里. Hugo的搭建过程非常简单, 可以参考[官方文档](https://gohugo.io/getting-started/quick-start/). 我在这里进行一个简单的总结.

## 安装
我使用的macos进行搭建. 首先用下面的命令安装Hugo:
```
brew install hugo
```

安装好之后用如下命令建站, ``blog``是Hugo博客的主目录名称.
```
hugo new site blog
```

Hugo如果没有theme是无法启动的, 我们可以选择一个自己喜欢的主题, 我选了知乎上高赞的主题, 来自于[flysnow-org](https://github.com/flysnow-org/maupassant-hugo). 很简洁, 并且功能强大. 使用如下命令安装. 因为我准备把博客备份到github, 所以把主题添加到了submodule, 如果没有此需求, 直接git clone也ok.
```
git init
git submodule add https://github.com/flysnow-org/maupassant-hugo themes/maupassant
```

并在配置文件中修改:
```
theme = "maupassant"
```

现在就可以开始写文章了, 首先创建一篇文章:
```
hugo new posts/my-first-post.md
```

启动本地服务器, 就可以在本地看到我们的网页了.
```
hugo server -D
```

## 部署
考虑到成本原因, 我依然把博客部署在了github page, 如果想博客能被国内的搜索引擎搜索到, github page一般不是一个好的选择.

和Hexo一样, Hugo的public文件夹中的内容就是有关静态网站的文件. 在跟目录下输入``hugo``命令, blog文件夹中就会生成public文件夹, 只要把这个文件夹复制到github page那个repo就可以了. 我的操作是在public文件夹下初始化一个git, 并关联到github, 命令如下, 请把其中的repo路径改成你的github page. push这里我选择强制``-f``了, 因为博客的那个repo只是用来放生成的文件而已, 我不在意是否有严格的版本管理. 部署的命令可以放在``.sh``中, 下次使用时就可以一键部署啦.
```
hugo # 生成public文件夹
cd public
git init
git remote add origin git@github.com:huanruiz/huanruiz.github.io.git
git add .
git commit -m 'init'
git push -f --set-upstream origin master
```

大功告成!

## 其他
对于图片的引用, 我们可以把图片直接放到static文件夹下, 比如我保存的图片路径是``static/example.png``, 那么在markdown中就需要填写``![example](/example.png)``, 路径的第一个斜杆不能省略.