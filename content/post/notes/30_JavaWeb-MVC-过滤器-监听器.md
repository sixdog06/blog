---
title: "JavaWeb-MVC/过滤器/监听器"
date: 2021-05-31
draft: false
toc: true
categories: ["学习笔记"]
tags: ["JavaWeb"]
---

## MVC三层架构
MVC: Controller专注于业务处理, 它的处理结果就是Model. Model可以是一个JavaBean(pojo), 也可以是一个包含多个对象的Map, Controller只负责把Model传递给View, View只负责把Model给渲染出来开发Controller时无需关注页面. 开发View时无需关心如何创建Model. `Browser`->`Controller: UserServlet`->`Model: User`->`View: user.jsp`.

- Model: 业务处理: 业务逻辑(Service); 数据持久层: CRUD(Dao)
- View: 展示数据; 提供链接发起Servlet请求(a, form, img...)
- Controller(Servlet): 接受用户请求, req请求参数, session信息. 给业务层处理对应代码; 控制试图跳转.

![](/notes/notes30_1.png)
> 登陆->接受用户的登陆请求->处理用户的请求(获取用户登陆的参数, username, password)->交给业务层处理登陆业务(判断用户名和密码是否正确: 事务)->Dao层查询用户名和密码是否正确.

## 过滤器



## 参考
1. [JavaWeb入门到实战-狂神说Java](https://www.bilibili.com/video/BV12J411M7Sj?p=1)
2. [廖雪峰Java](https://www.liaoxuefeng.com/wiki/1252599548343744/1266264917931808)