---
title: "JavaWeb-Tomcat/Maven及其配置"
date: 2021-05-10
draft: false
author: "小拳头"
categories: ["WEB开发"]
tags: ["JavaWeb"]
---

## Web服务器
静态web的客户端直接从服务器下文件, 像我的这个博客一样, 没法动态更新. 而动态web中, 服务器可以提供动态的资源, 可以连接数据库. 
![](/47_1.png)

## JSP/Servlet
B/S: 浏览器和服务器, C/S: 客户端和服务器. 而JSP(html嵌入Java)是sun主推的B/S架构, 基于java. 解决PHP无法承载高访问量的情况, 避免ASP的繁琐. 

## Tomcat
`apache-tomcat-7.0.70\webapps\ROOT`下面可以找到默认的webapp, 点`bin`目录中的`startup`启动服务, 就可以看到这个运行的页面. `Connector port="8001" ...>`对应了打开的端口号. 

还可以在`Host`下改域名, 并在windows本地的Host映射中, 将127.0.0.1映射到我们自己的URL上, 那么就可以用自己的域名登录本地的网站了. 回顾访问一个网页的过程, 最先找的就是Host中的ip映射, 然后才找各种缓存, 最后才DNS. 
![](/47_2.png)

## Maven
### 配置
M2_HOME: maven目录下的bin目录; MAVEN_HOME: maven的目录; 在系统的path中配置%MAVEN_HOME%\bin. 在`conf\setting/xml`文件下可以配置maven, 比如常用的配置阿里云镜像.

## idea中配置
### Maven
创建maven项目, 可以选择`create from archetype`中的`amven-archetype-webapp`, 创建一个webapp的maven项目. 填写组id和项目名, 创建项目, 等待jar包下好. **注意在这里有一个坑**, idea的`setting-maven`中找到home, 可能是idea自带的, 可能造成错误. 

作为对比, 不选`archetype`, 就可以创建一个干净的maven项目. 
![](/47_3.png)
![](/47_4.png)

如果新建文件夹, 可以右键, 标记这个文件夹. 比如把`main`下的`java`和`resource`分别标记为源码和资源目录, 一般项目也都是这么做. 也可以在project structure的module中标记. 
![](/47_5.png)

### Tomcat
在`Add Configuration`中点加号, 选择`Tomcat server-local`. 如下配置Tomcat, 其中Application context就是默认生成的目录, 而warning就是因为一个网站要选定一个文件夹的名字. 
![](/47_6.png)
![](/47_7.png)


## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)