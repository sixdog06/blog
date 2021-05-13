---
title: "JavaWeb-Tomcat"
date: 2021-05-10
draft: false
toc: true
categories: ["学习笔记"]
tags: ["Java"]
---

## Web服务器
静态web的客户端直接从服务器下文件, 像我的这个博客一样, 没法动态更新. 而动态web中, 服务器可以提供动态的资源, 可以连接数据库. 
![](/notes/notes27_1.png)

## JSP/Servlet
B/S: 浏览器和服务器, C/S: 客户端和服务器. 而JSP(html嵌入Java)是sun主推的B/S架构, 基于java. 解决PHP无法承载高访问量的情况, 避免ASP的繁琐. 

## Tomcat
`apache-tomcat-7.0.70\webapps\ROOT`下面可以找到默认的webapp, 点`bin`目录中的`startup`启动服务, 就可以看到这个运行的页面. `Connector port="8001" ...>`对应了打开的端口号. 

还可以在`Host`下改域名, 并在windows本地的Host映射中, 将127.0.0.1映射到我们自己的URL上, 那么就可以用自己的域名登录本地的网站了. 回顾访问一个网页的过程, 最先找的就是Host中的ip映射, 然后才找各种缓存, 最后才DNS. 
![](/notes/notes27_2.png)

## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)